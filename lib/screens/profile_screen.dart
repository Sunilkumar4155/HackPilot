import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'bookmarks_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onSignedOut});

  final VoidCallback? onSignedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, int>>? _countsFuture;
  String? _lastUid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _lastUid = user.uid;
      _countsFuture = _getCounts(user.uid);
    }
  }

  Future<void> _refreshCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _lastUid = user.uid;
        _countsFuture = _getCounts(user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid != _lastUid) {
      _lastUid = user.uid;
      _countsFuture = _getCounts(user.uid);
    }
    final colors = context.hubColors;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: const Text(
          'PROFILE & SETTINGS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_off_rounded, size: 54, color: colors.muted),
                    const SizedBox(height: 16),
                    Text(
                      'Please sign in to view your profile.',
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : FutureBuilder<Map<String, int>>(
              future: _countsFuture,
              builder: (context, snapshot) {
                final counts = snapshot.data;
                final name = user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!.trim()
                    : (user.email?.split('@').first ?? 'HackPilot Builder');

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: RefreshIndicator(
                      onRefresh: _refreshCounts,
                      color: colors.primary,
                      child: ListView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      children: [
                        // Profile Banner Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colors.primary, colors.violet],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.primary.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _initial(user),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            color: colors.ink,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: colors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            'BUILDER',
                                            style: TextStyle(
                                              color: colors.primary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      user.email ?? 'No email linked',
                                      style: TextStyle(
                                        color: colors.muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Activity Stats
                        Text(
                          'PLATFORM ACTIVITY',
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.bookmark_outline_rounded,
                                title: 'Saved Hackathons',
                                value: snapshot.connectionState == ConnectionState.waiting
                                    ? '...'
                                    : '${counts?['bookmarks'] ?? 0}',
                                color: colors.primary,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.groups_2_outlined,
                                title: 'Teams Joined',
                                value: snapshot.connectionState == ConnectionState.waiting
                                    ? '...'
                                    : '${counts?['teams'] ?? 0}',
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Technical Skills Section
                        Text(
                          'TECHNICAL INTERESTS & SKILLS',
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              _SkillBadge('Artificial Intelligence'),
                              _SkillBadge('Machine Learning'),
                              _SkillBadge('Full-Stack Web'),
                              _SkillBadge('Flutter & Mobile'),
                              _SkillBadge('Cloud & DevOps'),
                              _SkillBadge('Cybersecurity'),
                              _SkillBadge('Robotics & Hardware'),
                              _SkillBadge('Web3 & Blockchain'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Appearance Settings
                        Text(
                          'PREFERENCES',
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.dark_mode_rounded, color: colors.primary, size: 20),
                            ),
                            title: Text(
                              'Hackathon Dark Mode',
                              style: TextStyle(
                                color: colors.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'High-contrast startup event aesthetic',
                              style: TextStyle(color: colors.muted, fontSize: 12),
                            ),
                            trailing: Switch(
                              value: themeProvider.isDark,
                              activeThumbColor: colors.primary,
                              activeTrackColor: colors.primary.withValues(alpha: 0.5),
                              onChanged: (val) => themeProvider.toggleTheme(val),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign Out Button
                        OutlinedButton.icon(
                          onPressed: () => _confirmSignOut(context),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Sign out from HackPilot'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  static String _initial(User user) {
    final name = user.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name[0].toUpperCase();
    final email = user.email?.trim() ?? '';
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'H';
  }

  static Future<Map<String, int>> _getCounts(String uid) async {
    final bookmarkSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .get();
    final email = FirebaseAuth.instance.currentUser?.email;
    final teamSnapshot = email == null
        ? null
        : await FirebaseFirestore.instance
            .collection('teams')
            .where('members', arrayContains: email)
            .get();
    return {
      'bookmarks': bookmarkSnapshot.docs.length,
      'teams': teamSnapshot?.docs.length ?? 0,
    };
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.hubColors.surface,
        title: Text('Sign out from HackPilot?', style: TextStyle(color: context.hubColors.ink)),
        content: Text(
          'You will be signed out of your account on this device.',
          style: TextStyle(color: context.hubColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(color: context.hubColors.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (shouldSignOut != true) return;
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    widget.onSignedOut?.call();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.hubColors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillBadge extends StatelessWidget {
  const _SkillBadge(this.skill);

  final String skill;

  @override
  Widget build(BuildContext context) {
    final colors = context.hubColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        skill,
        style: TextStyle(
          color: colors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
