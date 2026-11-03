import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/hackathon.dart';
import '../services/bookmark_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hackathon_image_view.dart';
import 'login_screen.dart';
import 'team_finder_screen.dart';

class HackathonDetailsScreen extends StatefulWidget {
  final Hackathon? hackathon;
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
  final String officialWebsite;
  final String startDate;
  final String endDate;
  final String submissionDeadline;
  final List<String> themes;
  final String eligibility;
  final String problemStatements;
  final String judgingCriteria;
  final String requiredSkills;
  final String registrationInstructions;
  final String contactInfo;
  final String venue;

  const HackathonDetailsScreen({
    super.key,
    this.hackathon,
    this.hackathonId = '',
    this.title = '',
    this.organizer = '',
    this.deadline = '',
    this.prize = '',
    this.description = '',
    this.location = '',
    this.mode = '',
    this.teamSize = '',
    this.registrationLink = '',
    this.imageUrl = '',
    this.officialWebsite = '',
    this.startDate = '',
    this.endDate = '',
    this.submissionDeadline = '',
    this.themes = const [],
    this.eligibility = '',
    this.problemStatements = '',
    this.judgingCriteria = '',
    this.requiredSkills = '',
    this.registrationInstructions = '',
    this.contactInfo = '',
    this.venue = '',
  });

  @override
  State<HackathonDetailsScreen> createState() => _HackathonDetailsScreenState();
}

class _HackathonDetailsScreenState extends State<HackathonDetailsScreen> {
  final _translationService = TranslationService();

  late Hackathon _event;
  bool _savingBookmark = false;
  bool _launchingRegistration = false;
  bool _launchingWebsite = false;
  bool _isDescriptionExpanded = false;

