import 'package:cloud_firestore/cloud_firestore.dart';

class Hackathon {
  final String id;
  final String title;
  final String organizer;
  final String deadline;
  final String prize;
  final String description;
  final String location;
  final String mode;
  final String teamSize;
  final String registrationLink;
  final String imageUrl;
  final String city;
  final String state;
  final String country;
  final String? translatedTitle;
  final String? translatedDescription;

  Hackathon({
    required this.id,
    required this.title,
    required this.organizer,
    required this.deadline,
    required this.prize,
    required this.description,
    required this.location,
    required this.mode,
    required this.teamSize,
    required this.registrationLink,
    this.imageUrl = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.translatedTitle,
    this.translatedDescription,
  });

  factory Hackathon.fromMap(String id, Map<String, dynamic> data) {
    String textValue(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      if (value is Map) {
        final nested = value['name'] ??
            value['displayName'] ??
            value['label'] ??
            value['url'] ??
            value['value'];
        if (nested != null) return nested.toString().trim();
      }
      if (value is Timestamp) return value.toDate().toIso8601String();
      return value.toString().trim();
    }

    final rawLocationHint = parseLocation(data);
    final mode = parseMode(data, locationHint: rawLocationHint);
    final location = parseLocation(data, modeHint: mode);
    final components = parseComponents(data, location);

    return Hackathon(
      id: id,
      title: textValue(
        data['title'] ?? data['name'],
        fallback: 'Untitled Hackathon',
      ),
      organizer: textValue(
        data['organizer'] ?? data['host'] ?? data['organization'],
        fallback: 'Unknown Organizer',
      ),
      deadline: textValue(
        data['deadline'] ??
            data['endAt'] ??
            data['endDate'] ??
            data['registrationDeadline'] ??
            data['endsAt'] ??
            data['startsAt'],
      ),
      prize: textValue(
        data['prize'] ?? data['prizePool'] ?? data['prizes'],
        fallback: 'Not specified',
      ),
      description: textValue(data['description'] ?? data['summary']),
      location: location,
      mode: mode,
      teamSize: textValue(
        data['teamSize'] ?? data['team_size'] ?? data['teamSizeRange'],
        fallback: 'Not specified',
      ),
      registrationLink: textValue(
        data['registrationLink'] ??
            data['registrationUrl'] ??
            data['url'] ??
            data['website'],
      ),
      imageUrl: imageUrlFrom(data),
      city: components.city,
      state: components.state,
      country: components.country,
      translatedTitle: data['translatedTitle']?.toString(),
      translatedDescription: data['translatedDescription']?.toString(),
    );
  }

  /// Returns a copy of this Hackathon with optional updated fields.
  Hackathon copyWith({
    String? id,
    String? title,
    String? organizer,
    String? deadline,
    String? prize,
    String? description,
    String? location,
    String? mode,
    String? teamSize,
    String? registrationLink,
    String? imageUrl,
    String? city,
    String? state,
    String? country,
    String? translatedTitle,
    String? translatedDescription,
  }) {
    return Hackathon(
      id: id ?? this.id,
      title: title ?? this.title,
      organizer: organizer ?? this.organizer,
      deadline: deadline ?? this.deadline,
      prize: prize ?? this.prize,
      description: description ?? this.description,
      location: location ?? this.location,
      mode: mode ?? this.mode,
      teamSize: teamSize ?? this.teamSize,
      registrationLink: registrationLink ?? this.registrationLink,
      imageUrl: imageUrl ?? this.imageUrl,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      translatedTitle: translatedTitle ?? this.translatedTitle,
      translatedDescription: translatedDescription ?? this.translatedDescription,
    );
  }

  /// English title to display (translated if non-English, else original).
  String get displayTitle => (translatedTitle != null && translatedTitle!.trim().isNotEmpty)
      ? translatedTitle!.trim()
      : title;

  /// English description to display (translated if non-English, else original).
  String get displayDescription => (translatedDescription != null && translatedDescription!.trim().isNotEmpty)
      ? translatedDescription!.trim()
      : description;

