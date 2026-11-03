import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_hackathon_finder/models/hackathon.dart';
import 'package:ai_hackathon_finder/widgets/hackathon_card.dart';
import 'package:ai_hackathon_finder/theme/app_theme.dart';

void main() {
  testWidgets('HackathonCard renders title, organizer, prize, online location, and handles tap', (tester) async {
    final event = Hackathon(
      id: 'test_card_1',
      title: 'Global AI Championship',
      organizer: 'Google Cloud Hub',
      deadline: '2026-11-30',
      prize: '\$100,000 Grand Prize',
      description: 'Build frontier generative AI applications',
      location: 'Online',
      mode: 'Online',
      teamSize: '1-4',
      registrationLink: 'https://hackpilot.dev',
    );

    bool tapped = false;
    bool bookmarkToggled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkFor(HubPalette.hackathonNight),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              height: 360,
              child: HackathonCard(
                event: event,
                index: 1,
                onTap: () => tapped = true,
                isBookmarked: false,
                onBookmarkToggle: () => bookmarkToggled = true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify key texts are displayed
    expect(find.text('Global AI Championship'), findsOneWidget);
    expect(find.text('Google Cloud Hub'), findsOneWidget);
    expect(find.text('\$100,000 Grand Prize'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);

    // Verify online location badge and wifi icon
    expect(find.text('Online'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);

    // Verify tap on details
    await tester.tap(find.text('DETAILS'));
    expect(tapped, isTrue);

    // Verify bookmark toggle
    await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
    expect(bookmarkToggled, isTrue);
  });

  testWidgets('HackathonCard renders physical in-person location with pin icon', (tester) async {
    final event = Hackathon(
      id: 'test_card_in_person',
      title: 'Robotics Edge Summit',
      organizer: 'NVIDIA Lab',
      deadline: '2026-12-15',
      prize: '\$50,000 Hardware Grant',
      description: 'Autonomous robots sprint',
      location: 'San Francisco, CA',
      mode: 'In-person',
      teamSize: '2-4',
      registrationLink: 'https://hackpilot.dev',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkFor(HubPalette.hackathonNight),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              height: 360,
              child: HackathonCard(
                event: event,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('San Francisco, CA'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
  });

  testWidgets('HackathonCard renders "Location not provided" when no location in DB', (tester) async {
    final event = Hackathon(
      id: 'test_card_missing_loc',
      title: 'Secret Hack',
      organizer: 'Undisclosed',
      deadline: '2026-12-15',
      prize: '\$10,000',
      description: 'Secret challenge',
      location: 'Location not specified',
      mode: 'In-person',
      teamSize: '1-4',
      registrationLink: 'https://hackpilot.dev',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkFor(HubPalette.hackathonNight),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              height: 360,
              child: HackathonCard(
                event: event,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Location not provided'), findsOneWidget);
    expect(find.text('Location not specified'), findsNothing);
    expect(find.text('Not specified'), findsNothing);
  });
}
