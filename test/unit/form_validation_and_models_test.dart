import 'package:flutter_test/flutter_test.dart';
import 'package:ai_hackathon_finder/models/hackathon.dart';
import 'package:ai_hackathon_finder/models/team.dart';

void main() {
  group('Unit & Model Tests: Hackathon Model', () {
    test('Hackathon model serialization toMap and deserialization fromMap round-trip', () {
      final original = Hackathon(
        id: 'hack_99',
        title: 'Bharat AI Innovation Summit',
        organizer: 'MeitY India',
        deadline: '2026-12-15',
        prize: '₹20,00,000 Cash Pool',
        description: 'National developer challenge for building sovereign AI models.',
        location: 'Bengaluru, Karnataka, India',
        mode: 'In-person',
        teamSize: '2-4 Members',
        registrationLink: 'https://hackpilot.dev/register',
        imageUrl: 'https://images.unsplash.com/photo-ai',
        city: 'Bengaluru',
        state: 'Karnataka',
        country: 'India',
        translatedTitle: 'Bharat AI Innovation Summit (EN)',
        translatedDescription: 'National developer challenge for building sovereign AI models (EN).',
      );

      final map = original.toMap();
      final reconstructed = Hackathon.fromMap('hack_99', map);

      expect(reconstructed.id, original.id);
      expect(reconstructed.title, original.title);
      expect(reconstructed.organizer, original.organizer);
      expect(reconstructed.deadline, original.deadline);
      expect(reconstructed.prize, original.prize);
      expect(reconstructed.city, 'Bengaluru');
      expect(reconstructed.state, 'Karnataka');
      expect(reconstructed.country, 'India');
      expect(reconstructed.isIndia, isTrue);
      expect(reconstructed.displayLocation, 'Bengaluru, Karnataka, India');
      expect(reconstructed.displayTitle, 'Bharat AI Innovation Summit (EN)');
      expect(reconstructed.displayDescription, 'National developer challenge for building sovereign AI models (EN).');
    });

    test('Hackathon copyWith modifies specified attributes while preserving rest', () {
      final initial = Hackathon(
        id: 'event_01',
        title: 'Original Title',
        organizer: 'Org A',
        deadline: '2026-11-20',
        prize: '\$10,000',
        description: 'Description A',
        location: 'San Francisco, CA',
        mode: 'In-person',
        teamSize: '1-3',
        registrationLink: 'https://test.dev',
      );

      final updated = initial.copyWith(
        title: 'Updated Title',
        prize: '\$25,000',
        mode: 'Hybrid',
      );

      expect(updated.id, 'event_01');
      expect(updated.title, 'Updated Title');
      expect(updated.prize, '\$25,000');
      expect(updated.mode, 'Hybrid');
      expect(updated.organizer, 'Org A');
      expect(updated.location, 'San Francisco, CA');
    });

    test('Hackathon date status: isExpired and isUpcoming evaluate correctly against current time', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2)).toIso8601String().substring(0, 10);
      final futureDate = DateTime.now().add(const Duration(days: 14)).toIso8601String().substring(0, 10);

      final pastEvent = Hackathon(
        id: 'past',
        title: 'Past Event',
        organizer: 'Org',
        deadline: pastDate,
        prize: '',
        description: '',
        location: 'Online',
        mode: 'Online',
        teamSize: '',
        registrationLink: '',
      );

      final futureEvent = Hackathon(
        id: 'future',
        title: 'Future Event',
        organizer: 'Org',
        deadline: futureDate,
        prize: '',
        description: '',
        location: 'Online',
        mode: 'Online',
        teamSize: '',
        registrationLink: '',
      );

      expect(pastEvent.isExpired, isTrue);
      expect(pastEvent.isUpcoming, isFalse);

      expect(futureEvent.isExpired, isFalse);
      expect(futureEvent.isUpcoming, isTrue);
    });
  });

  group('Unit & Model Tests: Team Model', () {
    test('Team fromMap parses all attributes with safe fallbacks', () {
      final map = {
        'teamName': 'Neural Coders',
        'hackathon': 'Global AI Hackathon',
        'leader': 'lead@example.com',
        'requiredSkills': 'Flutter, PyTorch, LangChain',
        'maxMembers': 4,
        'members': ['lead@example.com', 'dev2@example.com'],
        'location': 'Bengaluru, India',
      };

      final team = Team.fromMap('team_01', map);

      expect(team.id, 'team_01');
      expect(team.teamName, 'Neural Coders');
      expect(team.hackathon, 'Global AI Hackathon');
      expect(team.leader, 'lead@example.com');
      expect(team.requiredSkills, 'Flutter, PyTorch, LangChain');
      expect(team.maxMembers, 4);
      expect(team.members.length, 2);
      expect(team.location, 'Bengaluru, India');
    });

    test('Team serialization toMap preserves structure', () {
      final team = Team(
        id: 'team_02',
        teamName: 'CyberDefenders',
        hackathon: 'CyberShield Summit',
        leader: 'alex@example.com',
        requiredSkills: 'Cryptography, Rust',
        maxMembers: 3,
        members: ['alex@example.com'],
        location: 'Hybrid',
      );

      final map = team.toMap();
      expect(map['teamName'], 'CyberDefenders');
      expect(map['hackathon'], 'CyberShield Summit');
      expect(map['leader'], 'alex@example.com');
      expect(map['maxMembers'], 3);
      expect(map['members'], ['alex@example.com']);
      expect(map['location'], 'Hybrid');
    });
  });

  group('Form Validation Logic Tests', () {
    test('Email validator accepts valid emails and rejects malformed inputs', () {
      bool isValidEmail(String input) {
        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
        return emailRegex.hasMatch(input.trim());
      }

      expect(isValidEmail('developer@hackpilot.dev'), isTrue);
      expect(isValidEmail('sunil.kumar@college.edu.in'), isTrue);
      expect(isValidEmail('test+alias@domain.org'), isTrue);

      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('invalid-email'), isFalse);
      expect(isValidEmail('missing@domain'), isFalse);
      expect(isValidEmail('@nodomain.com'), isFalse);
      expect(isValidEmail('spaces in@email.com'), isFalse);
    });

    test('Password validator enforces minimum length of 6 characters', () {
      String? validatePassword(String? value) {
        if (value == null || value.trim().isEmpty) return 'Password cannot be empty';
        if (value.trim().length < 6) return 'Password must be at least 6 characters';
        return null;
      }

      expect(validatePassword(null), 'Password cannot be empty');
      expect(validatePassword(''), 'Password cannot be empty');
      expect(validatePassword('12345'), 'Password must be at least 6 characters');
      expect(validatePassword('123456'), isNull);
      expect(validatePassword('StrongP@ssw0rd!'), isNull);
    });

    test('Create Team validator checks all required team constraints', () {
      String? validateTeamCreation({
        required String teamName,
        required String hackathon,
        required String skills,
        required int maxMembers,
      }) {
        if (teamName.trim().isEmpty) return 'Team name is required';
        if (hackathon.trim().isEmpty) return 'Target hackathon is required';
        if (skills.trim().isEmpty) return 'Required skills are needed';
        if (maxMembers < 2 || maxMembers > 10) return 'Team capacity must be between 2 and 10';
        return null;
      }

      expect(validateTeamCreation(teamName: '', hackathon: 'H', skills: 'S', maxMembers: 4), 'Team name is required');
      expect(validateTeamCreation(teamName: 'Alpha', hackathon: '', skills: 'S', maxMembers: 4), 'Target hackathon is required');
      expect(validateTeamCreation(teamName: 'Alpha', hackathon: 'H', skills: '', maxMembers: 4), 'Required skills are needed');
      expect(validateTeamCreation(teamName: 'Alpha', hackathon: 'H', skills: 'S', maxMembers: 1), 'Team capacity must be between 2 and 10');
      expect(validateTeamCreation(teamName: 'Alpha', hackathon: 'H', skills: 'S', maxMembers: 12), 'Team capacity must be between 2 and 10');
      expect(validateTeamCreation(teamName: 'Alpha', hackathon: 'H', skills: 'Flutter, Python', maxMembers: 4), isNull);
    });
  });
}
