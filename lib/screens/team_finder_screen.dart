import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/hackathon.dart';
import '../models/team.dart';
import '../services/firestore_service.dart';
import '../services/team_service.dart';
import '../theme/app_theme.dart';
import 'create_team_screen.dart';

class TeamFinderScreen extends StatefulWidget {
  const TeamFinderScreen({super.key});

  @override
  State<TeamFinderScreen> createState() => _TeamFinderScreenState();
}

class _TeamFinderScreenState extends State<TeamFinderScreen> {
  final TeamService teamService = TeamService();
  late final Stream<List<Team>> _teamsStream = teamService.getTeams();
  final TextEditingController searchController = TextEditingController();
  final Map<String, String> _hackathonLocations = {};
  StreamSubscription<List<Hackathon>>? _hackathonsSub;
  Timer? _searchDebounce;

  String searchText = '';
  bool openTeamsOnly = false;
  String? selectedSkillFilter;

  Color get background => context.hubColors.background;
  Color get surface => context.hubColors.surface;
  Color get primary => context.hubColors.primary;
  Color get secondary => context.hubColors.violet;
  Color get muted => context.hubColors.muted;

  @override
  void initState() {
    super.initState();
    _listenHackathons();
  }

  void _listenHackathons() {
    _hackathonsSub = FirestoreService().getHackathons().listen((list) {
      if (!mounted) return;
      setState(() {
        for (final h in list) {
          final key = h.title.trim().toLowerCase();
          if (key.isNotEmpty) {
            _hackathonLocations[key] = h.displayLocation;
          }
        }
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _hackathonsSub?.cancel();
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => searchText = value.trim().toLowerCase());
    });
  }

  String _resolveTeamLocation(Team team) {
    if (team.location.isNotEmpty && !Hackathon.isPlaceholder(team.location)) {
      return team.location;
    }
    final key = team.hackathon.trim().toLowerCase();
    if (key.isEmpty) return '';
    return _hackathonLocations[key] ?? '';
  }

  Future<void> joinTeam(Team team) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to join a team.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account does not have an email address.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (team.members.contains(user.email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already a member of this team.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (team.members.length >= team.maxMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This team is already full.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await teamService.joinTeam(team.id, email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team joined successfully! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to join team: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void openCreateTeam() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'TEAM FINDER',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            fontSize: 16,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: openCreateTeam,
              icon: const Icon(Icons.group_add_rounded, size: 16),
              label: const Text('CREATE TEAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              children: [
                // Header & Search section
                Padding(
                  padding: EdgeInsets.fromLTRB(width > 1100 ? 32 : 20, 8, width > 1100 ? 32 : 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CONNECT & COLLABORATE',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Find Your Dream Hackathon Team',
                                  style: TextStyle(
                                    fontSize: width < 600 ? 22 : 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: context.hubColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Team up with developers, designers, and AI specialists to build winning hackathon projects.',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 18),

                      // Search field
                      TextField(
                        controller: searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: (value) {
                          _searchDebounce?.cancel();
                          setState(() => searchText = value.trim().toLowerCase());
                        },
                        style: TextStyle(color: context.hubColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Search by team name, hackathon, role, or tech stack...',
                          hintStyle: TextStyle(color: muted, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, color: primary),
                          suffixIcon: searchText.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchDebounce?.cancel();
                                    searchController.clear();
                                    setState(() => searchText = '');
                                  },
                                  icon: Icon(Icons.close_rounded, color: muted),
                                )
                              : null,
                          filled: true,
                          fillColor: surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.hubColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: context.hubColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter chips row
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('OPEN POSITIONS'),
                                selected: openTeamsOnly,
                                onSelected: (value) => setState(() => openTeamsOnly = value),
                                labelStyle: TextStyle(
                                  color: openTeamsOnly ? Colors.white : context.hubColors.ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                                selectedColor: const Color(0xFF10B981),
                                backgroundColor: surface,
                                side: BorderSide(
                                  color: openTeamsOnly ? const Color(0xFF10B981) : context.hubColors.border,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                            for (final skill in const [
                              'All Skills',
                              'AI / ML',
                              'Flutter',
                              'React',
                              'Python',
                              'Backend',
                              'UI/UX',
                              'Cloud',
                              'Web3',
                              'Cybersecurity',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(skill),
                                  selected: skill == 'All Skills'
                                      ? selectedSkillFilter == null
                                      : selectedSkillFilter == skill.toLowerCase(),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (skill == 'All Skills' || !selected) {
                                        selectedSkillFilter = null;
                                      } else {
                                        selectedSkillFilter = skill.toLowerCase();
                                      }
                                    });
                                  },
                                  labelStyle: TextStyle(
                                    color: (skill == 'All Skills'
                                            ? selectedSkillFilter == null
                                            : selectedSkillFilter == skill.toLowerCase())
                                        ? Colors.white
                                        : context.hubColors.ink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  selectedColor: primary,
                                  backgroundColor: surface,
                                  side: BorderSide(
                                    color: (skill == 'All Skills'
                                            ? selectedSkillFilter == null
                                            : selectedSkillFilter == skill.toLowerCase())
                                        ? primary
                                        : context.hubColors.border,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Teams List or Grid
                Expanded(
                  child: StreamBuilder<List<Team>>(
                    stream: _teamsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent),
                                const SizedBox(height: 12),
                                Text(
                                  'Unable to load teams\n${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(color: primary),
                        );
                      }

                      final allTeams = snapshot.data!;

                      final teams = allTeams.where((team) {
                        final query = searchText.toLowerCase();
                        final matchesSearch = query.isEmpty ||
                            team.teamName.toLowerCase().contains(query) ||
                            team.hackathon.toLowerCase().contains(query) ||
                            team.leader.toLowerCase().contains(query) ||
                            team.requiredSkills.toLowerCase().contains(query) ||
                            team.location.toLowerCase().contains(query);

                        final skillFilter = selectedSkillFilter;
                        final matchesSkill = skillFilter == null ||
                            team.requiredSkills.toLowerCase().contains(skillFilter);

                        final matchesOpen = !openTeamsOnly || team.members.length < team.maxMembers;

                        return matchesSearch && matchesSkill && matchesOpen;
                      }).toList();

                      if (teams.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Icon(
                                    searchText.isEmpty ? Icons.groups_2_rounded : Icons.search_off_rounded,
                                    size: 36,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchText.isEmpty ? 'No Teams Created Yet' : 'No Teams Match Your Criteria',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: context.hubColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  searchText.isEmpty
                                      ? 'Be the first to create a team for an upcoming hackathon!'
                                      : 'Try clearing your search or selecting different skill filters.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: muted, fontSize: 13, height: 1.5),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: openCreateTeam,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Create a Team'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final isDesktop = width >= 850;

                      if (isDesktop) {
                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(width > 1100 ? 32 : 20, 6, width > 1100 ? 32 : 20, 80),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 310,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                          ),
                          itemCount: teams.length,
                          itemBuilder: (context, index) => _buildTeamCard(teams[index]),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 80),
                        itemCount: teams.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildTeamCard(teams[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateTeam,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create Team',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    final memberCount = team.members.length;
    final isFull = memberCount >= team.maxMembers;
    final openPositions = (team.maxMembers - memberCount).clamp(0, team.maxMembers);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMember = currentUser?.email != null && team.members.contains(currentUser!.email);
    final progress = team.maxMembers > 0 ? (memberCount / team.maxMembers).clamp(0.0, 1.0) : 0.0;
    final teamLocation = _resolveTeamLocation(team);

    final skills = team.requiredSkills
        .split(RegExp(r'[,|•/]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.hubColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent line
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  isFull ? Colors.redAccent : const Color(0xFF10B981),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team name, Hackathon, Location, and Status Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Avatar / Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary.withValues(alpha: 0.2),
                            context.hubColors.violet.withValues(alpha: 0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primary.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text(
                          team.teamName.isNotEmpty ? team.teamName[0].toUpperCase() : 'T',
                          style: TextStyle(
                            color: primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.teamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.hubColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.emoji_events_outlined, size: 12, color: context.hubColors.muted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  team.hackathon.isEmpty ? 'General Hackathon' : team.hackathon,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.hubColors.muted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (teamLocation.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  teamLocation.toLowerCase().contains('online')
                                      ? Icons.wifi_rounded
                                      : Icons.location_on_outlined,
                                  size: 11,
                                  color: context.hubColors.muted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    teamLocation,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.hubColors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isFull ? Colors.redAccent : const Color(0xFF10B981)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: (isFull ? Colors.redAccent : const Color(0xFF10B981)).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isFull ? 'FULL' : '$openPositions OPEN',
                        style: TextStyle(
                          color: isFull ? Colors.redAccent : const Color(0xFF10B981),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: context.hubColors.border),
                const SizedBox(height: 12),

                // Leader info with avatar initials
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: context.hubColors.background,
                      child: Text(
                        team.leader.isNotEmpty ? team.leader[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: context.hubColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Leader: ',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                    Expanded(
                      child: Text(
                        team.leader,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.hubColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Required skills tags
                Text(
                  'LOOKING FOR SKILLS',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: (skills.isNotEmpty ? skills : [team.requiredSkills])
                      .take(4)
                      .map((skill) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.hubColors.background,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: context.hubColors.border),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                color: context.hubColors.ink,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 12),

                // Team capacity progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Team capacity',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                    Text(
                      '$memberCount / ${team.maxMembers} members',
                      style: TextStyle(
                        color: context.hubColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: context.hubColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFull ? Colors.redAccent : primary,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Join button
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: (isFull || isMember) ? null : () => joinTeam(team),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMember ? const Color(0xFF10B981) : primary,
                      disabledBackgroundColor: isMember
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : context.hubColors.background,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: isMember ? const Color(0xFF10B981) : muted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isMember) ...[
                          const Icon(Icons.check_circle_rounded, size: 14),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          isMember
                              ? 'YOU ARE IN THIS TEAM'
                              : isFull
                                  ? 'TEAM IS FULL'
                                  : 'JOIN THIS TEAM',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
