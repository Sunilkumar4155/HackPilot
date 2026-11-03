import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/hackathon.dart';
import '../services/bookmark_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hackathon_image_view.dart';
import 'login_screen.dart';

class HackathonDetailsScreen extends StatefulWidget {
  final String hackathonId;
  final String title;
  final String organizer;
  final String deadline;
  final String prize;
  final String description;
  final String location;
  final String mode;
  final String teamSize;
  final String registrationLink;
  final String imageUrl;

  const HackathonDetailsScreen({
    super.key,
    this.hackathonId = '',
    required this.title,
    required this.organizer,
    required this.deadline,
    required this.prize,
    required this.description,
    required this.location,
    required this.mode,
    required this.teamSize,
    required this.registrationLink,
    this.imageUrl = '',
  });

  @override
  State<HackathonDetailsScreen> createState() => _HackathonDetailsScreenState();
}

class _HackathonDetailsScreenState extends State<HackathonDetailsScreen> {
  final _translationService = TranslationService();

  bool _savingBookmark = false;
  bool _launchingRegistration = false;

  // Translation states
  bool _isTranslating = false;
  bool _showOriginal = false;
  String _activeTitle = '';
  String _activeDescription = '';
  String? _detectedLanguage;
  bool _wasTranslated = false;
  bool _translationFailed = false;

  @override
  void initState() {
    super.initState();
    _activeTitle = widget.title;
    _activeDescription = widget.description;
    _initiateTranslation();
  }

  Future<void> _initiateTranslation() async {
    final titleNeeds = !_translationService.isLikelyEnglish(widget.title);
    final descNeeds = widget.description.trim().isNotEmpty &&
        !_translationService.isLikelyEnglish(widget.description);

    if (!titleNeeds && !descNeeds) {
      return;
    }

    if (mounted) setState(() => _isTranslating = true);

    try {
      final titleResult = await _translationService.translateToEnglish(widget.title);
      final descResult = await _translationService.translateToEnglish(widget.description);

      if (!mounted) return;

      final anyTranslated = titleResult.wasTranslated || descResult.wasTranslated;
      final anyFailed = (titleNeeds && titleResult.isError) || (descNeeds && descResult.isError);

      setState(() {
        _isTranslating = false;
        if (anyTranslated) {
          _wasTranslated = true;
          _activeTitle = titleResult.wasTranslated ? titleResult.translatedText : widget.title;
          _activeDescription = descResult.wasTranslated ? descResult.translatedText : widget.description;
          _detectedLanguage = titleResult.wasTranslated
              ? titleResult.detectedLanguage
              : descResult.detectedLanguage;
        } else if (anyFailed) {
          _translationFailed = true;
          _detectedLanguage = titleResult.detectedLanguage != 'English'
              ? titleResult.detectedLanguage
              : descResult.detectedLanguage;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translationFailed = true;
        });
      }
    }
  }

  Color get _background => context.hubColors.background;
  Color get _surface => context.hubColors.surface;
  Color get _ink => context.hubColors.ink;
  Color get _muted => context.hubColors.muted;
  Color get _border => context.hubColors.border;
  Color get _orange => context.hubColors.primary;
  Color get _cyan => const Color(0xFF00D9E8);

  String get _currentTitle => _showOriginal ? widget.title : _activeTitle;
  String get _currentDescription => _showOriginal ? widget.description : _activeDescription;

  String get _displayLocation {
    final temp = Hackathon(
      id: widget.hackathonId,
      title: widget.title,
      organizer: widget.organizer,
      deadline: widget.deadline,
      prize: widget.prize,
      description: widget.description,
      location: widget.location,
      mode: widget.mode,
      teamSize: widget.teamSize,
      registrationLink: widget.registrationLink,
      imageUrl: widget.imageUrl,
    );
    return temp.displayLocation;
  }

  bool get _isOnline {
    final m = widget.mode.trim().toLowerCase();
    final loc = widget.location.trim().toLowerCase();
    if (m.contains('hybrid') || loc.contains('hybrid')) return false;
    return m.contains('online') ||
        m.contains('virtual') ||
        m.contains('remote') ||
        loc == 'online' ||
        loc == 'virtual' ||
        loc == 'remote' ||
        loc.startsWith('online');
  }