  // Translation state
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
    _initEvent();
    _activeTitle = _event.title;
    _activeDescription = _event.description;
    _initiateTranslation();
  }

  void _initEvent() {
    final h = widget.hackathon;
    if (h != null) {
      _event = h;
    } else {
      _event = Hackathon(
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
        officialWebsite: widget.officialWebsite,
        startDate: widget.startDate,
        endDate: widget.endDate,
        submissionDeadline: widget.submissionDeadline,
        themes: widget.themes,
        eligibility: widget.eligibility,
        problemStatements: widget.problemStatements,
        judgingCriteria: widget.judgingCriteria,
        requiredSkills: widget.requiredSkills,
        registrationInstructions: widget.registrationInstructions,
        contactInfo: widget.contactInfo,
        venue: widget.venue,
      );
    }
  }

  Future<void> _initiateTranslation() async {
    final titleNeeds = !_translationService.isLikelyEnglish(_event.title);
    final descNeeds = _event.description.trim().isNotEmpty &&
        !_translationService.isLikelyEnglish(_event.description);

    if (!titleNeeds && !descNeeds) return;

    if (mounted) setState(() => _isTranslating = true);

    try {
      final titleResult = await _translationService.translateToEnglish(_event.title);
      final descResult = await _translationService.translateToEnglish(_event.description);

      if (!mounted) return;

      final anyTranslated = titleResult.wasTranslated || descResult.wasTranslated;
      final anyFailed = (titleNeeds && titleResult.isError) || (descNeeds && descResult.isError);

      setState(() {
        _isTranslating = false;
        if (anyTranslated) {
          _wasTranslated = true;
          _activeTitle = titleResult.wasTranslated ? titleResult.translatedText : _event.title;
          _activeDescription = descResult.wasTranslated ? descResult.translatedText : _event.description;
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
  Color get _emerald => const Color(0xFF10B981);
  Color get _cardBg => const Color(0xFF141C28);

  String get _currentTitle => _showOriginal ? _event.title : _activeTitle;
  String get _currentDescription => _showOriginal ? _event.description : _activeDescription;

  Hackathon get _currentEvent => _event.copyWith(
        title: _currentTitle,
        description: _currentDescription,
      );

  bool _hasValue(String value) {
    final text = value.trim().toLowerCase();
    return text.isNotEmpty && !Hackathon.isPlaceholder(text);
  }

  DateTime? get _deadline => DateTime.tryParse(_event.deadline.trim());

  String _formatDateString(String raw) {
    if (!_hasValue(raw)) return 'Not specified by organizer';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw.trim();
    final local = parsed.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  String get _deadlineLabel => _formatDateString(_event.deadline);

  String get _deadlineState {
    final date = _deadline;
    if (date == null) return '';
    final days = date.difference(DateTime.now()).inDays;
    if (days < 0) return 'REGISTRATION CLOSED';
    if (days == 0) return 'CLOSES TODAY';
    if (days <= 7) return 'CLOSES IN $days DAYS';
    return 'REGISTRATION OPEN';
  }

  String get _category {
    final text = '$_currentTitle $_currentDescription'.toLowerCase();
    if (_contains(text, ['ai', 'machine learning', 'llm', 'neural', 'agent'])) return 'AI & MACHINE LEARNING';
    if (_contains(text, ['cyber', 'security', 'privacy', 'ctf'])) return 'CYBERSECURITY';
    if (_contains(text, ['robot', 'hardware', 'iot', 'sensor'])) return 'ROBOTICS & IOT';
    if (_contains(text, ['space', 'satellite', 'nasa', 'aerospace'])) return 'SPACE TECHNOLOGY';
    if (_contains(text, ['climate', 'sustainability', 'green', 'clean'])) return 'CLIMATE & CLEANTECH';
    if (_contains(text, ['blockchain', 'web3', 'crypto', 'solana', 'eth'])) return 'WEB3 & BLOCKCHAIN';
    if (_contains(text, ['fintech', 'finance', 'payment', 'banking'])) return 'FINTECH';
    if (_contains(text, ['web', 'frontend', 'website', 'fullstack'])) return 'WEB DEVELOPMENT';
    if (_contains(text, ['mobile', 'flutter', 'android', 'ios'])) return 'MOBILE APP DEV';
    return 'HACKATHON';
  }

  bool _contains(String value, List<String> terms) => terms.any(value.contains);

  Uri? _parseVerifiedUri(String rawLink) {
    final trimmed = rawLink.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains('://') && !trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return null;
    }
    final withScheme = (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
        ? trimmed
        : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty) {
      return uri;
    }
    return null;
  }

  Future<void> _performLaunch(Uri uri, String actionLabel) async {
    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback) {
          await Clipboard.setData(ClipboardData(text: uri.toString()));
          _message('Could not open browser. Link copied to clipboard.');
        }
      }
    } catch (_) {
      try {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback) {
          await Clipboard.setData(ClipboardData(text: uri.toString()));
          _message('Could not open browser. Link copied to clipboard.');
        }
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        _message('Could not open browser. Link copied to clipboard.');
      }
    }
  }

  Future<void> _register() async {
    final uri = _parseVerifiedUri(_event.registrationLink);
    if (uri == null) {
      _message('A valid registration link was not provided by the organizer.');
      return;
    }

    final isMobile = MediaQuery.sizeOf(context).width < 768;
    if (isMobile) {
      await _showRegistrationConfirmation(uri);
    } else {
      setState(() => _launchingRegistration = true);
      await _performLaunch(uri, 'Registration');
      if (mounted) setState(() => _launchingRegistration = false);
    }
  }

  Future<void> _visitOfficialWebsite() async {
    final verifiedUrl = _event.verifiedOfficialWebsite;
    if (verifiedUrl.isEmpty) {
      _message('Official website was not specified by the organizer.');
      return;
    }

    final uri = _parseVerifiedUri(verifiedUrl);
    if (uri == null) {
      _message('The organizer website link is invalid or malformed.');
      return;
    }

    setState(() => _launchingWebsite = true);
    await _performLaunch(uri, 'Official Website');
    if (mounted) setState(() => _launchingWebsite = false);
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
                            'Open Registration Portal',
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
                              color: _emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'VERIFIED SECURE LINK',
                              style: TextStyle(
                                color: _emerald,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Opens in your default browser with responsive viewport scaling, readable text, and secure external authentication.',
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
      setState(() => _launchingRegistration = true);
      await _performLaunch(uri, 'Registration');
      if (mounted) setState(() => _launchingRegistration = false);
    }
  }

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleBookmark(bool isSaved) async {
    if (_event.id.isEmpty) {
      _message('This hackathon cannot be saved because its ID is missing.');
      return;
    }
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser ??
          await FirebaseAuth.instance.authStateChanges().first;
    } catch (_) {
      user = null;
    }
    if (!mounted) return;
    if (user == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoginScreen(pendingBookmark: _event)),
      );
      return;
    }
    setState(() => _savingBookmark = true);
    try {
      final service = BookmarkService();
      if (isSaved) {
        await service.removeBookmark(_event.id);
      } else {
        await service.addBookmark(
          hackathonId: _event.id,
          data: _event.toMap(),
        );
      }
      _message(isSaved ? 'Removed from saved hackathons.' : 'Hackathon saved to bookmarks.');
    } catch (_) {
      _message('Could not update saved hackathons. Please try again.');
    } finally {
      if (mounted) setState(() => _savingBookmark = false);
    }
  }

  Future<void> _share() async {
    final link = _event.verifiedOfficialWebsite.isNotEmpty
        ? _event.verifiedOfficialWebsite
        : _event.registrationLink.trim();
    if (!_hasValue(link)) {
      _message('An event link is not available to share.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    _message('Event link copied to clipboard.');
  }

  void _message(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  // UI WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Hackathon Details',
          style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _share,
            tooltip: 'Share event link',
            icon: Icon(Icons.share_outlined, color: _cyan),
          ),
          if (_event.id.isNotEmpty) _bookmarkControl(user),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1080;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 16, 20, 48),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 880),
                        child: _buildMainColumn(isWide: true),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 16, 28, 36),
                    child: _buildDesktopSidebar(),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: _buildMainColumn(isWide: false),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainColumn({required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroSection(isWide),
        const SizedBox(height: 22),
        _buildTranslationBanner(),

        // SECTION 1: AT A GLANCE (QUICK FACTS)
        _buildSectionHeader(
          'At a Glance',
          'Key event parameters supplied for this listing.',
          Icons.dashboard_outlined,
        ),
        const SizedBox(height: 12),
        _buildFactsGrid(),
        const SizedBox(height: 28),

        // SECTION 2: IMPORTANT DATES
        _buildSectionHeader(
          'Important Dates & Timeline',
          'Registration deadline, event dates, and project submissions.',
          Icons.event_note_rounded,
        ),
        const SizedBox(height: 12),
        _buildImportantDatesTimeline(),
        const SizedBox(height: 28),

        // SECTION 3: EVENT FORMAT & VENUE
        _buildSectionHeader(
          'Event Format & Location',
          'Participation mode, physical venue, and attendee requirements.',
          Icons.location_on_outlined,
        ),
        const SizedBox(height: 12),
        _buildFormatAndLocationCard(),
        const SizedBox(height: 28),

        // SECTION 4: PRIZES & REWARDS
        _buildSectionHeader(
          'Prizes & Rewards',
          'Cash pool, track awards, certificates, and recognition.',
          Icons.emoji_events_outlined,
        ),
        const SizedBox(height: 12),
        _buildPrizesSection(),
        const SizedBox(height: 28),

        // SECTION 5: THEMES & DOMAINS
        _buildSectionHeader(
          'Themes & Domains',
          'Focus areas, challenge tracks, and application disciplines.',
          Icons.category_outlined,
        ),
        const SizedBox(height: 12),
        _buildThemesChipsGrid(),
        const SizedBox(height: 28),

        // SECTION 6: TEAM REQUIREMENTS
        _buildSectionHeader(
          'Team Requirements & Squad Size',
          'Team size constraints, eligibility, and squad assembly.',
          Icons.groups_outlined,
        ),
        const SizedBox(height: 12),
        _buildTeamRequirementsCard(),
        const SizedBox(height: 28),

        // SECTION 7: ABOUT THE HACKATHON
        _buildSectionHeader(
          'About the Hackathon',
          'Detailed overview, mission, and background.',
          Icons.article_outlined,
        ),
        const SizedBox(height: 12),
        _buildAboutSection(),
        const SizedBox(height: 28),

        // SECTION 8: PROBLEM STATEMENTS & CHALLENGES
        _buildSectionHeader(
          'Problem Statements & Challenges',
          'Specific challenges proposed by the organizer or sponsors.',
          Icons.flag_outlined,
        ),
        const SizedBox(height: 12),
        _buildProblemStatementsSection(),
        const SizedBox(height: 28),

        // SECTION 9: ELIGIBILITY
        _buildSectionHeader(
          'Eligibility & Who Can Participate',
          'Participant qualifications, student/professional criteria.',
          Icons.verified_user_outlined,
        ),
        const SizedBox(height: 12),
        _buildEligibilitySection(),
        const SizedBox(height: 28),

        // SECTION 10: JUDGING CRITERIA
        _buildSectionHeader(
          'Judging Criteria',
          'Evaluation dimensions used to score hackathon submissions.',
          Icons.gavel_rounded,
        ),
        const SizedBox(height: 12),
        _buildJudgingCriteriaSection(),
        const SizedBox(height: 28),

        // SECTION 11: REQUIRED SKILLS & TECH
        _buildSectionHeader(
          'Required Skills & Technologies',
          'Suggested languages, frameworks, APIs, and tools.',
          Icons.terminal_rounded,
        ),
        const SizedBox(height: 12),
        _buildRequiredSkillsSection(),
        const SizedBox(height: 28),

        // SECTION 12: REGISTRATION INSTRUCTIONS
        _buildSectionHeader(
          'Registration Instructions',
          'Step-by-step guidance to secure your spot.',
          Icons.how_to_reg_outlined,
        ),
        const SizedBox(height: 12),
        _buildRegistrationInstructionsSection(),
        const SizedBox(height: 28),

        // SECTION 13: OFFICIAL CONTACT INFO
        _buildSectionHeader(
          'Official Contact & Support',
          'Direct organizer inquiries, community channels, and support.',
          Icons.contact_support_outlined,
        ),
        const SizedBox(height: 12),
        _buildContactSection(),
        const SizedBox(height: 36),

        // SECTION 14: OFFICIAL WEBSITE CTA (MANDATORY REQUIREMENT 2)
        _buildOfficialWebsiteCtaCard(),
        const SizedBox(height: 24),

        if (!isWide) ...[
          _buildMobileBottomActionBar(),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HERO & COVER
  // ---------------------------------------------------------------------------

  Widget _buildHeroSection(bool isWide) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image with Gradient
          SizedBox(
            height: isWide ? 280 : 210,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HackathonImageView(
                  event: _currentEvent,
                  showGradientOverlay: true,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        _background.withValues(alpha: 0.92),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  child: _badgePill(_category, _orange),
                ),
                if (_deadlineState.isNotEmpty)
                  Positioned(
                    right: 18,
                    top: 18,
                    child: _badgePill(
                      _deadlineState,
                      _deadlineState.contains('CLOSED') ? _muted : _cyan,
                    ),
                  ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 14,
                  child: Text(
                    _currentTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWide ? 28 : 22,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.4,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sub-hero details
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: _orange.withValues(alpha: 0.15),
                      child: Text(
                        _event.organizer.trim().isEmpty
                            ? '?'
                            : _event.organizer.trim()[0].toUpperCase(),
                        style: TextStyle(color: _orange, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORGANIZED BY',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _event.organizer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_event.isIndia)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2E22),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _emerald.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇮🇳', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 5),
                            Text(
                              'INDIA FOCUS',
                              style: TextStyle(
                                color: _emerald,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metaChip(
                      _event.isOnline ? Icons.wifi_rounded : Icons.location_on_outlined,
                      _event.displayLocation,
                    ),
                    if (_hasValue(_event.mode))
                      _metaChip(Icons.laptop_chromebook_outlined, _event.mode),
                    if (_hasValue(_event.teamSize))
                      _metaChip(Icons.groups_outlined, 'Team: ${_event.teamSize}'),
                    if (_hasValue(_event.deadline))
                      _metaChip(Icons.event_outlined, 'Deadline: $_deadlineLabel'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. AT A GLANCE (FACTS GRID)
  // ---------------------------------------------------------------------------

  Widget _buildFactsGrid() {
    final facts = [
      (Icons.emoji_events_outlined, 'Prize Pool', _event.prize, _orange, _hasValue(_event.prize)),
      (Icons.event_available_outlined, 'Registration Deadline', _deadlineLabel, _cyan, _hasValue(_event.deadline)),
      (Icons.play_circle_outline_rounded, 'Event Start Date', _formatDateString(_event.startDate), _emerald, _hasValue(_event.startDate)),
      (Icons.groups_outlined, 'Team Size', _hasValue(_event.teamSize) ? _event.teamSize : 'Not specified by organizer', _orange, _hasValue(_event.teamSize)),
      (Icons.devices_rounded, 'Format', _event.mode.isNotEmpty ? _event.mode : (_event.isOnline ? 'Online' : 'In-person'), _cyan, true),
      (Icons.location_city_outlined, 'Location', _event.displayLocation, _orange, _event.hasPhysicalLocation || _event.isOnline),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 3 : (constraints.maxWidth >= 420 ? 2 : 1);
        final itemWidth = (constraints.maxWidth - ((columns - 1) * 10)) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: facts.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _buildFactCard(
                icon: item.$1,
                label: item.$2,
                value: item.$3,
                accent: item.$4,
                isVerified: item.$5,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFactCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    required bool isVerified,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                _statusTag(isVerified ? 'VERIFIED' : 'NOT SPECIFIED', isVerified),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. IMPORTANT DATES TIMELINE
  // ---------------------------------------------------------------------------

  Widget _buildImportantDatesTimeline() {
    final hasStart = _hasValue(_event.startDate);
    final hasEnd = _hasValue(_event.endDate);
    final hasSub = _hasValue(_event.submissionDeadline);

    final dates = [
      (
        '1. Registration Deadline',
        _deadlineLabel,
        _deadlineState.isNotEmpty ? _deadlineState : 'Specified by organizer',
        Icons.how_to_reg_rounded,
        _hasValue(_event.deadline),
      ),
      (
        '2. Event Kickoff',
        _formatDateString(_event.startDate),
        hasStart ? 'Opening ceremony & hacking begins' : 'Schedule not published yet',
        Icons.play_arrow_rounded,
        hasStart,
      ),
      (
        '3. Event Concludes',
        _formatDateString(_event.endDate),
        hasEnd ? 'Hacking stops & demos commence' : 'Schedule not published yet',
        Icons.flag_rounded,
        hasEnd,
      ),
      (
        '4. Project Submission Deadline',
        _hasValue(_event.submissionDeadline)
            ? _formatDateString(_event.submissionDeadline)
            : (hasEnd ? 'Matches event end date' : 'Not specified by organizer'),
        hasSub ? 'Final code & video submission' : 'Check official schedule',
        Icons.cloud_upload_outlined,
        hasSub,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: dates.asMap().entries.map((entry) {
          final idx = entry.key;
          final d = entry.value;
          final isLast = idx == dates.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: d.$5 ? _cyan.withValues(alpha: 0.15) : _muted.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: d.$5 ? _cyan.withValues(alpha: 0.4) : _border,
                      ),
                    ),
                    child: Icon(d.$4, size: 16, color: d.$5 ? _cyan : _muted),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 44,
                      color: _border,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            d.$1,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          _statusTag(d.$5 ? 'VERIFIED DATE' : 'NOT SPECIFIED', d.$5),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.$2,
                        style: TextStyle(
                          color: d.$5 ? _orange : _muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.$3,
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. EVENT FORMAT & VENUE
  // ---------------------------------------------------------------------------

  Widget _buildFormatAndLocationCard() {
    final isOnline = _event.isOnline;
    final isHybrid = _event.isHybrid;
    final hasVenue = _event.venue.trim().isNotEmpty && !Hackathon.isPlaceholder(_event.venue);

    String formatDescription;
    if (isOnline) {
      formatDescription =
          '100% Virtual Hackathon • No physical travel required. Collaborate with teammates remotely, attend workshops on livestream, and submit deliverables digitally.';
    } else if (isHybrid) {
      formatDescription =
          'Hybrid Participation • Participants can either attend in-person at the host venue or participate remotely online. Check official guidelines for team quotas.';
    } else {
      formatDescription =
          'In-Person Hackathon • Physical attendance at the venue is mandatory for hacking, mentorship, and judge evaluations.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isOnline ? _cyan : _orange).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOnline ? Icons.wifi_rounded : (isHybrid ? Icons.devices_rounded : Icons.location_on_rounded),
                  color: isOnline ? _cyan : _orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _event.mode.isNotEmpty ? _event.mode.toUpperCase() : (isOnline ? 'ONLINE' : 'IN-PERSON'),
                      style: TextStyle(
                        color: isOnline ? _cyan : _orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _event.displayLocation,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _statusTag(_event.hasPhysicalLocation || isOnline ? 'VERIFIED' : 'NOT SPECIFIED', _event.hasPhysicalLocation || isOnline),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatDescription,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.45),
          ),
          if (hasVenue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Icon(Icons.business_outlined, size: 16, color: _orange),
                  const SizedBox(width: 8),
                  Text(
                    'Venue: ',
                    style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      _event.venue,
                      style: TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. PRIZES & REWARDS
  // ---------------------------------------------------------------------------

  Widget _buildPrizesSection() {
    final hasPrize = _hasValue(_event.prize);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF24180A),
            const Color(0xFF161C26),
            _surface,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasPrize ? _orange.withValues(alpha: 0.4) : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _orange.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.emoji_events_rounded, color: _orange, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PRIZE POOL',
                      style: TextStyle(
                        color: _orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasPrize ? _event.prize : 'Not specified by organizer',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _statusTag(hasPrize ? 'VERIFIED REWARDS' : 'NOT SPECIFIED', hasPrize),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            hasPrize
                ? 'Prize money, certificates, sponsor track bounties, and participant swags as announced by the host.'
                : 'The organizer has not published a specific monetary prize pool. Non-cash perks, certificates, or mentorship awards may be granted.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. THEMES & DOMAINS
  // ---------------------------------------------------------------------------

  Widget _buildThemesChipsGrid() {
    final themes = _event.resolvedThemes;
    final isExplicit = _event.themes.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Focus Areas & Tech Disciplines',
                style: TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w800),
              ),
              _statusTag(isExplicit ? 'ORGANIZER THEMES' : 'INFERRED TRACKS', isExplicit),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: themes.map((theme) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _cyan.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.label_outline_rounded, size: 12, color: _cyan),
                    const SizedBox(width: 6),
                    Text(
                      theme,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. TEAM REQUIREMENTS
  // ---------------------------------------------------------------------------

  Widget _buildTeamRequirementsCard() {
    final hasTeamSize = _hasValue(_event.teamSize);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.groups_rounded, color: _orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEAM SIZE SPECIFICATION',
                      style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasTeamSize ? _event.teamSize : 'Not specified by organizer',
                      style: TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              _statusTag(hasTeamSize ? 'VERIFIED SQUAD' : 'NOT SPECIFIED', hasTeamSize),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(Icons.person_search_rounded, color: _cyan, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Looking for teammates for this event?',
                        style: TextStyle(color: _ink, fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Find Flutter devs, backend architects, and AI engineers in HackPilot Team Finder.',
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TeamFinderScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _cyan,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Find Squad ↗', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. ABOUT THE HACKATHON (EXPANDABLE)
  // ---------------------------------------------------------------------------

  Widget _buildAboutSection() {
    final desc = _currentDescription.trim();
    final hasDesc = desc.isNotEmpty && !Hackathon.isPlaceholder(desc);

    if (!hasDesc) {
      return _buildUnavailableCard('Overview and event description not specified by organizer.');
    }

    final isLong = desc.length > 500;
    final displayContent = (isLong && !_isDescriptionExpanded)
        ? '${desc.substring(0, 480)}...'
        : desc;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Event Overview & Mission',
                style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              _statusTag('VERIFIED OVERVIEW', true),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: _formatMarkdownHeadings(displayContent),
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: _ink, height: 1.6, fontSize: 13),
              h1: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800),
              h2: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800),
              h3: TextStyle(color: _cyan, fontSize: 14, fontWeight: FontWeight.w800),
              listBullet: TextStyle(color: _orange),
              strong: TextStyle(color: _ink, fontWeight: FontWeight.w800),
              a: TextStyle(color: _cyan, decoration: TextDecoration.underline),
              blockquote: TextStyle(color: _muted, height: 1.5),
            ),
            onTapLink: (_, href, _) {
              if (href != null) {
                final uri = _parseVerifiedUri(href);
                if (uri != null) _performLaunch(uri, 'Link');
              }
            },
          ),
          if (isLong) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isDescriptionExpanded ? 'Show less' : 'Read full overview',
                      style: TextStyle(color: _orange, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: _orange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. PROBLEM STATEMENTS & CHALLENGES
  // ---------------------------------------------------------------------------

  Widget _buildProblemStatementsSection() {
    final ps = _event.resolvedProblemStatements;
    if (ps != null && ps.isNotEmpty) {
      return _buildInfoContentCard(
        title: 'Challenge Problem Statements',
        content: ps,
        icon: Icons.lightbulb_outline_rounded,
        accent: _cyan,
      );
    }
    return _buildUnavailableCard(
      'Problem statements have not been pre-published by the organizer. Detailed problem tracks are typically announced during the opening ceremony or on the official event portal.',
    );
  }

  // ---------------------------------------------------------------------------
  // 10. ELIGIBILITY
  // ---------------------------------------------------------------------------

  Widget _buildEligibilitySection() {
    final elig = _event.resolvedEligibility;
    if (elig != null && elig.isNotEmpty) {
      return _buildInfoContentCard(
        title: 'Participant Eligibility Guidelines',
        content: elig,
        icon: Icons.verified_user_outlined,
        accent: _emerald,
      );
    }
    return _buildUnavailableCard(
      'Eligibility criteria not specified by organizer. Most open hackathons welcome students, working software engineers, and cross-disciplinary makers.',
    );
  }

  // ---------------------------------------------------------------------------
  // 11. JUDGING CRITERIA
  // ---------------------------------------------------------------------------

  Widget _buildJudgingCriteriaSection() {
    final judging = _event.resolvedJudgingCriteria;
    if (judging != null && judging.isNotEmpty) {
      return _buildInfoContentCard(
        title: 'Evaluation & Scoring Framework',
        content: judging,
        icon: Icons.gavel_rounded,
        accent: _orange,
      );
    }
    return _buildUnavailableCard(
      'Specific judging rubric not specified by organizer. Submissions are generally evaluated on Innovation, Technical Execution, Real-World Impact, and Presentation.',
    );
  }

  // ---------------------------------------------------------------------------
  // 12. REQUIRED SKILLS & TECH
  // ---------------------------------------------------------------------------

  Widget _buildRequiredSkillsSection() {
    final skills = _event.resolvedRequiredSkills;
    if (skills != null && skills.isNotEmpty) {
      return _buildInfoContentCard(
        title: 'Recommended Technology Stack',
        content: skills,
        icon: Icons.terminal_rounded,
        accent: _cyan,
      );
    }
    return _buildUnavailableCard(
      'Technology stack not restricted by organizer. Teams may typically leverage any modern programming languages, libraries, APIs, or cloud platforms.',
    );
  }

  // ---------------------------------------------------------------------------
  // 13. REGISTRATION INSTRUCTIONS
  // ---------------------------------------------------------------------------

  Widget _buildRegistrationInstructionsSection() {
    final instructions = _event.resolvedRegistrationInstructions;
    if (instructions != null && instructions.isNotEmpty) {
      return _buildInfoContentCard(
        title: 'Registration Procedure',
        content: instructions,
        icon: Icons.how_to_reg_outlined,
        accent: _emerald,
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Standard Registration Flow', style: TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w800)),
              _statusTag('GENERAL GUIDELINE', false),
            ],
          ),
          const SizedBox(height: 12),
          _stepRow('1', 'Click "Register Now" or "Visit Official Website" below to access the event page.'),
          _stepRow('2', 'Complete applicant registration individually or link team squad profiles.'),
          _stepRow('3', 'Receive email confirmation and join the official communication server (Discord/Slack).'),
        ],
      ),
    );
  }

  Widget _stepRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: _orange.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(
              child: Text(num, style: TextStyle(color: _orange, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: _muted, fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 14. OFFICIAL CONTACT INFO
  // ---------------------------------------------------------------------------

  Widget _buildContactSection() {
    final contact = _event.resolvedContactInfo;
    final hasContact = contact != null && contact.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _cyan.withValues(alpha: 0.15),
            child: Icon(Icons.business_rounded, color: _cyan, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORGANIZER CONTACT',
                  style: TextStyle(color: _muted, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                ),
                const SizedBox(height: 2),
                Text(
                  _event.organizer,
                  style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  hasContact ? contact : 'Contact information not specified by organizer. Direct questions through the official website.',
                  style: TextStyle(color: _muted, fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),
          _statusTag(hasContact ? 'VERIFIED' : 'NOT SPECIFIED', hasContact),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 15. OFFICIAL WEBSITE CTA CARD (MANDATORY REQUIREMENT 2)
  // ---------------------------------------------------------------------------

  Widget _buildOfficialWebsiteCtaCard() {
    final hasVerifiedSite = _event.hasVerifiedWebsite;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF131D2D),
            const Color(0xFF101824),
            const Color(0xFF0D121B),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _orange.withValues(alpha: 0.45)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _orange.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.language_rounded, color: _orange, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Want to know more about this hackathon?',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Official Organizer Source',
                      style: TextStyle(color: _orange, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Visit the official event website for complete guidelines, updated schedules, eligibility requirements and registration information.',
            style: TextStyle(
              color: _muted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _launchingWebsite ? null : _visitOfficialWebsite,
                  icon: _launchingWebsite
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    _launchingWebsite
                        ? 'OPENING WEBSITE...'
                        : 'Visit Official Website ↗',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          if (!hasVerifiedSite) ...[
            const SizedBox(height: 8),
            Text(
              'Note: Official site link derived from published registration portal.',
              style: TextStyle(color: _muted, fontSize: 10.5, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP STICKY SIDEBAR (WHEN WIDTH >= 1080)
  // ---------------------------------------------------------------------------

  Widget _buildDesktopSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(color: Color(0x28000000), blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registration & Access',
                style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _sidebarItem('Prize Pool', _event.prize, Icons.emoji_events_outlined, _orange),
              _sidebarItem('Deadline', _deadlineLabel, Icons.event_outlined, _cyan),
              _sidebarItem('Format', _event.mode.isNotEmpty ? _event.mode : 'Online', Icons.laptop_chromebook_outlined, _emerald),
              _sidebarItem('Location', _event.displayLocation, Icons.location_on_outlined, _orange),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_hasValue(_event.registrationLink) && !_launchingRegistration)
                      ? _register
                      : null,
                  icon: _launchingRegistration
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.how_to_reg_rounded, size: 17),
                  label: Text(_launchingRegistration ? 'OPENING...' : 'REGISTER NOW ↗'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _launchingWebsite ? null : _visitOfficialWebsite,
                  icon: const Icon(Icons.language_rounded, size: 16),
                  label: const Text('Official Website ↗'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _cyan,
                    side: BorderSide(color: _cyan.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Share & Save', style: TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Copy Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        side: BorderSide(color: _border),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sidebarItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: _muted, fontSize: 10)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _ink, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: (_hasValue(_event.registrationLink) && !_launchingRegistration)
                  ? _register
                  : null,
              icon: _launchingRegistration
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(_launchingRegistration ? 'OPENING...' : 'REGISTER NOW'),
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER SUBWIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: _orange),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: _muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoContentCard({
    required String title,
    required String content,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w800)),
              _statusTag('VERIFIED', true),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: _formatMarkdownHeadings(content),
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: _ink, height: 1.55, fontSize: 12.5),
              h1: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800),
              h2: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w800),
              h3: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w800),
              listBullet: TextStyle(color: accent),
              strong: TextStyle(color: _ink, fontWeight: FontWeight.w800),
              a: TextStyle(color: accent, decoration: TextDecoration.underline),
            ),
            onTapLink: (_, href, _) {
              if (href != null) {
                final uri = _parseVerifiedUri(href);
                if (uri != null) _performLaunch(uri, 'Link');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: _muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: _muted, fontSize: 12, height: 1.45),
            ),
          ),
          const SizedBox(width: 6),
          _statusTag('NOT SPECIFIED', false),
        ],
      ),
    );
  }

  Widget _statusTag(String label, bool isVerified) {
    final color = isVerified ? _emerald : _muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _cyan),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgePill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE6101720),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _bookmarkControl(User? user) {
    if (user == null) {
      return IconButton(
        onPressed: _savingBookmark ? null : () => _toggleBookmark(false),
        tooltip: 'Save hackathon',
        icon: Icon(Icons.bookmark_add_outlined, color: _orange),
      );
    }
    try {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('bookmarks')
            .doc(_event.id)
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
    } catch (_) {
      return IconButton(
        onPressed: _savingBookmark ? null : () => _toggleBookmark(false),
        tooltip: 'Save hackathon',
        icon: Icon(Icons.bookmark_add_outlined, color: _orange),
      );
    }
  }

  Widget _buildTranslationBanner() {
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
                style: TextStyle(color: _ink, fontSize: 11.5, fontWeight: FontWeight.w600),
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

  String _formatMarkdownHeadings(String raw) {
    final lines = raw.replaceAll('\r', '').split('\n');
    const knownHeadings = [
      'overview', 'about', 'challenge', 'challenges', 'problem statements', 'problem statement',
      'objectives', 'themes', 'tracks', 'eligibility', 'who can participate', 'prizes', 'prize',
      'schedule', 'agenda', 'important dates', 'rules', 'what to bring', 'sponsors', 'resources',
      'submission', 'judging criteria', 'criteria', 'required skills', 'skills', 'technologies',
      'contact', 'contact us', 'registration instructions'
    ];
    return lines.map((line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('- ') ||
          trimmed.startsWith('* ') ||
          RegExp(r'^\d+[.)]\s').hasMatch(trimmed)) {
        return line;
      }
      final normalized = trimmed.toLowerCase().replaceAll(':', '');
      if (knownHeadings.contains(normalized)) return '### $trimmed';
      return line;
    }).join('\n');
  }
}
