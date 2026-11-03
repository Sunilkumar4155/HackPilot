import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_hackathon_finder/models/hackathon.dart';
import 'package:ai_hackathon_finder/screens/hackathon_details_screen.dart';
import 'package:ai_hackathon_finder/theme/app_theme.dart';

void main() {
  group('Widget Tests: HackathonDetailsScreen Comprehensive Sections & Official Website CTA', () {
    final sampleHackathon = Hackathon(
      id: 'bharat_ai_01',
      title: 'Bharat AI National Innovation Hackathon 2026',
      organizer: 'Ministry of Electronics & IT',
      deadline: '2026-12-15',
      prize: '₹25,00,000 Cash Pool',
      description: '''
### Overview
A premier national hackathon to build sovereign AI systems and Indian language models.

### Problem Statements
- Challenge 1: Indic Multimodal LLMs for vernacular education
- Challenge 2: Autonomous drone pathfinding for disaster relief

### Eligibility
- Open to undergraduate and postgraduate students in India
- Early stage startup founders and working software engineers

### Judging Criteria
- Innovation & Originality (30%)
- Technical Architecture & Depth (30%)
- Impact & Practical Scalability (40%)

### Required Skills
- Python, PyTorch, Flutter, LangChain, FastEmbed

### Registration Instructions
1. Submit team application on the official portal.
2. Join the Discord developer workspace.

### Contact Information
Email: hackathon@meity.gov.in
''',
      location: 'Bengaluru, Karnataka, India',
      mode: 'In-person',
      teamSize: '2-4 Developers',
      registrationLink: 'https://hackpilot.dev/register/bharat-ai',
      imageUrl: '',
      officialWebsite: 'https://bharatai.gov.in',
      startDate: '2026-12-20',
      endDate: '2026-12-22',
      submissionDeadline: '2026-12-22',
      venue: 'National Science Seminar Complex, IISc',
      themes: ['AI & Machine Learning', 'Indic NLP', 'GovTech'],
    );

    Widget buildTestScreen(Hackathon event) {
      return MaterialApp(
        theme: AppTheme.dark,
        home: HackathonDetailsScreen(
          hackathon: event,
        ),
      );
    }

    testWidgets('renders all major expanded detail sections and official website CTA', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(sampleHackathon));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Hero branding
      expect(find.text('Bharat AI National Innovation Hackathon 2026'), findsWidgets);
      expect(find.text('Ministry of Electronics & IT'), findsWidgets);

      // Section Headers
      expect(find.text('At a Glance'), findsOneWidget);
      expect(find.text('Important Dates & Timeline'), findsOneWidget);
      expect(find.text('Event Format & Location'), findsOneWidget);
      expect(find.text('Prizes & Rewards'), findsOneWidget);
      expect(find.text('Themes & Domains'), findsOneWidget);
      expect(find.text('Team Requirements & Squad Size'), findsOneWidget);
      expect(find.text('About the Hackathon'), findsOneWidget);
      expect(find.text('Problem Statements & Challenges'), findsOneWidget);
      expect(find.text('Eligibility & Who Can Participate'), findsOneWidget);
      expect(find.text('Judging Criteria'), findsWidgets);
      expect(find.text('Required Skills & Technologies'), findsOneWidget);
      expect(find.text('Registration Instructions'), findsWidgets);
      expect(find.text('Official Contact & Support'), findsOneWidget);

      // Mandatory Requirement 2: Official Website CTA
      expect(find.text('Want to know more about this hackathon?'), findsOneWidget);
      expect(find.text('Visit Official Website ↗'), findsOneWidget);

      // Separate Registration Button
      expect(find.text('REGISTER NOW ↗'), findsWidgets);

      // Verified themes
      expect(find.text('AI & Machine Learning'), findsWidgets);
      expect(find.text('Indic NLP'), findsOneWidget);

      // Venue
      expect(find.text('National Science Seminar Complex, IISc'), findsOneWidget);
    });

    testWidgets('displays "Not specified by organizer" for missing fields gracefully', (tester) async {
      final minimalHackathon = Hackathon(
        id: 'minimal_01',
        title: 'Minimal Community Hackathon',
        organizer: 'Open Community',
        deadline: '',
        prize: '',
        description: '',
        location: '',
        mode: 'Online',
        teamSize: '',
        registrationLink: 'https://example.com/reg',
      );

      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestScreen(minimalHackathon));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Confirms graceful fallback
      expect(find.textContaining('Not specified by organizer'), findsWidgets);
      expect(find.text('Want to know more about this hackathon?'), findsOneWidget);
      expect(find.text('Visit Official Website ↗'), findsOneWidget);
    });
  });
}