  /// True if the event is held online or virtually.
  bool get isOnline {
    final m = mode.trim().toLowerCase();
    final loc = location.trim().toLowerCase();
    if (isHybrid) return false;
    return m.contains('online') ||
        m.contains('virtual') ||
        m.contains('remote') ||
        loc == 'online' ||
        loc == 'virtual' ||
        loc == 'remote' ||
        loc.startsWith('online');
  }

  /// True if the event format is hybrid.
  bool get isHybrid {
    final m = mode.trim().toLowerCase();
    final loc = location.trim().toLowerCase();
    return m.contains('hybrid') || loc.startsWith('hybrid');
  }

  /// True if the event is held in person at a physical location.
  bool get isInPerson => !isOnline && !isHybrid;

  /// Returns true if this hackathon has a genuine physical or specific location.
  bool get hasPhysicalLocation {
    final loc = location.trim();
    if (loc.isEmpty) return false;
    final lower = loc.toLowerCase();
    if (isPlaceholder(lower)) return false;
    if (lower == 'online' || lower == 'virtual' || lower == 'remote') return false;
    if (lower == 'hybrid') return false;
    return true;
  }

  /// Formatted location string suitable for cards, headers, and detail screens.
  /// - Online events -> "Online"
  /// - Hybrid events -> "Hybrid" or "Hybrid • [City/Venue]"
  /// - In-person events -> "[City, State, Country]" or "Location not provided"
  /// - Genuinely missing -> "Location not provided"
  String get displayLocation {
    if (isOnline) {
      return 'Online';
    }
    if (isHybrid) {
      final physical = _cleanPhysicalPart(location);
      if (physical.isNotEmpty && !isPlaceholder(physical)) {
        return physical.toLowerCase().startsWith('hybrid')
            ? physical
            : 'Hybrid • $physical';
      }
      return 'Hybrid';
    }
    final cleaned = _cleanPhysicalPart(location);
    if (cleaned.isNotEmpty && !isPlaceholder(cleaned)) {
      return cleaned;
    }
    return 'Location not provided';
  }

  /// True if this hackathon is conducted in India (physical or hybrid).
  bool get isIndia {
    final c = country.trim().toLowerCase();
    if (c == 'india' || c == 'in' || c == 'ind') return true;
    if (isIndianState(state)) return true;
    if (isIndianCity(city)) return true;
    final loc = location.trim().toLowerCase();
    if (loc.contains('india')) return true;
    for (final s in indianStates) {
      if (loc.contains(s)) return true;
    }
    for (final ci in indianCities) {
      if (loc.contains(ci)) return true;
    }
    return false;
  }

  /// True if this hackathon is an in-person or hybrid event held outside India.
  bool get isInternational => !isIndia && !isOnline && hasPhysicalLocation;