  bool _hasValue(String value) {
    final text = value.trim().toLowerCase();
    return text.isNotEmpty && !Hackathon.isPlaceholder(text);
  }

  DateTime? get _deadline => DateTime.tryParse(widget.deadline.trim());

  String get _deadlineLabel {
    final date = _deadline;
    if (date == null) return widget.deadline.trim();
    final local = date.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  String get _deadlineState {
    final date = _deadline;
    if (date == null) return '';
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return 'REGISTRATION CLOSED';
    if (days <= 7) return days == 0 ? 'CLOSES TODAY' : 'CLOSES IN $days DAYS';
    return 'REGISTRATION OPEN';
  }

  String get _category {
    final text = '$_currentTitle $_currentDescription'.toLowerCase();
    if (_contains(text, ['ai', 'machine learning', 'llm', 'neural'])) return 'AI & MACHINE LEARNING';
    if (_contains(text, ['cyber', 'security', 'privacy'])) return 'CYBERSECURITY';
    if (_contains(text, ['robot', 'hardware', 'iot'])) return 'ROBOTICS & HARDWARE';
    if (_contains(text, ['space', 'satellite', 'nasa'])) return 'SPACE TECHNOLOGY';
    if (_contains(text, ['climate', 'sustainability', 'environment'])) return 'CLIMATE';
    if (_contains(text, ['startup', 'entrepreneur', 'founder'])) return 'STARTUP';
    if (_contains(text, ['web', 'frontend', 'website'])) return 'WEB DEVELOPMENT';
    return 'HACKATHON';
  }

  bool _contains(String value, List<String> terms) => terms.any(value.contains);

  Future<void> _toggleBookmark(bool isSaved) async {
    if (widget.hackathonId.isEmpty) {
      _message('This opportunity cannot be saved because its ID is missing.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance.authStateChanges().first;
    if (!mounted) return;
    if (user == null) {
      final event = Hackathon(
        id: widget.hackathonId,
        title: widget.title,
        organizer: widget.organizer,
        deadline: widget.deadline,
        prize: widget.prize,
        description: widget.description,
        location: widget.location,
        mode: widget.mode,
        teamSize: widget.teamSize,
        registrationLink: widget.registrationLink,
        imageUrl: widget.imageUrl,
      );
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoginScreen(pendingBookmark: event)),
      );
      return;
    }
    setState(() => _savingBookmark = true);
    try {
      final service = BookmarkService();
      if (isSaved) {
        await service.removeBookmark(widget.hackathonId);
      } else {
        await service.addBookmark(
          hackathonId: widget.hackathonId,
          data: {
            'title': widget.title,
            'organizer': widget.organizer,
            'deadline': widget.deadline,
            'prize': widget.prize,
            'description': widget.description,
            'location': widget.location,
            'mode': widget.mode,
            'teamSize': widget.teamSize,
            'registrationLink': widget.registrationLink,
            'imageUrl': widget.imageUrl,
          },
        );
      }
      _message(isSaved ? 'Removed from saved hackathons.' : 'Hackathon saved.');
    } catch (_) {
      _message('Could not update your saved hackathons. Please try again.');
    } finally {
      if (mounted) setState(() => _savingBookmark = false);
    }
  }

  Uri? _parseRegistrationUri(String rawLink) {
    final trimmed = rawLink.trim();
    if (trimmed.isEmpty) return null;
    final withScheme = (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
        ? trimmed
        : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty) {
      return uri;
    }
    return null;
  }

  Future<void> _register() async {
    final uri = _parseRegistrationUri(widget.registrationLink);
    if (uri == null) {
      _message('A valid registration link is not available.');
      return;
    }

    final isMobile = MediaQuery.sizeOf(context).width < 768;
    if (isMobile) {
      await _showRegistrationConfirmation(uri);
    } else {
      await _performLaunch(uri);
    }
  }

  Future<void> _showRegistrationConfirmation(Uri uri) async {
    final domain = uri.host.isNotEmpty ? uri.host : 'registration portal';
    final colors = context.hubColors;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.open_in_browser_rounded, color: _orange, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Open Registration Website',
                            style: TextStyle(
                              color: colors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.language_rounded, size: 14, color: _cyan),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              domain,
                              style: TextStyle(
                                color: _cyan,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'MOBILE VIEWPORT READY',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Opens in your default mobile browser with full responsive scaling, readable text, and secure authentication.',
                        style: TextStyle(
                          color: colors.muted,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: uri.toString()));
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext, false);
                        }
                        _message('Registration URL copied to clipboard.');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.ink,
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Continue to Website'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await _performLaunch(uri);
    }
  }

  Future<void> _performLaunch(Uri uri) async {
    setState(() => _launchingRegistration = true);
    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success) {
        final fallbackSuccess = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (!fallbackSuccess) {
          await Clipboard.setData(ClipboardData(text: uri.toString()));
          _message('Could not open browser. Link copied to clipboard.');
        }
      }
    } catch (_) {
      try {
        final fallbackSuccess = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (!fallbackSuccess) {
          await Clipboard.setData(ClipboardData(text: uri.toString()));
          _message('Could not open browser. Link copied to clipboard.');
        }
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        _message('Could not open browser. Link copied to clipboard.');
      }
    } finally {
      if (mounted) {
        setState(() => _launchingRegistration = false);
      }
    }
  }

  Future<void> _share() async {
    final link = widget.registrationLink.trim();
    if (!_hasValue(link)) {
      _message('An event link is not available to share.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    _message('Event link copied to clipboard.');
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formattedDescription(String description) {
    final lines = description.replaceAll('\r', '').split('\n');
    const knownHeadings = [
      'overview', 'about', 'challenge', 'objectives', 'themes', 'tracks',
      'eligibility', 'who can participate', 'prizes', 'prize', 'schedule',
      'agenda', 'important dates', 'rules', 'what to bring', 'sponsors',
      'resources', 'submission', 'judging criteria',
    ];
    return lines.map((line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#') ||
          trimmed.startsWith('- ') || trimmed.startsWith('* ') ||
          RegExp(r'^\d+[.)]\s').hasMatch(trimmed)) {
        return line;
      }
      final normalized = trimmed.toLowerCase().replaceAll(':', '');
      if (knownHeadings.contains(normalized)) return '### $trimmed';
      return line;
    }).join('\n');
  }

  String? _descriptionSection(List<String> names, [String? source]) {
    final raw = source ?? _currentDescription;
    final lines = raw.replaceAll('\r', '').split('\n');
    final headingPattern = RegExp(
      r'^\s{0,3}#{0,3}\s*([^:]+?)\s*:?\s*(.*)$',
      caseSensitive: false,
    );
    final endNames = [
      'overview', 'about', 'challenge', 'objectives', 'themes', 'tracks',
      'eligibility', 'who can participate', 'prizes', 'prize', 'schedule',
      'agenda', 'important dates', 'rules', 'what to bring', 'sponsors',
      'resources', 'submission', 'judging criteria',
    ];
    for (var i = 0; i < lines.length; i++) {
      final match = headingPattern.firstMatch(lines[i].trim());
      if (match == null) continue;
      final heading = match.group(1)!.trim().toLowerCase();
      if (!names.any((name) => heading == name || heading.startsWith('$name '))) continue;
      final content = <String>[];
      final inline = match.group(2)?.trim() ?? '';
      if (inline.isNotEmpty) content.add(inline);
      for (var j = i + 1; j < lines.length; j++) {
        final next = lines[j].trim();
        final nextMatch = headingPattern.firstMatch(next);
        final nextHeading = nextMatch?.group(1)?.trim().toLowerCase() ?? '';
        if (nextHeading.isNotEmpty && endNames.contains(nextHeading)) break;
        content.add(lines[j]);
      }
      final result = content.join('\n').trim();
      if (result.isNotEmpty) return result;
    }
    return null;
  }

  Widget _translationBanner() {
    if (_isTranslating) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D9E8)),
            ),
            const SizedBox(width: 10),
            Text(
              'Translating content to English...',
              style: TextStyle(color: _muted, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (_wasTranslated) {
      final lang = _detectedLanguage ?? 'original language';
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF00D9E8).withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.translate_rounded, color: Color(0xFF00D9E8), size: 16),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _showOriginal
                    ? 'Showing original text in $lang'
                    : 'Translated to English from $lang',
                style: TextStyle(
                  color: _ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _showOriginal = !_showOriginal),
              icon: Icon(
                _showOriginal ? Icons.translate_rounded : Icons.history_rounded,
                size: 14,
                color: const Color(0xFF00D9E8),
              ),
              label: Text(
                _showOriginal ? 'Show English' : 'Show Original',
                style: const TextStyle(
                  color: Color(0xFF00D9E8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
      );
    }

    if (_translationFailed) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: _muted, size: 16),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Translation unavailable • Showing original text',
                style: TextStyle(color: _muted, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _cover(double width) {
    final event = Hackathon(
      id: widget.hackathonId,
      title: _currentTitle,
      organizer: widget.organizer,
      deadline: widget.deadline,
      prize: widget.prize,
      description: _currentDescription,
      location: widget.location,
      mode: widget.mode,
      teamSize: widget.teamSize,
      registrationLink: widget.registrationLink,
      imageUrl: widget.imageUrl,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: width >= 850 ? 320 : 230,
        width: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
          HackathonImageView(
            event: event,
            showGradientOverlay: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22050A12), Color(0xEB080B10)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 18,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badge(_category, _orange),
                const SizedBox(height: 12),
                Text(
                  _currentTitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width >= 850 ? 34 : 25,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.7,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 2))],
                  ),
                ),
              ],
            ),
          ),
          if (_deadlineState.isNotEmpty)
            Positioned(
              right: 14,
              top: 14,
              child: _badge(_deadlineState, _cyan),
            ),
        ]),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xE6101720),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withValues(alpha: .65)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .6)),
  );

  Widget _hero(bool wide) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 22 : 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101A27), Color(0xFF0B1017)],
        ),
        border: Border.all(color: _border.withValues(alpha: .9)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x28000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cover(wide ? 900 : 600),
        const SizedBox(height: 17),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _orange.withValues(alpha: .25)),
            ),
            child: Center(
              child: Text(
                widget.organizer.trim().isEmpty ? '?' : widget.organizer.trim()[0].toUpperCase(),
                style: TextStyle(color: _orange, fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ORGANIZED BY', style: TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 3),
            Text(widget.organizer, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w800)),
          ])),
          IconButton(onPressed: _share, tooltip: 'Copy event link', icon: Icon(Icons.share_outlined, color: _cyan)),
          if (widget.hackathonId.isNotEmpty) _bookmarkControl(user),
        ]),
        const SizedBox(height: 13),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _metaChip(
            _isOnline ? Icons.wifi_rounded : Icons.location_on_outlined,
            _displayLocation,
          ),
          if (!_isOnline && _hasValue(widget.mode))
            _metaChip(Icons.laptop_chromebook_outlined, widget.mode),
          if (_hasValue(widget.teamSize))
            _metaChip(Icons.groups_outlined, 'Team ${widget.teamSize}'),
          if (_hasValue(widget.deadline))
            _metaChip(Icons.event_outlined, 'Deadline · $_deadlineLabel'),
        ]),
        if (!wide) ...[
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: _registerButton()),
        ],
      ]),
    );
  }

  Widget _metaChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(5), border: Border.all(color: _border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: _cyan),
      const SizedBox(width: 5),
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _muted, fontSize: 11))),
    ]),
  );

  Widget _bookmarkControl(User? user) {
    if (user == null) {
      return IconButton(
        onPressed: _savingBookmark ? null : () => _toggleBookmark(false),
        tooltip: 'Save hackathon',
        icon: Icon(Icons.bookmark_add_outlined, color: _orange),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(widget.hackathonId)
          .snapshots(),
      builder: (context, snapshot) {
        final saved = snapshot.data?.exists ?? false;
        return IconButton(
          onPressed: _savingBookmark ? null : () => _toggleBookmark(saved),
          tooltip: saved ? 'Remove bookmark' : 'Save hackathon',
          icon: Icon(saved ? Icons.bookmark_added : Icons.bookmark_add_outlined, color: _orange),
        );
      },
    );
  }

  Widget _registerButton() => ElevatedButton.icon(
    onPressed: (_hasValue(widget.registrationLink) && !_launchingRegistration)
        ? _register
        : null,
    icon: _launchingRegistration
        ? const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : const Icon(Icons.open_in_new_rounded, size: 17),
    label: Text(_launchingRegistration ? 'OPENING...' : 'REGISTER NOW'),
    style: ElevatedButton.styleFrom(
      backgroundColor: _orange,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: .5),
    ),
  );

  List<(IconData, String, String, Color)> _facts() => [
    (Icons.emoji_events_outlined, 'Prize pool', widget.prize, _orange),
    (Icons.event_outlined, 'Registration deadline', _deadlineLabel, _cyan),
    (Icons.groups_outlined, 'Team size', widget.teamSize, _orange),
    (Icons.laptop_chromebook_outlined, 'Format', _hasValue(widget.mode) ? widget.mode : (_isOnline ? 'Online' : 'In-person'), _cyan),
    (Icons.location_on_outlined, 'Location', _displayLocation, _orange),
    (Icons.business_outlined, 'Organizer', widget.organizer, _cyan),
  ].where((fact) {
    if (fact.$2 == 'Location') return true;
    return _hasValue(fact.$3);
  }).toList();

  Widget _factsGrid(bool wide) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth >= 740 ? 3 : constraints.maxWidth >= 480 ? 2 : 1;
    final facts = _facts();
    if (facts.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: facts.map((fact) => SizedBox(
        width: (constraints.maxWidth - (columns - 1) * 10) / columns,
        child: _factCard(fact.$1, fact.$2, fact.$3, fact.$4),
      )).toList(),
    );
  });

  Widget _factCard(IconData icon, String label, String value, Color accent) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF141D29), Color(0xFF101720)]),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border.withValues(alpha: .85)),
    ),
    child: Row(children: [
      Container(width: 39, height: 39, decoration: BoxDecoration(color: accent.withValues(alpha: .12), borderRadius: BorderRadius.circular(10), border: Border.all(color: accent.withValues(alpha: .18))), child: Icon(icon, size: 19, color: accent)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: _ink, fontSize: 12, height: 1.25, fontWeight: FontWeight.w700)),
      ])),
    ]),
  );

  Widget _section(String title, {String? subtitle, required Widget child}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 4,
          height: 23,
          decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: TextStyle(
          color: _ink, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.35,
        ))),
      ]),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(subtitle, style: TextStyle(color: _muted, fontSize: 11, height: 1.4)),
        ),
      ],
      const SizedBox(height: 14),
      child,
    ],
  );

  Widget _markdownCard(String data) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _border.withValues(alpha: .9)),
    ),
    child: MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: _ink, height: 1.65, fontSize: 13),
        h1: TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w800),
        h2: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w800),
        h3: TextStyle(color: _cyan, fontSize: 14, fontWeight: FontWeight.w800),
        listBullet: TextStyle(color: _orange),
        strong: TextStyle(color: _ink, fontWeight: FontWeight.w800),
        a: TextStyle(color: _cyan, decoration: TextDecoration.underline),
        blockquote: TextStyle(color: _muted, height: 1.5),
      ),
      onTapLink: (_, href, _) {
        if (href != null) {
          final uri = Uri.tryParse(href.trim());
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
          }
        }
      },
    ),
  );

  Widget _registrationPanel() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
      boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 18, offset: Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Registration', style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      if (_hasValue(widget.deadline)) _panelFact('Deadline', _deadlineLabel),
      if (_hasValue(widget.prize)) _panelFact('Prize pool', widget.prize),
      if (_hasValue(widget.teamSize)) _panelFact('Team size', widget.teamSize),
      _panelFact('Location', _displayLocation),
      if (!_isOnline && _hasValue(widget.mode)) _panelFact('Format', widget.mode),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: _registerButton()),
      if (_deadlineState.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(_deadlineState, style: TextStyle(color: _deadlineState.contains('CLOSED') ? _muted : _cyan, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .5)),
      ],
    ]),
  );

  Widget _panelFact(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label, style: TextStyle(color: _muted, fontSize: 11))),
      const SizedBox(width: 10),
      Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w700))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final registrationText = _hasValue(widget.registrationLink);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: _ink), onPressed: () => Navigator.maybePop(context)),
        title: Text('Hackathon details', style: TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(onPressed: _share, tooltip: 'Copy event link', icon: Icon(Icons.share_outlined, color: _cyan)),
          if (widget.hackathonId.isNotEmpty) _bookmarkControl(user),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1120;
        final mainContent = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _hero(wide),
          const SizedBox(height: 24),
          if (registrationText && !wide) ...[
            _registrationPanel(),
            const SizedBox(height: 24),
          ],
          _section('At a glance', subtitle: 'The event information provided by its organizer.', child: _factsGrid(wide)),
          const SizedBox(height: 26),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _translationBanner(),
            if (_currentDescription.trim().isNotEmpty) ...[
              _section('About this hackathon', subtitle: 'Challenge details, themes and event information.', child: _markdownCard(_formattedDescription(_currentDescription))),
              const SizedBox(height: 24),
            ],
            if (_hasValue(widget.prize)) ...[
              _section('Prizes and rewards', subtitle: 'Prize information supplied for this listing.', child: _prizeCard(widget.prize)),
              const SizedBox(height: 24),
            ],
            _optionalDescriptionSection('Eligibility', ['eligibility', 'who can participate', 'participation']),
            _optionalDescriptionSection('Event schedule', ['schedule', 'agenda']),
            _optionalDescriptionSection('Themes and tracks', ['themes', 'tracks', 'problem statements']),
            _optionalDescriptionSection('Additional rewards', ['additional rewards', 'sponsor perks', 'special awards', 'rewards']),
            _optionalDescriptionSection('Sponsors', ['sponsors', 'partners']),
            if (!wide) ...[
              _section('Organizer and event link', child: _organizerCard()),
              const SizedBox(height: 24),
            ],
          ]),
        ]);
        if (wide && registrationText) {
          return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: SingleChildScrollView(
                child: Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Padding(padding: const EdgeInsets.fromLTRB(24, 14, 20, 32), child: mainContent),
                )),
              ),
            ),
            SizedBox(
              width: 302,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 28, 22, 24),
                child: Column(children: [
                  _registrationPanel(),
                  const SizedBox(height: 14),
                  _organizerCard(),
                ]),
              ),
            ),
          ]);
        }
        return SingleChildScrollView(
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 34), child: mainContent),
          )),
        );
      }),
    );
  }

  Widget _prizeCard(String prize) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A2117), Color(0xFF171A20), Color(0xFF111923)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _orange.withValues(alpha: .42)),
      boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 18, offset: Offset(0, 7))],
    ),
    child: Row(children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _orange.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _orange.withValues(alpha: .25)),
        ),
        child: Icon(Icons.emoji_events_rounded, color: _orange, size: 25),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TOTAL PRIZE POOL', style: TextStyle(color: _orange, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        const SizedBox(height: 5),
        Text(prize, style: TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w900, height: 1.2)),
      ])),
      Icon(Icons.arrow_outward_rounded, color: _orange.withValues(alpha: .8), size: 19),
    ]),
  );

  Widget _optionalDescriptionSection(String title, List<String> headings) {
    final content = _descriptionSection(headings);
    if (content == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: _section(title, child: _markdownCard(content)),
    );
  }

  Widget _organizerCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
    child: Row(children: [
      CircleAvatar(radius: 20, backgroundColor: _cyan.withValues(alpha: .12), child: Text(widget.organizer.trim().isEmpty ? '?' : widget.organizer.trim()[0].toUpperCase(), style: TextStyle(color: _cyan, fontWeight: FontWeight.w800))),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ORGANIZED BY', style: TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .7)), const SizedBox(height: 4), Text(widget.organizer, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700))])),
      if (_hasValue(widget.registrationLink)) IconButton(onPressed: _register, tooltip: 'Open event website', icon: Icon(Icons.open_in_new_rounded, color: _cyan, size: 18)),
    ]),
  );
}
