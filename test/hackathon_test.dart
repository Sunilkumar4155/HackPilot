import 'package:flutter_test/flutter_test.dart';
import 'package:ai_hackathon_finder/models/hackathon.dart';
import 'package:ai_hackathon_finder/models/team.dart';
import 'package:ai_hackathon_finder/utils/hackathon_image_helper.dart';

void main() {
  group('Hackathon Model & Image Helper Tests', () {
    test('Hackathon model parses from map correctly', () {
      final map = {
        'title': 'AI Agents Summit',
        'organizer': 'Google Cloud',
        'deadline': '2026-12-01',
        'prize': '\$50,000',
        'description': 'Build autonomous LLM agents',
        'location': 'Online',
        'mode': 'Online',
        'teamSize': '1-4',
        'registrationLink': 'https://example.com/register',
        'imageUrl': 'https://example.com/banner.jpg',
      };

      final hackathon = Hackathon.fromMap('ai_summit_1', map);

      expect(hackathon.id, 'ai_summit_1');
      expect(hackathon.title, 'AI Agents Summit');
      expect(hackathon.organizer, 'Google Cloud');
      expect(hackathon.prize, '\$50,000');
      expect(hackathon.imageUrl, 'https://example.com/banner.jpg');
    });

    test('HackathonImageHelper resolves custom URL when provided', () {
      final event = Hackathon(
        id: 'test_1',
        title: 'Custom Event',
        organizer: 'Org',
        deadline: '2026-11-20',
        prize: '\$10,000',
        description: 'Test event',
        location: 'Online',
        mode: 'Online',
        teamSize: '2-4',
        registrationLink: '',
        imageUrl: 'https://images.example.com/custom.png',
      );

      final resolved = HackathonImageHelper.resolveImageUrl(event);
      expect(resolved, 'https://images.example.com/custom.png');
    });

    test('HackathonImageHelper assigns distinct domain-specific photography', () {
      final aiEvent = Hackathon(
        id: 'ai_1',
        title: 'Deep Learning & AI Agents',
        organizer: 'AI Lab',
        deadline: '',
        prize: '',
        description: 'Machine learning neural networks',
        location: '',
        mode: 'Online',
        teamSize: '',
        registrationLink: '',
      );

      final webEvent = Hackathon(
        id: 'web_1',
        title: 'Frontend & Full-Stack Showcase',
        organizer: 'Web Devs',
        deadline: '',
        prize: '',
        description: 'React, Flutter, and JavaScript web apps',
        location: '',
        mode: 'Online',
        teamSize: '',
        registrationLink: '',
      );

      final cyberEvent = Hackathon(
        id: 'cyber_1',
        title: 'Cyber Defense & Security CTF',
        organizer: 'SecOps',
        deadline: '',
        prize: '',
        description: 'Zero day vulnerabilities and cybersecurity shields',
        location: '',
        mode: 'Online',
        teamSize: '',
        registrationLink: '',
      );

      final aiImage = HackathonImageHelper.resolveImageUrl(aiEvent);
      final webImage = HackathonImageHelper.resolveImageUrl(webEvent);
      final cyberImage = HackathonImageHelper.resolveImageUrl(cyberEvent);

      expect(aiImage.startsWith('https://images.unsplash.com/'), isTrue);
      expect(webImage.startsWith('https://images.unsplash.com/'), isTrue);
      expect(cyberImage.startsWith('https://images.unsplash.com/'), isTrue);

      // Verify that different domains get different images
      expect(aiImage != webImage, isTrue);
      expect(aiImage != cyberImage, isTrue);
      expect(webImage != cyberImage, isTrue);
    });

    test('HackathonImageHelper fallback assets are non-empty and valid', () {
      final fallback = HackathonImageHelper.getLocalAssetFallback(
        'Autonomous Robotics Lab',
        'Hardware and robotics engineering',
      );
      expect(fallback.contains('robotics'), isTrue);
    });

    test('Registration URL normalization and query preservation', () {
      Uri? parseLink(String raw) {
        final trimmed = raw.trim();
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

      // Devpost URL with tracking parameters
      final devpost = parseLink('https://devpost.com/hackathons/agentic-ai?ref=hackpilot&track=ml');
      expect(devpost, isNotNull);
      expect(devpost!.host, 'devpost.com');
      expect(devpost.queryParameters['ref'], 'hackpilot');
      expect(devpost.queryParameters['track'], 'ml');

      // Schemeless URL
      final schemeless = parseLink('unstop.com/hackathons/build-with-ai-2026');
      expect(schemeless, isNotNull);
      expect(schemeless!.scheme, 'https');
      expect(schemeless.host, 'unstop.com');

      // MLH URL
      final mlh = parseLink('https://mlh.io/seasons/2026/events');
      expect(mlh, isNotNull);
      expect(mlh!.host, 'mlh.io');

      // Invalid empty link
      expect(parseLink(''), isNull);
      expect(parseLink('   '), isNull);
    });

    group('Location Mapping & Display Tests', () {
      test('Direct string location mapped for in-person event', () {
        final map = {
          'title': 'Bay Area AI Hack',
          'location': 'San Francisco, CA',
          'mode': 'In-person',
        };
        final h = Hackathon.fromMap('h1', map);
        expect(h.isOnline, isFalse);
        expect(h.isHybrid, isFalse);
        expect(h.isInPerson, isTrue);
        expect(h.displayLocation, 'San Francisco, CA');
      });

      test('Separate city and state mapped correctly', () {
        final map = {
          'title': 'Austin Builder Fest',
          'city': 'Austin',
          'state': 'TX',
          'mode': 'In-person',
        };
        final h = Hackathon.fromMap('h2', map);
        expect(h.displayLocation, 'Austin, TX');
      });

      test('Separate city and country mapped correctly', () {
        final map = {
          'title': 'Bengaluru Cloud Sprint',
          'city': 'Bengaluru',
          'country': 'India',
        };
        final h = Hackathon.fromMap('h3', map);
        expect(h.displayLocation, 'Bengaluru, India');
      });

      test('Nested map in location field parsed correctly', () {
        final map = {
          'title': 'Silicon Valley AI',
          'location': {
            'venue': 'Moscone West',
            'city': 'San Francisco',
            'state': 'CA',
          },
          'mode': 'In-person',
        };
        final h = Hackathon.fromMap('h4', map);
        expect(h.displayLocation, 'Moscone West, San Francisco, CA');
      });

      test('Nested map in venue field parsed correctly', () {
        final map = {
          'title': 'London FinTech Hackathon',
          'venue': {
            'name': 'ExCeL London',
            'city': 'London',
            'country': 'United Kingdom',
          },
          'mode': 'In-person',
        };
        final h = Hackathon.fromMap('h5', map);
        expect(h.displayLocation, 'ExCeL London, London, United Kingdom');
      });

      test('Top-level address key parsed correctly', () {
        final map = {
          'title': 'Toronto Tech Summit',
          'address': '100 University Ave, Toronto',
          'mode': 'In-person',
        };
        final h = Hackathon.fromMap('h6', map);
        expect(h.displayLocation, '100 University Ave, Toronto');
      });

      test('Online events display "Online" regardless of empty location', () {
        final map = {
          'title': 'Global Virtual Hackathon',
          'mode': 'Online',
        };
        final h = Hackathon.fromMap('h7', map);
        expect(h.isOnline, isTrue);
        expect(h.isHybrid, isFalse);
        expect(h.displayLocation, 'Online');
      });

      test('Online boolean flag recognized', () {
        final map = {
          'title': 'Virtual DevSprint',
          'isOnline': true,
        };
        final h = Hackathon.fromMap('h8', map);
        expect(h.isOnline, isTrue);
        expect(h.displayLocation, 'Online');
      });

      test('Hybrid event with physical location displays "Hybrid • [City]"', () {
        final map = {
          'title': 'CyberShield Defense Summit',
          'city': 'Austin, TX',
          'mode': 'Hybrid',
        };
        final h = Hackathon.fromMap('h9', map);
        expect(h.isHybrid, isTrue);
        expect(h.displayLocation, 'Hybrid • Austin, TX');
      });

      test('Hybrid event with pre-formatted location does not duplicate prefix', () {
        final map = {
          'title': 'ClimateTech Hackathon',
          'location': 'Hybrid • Seattle, WA',
          'mode': 'Hybrid',
        };
        final h = Hackathon.fromMap('h10', map);
        expect(h.isHybrid, isTrue);
        expect(h.displayLocation, 'Hybrid • Seattle, WA');
      });

      test('Hybrid event with no physical location displays "Hybrid"', () {
        final map = {
          'title': 'Generic Hybrid Challenge',
          'mode': 'Hybrid',
        };
        final h = Hackathon.fromMap('h11', map);
        expect(h.isHybrid, isTrue);
        expect(h.displayLocation, 'Hybrid');
      });

      test('Missing location for in-person event displays "Location not provided"', () {
        final map = {
          'title': 'Physical Gathering',
          'mode': 'In-person',
        };
        final h = Hackathon.fromMap('h12', map);
        expect(h.displayLocation, 'Location not provided');
      });

      test('Placeholders are suppressed and display "Location not provided"', () {
        final map = {
          'title': 'Old Record Hackathon',
          'location': 'Location not specified',
          'mode': 'In-person',
        };
        final h = Hackathon.fromMap('h13', map);
        expect(h.displayLocation, 'Location not provided');
        expect(h.displayLocation.contains('not specified'), isFalse);
      });

      test('Organizer address is never used as event location', () {
        final map = {
          'title': 'Company Hackathon',
          'organizer': 'Alphabet Inc, 1600 Amphitheatre Pkwy, Mountain View, CA',
          'mode': 'In-person',
        };
        final h = Hackathon.fromMap('h14', map);
        expect(h.displayLocation, 'Location not provided');
        expect(h.organizer, 'Alphabet Inc, 1600 Amphitheatre Pkwy, Mountain View, CA');
      });
    });

    group('Team Model Location Tests', () {
      test('Team parses location field and falls back safely', () {
        final teamWithLoc = Team.fromMap('t1', {
          'teamName': 'CodeCrafters',
          'hackathon': 'Bay Area AI Hack',
          'location': 'San Francisco, CA',
          'leader': 'alice@example.com',
          'requiredSkills': 'Flutter',
          'maxMembers': 4,
          'members': ['alice@example.com'],
        });
        expect(teamWithLoc.location, 'San Francisco, CA');

        final teamWithoutLoc = Team.fromMap('t2', {
          'teamName': 'DevSquad',
          'hackathon': 'Global Virtual Hackathon',
          'leader': 'bob@example.com',
          'requiredSkills': 'Python',
          'maxMembers': 4,
          'members': ['bob@example.com'],
        });
        expect(teamWithoutLoc.location, '');
      });
    });
  });
}
