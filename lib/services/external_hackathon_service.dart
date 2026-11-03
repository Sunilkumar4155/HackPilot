import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/hackathon.dart';

class ExternalHackathonService {
  static const String _baseUrl = 'https://hackalendar.com/api/events';
  static const Duration _cacheDuration = Duration(minutes: 10);

  static List<Hackathon>? _cachedEvents;
  static DateTime? _cachedAt;
  static String? _cachedDate;
  static Future<List<Hackathon>>? _inFlight;

  Future<List<Hackathon>> fetchHackathons({
    bool forceRefresh = false,
  }) async {
    final today = DateTime.now();
    final from =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final cachedAt = _cachedAt;
    final cached = _cachedEvents;

    if (!forceRefresh &&
        _cachedDate == from &&
        cachedAt != null &&
        cached != null &&
        DateTime.now().difference(cachedAt) < _cacheDuration) {
      return List<Hackathon>.unmodifiable(cached);
    }

    final pending = _inFlight;
    if (pending != null) {
      return pending;
    }

    final request = _fetchForDate(from);
    _inFlight = request;

    try {
      final events = await request;
      _cachedEvents = List<Hackathon>.unmodifiable(events);
      _cachedAt = DateTime.now();
      _cachedDate = from;
      return events;
    } catch (error, stackTrace) {
      debugPrint('HACKPILOT external fetch error: $error\n$stackTrace');
      rethrow;
    } finally {
      _inFlight = null;
    }
  }

  Future<List<Hackathon>> _fetchForDate(String from) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {'from': from, 'limit': '100'},
    );

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Hackathon API returned HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected API response format.');
    }

    final rawEvents = decoded['data'];

    if (rawEvents is! List) {
      throw const FormatException(
        'The API response did not contain an events list.',
      );
    }

    final events = <Hackathon>[];

    for (final raw in rawEvents) {
      if (raw is! Map) continue;

      final event = Map<String, dynamic>.from(raw);

      if (event['cancelled'] == true) continue;

      final mapped = _toHackathon(event);

      if (mapped.title.trim().isNotEmpty) {
        events.add(mapped);
      }
    }

    return events;
  }

  Hackathon _toHackathon(Map<String, dynamic> event) {
    final organizerValue = event['organizer'];

    final organizer = organizerValue is Map
        ? (organizerValue['name'] ??
                organizerValue['displayName'] ??
                'Unknown Organizer')
            .toString()
        : (organizerValue ?? 'Unknown Organizer').toString();

    final mode = Hackathon.parseMode(event);
    final location = Hackathon.parseLocation(event, modeHint: mode);

    final deadline = (event['registrationDeadline'] ??
            event['endsAt'] ??
            event['endAt'] ??
            event['startsAt'] ??
            '')
        .toString();

    final registrationLink =
        (event['registrationUrl'] ?? event['url'] ?? '')
            .toString()
            .trim();

    final title =
        (event['name'] ?? event['title'] ?? 'Untitled Hackathon')
            .toString()
            .trim();

    final stableId =
        (event['slug'] ?? event['id'] ?? registrationLink)
            .toString()
            .trim();

    final id = stableId.isNotEmpty
        ? stableId
        : '${_stableKey(title)}-${_stableKey(organizer)}';

    final themes = event['themes'];

    final description = [
      event['description']?.toString(),
      if (themes is List && themes.isNotEmpty)
        'Themes: ${themes.join(', ')}',
    ]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join('\n\n');

    final rawImageUrl = Hackathon.imageUrlFrom(event);
    final imageUrl = _normalizeImageUrl(rawImageUrl);

    return Hackathon(
      id: 'external_$id',
      title: title,
      organizer: organizer,
      deadline: deadline,
      prize: (event['prizePool'] ?? 'Not specified').toString(),
      description: description,
      location: location,
      mode: mode,
      teamSize: 'See event details',
      registrationLink: registrationLink,
      imageUrl: imageUrl,
    );
  }

  String _normalizeImageUrl(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    final uri = Uri.tryParse(trimmed);

    if (uri == null) return '';

    if (uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return uri.toString();
    }

    if (!uri.hasScheme && trimmed.startsWith('/')) {
      return Uri.https('hackalendar.com', trimmed).toString();
    }

    return '';
  }

  String _stableKey(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
