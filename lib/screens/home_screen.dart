import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/hackathon.dart';
import '../services/bookmark_service.dart';
import '../services/external_hackathon_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hackathon_card.dart';
import '../widgets/hackathon_image_view.dart';
import 'hackathon_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onFindTeams,
    this.onBookmarkRequested,
    this.initialBookmark,
  });

  final VoidCallback? onFindTeams;
  final ValueChanged<Hackathon>? onBookmarkRequested;
  final Hackathon? initialBookmark;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirestoreService();
  final _bookmarks = BookmarkService();
  final _external = ExternalHackathonService();
  final _search = TextEditingController();
  final _discoverKey = GlobalKey();
  late Stream<List<Hackathon>> _hackathonsStream;
  Timer? _firestoreLoadTimer;
  Timer? _searchDebounce;
  bool _firestoreTimedOut = false;

  List<Hackathon> _externalHackathons = [];
  List<Hackathon>? _lastFirestoreEvents;
  List<Hackathon>? _allEventsCache;
  List<Hackathon>? _filteredEventsCache;
  List<Hackathon> _upcomingEventsCache = [];
  List<Hackathon>? _filterCacheSource;
  String? _filterCacheKey;
  int _openCount = 0;
  int _closingCount = 0;
  bool _loadingExternal = true;
  bool _externalFailed = false;
  bool _usingSampleEvents = false;
  String? _externalError;

  // Filter States
  String _query = '';
  String _category = 'All categories';
  String _locationScope = 'India'; // 'India', 'International', 'All Locations'
  String _selectedState = 'All States';
  String _selectedCity = 'All Cities';
  String _mode = 'Any format';
  String _status = 'Any status';
  bool _hideExpired = true;

  static const _categories = [
    'All categories',
    'AI & Machine Learning',
    'Web Development',
    'Cybersecurity',
    'Robotics & Hardware',
    'Web3 & Blockchain',
    'Cloud Computing',
    'Climate & Green Tech',
    'Startup & Open Source',
  ];

  static const _indianStates = [
    'All States',
    'Karnataka',
    'Maharashtra',
    'Delhi',
    'Telangana',
    'Tamil Nadu',
    'Uttar Pradesh',
    'Kerala',
    'Gujarat',
    'West Bengal',
    'Rajasthan',
    'Punjab',
    'Haryana',
  ];

  static const _indianCities = [
    'All Cities',
    'Bengaluru',
    'New Delhi',
    'Mumbai',
    'Hyderabad',
    'Pune',
    'Chennai',
    'Kolkata',
    'Noida',
    'Gurugram',
    'Ahmedabad',
    'Jaipur',
    'Kochi',
  ];

  static const _internationalCities = [
    'All Cities',
    'San Francisco',
    'Austin',
    'Seattle',
    'New York',
    'London',
    'Berlin',
    'Singapore',
    'Tokyo',
  ];

  @override
  void initState() {
    super.initState();
    _watchFirestore();
    _refreshExternal();
    final initialBookmark = widget.initialBookmark;
    if (initialBookmark != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && FirebaseAuth.instance.currentUser != null) {
          _toggleBookmark(initialBookmark, false);
        }
      });
    }
  }

  @override
  void dispose() {
    _firestoreLoadTimer?.cancel();
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value);
    });
  }

  Future<void> _refreshExternal({bool forceRefresh = false}) async {
    setState(() {
      _loadingExternal = true;
      _externalFailed = false;
      _externalError = null;
    });
    try {
      final events = await _external.fetchHackathons(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _externalHackathons = events;
        _allEventsCache = null;
        _loadingExternal = false;
        _externalError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _externalFailed = true;
        _loadingExternal = false;
        _externalError = error.toString();
      });
    }
  }

  void _watchFirestore() {
    _firestoreLoadTimer?.cancel();
    _firestoreTimedOut = false;
    _hackathonsStream = _firestore.getHackathons().map((events) {
      _firestoreLoadTimer?.cancel();
      _firestoreTimedOut = false;
      return events;
    });
    _firestoreLoadTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _firestoreTimedOut = true);
    });
  }

  void _retryDataSources() {
    setState(() {
      _lastFirestoreEvents = null;
      _allEventsCache = null;
      _usingSampleEvents = false;
      _watchFirestore();
    });
    _refreshExternal(forceRefresh: true);
  }

  String _statusOf(Hackathon event) {
    final deadline = DateTime.tryParse(event.deadline);
    if (deadline == null) return 'Open';
    final remaining = deadline.difference(DateTime.now());
    if (!deadline.isAfter(DateTime.now())) return 'Closed';
    if (remaining.inDays <= 7) return 'Closing soon';
    return 'Open';
  }

  DateTime? _deadlineOf(Hackathon event) => DateTime.tryParse(event.deadline);

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value.trim().isEmpty ? 'Date TBA' : value;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _statusColor(String status) => switch (status) {
    'Closed' => Theme.of(context).colorScheme.error,
    'Closing soon' => context.hubColors.warning,
    'Not announced' => context.hubColors.muted,
    _ => context.hubColors.positive,
  };

  bool _matches(Hackathon event) {
    // 1. Expired check
    if (_hideExpired && event.isExpired) {
      return false;
    }

    // 2. Query search
    final query = _query.trim().toLowerCase();
    final fields = [
      event.title,
      event.displayTitle,
      event.organizer,
      event.location,
      event.displayLocation,
      event.city,
      event.state,
      event.country,
      event.description,
      event.prize,
      event.mode,
    ];
    final matchesQuery = query.isEmpty || fields.any((field) => field.toLowerCase().contains(query));
    if (!matchesQuery) return false;

    // 3. Location Scope
    final matchesScope = switch (_locationScope) {
      'India' => event.isIndia || event.isOnline,
      'International' => event.isInternational,
      _ => true, // 'All Locations'
    };
    if (!matchesScope) return false;

    // 4. State filter
    if (_selectedState != 'All States') {
      final s = _selectedState.toLowerCase();
      final eventState = event.state.toLowerCase();
      final eventLoc = event.location.toLowerCase();
      if (eventState != s && !eventLoc.contains(s)) return false;
    }

    // 5. City filter
    if (_selectedCity != 'All Cities') {
      final c = _selectedCity.toLowerCase();
      final eventCity = event.city.toLowerCase();
      final eventLoc = event.location.toLowerCase();
      if (eventCity != c && !eventLoc.contains(c)) return false;
    }

    // 6. Registration Status
    final matchesStatus = _status == 'Any status' || _statusOf(event).toLowerCase() == _status.toLowerCase();
    if (!matchesStatus) return false;

    // 7. Format / Mode
    final matchesMode = _mode == 'Any format' || switch (_mode) {
      'Online' => event.isOnline,
      'In person' => event.isInPerson,
      'Hybrid' => event.isHybrid,
      _ => true,
    };
    if (!matchesMode) return false;

    // 8. Category
    final searchable = '${event.title} ${event.description} ${event.organizer}'.toLowerCase();
    final matchesCategory = _category == 'All categories' || switch (_category) {
      'AI & Machine Learning' => _containsAny(searchable, ['ai', 'machine learning', 'artificial intelligence', 'llm', 'deep learning', 'neural']),
      'Web Development' => _containsAny(searchable, ['web', 'frontend', 'backend', 'fullstack', 'react', 'javascript', 'flutter', 'app']),
      'Cybersecurity' => _containsAny(searchable, ['cyber', 'security', 'infosec', 'privacy', 'hacker', 'crypto']),
      'Robotics & Hardware' => _containsAny(searchable, ['robot', 'hardware', 'iot', 'embedded', 'sensor', 'arduino']),
      'Web3 & Blockchain' => _containsAny(searchable, ['web3', 'blockchain', 'crypto', 'nft', 'solana', 'ethereum', 'defi']),
      'Cloud Computing' => _containsAny(searchable, ['cloud', 'aws', 'azure', 'devops', 'kubernetes', 'docker', 'server']),
      'Climate & Green Tech' => _containsAny(searchable, ['climate', 'sustainability', 'environment', 'green', 'clean energy']),
      'Startup & Open Source' => _containsAny(searchable, ['startup', 'founder', 'venture', 'open source', 'opensource', 'community']),
      _ => true,
    };
    if (!matchesCategory) return false;

    return true;
  }

  bool _containsAny(String value, List<String> needles) => needles.any(value.contains);

  String _canonicalEventTitle(String title) => title
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  void _cacheEvents(
    List<Hackathon> firestoreEvents, {
    bool firestoreFailed = false,
  }) {
    final eventsByTitle = <String, Hackathon>{};
    for (final event in firestoreEvents) {
      eventsByTitle[_canonicalEventTitle(event.title)] = event;
    }
    for (final event in _externalHackathons) {
      eventsByTitle.putIfAbsent(_canonicalEventTitle(event.title), () => event);
    }
    _usingSampleEvents = eventsByTitle.isEmpty &&
        (!_loadingExternal || _firestoreTimedOut || firestoreFailed);
    if (_usingSampleEvents) {
      for (final event in _sampleEvents) {
        eventsByTitle[_canonicalEventTitle(event.title)] = event;
      }
    }
    final events = eventsByTitle.values.toList()
      ..sort((a, b) {
        // 1. Expired events always go to the bottom
        final aExpired = a.isExpired;
        final bExpired = b.isExpired;
        if (aExpired != bExpired) return aExpired ? 1 : -1;

        // 2. Location priority when India or All Locations is active:
        // Priority 0: Indian physical & hybrid events
        // Priority 1: Indian online events
        // Priority 2: Global online events
        // Priority 3: International physical/hybrid events
        if (_locationScope == 'India' || _locationScope == 'All Locations') {
          int priority(Hackathon h) {
            if (h.isIndia && !h.isOnline) return 0;
            if (h.isIndia && h.isOnline) return 1;
            if (h.isOnline) return 2;
            return 3;
          }
          final pA = priority(a);
          final pB = priority(b);
          if (pA != pB) return pA.compareTo(pB);
        }

        // 3. Nearest registration deadline first
        final aDeadline = _deadlineOf(a);
        final bDeadline = _deadlineOf(b);
        if (aDeadline == null && bDeadline == null) {
          return a.title.compareTo(b.title);
        }
        if (aDeadline == null) return 1;
        if (bDeadline == null) return -1;
        return aDeadline.compareTo(bDeadline);
      });

    _allEventsCache = events;
    _filteredEventsCache = null;
    _filterCacheSource = null;
    _openCount = 0;
    _closingCount = 0;
    _upcomingEventsCache = [];
    final now = DateTime.now();
    for (final event in events) {
      final status = _statusOf(event);
      if (status == 'Open' || status == 'Closing soon') _openCount++;
      if (status == 'Closing soon') _closingCount++;
      final deadline = _deadlineOf(event);
      if (deadline != null &&
          deadline.isAfter(now) &&
          _upcomingEventsCache.length < 6) {
        _upcomingEventsCache.add(event);
      }
    }
  }

  static List<Hackathon> get _sampleEvents {
    final now = DateTime.now();
    String futureDate(int days) {
      final d = now.add(Duration(days: days));
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    return [
      Hackathon(
        id: 'sample_smart_india_ai',
        title: 'Smart India AI Innovation Hackathon',
        organizer: 'MeitY & AICTE India',
        deadline: futureDate(14),
        prize: '₹15,00,000 Cash Pool',
        description: 'Build sovereign generative AI solutions, Indic language foundation models, and agricultural intelligence systems for India.',
        location: 'Bengaluru, Karnataka, India',
        mode: 'In-person',
        city: 'Bengaluru',
        state: 'Karnataka',
        country: 'India',
        teamSize: '2-4 Members',
        registrationLink: 'https://hackpilot.dev',
      ),
      Hackathon(
        id: 'sample_bharat_web3_summit',
        title: 'Bharat Web3 & Open Source Sprint',
        organizer: 'Polygon & Devfolio India',
        deadline: futureDate(9),
        prize: '₹10,00,000 in Grants',
        description: 'Engineer high-throughput decentralized protocols, public digital goods, and zero-knowledge privacy layers for Indian digital infrastructure.',
        location: 'New Delhi, Delhi, India',
        mode: 'Hybrid',
        city: 'New Delhi',
        state: 'Delhi',
        country: 'India',
        teamSize: '1-4 Members',
        registrationLink: 'https://hackpilot.dev',
      ),
      Hackathon(
        id: 'sample_fintech_mumbai_sprint',
        title: 'FinTech Supercharge Mumbai Challenge',
        organizer: 'NPCI & Mumbai Tech Council',
        deadline: futureDate(6),
        prize: '₹12,00,000 Cash Prize',
        description: 'Create next-generation UPI offline protocols, automated micro-lending fraud detection, and biometric digital banking interfaces.',
        location: 'Mumbai, Maharashtra, India',
        mode: 'In-person',
        city: 'Mumbai',
        state: 'Maharashtra',
        country: 'India',
        teamSize: '2-5 Members',
        registrationLink: 'https://hackpilot.dev',
      ),
      Hackathon(
        id: 'sample_cybershield_hyderabad',
        title: 'CyberShield India Defense Challenge',
        organizer: 'CERT-In & CyberPeace Foundation',
        deadline: futureDate(18),
        prize: '₹8,00,000 Security Bounty',
        description: 'Compete in zero-day critical infrastructure defense, telecom threat intelligence, and quantum-resistant cryptography puzzles.',
        location: 'Hyderabad, Telangana, India',
        mode: 'In-person',
        city: 'Hyderabad',
        state: 'Telangana',
        country: 'India',
        teamSize: '2-4 Members',
        registrationLink: 'https://hackpilot.dev',
      ),
      Hackathon(
        id: 'sample_pune_healthtech',
        title: 'Pune Next-Gen HealthTech Innovation',
        organizer: 'Pune Health Sciences Hub',
        deadline: futureDate(21),
        prize: '₹7,50,000 Grants',
        description: 'Develop IoT remote patient monitoring devices, clinical predictive diagnostics, and telemedicine edge systems.',
        location: 'Pune, Maharashtra, India',
        mode: 'Hybrid',
        city: 'Pune',
        state: 'Maharashtra',
        country: 'India',
        teamSize: '2-4 Members',
        registrationLink: 'https://hackpilot.dev',
      ),
      Hackathon(
        id: 'sample_chennai_robotics',
        title: 'Autonomous Edge AI & Robotics Expo',
        organizer: 'IIT Madras Research Park',
        deadline: futureDate(11),
        prize: '₹8,50,000 Hardware Grants',
        description: 'Program autonomous robotics, drone delivery telemetry, and embedded computer vision models for industrial automation.',
        location: 'Chennai, Tamil Nadu, India',
        mode: 'In-person',
        city: 'Chennai',
        state: 'Tamil Nadu',
        country: 'India',
        teamSize: '2-4 Members',
        registrationLink: 'https://hackpilot.dev',
      ),
      Hackathon(
        id: 'sample_global_ai_agents',
        title: 'Global AI Agents & LLM Hackathon',
        organizer: 'Google DeepMind & Cloud',
        deadline: futureDate(16),
        prize: '\$75,000 Cash + Cloud Credits',
        description: 'Build autonomous multimodal AI agents, multi-step reasoning tools, and generative workflows with frontier models.',
        location: 'Online',
        mode: 'Online',
        teamSize: '1-4 Members',
        registrationLink: 'https://hackpilot.dev',
      ),
      Hackathon(
        id: 'sample_fullstack_web_sprint',
        title: 'Next-Gen Web & Full-Stack Challenge',
        organizer: 'Vercel & Chrome Dev',
        deadline: futureDate(12),
        prize: '\$45,000 Total Prize Pool',
        description: 'Design and ship high-performance web applications, edge runtimes, and accessible reactive UI components.',
        location: 'Online',
        mode: 'Online',
        teamSize: '1-3 Members',
        registrationLink: 'https://hackpilot.dev',
      ),
      Hackathon(
        id: 'sample_cybershield_defense',
        title: 'CyberShield Global Defense Summit',
        organizer: 'Cloudflare & InfoSec Alliance',
        deadline: futureDate(4),
        prize: '\$60,000 Security Bounty',
        description: 'Compete in zero-day threat detection, cryptography puzzles, secure enclave design, and vulnerability penetration testing.',
        location: 'Austin, TX, USA',
        mode: 'Hybrid',
        city: 'Austin',
        state: 'TX',
        country: 'USA',
        teamSize: '2-4 Members',
        registrationLink: 'https://hackpilot.dev',
      ),
      Hackathon(
        id: 'sample_autonomous_robotics',
        title: 'Autonomous Robotics & Edge AI Expo',
        organizer: 'NVIDIA Robotics Lab',
        deadline: futureDate(25),
        prize: '\$80,000 Hardware Grants',
        description: 'Program robotic arms, computer vision rovers, and sensor arrays for industrial and environmental automation.',
        location: 'San Francisco, CA, USA',
        mode: 'In-person',
        city: 'San Francisco',
        state: 'CA',
        country: 'USA',
        teamSize: '2-5 Members',
        registrationLink: 'https://hackpilot.dev',
      ),
      Hackathon(
        id: 'sample_climatetech_innovation',
        title: 'ClimateTech & Clean Energy Innovation',
        organizer: 'Green Tech World Initiative',
        deadline: futureDate(19),
        prize: '\$35,00,000 Innovation Grant',
        description: 'Create predictive algorithms, smart energy grid monitors, and carbon offset tracking tools to accelerate sustainability.',
        location: 'Seattle, WA, USA',
        mode: 'Hybrid',
        city: 'Seattle',
        state: 'WA',
        country: 'USA',
        teamSize: '1-4 Members',
        registrationLink: 'https://hackpilot.dev',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.hubColors.background,
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<Hackathon>>(
          stream: _hackathonsStream,
          builder: (context, snapshot) {
            if (!identical(_lastFirestoreEvents, snapshot.data) ||
                _allEventsCache == null ||
                (_firestoreTimedOut && !_usingSampleEvents)) {
              _lastFirestoreEvents = snapshot.data;
              _cacheEvents(
                snapshot.data ?? const <Hackathon>[],
                firestoreFailed: snapshot.hasError,
              );
            }
            final all = _allEventsCache!;
            final filterKey =
                '$_query|$_category|$_locationScope|$_selectedState|$_selectedCity|$_mode|$_status|$_hideExpired';
            if (!identical(_filterCacheSource, all) ||
                _filterCacheKey != filterKey) {
              _filterCacheSource = all;
              _filterCacheKey = filterKey;
              _filteredEventsCache = all.where(_matches).toList();
            }
            final filtered = _filteredEventsCache!;
            final width = MediaQuery.sizeOf(context).width;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: _hero(width)),
                SliverToBoxAdapter(child: _benefitStrip(width)),
                SliverToBoxAdapter(child: _searchSection(width)),
                SliverToBoxAdapter(child: _stats(all.length, _openCount, _closingCount)),
                SliverToBoxAdapter(child: _featuredSection(all, width)),
                if (_upcomingEventsCache.isNotEmpty)
                  SliverToBoxAdapter(child: _deadlinesSection(_upcomingEventsCache, width)),
                SliverToBoxAdapter(child: _domains(width)),
                SliverToBoxAdapter(child: _discoveryHeader(filtered.length, width)),
                if ((snapshot.hasError || _firestoreTimedOut) && all.isEmpty)
                  SliverToBoxAdapter(child: _message(Icons.cloud_off_outlined, 'Hackathon listings could not load', _firestoreTimedOut && !snapshot.hasError ? 'Firestore is synchronizing. Showing catalog listings.' : 'Firestore sync: ${snapshot.error}', retryLabel: 'Retry', retry: _retryDataSources))
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(child: _message(Icons.search_off_rounded, 'No hackathons match those filters', 'Try a different search term, change your location filter, or reset filters to explore.', retryLabel: 'Reset filters', retry: _resetFilters))
                else
                  _eventGrid(filtered, width),
                if (_externalFailed && all.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                        child: TextButton.icon(
                          onPressed: () => _refreshExternal(forceRefresh: true),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(
                            'External feed notice: ${_externalError ?? 'tap to refresh'}.',
                            style: TextStyle(color: context.hubColors.muted, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: _closingCta(width)),
                SliverToBoxAdapter(child: _footer(width)),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hero(double width) {
    final horizontal = width >= 850;
    final titleSize = width < 480 ? 38.0 : width < 850 ? 50.0 : 64.0;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6818).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFFF6818).withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF6818),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'INDIA & GLOBAL DEVELOPER HUB',
                style: TextStyle(
                  color: Color(0xFFFF6818),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: titleSize,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.6,
              color: context.hubColors.ink,
            ),
            children: const [
              TextSpan(text: 'Find your crew.\nBuild what\n'),
              TextSpan(
                text: 'matters next.',
                style: TextStyle(color: Color(0xFFFF6818)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Discover top hackathons in India and worldwide, assemble competitive teams, and track registration deadlines with real-time sync.',
          style: TextStyle(
            color: context.hubColors.muted,
            fontSize: width < 480 ? 14.0 : 16.0,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _scrollToListings,
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text('Explore Hackathons'),
              style: FilledButton.styleFrom(
                backgroundColor: context.hubColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _openTeamFinder,
              icon: const Icon(Icons.groups_2_rounded, size: 18),
              label: const Text('Find Teams'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.hubColors.ink,
                side: BorderSide(color: context.hubColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: context.hubColors.background,
        border: Border(bottom: BorderSide(color: context.hubColors.border)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6818).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  width > 1100 ? 36 : (width < 600 ? 16 : 22),
                  width < 600 ? 28 : 54,
                  width > 1100 ? 36 : (width < 600 ? 16 : 22),
                  width < 600 ? 24 : 48,
                ),
                child: horizontal
                    ? Row(
                        children: [
                          Expanded(flex: 6, child: text),
                          const SizedBox(width: 32),
                          Expanded(flex: 5, child: _heroIllustration()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text,
                          const SizedBox(height: 24),
                          Center(child: _heroIllustration(compact: true)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroIllustration({bool compact = false}) => SizedBox(
    height: compact ? 190 : 280,
    width: compact ? 330 : double.infinity,
    child: LayoutBuilder(builder: (context, box) {
      final scale = (box.maxWidth / 440).clamp(0.7, 1.0);
      return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        Container(
          width: 300 * scale,
          height: 235 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.hubColors.primary.withValues(alpha: 0.1),
          ),
        ),
        Positioned(
          right: 25 * scale,
          top: 24 * scale,
          child: Container(
            width: 60 * scale,
            height: 60 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.hubColors.warning.withValues(alpha: 0.2),
            ),
          ),
        ),
        Positioned(
          left: 26 * scale,
          top: 37 * scale,
          child: _floatingCard(Icons.lightbulb_outline_rounded, 'BIG IDEAS', context.hubColors.warning, scale),
        ),
        Positioned(
          right: 15 * scale,
          bottom: 32 * scale,
          child: _floatingCard(Icons.groups_2_outlined, 'DREAM TEAMS', context.hubColors.violet, scale),
        ),
        Positioned(
          left: 83 * scale,
          bottom: 21 * scale,
          child: Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 230 * scale,
              height: 164 * scale,
              padding: EdgeInsets.all(15 * scale),
              decoration: BoxDecoration(
                color: context.hubColors.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: context.hubColors.border),
                boxShadow: [
                  BoxShadow(
                    color: context.hubColors.deep.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 31 * scale,
                        height: 31 * scale,
                        decoration: BoxDecoration(
                          color: context.hubColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.code_rounded, color: context.hubColors.primary, size: 17 * scale),
                      ),
                      SizedBox(width: 9 * scale),
                      Text(
                        'HACKATHON SPRINT',
                        style: TextStyle(
                          fontSize: 9 * scale,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                          color: context.hubColors.muted,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
                  Text(
                    'Ideas become\nreal things here.',
                    style: TextStyle(
                      fontSize: 17 * scale,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: context.hubColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Align(
                          widthFactor: 0.78,
                          child: CircleAvatar(
                            radius: 12 * scale,
                            backgroundColor: [
                              context.hubColors.primary,
                              context.hubColors.positive,
                              context.hubColors.violet,
                              context.hubColors.warning,
                            ][i],
                            child: Icon(Icons.person, size: 13 * scale, color: Colors.white),
                          ),
                        ),
                      SizedBox(width: 8 * scale),
                      Text(
                        'your next team',
                        style: TextStyle(fontSize: 9 * scale, color: context.hubColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 42 * scale,
          right: 65 * scale,
          child: Icon(Icons.auto_awesome_rounded, color: context.hubColors.warning, size: 24 * scale),
        ),
      ]);
    }),
  );

  Widget _floatingCard(IconData icon, String text, Color color, double scale) => Container(
    padding: EdgeInsets.symmetric(horizontal: 11 * scale, vertical: 9 * scale),
    decoration: BoxDecoration(
      color: context.hubColors.surface,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: context.hubColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16 * scale),
        SizedBox(width: 6 * scale),
        Text(
          text,
          style: TextStyle(
            fontSize: 8.5 * scale,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w900,
            color: context.hubColors.ink,
          ),
        ),
      ],
    ),
  );

  Widget _benefitStrip(double width) => Container(
    decoration: BoxDecoration(
      color: context.hubColors.surface,
      border: Border(bottom: BorderSide(color: context.hubColors.border)),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width > 1100 ? 36 : 22,
            vertical: 16,
          ),
          child: Wrap(
            spacing: 32,
            runSpacing: 14,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _Benefit(
                icon: Icons.flag_rounded,
                title: 'India-First Discovery',
                subtitle: 'Prioritizing events in Bengaluru, Delhi, Mumbai & nationwide',
                color: context.hubColors.primary,
              ),
              _Benefit(
                icon: Icons.handshake_outlined,
                title: 'Assemble Your Team',
                subtitle: 'Meet teammates for your next big idea',
                color: const Color(0xFF00D9E8),
              ),
              _Benefit(
                icon: Icons.translate_rounded,
                title: 'Auto-Translated English',
                subtitle: 'Multilingual listings naturally translated to English',
                color: context.hubColors.positive,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _searchSection(double width) {
    final hasActiveFilters = _query.isNotEmpty ||
        _category != 'All categories' ||
        _locationScope != 'India' ||
        _selectedState != 'All States' ||
        _selectedCity != 'All Cities' ||
        _mode != 'Any format' ||
        _status != 'Any status' ||
        !_hideExpired;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: EdgeInsets.fromLTRB(width > 1100 ? 36 : 22, 28, width > 1100 ? 36 : 22, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Your Next Hackathon',
                style: TextStyle(
                  color: context.hubColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),

              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      onSubmitted: (value) {
                        _searchDebounce?.cancel();
                        setState(() => _query = value);
                      },
                      style: TextStyle(color: context.hubColors.ink),
                      decoration: InputDecoration(
                        hintText: 'Search by title, organizer, city, state, domain, or prize...',
                        hintStyle: TextStyle(color: context.hubColors.muted, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: context.hubColors.primary),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchDebounce?.cancel();
                                  _search.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: context.hubColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.hubColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.hubColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.hubColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () {
                      _searchDebounce?.cancel();
                      setState(() => _query = _search.text);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: context.hubColors.primary,
                      minimumSize: const Size(100, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Search', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Location Scope Selector Bar (India-First default)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _scopeChip('🇮🇳 India (Default)', 'India'),
                    const SizedBox(width: 8),
                    _scopeChip('🌐 International', 'International'),
                    const SizedBox(width: 8),
                    _scopeChip('🗺️ All Locations', 'All Locations'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Horizontal Category Pills
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    for (final cat in _categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: _category == cat,
                          onSelected: (selected) {
                            setState(() => _category = selected ? cat : 'All categories');
                          },
                          labelStyle: TextStyle(
                            color: _category == cat ? Colors.white : context.hubColors.ink,
                            fontSize: 11,
                            fontWeight: _category == cat ? FontWeight.w800 : FontWeight.w600,
                          ),
                          selectedColor: context.hubColors.primary,
                          backgroundColor: context.hubColors.surface,
                          side: BorderSide(
                            color: _category == cat ? context.hubColors.primary : context.hubColors.border,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Filters: Format, State, City, Status, Hide Expired, Reset
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _filterMenu(
                    'Format',
                    _mode,
                    ['Any format', 'Online', 'In person', 'Hybrid'],
                    (val) => setState(() => _mode = val),
                  ),
                  if (_locationScope != 'International')
                    _filterMenu(
                      'State',
                      _selectedState,
                      _indianStates,
                      (val) => setState(() => _selectedState = val),
                    ),
                  _filterMenu(
                    'City',
                    _selectedCity,
                    _locationScope == 'International' ? _internationalCities : _indianCities,
                    (val) => setState(() => _selectedCity = val),
                  ),
                  _filterMenu(
                    'Status',
                    _status,
                    ['Any status', 'Open', 'Closing soon', 'Closed'],
                    (val) => setState(() => _status = val),
                  ),
                  // Upcoming only toggle chip
                  InkWell(
                    onTap: () => setState(() => _hideExpired = !_hideExpired),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _hideExpired
                            ? context.hubColors.primary.withValues(alpha: 0.14)
                            : context.hubColors.surface,
                        border: Border.all(
                          color: _hideExpired ? context.hubColors.primary : context.hubColors.border,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _hideExpired ? Icons.check_circle_rounded : Icons.schedule_rounded,
                            size: 13,
                            color: _hideExpired ? context.hubColors.primary : context.hubColors.muted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Active & Upcoming',
                            style: TextStyle(
                              color: _hideExpired ? context.hubColors.primary : context.hubColors.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasActiveFilters)
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Reset filters', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      style: TextButton.styleFrom(foregroundColor: context.hubColors.primary),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scopeChip(String label, String value) {
    final isSelected = _locationScope == value;
    final primary = context.hubColors.primary;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _locationScope = value;
            _selectedState = 'All States';
            _selectedCity = 'All Cities';
          });
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : context.hubColors.ink,
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
      ),
      selectedColor: primary,
      backgroundColor: context.hubColors.surface,
      side: BorderSide(
        color: isSelected ? primary : context.hubColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  Widget _filterMenu(
    String label,
    String value,
    List<String> choices,
    ValueChanged<String> onSelected,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Filter by $label',
      onSelected: onSelected,
      itemBuilder: (_) => choices.map((item) => PopupMenuItem(value: item, child: Text(item))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.hubColors.surface,
          border: Border.all(color: context.hubColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ', style: TextStyle(color: context.hubColors.muted, fontSize: 11)),
            Text(value, style: TextStyle(color: context.hubColors.ink, fontSize: 11, fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: context.hubColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _stats(int total, int open, int closing) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1280),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
        child: Wrap(
          spacing: 20,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _stat(Icons.explore_outlined, '$total', 'hackathons listed', context.hubColors.primary),
            _stat(Icons.bolt_rounded, '$open', 'open for registration', context.hubColors.positive),
            _stat(Icons.schedule_rounded, '$closing', 'closing this week', context.hubColors.warning),
            if (_loadingExternal)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    ),
  );

  Widget _stat(IconData icon, String value, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(value, style: TextStyle(color: context.hubColors.ink, fontWeight: FontWeight.w900, fontSize: 13)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: context.hubColors.muted, fontSize: 11)),
    ],
  );

  Widget _featuredSection(List<Hackathon> events, double width) {
    final featured = events.where((event) => _statusOf(event) != 'Closed').take(4).toList();
    if (featured.isEmpty) return const SizedBox(height: 14);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: EdgeInsets.fromLTRB(width > 1100 ? 36 : 22, 22, width > 1100 ? 36 : 22, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6818),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Featured Opportunities',
                    style: TextStyle(
                      color: context.hubColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _scrollToListings,
                    child: const Text('View all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: featured.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) => SizedBox(
                    width: width < 600 ? width - 56 : 350,
                    child: _featuredCard(featured[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featuredCard(Hackathon event) {
    final status = _statusOf(event);
    final statusColor = _statusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: context.hubColors.surface,
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
      child: InkWell(
        onTap: () => _openDetails(event),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              height: double.infinity,
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
            ),
            Expanded(
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
                        color: context.hubColors.ink,
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.organizer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.hubColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (event.prize.isNotEmpty && event.prize != 'Not specified')
                      Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, size: 12, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.prize,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 11, color: context.hubColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(event.deadline),
                          style: TextStyle(
                            color: context.hubColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          event.isOnline ? Icons.wifi_rounded : Icons.location_on_outlined,
                          size: 11,
                          color: context.hubColors.muted,
                        ),
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 105),
                          child: Text(
                            event.displayLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.hubColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }

  Widget _deadlinesSection(List<Hackathon> events, double width) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1280),
      child: Padding(
        padding: EdgeInsets.fromLTRB(width > 1100 ? 36 : 22, 18, width > 1100 ? 36 : 22, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alarm_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Registration Deadlines',
                  style: TextStyle(
                    color: context.hubColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: events.take(4).map((event) {
                final deadline = DateTime.tryParse(event.deadline);
                final days = deadline != null ? deadline.difference(DateTime.now()).inDays : 0;
                final countdownText = days <= 0
                    ? 'Closes Today'
                    : days == 1
                        ? '1 Day Left'
                        : '$days Days Left';

                return SizedBox(
                  width: width < 600 ? width - 44 : 270,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.hubColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.hubColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openDetails(event),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: HackathonImageView(
                                  event: event,
                                  width: 44,
                                  height: 44,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.hubColors.ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          countdownText,
                                          style: const TextStyle(
                                            color: Color(0xFFF59E0B),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _formatDate(event.deadline),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: context.hubColors.muted,
                                            fontSize: 9.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _domains(double width) => _contentBand(
    width,
    eyebrow: 'PICK YOUR FRONTIER',
    title: 'Explore Opportunities Across Every Tech Domain',
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in [
          (Icons.smart_toy_outlined, 'AI & Machine Learning'),
          (Icons.language_rounded, 'Web Development'),
          (Icons.phone_iphone_rounded, 'Mobile Apps'),
          (Icons.security_rounded, 'Cybersecurity'),
          (Icons.currency_bitcoin_rounded, 'Web3 & Blockchain'),
          (Icons.sensors_rounded, 'IoT & Robotics'),
          (Icons.query_stats_rounded, 'Data Science'),
          (Icons.cloud_outlined, 'Cloud Computing'),
        ])
          InkWell(
            onTap: () {
              setState(() {
                _category = item.$2;
                _scrollToListings();
              });
            },
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.hubColors.surface,
                border: Border.all(color: context.hubColors.border),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$1, color: context.hubColors.primary, size: 17),
                  const SizedBox(width: 8),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: context.hubColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _discoveryHeader(int count, double width) => Center(
    key: _discoverKey,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1280),
      child: Padding(
        padding: EdgeInsets.fromLTRB(width > 1100 ? 36 : 22, 24, width > 1100 ? 36 : 22, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Hackathons',
                    style: TextStyle(
                      color: context.hubColors.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _locationScope == 'India'
                        ? 'Prioritizing Indian hackathons and online events open to India.'
                        : _locationScope == 'International'
                            ? 'Exploring international and worldwide hackathons.'
                            : 'Showing hackathons across all global locations.',
                    style: TextStyle(color: context.hubColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.hubColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.hubColors.border),
              ),
              child: Text(
                '$count RESULTS',
                style: TextStyle(
                  color: context.hubColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _eventGrid(List<Hackathon> events, double width) => SliverPadding(
    padding: EdgeInsets.fromLTRB(width > 1100 ? 36 : 22, 14, width > 1100 ? 36 : 22, 20),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.crossAxisExtent;
        final columns = available >= 1200
            ? 4
            : available >= 860
                ? 3
                : available >= 580
                    ? 2
                    : 1;
        final cardHeight = columns == 1 ? 328.0 : 356.0;
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          return SliverGrid.builder(
            itemCount: events.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: cardHeight,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),
            itemBuilder: (context, index) {
              final event = events[index];
              return HackathonCard(
                event: event,
                index: index + 1,
                onTap: () => _openDetails(event),
                isBookmarked: false,
                onBookmarkToggle: () {
                  final callback = widget.onBookmarkRequested;
                  if (callback == null) {
                    _notify('Sign in to save hackathons.');
                  } else {
                    callback(event);
                  }
                },
              );
            },
          );
        }

        return StreamBuilder<Set<String>>(
          stream: _bookmarks.getBookmarkIds(),
          builder: (context, snapshot) {
            final savedIds = snapshot.data ?? const <String>{};
            return SliverGrid.builder(
              itemCount: events.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: cardHeight,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
              ),
              itemBuilder: (context, index) {
                final event = events[index];
                final isSaved = savedIds.contains(event.id);
                return HackathonCard(
                  event: event,
                  index: index + 1,
                  onTap: () => _openDetails(event),
                  isBookmarked: isSaved,
                  onBookmarkToggle: () => _toggleBookmark(event, isSaved),
                );
              },
            );
          },
        );
      },
    ),
  );

  Widget _closingCta(double width) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1280),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(width > 1100 ? 36 : 22, 30, width > 1100 ? 36 : 22, 14),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF101720),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF202A35)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 18,
          runSpacing: 14,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'READY TO BUILD SOMETHING EXTRAORDINARY?',
                  style: TextStyle(
                    color: Color(0xFFF5F7FA),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Find your team. Ship your MVP. Launch your startup.',
                  style: TextStyle(color: Color(0xFFA1B1C4), fontSize: 13),
                ),
              ],
            ),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _openTeamFinder,
                  icon: const Icon(Icons.groups_2_rounded, size: 17),
                  label: const Text('Find Teammates'),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.hubColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _scrollToListings,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 17),
                  label: const Text('Back to Top'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _footer(double width) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1280),
      child: Padding(
        padding: EdgeInsets.fromLTRB(width > 1100 ? 36 : 22, 24, width > 1100 ? 36 : 22, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: context.hubColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      'H',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'HACKPILOT',
                  style: TextStyle(
                    color: context.hubColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            Text(
              'MADE FOR DEVELOPERS',
              style: TextStyle(
                color: context.hubColors.muted,
                fontSize: 9.5,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _contentBand(
    double width, {
    required String eyebrow,
    required String title,
    required Widget child,
  }) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1280),
      child: Padding(
        padding: EdgeInsets.fromLTRB(width > 1100 ? 36 : 22, 36, width > 1100 ? 36 : 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: TextStyle(
                color: context.hubColors.violet,
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: context.hubColors.ink,
                fontSize: 24,
                letterSpacing: -0.4,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );

  Widget _message(
    IconData icon,
    String title,
    String subtitle, {
    String? retryLabel,
    VoidCallback? retry,
  }) => Center(
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(22, 14, 22, 18),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: context.hubColors.surface,
        border: Border.all(color: context.hubColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: context.hubColors.primary, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.hubColors.ink, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.hubColors.muted, fontSize: 12.5, height: 1.45),
          ),
          if (retry != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: retry,
              style: FilledButton.styleFrom(
                backgroundColor: context.hubColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: Text(retryLabel ?? 'Try again'),
            ),
          ],
        ],
      ),
    ),
  );

  void _resetFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _category = 'All categories';
      _locationScope = 'India';
      _selectedState = 'All States';
      _selectedCity = 'All Cities';
      _mode = 'Any format';
      _status = 'Any status';
      _hideExpired = true;
    });
  }

  void _scrollToListings() {
    final target = _discoverKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 400),
        alignment: 0.15,
      );
    }
  }

  void _openTeamFinder() {
    final callback = widget.onFindTeams;
    if (callback != null) {
      callback();
    } else {
      _notify('Choose Find Teams in the navigation to meet your next teammates.');
    }
  }

  Future<void> _toggleBookmark(Hackathon event, bool saved) async {
    try {
      if (saved) {
        await _bookmarks.removeBookmark(event.id);
      } else {
        await _bookmarks.addBookmark(hackathonId: event.id, data: event.toMap());
      }
      if (mounted) {
        _notify(saved ? 'Removed from saved hackathons.' : 'Hackathon saved! 🚀');
      }
    } catch (_) {
      if (mounted) _notify('Could not update bookmark. Please try again.');
    }
  }

  void _openDetails(Hackathon event) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HackathonDetailsScreen(
        hackathon: event,
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

  void _notify(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.hubColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.hubColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: context.hubColors.muted, fontSize: 10.5),
            ),
          ],
        ),
      ],
    );
  }
}