  /// True if the registration deadline has already passed.
  bool get isExpired {
    final date = DateTime.tryParse(deadline.trim());
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  /// True if the hackathon is open or upcoming.
  bool get isUpcoming => !isExpired;

  static String _cleanPhysicalPart(String raw) {
    var s = raw.trim();
    final hybridRegex = RegExp(r'^hybrid\s*([•\-\|:,]\s*)?', caseSensitive: false);
    if (hybridRegex.hasMatch(s)) {
      s = s.replaceFirst(hybridRegex, '').trim();
    }
    return s;
  }

  /// Checks if a string contains generic placeholder text.
  static bool isPlaceholder(String? text) {
    if (text == null) return true;
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    const placeholders = {
      'not specified',
      'location not specified',
      'not provided',
      'location not provided',
      'not available',
      'location not available',
      'unknown',
      'unknown location',
      'n/a',
      'na',
      'none',
      'null',
      'tbd',
      'tba',
      'see event details',
      'see details',
      'flexible',
      'undefined',
      'somewhere',
      'anywhere',
      'unspecified',
    };
    return placeholders.contains(trimmed);
  }

  /// Extracts the event format/mode (Online, In-person, Hybrid).
  static String parseMode(Map<String, dynamic> data, {String? locationHint}) {
    final isOnlineFlag = data['isOnline'] == true ||
        data['is_online'] == true ||
        data['online'] == true ||
        data['isVirtual'] == true ||
        data['virtual'] == true;

    final isHybridFlag = data['isHybrid'] == true ||
        data['is_hybrid'] == true ||
        data['hybrid'] == true;

    if (isHybridFlag) return 'Hybrid';
    if (isOnlineFlag) return 'Online';

    final rawMode = (data['mode'] ??
            data['format'] ??
            data['eventType'] ??
            data['event_type'] ??
            data['eventMode'] ??
            data['event_mode'] ??
            '')
        .toString()
        .trim();

    if (rawMode.isNotEmpty && !isPlaceholder(rawMode)) {
      final lower = rawMode.toLowerCase();
      if (lower.contains('hybrid')) return 'Hybrid';
      if (lower.contains('online') ||
          lower.contains('virtual') ||
          lower.contains('remote')) {
        return 'Online';
      }
      if (lower.contains('in_person') ||
          lower.contains('in-person') ||
          lower.contains('in person') ||
          lower.contains('offline') ||
          lower.contains('physical') ||
          lower.contains('onsite') ||
          lower.contains('on-site')) {
        return 'In-person';
      }
      return rawMode;
    }

    final loc = (locationHint ?? '').trim();
    if (loc.isNotEmpty && !isPlaceholder(loc)) {
      final lowerLoc = loc.toLowerCase();
      if (lowerLoc.contains('hybrid')) return 'Hybrid';
      if (lowerLoc == 'online' ||
          lowerLoc == 'virtual' ||
          lowerLoc == 'remote' ||
          lowerLoc.startsWith('online')) {
        return 'Online';
      }
      return 'In-person';
    }

    final hasPhysicalKeys = (data['city'] != null && !isPlaceholder(data['city'].toString())) ||
        (data['venue'] != null && !isPlaceholder(data['venue'].toString())) ||
        (data['address'] != null && !isPlaceholder(data['address'].toString()));
    if (hasPhysicalKeys) {
      return 'In-person';
    }

    return 'Online';
  }

  /// Extracts the actual city, venue, or online status.
  static String parseLocation(Map<String, dynamic> data, {String? modeHint}) {
    dynamic rawValue = data['location'] ??
        data['venue'] ??
        data['address'] ??
        data['place'] ??
        data['eventLocation'] ??
        data['locationName'] ??
        data['location_name'] ??
        data['venue_name'] ??
        data['cityLocation'];

    String extracted = '';

    if (rawValue is Map) {
      extracted = _formatLocationFromMap(rawValue);
    } else if (rawValue is List) {
      extracted = rawValue
          .where((item) => item != null && !isPlaceholder(item.toString()))
          .map((item) => item.toString().trim())
          .join(', ');
    } else if (rawValue != null) {
      extracted = rawValue.toString().trim();
    }

    final city = (data['city'] ?? data['town'])?.toString().trim() ?? '';
    final state = (data['state'] ?? data['province'] ?? data['region'])?.toString().trim() ?? '';
    final country = data['country']?.toString().trim() ?? '';

    final combinedParts = [city, state, country]
        .where((p) => p.isNotEmpty && !isPlaceholder(p))
        .toList();

    if (combinedParts.isNotEmpty) {
      final combined = combinedParts.join(', ');
      if (extracted.isEmpty || isPlaceholder(extracted) || extracted == city) {
        extracted = combined;
      }
    }

    if (isPlaceholder(extracted)) {
      extracted = '';
    }

    final mode = (modeHint ?? parseMode(data, locationHint: extracted)).toLowerCase();

    if (mode.contains('online') || mode.contains('virtual') || mode.contains('remote')) {
      return 'Online';
    }

    if (mode.contains('hybrid')) {
      if (extracted.isNotEmpty && !extracted.toLowerCase().contains('online')) {
        return extracted;
      }
      return 'Hybrid';
    }

    if (extracted.isNotEmpty) {
      return extracted;
    }

    return 'Location not provided';
  }

  static String _formatLocationFromMap(Map map) {
    final direct = map['formatted'] ??
        map['displayName'] ??
        map['formatted_address'] ??
        map['full'] ??
        map['name'] ??
        map['locationName'];

    final venue = (map['venue'] ?? map['venue_name'] ?? map['name'])?.toString().trim() ?? '';
    final address = (map['address'] ?? map['street'] ?? map['formattedAddress'])?.toString().trim() ?? '';
    final city = (map['city'] ?? map['town'])?.toString().trim() ?? '';
    final state = (map['state'] ?? map['province'] ?? map['region'])?.toString().trim() ?? '';
    final country = map['country']?.toString().trim() ?? '';

    final parts = <String>[];
    if (venue.isNotEmpty && !isPlaceholder(venue)) parts.add(venue);
    if (address.isNotEmpty && !isPlaceholder(address) && address != venue) parts.add(address);
    if (city.isNotEmpty && !isPlaceholder(city) && city != venue) parts.add(city);
    if (state.isNotEmpty && !isPlaceholder(state) && state != city) parts.add(state);
    if (country.isNotEmpty && !isPlaceholder(country) && country != city && country != state) parts.add(country);

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    if (direct != null && !isPlaceholder(direct.toString())) {
      return direct.toString().trim();
    }

    for (final val in map.values) {
      if (val is String && val.trim().isNotEmpty && !isPlaceholder(val)) {
        return val.trim();
      }
    }

    return '';
  }

  /// Parses individual location components (city, state, country).
  static ({String city, String state, String country}) parseComponents(
    Map<String, dynamic> data,
    String locationString,
  ) {
    String city = (data['city'] ?? data['town'])?.toString().trim() ?? '';
    String state = (data['state'] ?? data['province'] ?? data['region'])?.toString().trim() ?? '';
    String country = data['country']?.toString().trim() ?? '';

    final locObj = data['location'] is Map
        ? data['location'] as Map
        : (data['venue'] is Map ? data['venue'] as Map : null);

    if (locObj != null) {
      if (city.isEmpty) city = (locObj['city'] ?? locObj['town'])?.toString().trim() ?? '';
      if (state.isEmpty) state = (locObj['state'] ?? locObj['province'] ?? locObj['region'])?.toString().trim() ?? '';
      if (country.isEmpty) country = locObj['country']?.toString().trim() ?? '';
    }

    if (isPlaceholder(city)) city = '';
    if (isPlaceholder(state)) state = '';
    if (isPlaceholder(country)) country = '';

    // If components are empty, attempt deduction from formatted location string
    if ((city.isEmpty || state.isEmpty || country.isEmpty) &&
        locationString.isNotEmpty &&
        !isPlaceholder(locationString)) {
      final cleanText = _cleanPhysicalPart(locationString);
      final segments = cleanText.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      if (segments.length == 3) {
        if (city.isEmpty) city = segments[0];
        if (state.isEmpty) state = segments[1];
        if (country.isEmpty) country = segments[2];
      } else if (segments.length == 2) {
        if (city.isEmpty) city = segments[0];
        final second = segments[1];
        if (second.toLowerCase() == 'india' || second.toLowerCase() == 'usa' || second.toLowerCase() == 'uk') {
          if (country.isEmpty) country = second;
        } else {
          if (state.isEmpty) state = second;
        }
      } else if (segments.length == 1) {
        final single = segments[0];
        if (isIndianCity(single)) {
          if (city.isEmpty) city = single;
          if (country.isEmpty) country = 'India';
        } else if (isIndianState(single)) {
          if (state.isEmpty) state = single;
          if (country.isEmpty) country = 'India';
        }
      }
    }

    // Auto-fill India if recognized Indian city or state is present
    if (country.isEmpty && (isIndianCity(city) || isIndianState(state))) {
      country = 'India';
    }

    return (city: city, state: state, country: country);
  }

  static const Set<String> indianStates = {
    'andhra pradesh',
    'arunachal pradesh',
    'assam',
    'bihar',
    'chhattisgarh',
    'goa',
    'gujarat',
    'haryana',
    'himachal pradesh',
    'jharkhand',
    'karnataka',
    'kerala',
    'madhya pradesh',
    'maharashtra',
    'manipur',
    'meghalaya',
    'mizoram',
    'nagaland',
    'odisha',
    'punjab',
    'rajasthan',
    'sikkim',
    'tamil nadu',
    'telangana',
    'tripura',
    'uttar pradesh',
    'uttarakhand',
    'west bengal',
    'delhi',
    'delhi ncr',
    'new delhi',
    'chandigarh',
    'puducherry',
    'jammu and kashmir',
    'jammu & kashmir',
    'ladakh',
    'andaman and nicobar',
    'daman and diu',
    'lakshadweep',
  };

  static const Set<String> indianCities = {
    'bengaluru',
    'bangalore',
    'mumbai',
    'delhi',
    'new delhi',
    'hyderabad',
    'pune',
    'chennai',
    'kolkata',
    'noida',
    'greater noida',
    'gurugram',
    'gurgaon',
    'ahmedabad',
    'jaipur',
    'kochi',
    'cochin',
    'thiruvananthapuram',
    'trivandrum',
    'indore',
    'bhopal',
    'chandigarh',
    'surat',
    'lucknow',
    'kanpur',
    'nagpur',
    'patna',
    'vadodara',
    'ghaziabad',
    'ludhiana',
    'agra',
    'nashik',
    'varanasi',
    'ranchi',
    'coimbatore',
    'visakhapatnam',
    'mysuru',
    'mysore',
    'hubballi',
    'hubli',
    'mangalore',
    'mangaluru',
    'dehradun',
    'bhubaneswar',
    'guwahati',
    'amritsar',
    'jodhpur',
    'udaipur',
    'raipur',
    'gwalior',
    'vijayawada',
    'madurai',
    'tiruchirappalli',
    'salem',
    'warangal',
    'guntur',
    'kozhikode',
    'calicut',
    'faridabad',
  };

  static bool isIndianState(String name) {
    if (name.isEmpty) return false;
    return indianStates.contains(name.trim().toLowerCase());
  }

  static bool isIndianCity(String name) {
    if (name.isEmpty) return false;
    return indianCities.contains(name.trim().toLowerCase());
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'organizer': organizer,
        'deadline': deadline,
        'prize': prize,
        'description': description,
        'location': location,
        'mode': mode,
        'teamSize': teamSize,
        'registrationLink': registrationLink,
        'imageUrl': imageUrl,
        'city': city,
        'state': state,
        'country': country,
        if (translatedTitle != null) 'translatedTitle': translatedTitle,
        if (translatedDescription != null) 'translatedDescription': translatedDescription,
      };

  /// Extracts common API, Open Graph, CDN, and Firestore image fields.
  static String imageUrlFrom(Map<String, dynamic> data) {
    const fields = [
      'imageUrl',
      'image_url',
      'bannerImage',
      'banner_image',
      'coverImage',
      'cover_image',
      'cover',
      'coverUrl',
      'cover_url',
      'thumbnail',
      'thumbnailUrl',
      'thumbnail_url',
      'eventLogo',
      'event_logo',
      'logo',
      'poster',
      'banner',
      'socialImage',
      'social_image',
      'og:image',
      'ogImage',
      'og',
      'images',
      'image',
    ];

    for (final field in fields) {
      final result = _imageUrlValue(data[field]);
      if (result.isNotEmpty) return result;
    }
    return '';
  }

  static String _imageUrlValue(dynamic value) {
    if (value is String) return value.trim();

    if (value is List) {
      for (final item in value) {
        final result = _imageUrlValue(item);
        if (result.isNotEmpty) return result;
      }
    }

    if (value is Map) {
      const nestedKeys = [
        'url',
        'src',
        'href',
        'image_url',
        'imageUrl',
        'downloadURL',
        'contentUrl',
        'original',
        'large',
        'medium',
        'thumbnail',
        'image',
        'og:image',
      ];
      for (final key in nestedKeys) {
        final result = _imageUrlValue(value[key]);
        if (result.isNotEmpty) return result;
      }
    }

    return '';
  }
}
