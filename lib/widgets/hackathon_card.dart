import 'package:flutter/material.dart';
import '../models/hackathon.dart';
import '../theme/app_theme.dart';
import 'hackathon_image_view.dart';

class HackathonCard extends StatefulWidget {
  const HackathonCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isBookmarked = false,
    this.onBookmarkToggle,
    this.index,
    this.compact = false,
  });

  final Hackathon event;
  final VoidCallback onTap;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;
  final int? index;
  final bool compact;

  @override
  State<HackathonCard> createState() => _HackathonCardState();
}

class _HackathonCardState extends State<HackathonCard> {
  bool _isHovered = false;

  String _statusOf(Hackathon event) {
    final deadline = DateTime.tryParse(event.deadline.trim());
    if (deadline == null) return 'OPEN';
    final remaining = deadline.difference(DateTime.now());
    if (!deadline.isAfter(DateTime.now())) return 'CLOSED';
    if (remaining.inDays <= 7) {
      final days = remaining.inDays;
      return days <= 0 ? 'CLOSES TODAY' : 'CLOSES IN ${days}D';
    }
    return 'OPEN';
  }

  Color _statusColor(String status, BuildContext context) {
    if (status.contains('CLOSED')) return const Color(0xFFEF4444);
    if (status.contains('CLOSES')) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  (IconData, String, Color) _categoryOf(Hackathon event) {
    final text = '${event.title} ${event.description}'.toLowerCase();
    if (text.contains('ai') || text.contains('machine learning') || text.contains('llm')) {
      return (Icons.smart_toy_rounded, 'AI & ML', const Color(0xFFFF6818));
    }
    if (text.contains('cyber') || text.contains('security') || text.contains('privacy')) {
      return (Icons.shield_rounded, 'SECURITY', const Color(0xFFEF4444));
    }
    if (text.contains('robot') || text.contains('hardware') || text.contains('iot')) {
      return (Icons.memory_rounded, 'ROBOTICS', const Color(0xFF00D9E8));
    }
    if (text.contains('blockchain') || text.contains('web3') || text.contains('crypto')) {
      return (Icons.currency_bitcoin_rounded, 'WEB3', const Color(0xFFA855F7));
    }
    if (text.contains('cloud') || text.contains('devops') || text.contains('server')) {
      return (Icons.cloud_rounded, 'CLOUD', const Color(0xFF3B82F6));
    }
    if (text.contains('climate') || text.contains('green') || text.contains('sustainability')) {
      return (Icons.eco_rounded, 'CLIMATE', const Color(0xFF10B981));
    }
    if (text.contains('startup') || text.contains('business') || text.contains('venture')) {
      return (Icons.rocket_launch_rounded, 'STARTUP', const Color(0xFFF59E0B));
    }
    return (Icons.code_rounded, 'CODING', const Color(0xFFFF6818));
  }

  String _formatDate(String rawDate) {
    final date = DateTime.tryParse(rawDate.trim());
    if (date == null) return rawDate.trim().isEmpty ? 'TBA' : rawDate;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hubColors;
    final status = _statusOf(widget.event);
    final statusCol = _statusColor(status, context);
    final category = _categoryOf(widget.event);
    final prize = widget.event.prize.trim();
    final hasPrize = prize.isNotEmpty && prize.toLowerCase() != 'not specified';
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final isHovered = !isMobile && _isHovered;
    final bannerHeight = widget.compact ? 120.0 : (isMobile ? 138.0 : 154.0);

    return MouseRegion(
      onEnter: isMobile ? null : (_) => setState(() => _isHovered = true),
      onExit: isMobile ? null : (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: isHovered ? 1.018 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered
                  ? category.$3.withValues(alpha: 0.5)
                  : colors.border,
              width: isHovered ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? category.$3.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: isHovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top banner image with overlays
                SizedBox(
                  height: bannerHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      HackathonImageView(
                        event: widget.event,
                        showGradientOverlay: true,
                      ),

                      // Category Pill Top-Left
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xDD0B0F17),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: category.$3.withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(category.$1, size: 11, color: category.$3),
                              const SizedBox(width: 4),
                              Text(
                                category.$2,
                                style: TextStyle(
                                  color: category.$3,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Status Badge Top-Right or Bookmark
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xDD0B0F17),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: statusCol.withValues(alpha: 0.7),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: statusCol,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: statusCol,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.onBookmarkToggle != null) ...[
                              const SizedBox(width: 6),
                              Material(
                                color: const Color(0xDD0B0F17),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: widget.onBookmarkToggle,
                                  child: SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: Center(
                                      child: Icon(
                                        widget.isBookmarked
                                            ? Icons.bookmark_rounded
                                            : Icons.bookmark_border_rounded,
                                        size: 17,
                                        color: widget.isBookmarked
                                            ? const Color(0xFFFF6818)
                                            : Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Index / Rank Badge Bottom-Left (if provided)
                      if (widget.index != null)
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xDD0B0F17),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: category.$3.withValues(alpha: 0.6),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              widget.index.toString().padLeft(2, '0'),
                              style: TextStyle(
                                color: category.$3,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Card Body Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Title
                        Text(
                          widget.event.displayTitle,
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

                        // Organizer Name
                        Row(
                          children: [
                            Icon(Icons.business_rounded, size: 12, color: colors.muted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.event.organizer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),
                        Divider(height: 14, color: colors.border),

                        // Metadata: Deadline & Location / Mode
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: colors.primary),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _formatDate(widget.event.deadline),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.event.isOnline
                                        ? Icons.wifi_rounded
                                        : Icons.location_on_outlined,
                                    size: 11,
                                    color: colors.muted,
                                  ),
                                  const SizedBox(width: 3),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 120),
                                    child: Text(
                                      widget.event.displayLocation,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.muted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Bottom Row: Prize & View Details
                        Row(
                          children: [
                            if (hasPrize)
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.emoji_events_rounded,
                                      size: 13,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        prize,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFF59E0B),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Expanded(
                                child: Text(
                                  widget.event.teamSize.isNotEmpty &&
                                          widget.event.teamSize != 'Not specified'
                                      ? 'Team: ${widget.event.teamSize}'
                                      : 'Open Participation',
                                  style: TextStyle(
                                    color: colors.muted,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),

                            // View details button
                            TextButton(
                              onPressed: widget.onTap,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: const Size(48, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: colors.primary,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'DETAILS',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(Icons.arrow_forward_rounded, size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
