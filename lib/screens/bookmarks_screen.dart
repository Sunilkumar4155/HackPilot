import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/hackathon.dart';
import '../services/bookmark_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hackathon_image_view.dart';
import 'hackathon_details_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key, this.onExploreTap});

  final VoidCallback? onExploreTap;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colors = context.hubColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: const Text(
          'SAVED HACKATHONS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
      body: user == null
          ? _BookmarksEmpty(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to see your saved events',
              message: 'Your saved hackathons and deadlines will be synced across your devices here.',
              actionLabel: 'Sign In',
              onAction: () => Navigator.of(context).pop(),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('bookmarks')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _BookmarksEmpty(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load saved hackathons',
                    message: 'Check your internet connection or Firestore permissions and try again.',
                    actionLabel: 'Retry',
                    onAction: () => setState(() {}),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _BookmarksEmpty(
                    icon: Icons.bookmark_border_rounded,
                    title: 'No saved hackathons yet',
                    message: 'Explore active hackathons and tap the bookmark icon to keep track of upcoming registration deadlines.',
                    actionLabel: 'Explore Hackathons',
                    onAction: widget.onExploreTap ?? () => Navigator.of(context).pop(),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      itemCount: docs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    '${docs.length} SAVED ${docs.length == 1 ? 'EVENT' : 'EVENTS'}',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Auto-syncs with Firestore',
                                  style: TextStyle(
                                    color: colors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final doc = docs[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _BookmarkCard(
                            id: doc.id,
                            data: doc.data(),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final colors = context.hubColors;
    final event = Hackathon.fromMap(id, data);
    final deadline = event.deadline;
    final status = _eventStatus(deadline);
    final statusColor = status == 'Closed'
        ? const Color(0xFFEF4444)
        : status == 'Closing soon'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;

          final imageWidget = SizedBox(
            width: compact ? double.infinity : 150,
            height: compact ? 120 : 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HackathonImageView(
                  event: event,
                  showGradientOverlay: true,
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xDD0B0F17),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          final detailsWidget = Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.organizer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _metadata(
                        Icons.calendar_today_rounded,
                        deadline.isEmpty ? 'Date TBA' : _formatDate(deadline),
                        colors.muted,
                      ),
                      if (event.prize.isNotEmpty && event.prize != 'Not specified')
                        _metadata(
                          Icons.emoji_events_rounded,
                          event.prize,
                          const Color(0xFFF59E0B),
                        ),
                      _metadata(
                        event.isOnline
                            ? Icons.wifi_rounded
                            : Icons.location_on_outlined,
                        event.displayLocation,
                        colors.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          final actionsWidget = Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 12,
              vertical: compact ? 10 : 12,
            ),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openDetails(context, event),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('Details', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.ink,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove bookmark',
                  onPressed: () => _remove(context),
                  icon: const Icon(Icons.bookmark_remove_rounded, size: 18),
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageWidget,
                detailsWidget,
                Divider(height: 1, color: colors.border),
                actionsWidget,
              ],
            );
          }

          return Row(
            children: [
              imageWidget,
              detailsWidget,
              actionsWidget,
            ],
          );
        },
      ),
    );
  }

  Widget _metadata(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String rawDate) {
    final date = DateTime.tryParse(rawDate.trim());
    if (date == null) return rawDate;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _openDetails(BuildContext context, Hackathon event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HackathonDetailsScreen(
          hackathonId: event.id,
          title: event.title,
          organizer: event.organizer,
          deadline: event.deadline,
          prize: event.prize,
          description: event.description,
          location: event.location,
          mode: event.mode,
          teamSize: event.teamSize,
          registrationLink: event.registrationLink,
          imageUrl: event.imageUrl,
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context) async {
    try {
      await BookmarkService().removeBookmark(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from saved hackathons.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove bookmark. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

String _eventStatus(String deadline) {
  final date = DateTime.tryParse(deadline);
  if (date == null) return 'Open';
  if (date.isBefore(DateTime.now())) return 'Closed';
  if (date.difference(DateTime.now()).inDays <= 7) return 'Closing soon';
  return 'Open';
}

class _BookmarksEmpty extends StatelessWidget {
  const _BookmarksEmpty({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.hubColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(icon, size: 34, color: colors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.explore_rounded, size: 16),
                  label: Text(actionLabel!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
