import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/hackathon.dart';
import '../services/bookmark_service.dart';
import '../theme/app_theme.dart';
import 'bookmarks_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'signup_screen.dart';
import 'team_finder_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({
    super.key,
    this.initialIndex = 0,
    this.pendingBookmark,
  });

  final int initialIndex;
  final Hackathon? pendingBookmark;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  late final List<Widget?> pages;
  late final Stream<User?> _authChanges;

  static const _items = <(IconData, String)>[
    (Icons.explore_outlined, 'EXPLORE'),
    (Icons.groups_outlined, 'TEAMS'),
    (Icons.bookmark_border_rounded, 'BOOKMARKS'),
  ];

  @override
  void initState() {
    super.initState();
    _authChanges = FirebaseAuth.instance.authStateChanges();
    currentIndex = widget.initialIndex.clamp(0, 3).toInt();
    pages = List<Widget?>.filled(4, null);
    pages[0] = HomeScreen(
        onFindTeams: () => _requestProtectedTab(1),
        onBookmarkRequested: _requestBookmark,
        initialBookmark: widget.pendingBookmark,
      );
    if (currentIndex != 0) pages[currentIndex] = _protectedPage(currentIndex);
  }

  Widget _protectedPage(int index) => switch (index) {
    1 => const TeamFinderScreen(),
    2 => const BookmarksScreen(),
    3 => ProfileScreen(onSignedOut: () => _select(0)),
    _ => const SizedBox.shrink(),
  };

  void _select(int index) => setState(() {
    currentIndex = index;
    pages[index] ??= index == 0 ? pages[0] : _protectedPage(index);
  });

  Future<User?> _resolveUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user;
    try {
      return await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(milliseconds: 300));
    } catch (_) {
      return FirebaseAuth.instance.currentUser;
    }
  }

  Future<void> _requestProtectedTab(int index) async {
    final user = await _resolveUser();
    if (!mounted) return;
    if (user != null) {
      _select(index);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LoginScreen(returnTo: index),
    ));
  }

  Future<void> _requestBookmark(Hackathon event) async {
    final user = await _resolveUser();
    if (!mounted) return;
    if (user == null) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LoginScreen(returnTo: 0, pendingBookmark: event),
      ));
      return;
    }
    try {
      await BookmarkService().addBookmark(
        hackathonId: event.id,
        data: event.toMap(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hackathon saved.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save bookmark. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authChanges,
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        final authResolved = snapshot.connectionState != ConnectionState.waiting;
        final width = MediaQuery.sizeOf(context).width;
        final compact = width < 760;
        return Scaffold(
          backgroundColor: context.hubColors.background,
          bottomNavigationBar: compact ? _mobileBottomBar() : null,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _navbar(compact: compact, user: user, authResolved: authResolved),
                Expanded(
                  child: IndexedStack(
                    index: currentIndex,
                    children: pages.map((page) => page ?? const SizedBox.shrink()).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _navbar({
    required bool compact,
    required User? user,
    required bool authResolved,
  }) => Material(
    color: const Color(0xFF080B10),
    child: Container(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 32),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.hubColors.border))),
      child: Row(
        children: [
          InkWell(
            onTap: () => _select(0),
            borderRadius: BorderRadius.circular(6),
            child: Row(children: [
              Container(width: 33, height: 33, decoration: BoxDecoration(color: context.hubColors.primary, borderRadius: BorderRadius.circular(7)), child: Icon(Icons.rocket_launch_rounded, color: context.hubColors.surface, size: 18)),
              const SizedBox(width: 9),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text('HACKPILOT', style: TextStyle(color: context.hubColors.ink, fontSize: 13, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: .8)), Text('YOUR INNOVATION. OUR DIRECTION.', style: TextStyle(color: context.hubColors.muted, fontSize: 7, letterSpacing: .55, fontWeight: FontWeight.w700))]),
            ]),
          ),
          if (compact) ...[
            const Spacer(),
            PopupMenuButton<String>(
              tooltip: 'Open navigation',
              icon: Icon(Icons.menu_rounded, color: context.hubColors.ink),
              onSelected: (value) {
                switch (value) {
                  case 'Discover Hackathons': _select(0);
                  case 'Find Teams': _requestProtectedTab(1);
                  case 'Saved': _requestProtectedTab(2);
                  case 'Log in': _openLogin();
                  case 'Resources': _showResources();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'Discover Hackathons', child: Text('Discover Hackathons')),
                const PopupMenuItem(value: 'Find Teams', child: Text('Find Teams')),
                const PopupMenuItem(value: 'Saved', child: Text('Saved')),
                const PopupMenuItem(value: 'Resources', child: Text('Resources')),
                if (user == null && authResolved)
                  const PopupMenuItem(value: 'Log in', child: Text('Log in')),
              ],
            ),
            const SizedBox(width: 4),
            _accountAction(user, compact: true, authResolved: authResolved),
          ] else ...[
            const SizedBox(width: 40),
            for (var i = 0; i < _items.length; i++) _desktopLink(i),
            _resourcesLink(),
            const Spacer(),
            if (user == null && authResolved) ...[
              TextButton(onPressed: _openLogin, child: const Text('Log in')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _openSignup, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('GET STARTED')),
            ] else if (user != null) ...[
              TextButton.icon(onPressed: () => _select(3), icon: const Icon(Icons.person_outline_rounded, size: 18), label: Text(user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : 'Profile')),
            ] else ...[
              const SizedBox(width: 124),
            ],
          ],
        ],
      ),
    ),
  );

  Widget _desktopLink(int index) {
    final selected = currentIndex == index;
    final item = _items[index];
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: TextButton.icon(
        onPressed: () => index == 0 ? _select(0) : _requestProtectedTab(index),
        icon: Icon(item.$1, size: 17, color: context.hubColors.primary),
        label: Text(item.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .7)),
        style: TextButton.styleFrom(foregroundColor: selected ? context.hubColors.primary : context.hubColors.muted, padding: EdgeInsets.symmetric(horizontal: 11, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
      ),
    );
  }

  Widget _resourcesLink() => PopupMenuButton<String>(
    tooltip: 'Resources',
    onSelected: (_) => _showResources(),
    itemBuilder: (_) => const [PopupMenuItem(value: 'about', child: Text('About HACKPILOT')), PopupMenuItem(value: 'tips', child: Text('HACKATHON TIPS'))],
    child: Padding(padding: EdgeInsets.symmetric(horizontal: 11, vertical: 12), child: Row(mainAxisSize: MainAxisSize.min, children: [Text('Resources', style: TextStyle(color: context.hubColors.muted, fontSize: 12, fontWeight: FontWeight.w600)), SizedBox(width: 4), Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: context.hubColors.muted)])),
  );

  Widget _accountAction(
    User? user, {
    required bool compact,
    required bool authResolved,
  }) {
    if (user == null) {
      if (!authResolved) return const SizedBox(width: 64);
      return FilledButton(onPressed: _openSignup, style: FilledButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 17, vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: Text(compact ? 'JOIN' : 'GET STARTED'));
    }
    return IconButton(tooltip: 'Profile', onPressed: () => _select(3), icon: CircleAvatar(radius: 15, backgroundColor: context.hubColors.background, child: Icon(Icons.person_outline_rounded, color: context.hubColors.primary, size: 18)));
  }

  void _openLogin() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));

  void _openSignup() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen()));

  void _showResources() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Make the most of HACKPILOT'),
      content: const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Discover hackathons from Firestore and the connected events feed.'),
        SizedBox(height: 12),
        Text('Save opportunities to revisit them from your Saved page.'),
        SizedBox(height: 12),
        Text('Open an event for complete details, guidelines, and registration links.'),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
    ),
  );

  Widget _mobileBottomBar() => SafeArea(
    top: false,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080B10),
        border: Border(top: BorderSide(color: context.hubColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex.clamp(0, 3),
        onDestinationSelected: (index) {
          if (index == 0) {
            _select(0);
          } else {
            _requestProtectedTab(index);
          }
        },
        backgroundColor: Colors.transparent,
        indicatorColor: context.hubColors.primary.withValues(alpha: 0.2),
        height: 60,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, size: 22),
            selectedIcon: Icon(Icons.explore_rounded, color: Color(0xFFFF6818), size: 22),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, size: 22),
            selectedIcon: Icon(Icons.groups_rounded, color: Color(0xFFFF6818), size: 22),
            label: 'Teams',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded, size: 22),
            selectedIcon: Icon(Icons.bookmark_rounded, color: Color(0xFFFF6818), size: 22),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, size: 22),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFFFF6818), size: 22),
            label: 'Profile',
          ),
        ],
      ),
    ),
  );
}

