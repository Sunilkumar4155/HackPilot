import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of a translation operation containing the translated text,
/// whether it was actually translated, the detected source language,
/// and any error status.
class TranslationResult {
  final String originalText;
  final String translatedText;
  final bool wasTranslated;
  final String detectedLanguage;
  final bool isError;
  final String? errorMessage;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.wasTranslated,
    required this.detectedLanguage,
    this.isError = false,
    this.errorMessage,
  });

  /// The text to display to the user (translated if available, else original).
  String get displayText => translatedText.isNotEmpty ? translatedText : originalText;
}

/// Service providing automatic language detection and translation into English
/// with in-memory caching and zero required API credentials.
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  /// In-memory cache for translations: key = rawText, value = TranslationResult
  final Map<String, TranslationResult> _cache = {};

  /// Fast language detection: checks whether the text is already predominantly English.
  /// Detects Indic scripts (Devanagari/Hindi, Tamil, Telugu, Bengali, Kannada, Gujarati, etc.),
  /// Cyrillic, East Asian (Chinese, Japanese, Korean), Arabic, and common non-English Latin text.
  bool isLikelyEnglish(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;

    // Check for non-Latin script characters
    int nonLatinCount = 0;
    int letterCount = 0;

    for (final rune in trimmed.runes) {
      // Devanagari (Hindi, Marathi, Sanskrit)
      final isDevanagari = rune >= 0x0900 && rune <= 0x097F;
      // Bengali
      final isBengali = rune >= 0x0980 && rune <= 0x09FF;
      // Gurmukhi (Punjabi)
      final isGurmukhi = rune >= 0x0A00 && rune <= 0x0A7F;
      // Gujarati
      final isGujarati = rune >= 0x0A80 && rune <= 0x0AFF;
      // Oriya
      final isOriya = rune >= 0x0B00 && rune <= 0x0B7F;
      // Tamil
      final isTamil = rune >= 0x0B80 && rune <= 0x0BFF;
      // Telugu
      final isTelugu = rune >= 0x0C00 && rune <= 0x0C7F;
      // Kannada
      final isKannada = rune >= 0x0C80 && rune <= 0x0CFF;
      // Malayalam
      final isMalayalam = rune >= 0x0D00 && rune <= 0x0D7F;
      // Arabic / Persian / Urdu
      final isArabic = rune >= 0x0600 && rune <= 0x06FF;
      // Cyrillic (Russian, Ukrainian, etc.)
      final isCyrillic = rune >= 0x0400 && rune <= 0x04FF;
      // CJK (Chinese, Japanese, Korean)
      final isCJK = (rune >= 0x4E00 && rune <= 0x9FFF) ||
          (rune >= 0x3040 && rune <= 0x30FF) ||
          (rune >= 0xAC00 && rune <= 0xD7AF);

      if (isDevanagari ||
          isBengali ||
          isGurmukhi ||
          isGujarati ||
          isOriya ||
          isTamil ||
          isTelugu ||
          isKannada ||
          isMalayalam ||
          isArabic ||
          isCyrillic ||
          isCJK) {
        nonLatinCount++;
      }

      // Is alphabetic letter
      if ((rune >= 65 && rune <= 90) || (rune >= 97 && rune <= 122) || rune > 127) {
        letterCount++;
      }
    }

    // If any significant non-Latin script is present, it's not English
    if (nonLatinCount > 0 && (letterCount == 0 || nonLatinCount / letterCount > 0.05)) {
      return false;
    }

    // Check for distinctive non-English Latin words or diacritics
    final lower = trimmed.toLowerCase();

    // Check accented characters common in Spanish, French, German, Portuguese
    const nonEnglishAccents = ['ñ', '¿', '¡', 'ß', 'ä', 'ö', 'ü', 'é', 'à', 'è', 'ù', 'ç', 'ê', 'î', 'ô', 'ã', 'õ'];
    int accentCount = 0;
    for (final accent in nonEnglishAccents) {
      if (lower.contains(accent)) accentCount++;
    }

    if (accentCount >= 2) {
      return false;
    }

    // Check strong non-English vocabulary keywords
    final nonEnglishKeywords = [
      // Spanish
      'concurso', 'descripción', 'inscripción', 'desarrollo', 'premios', 'participar', 'requisitos',
      // French
      'défi', 'inscription', 'règles', 'développeurs', 'concours',
      // German
      'herausforderung', 'anmeldung', 'teilnehmen', 'entwickler', 'preisgeld',
      // Portuguese
      'desafio', 'inscrição', 'premiação', 'regulamento',
    ];

    final words = lower.split(RegExp(r'\s+'));
    for (final kw in nonEnglishKeywords) {
      if (words.contains(kw) || lower.contains(kw)) {
        return false;
      }
    }

    return true;
  }

  /// Detects language name/label for UI presentation.
  String detectLanguageLabel(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x0900 && rune <= 0x097F) return 'हिन्दी (Hindi)';
      if (rune >= 0x0980 && rune <= 0x09FF) return 'বাংলা (Bengali)';
      if (rune >= 0x0B80 && rune <= 0x0BFF) return 'தமிழ் (Tamil)';
      if (rune >= 0x0C00 && rune <= 0x0C7F) return 'తెలుగు (Telugu)';
      if (rune >= 0x0C80 && rune <= 0x0CFF) return 'ಕನ್ನಡ (Kannada)';
      if (rune >= 0x0D00 && rune <= 0x0D7F) return 'മലയാളം (Malayalam)';
      if (rune >= 0x0A80 && rune <= 0x0AFF) return 'ગુજરાતી (Gujarati)';
      if (rune >= 0x0400 && rune <= 0x04FF) return 'Русский (Russian)';
      if (rune >= 0x4E00 && rune <= 0x9FFF) return '中文 (Chinese)';
      if (rune >= 0x3040 && rune <= 0x30FF) return '日本語 (Japanese)';
      if (rune >= 0xAC00 && rune <= 0xD7AF) return '한국어 (Korean)';
      if (rune >= 0x0600 && rune <= 0x06FF) return 'العربية (Arabic)';
    }

    final lower = text.toLowerCase();
    if (lower.contains('concurso') || lower.contains('descripción') || lower.contains('inscripción')) {
      return 'Español (Spanish)';
    }
    if (lower.contains('défi') || lower.contains('inscription') || lower.contains('concours')) {
      return 'Français (French)';
    }
    if (lower.contains('herausforderung') || lower.contains('anmeldung')) {
      return 'Deutsch (German)';
    }

    return 'Non-English';
  }

  /// Translates [text] to English if needed.
  /// If [text] is already English, returns immediately without network calls.
  /// If translation fails, returns [TranslationResult] with original text and `isError = true`.
  Future<TranslationResult> translateToEnglish(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return TranslationResult(
        originalText: text,
        translatedText: text,
        wasTranslated: false,
        detectedLanguage: 'English',
      );
    }

    // Fast path: already English
    if (isLikelyEnglish(trimmed)) {
      final res = TranslationResult(
        originalText: text,
        translatedText: text,
        wasTranslated: false,
        detectedLanguage: 'English',
      );
      _cache[trimmed] = res;
      return res;
    }

    // Check cache
    if (_cache.containsKey(trimmed)) {
      return _cache[trimmed]!;
    }

    final detectedLabel = detectLanguageLabel(trimmed);

    try {
      final translated = await _callGoogleTranslateApi(trimmed);
      if (translated.isNotEmpty) {
        final result = TranslationResult(
          originalText: text,
          translatedText: translated,
          wasTranslated: true,
          detectedLanguage: detectedLabel,
        );
        _cache[trimmed] = result;
        return result;
      }
    } catch (e) {
      debugPrint('TranslationService primary provider error: $e');
    }

    // Secondary fallback: MyMemory Translation API
    try {
      final fallbackTranslated = await _callMyMemoryApi(trimmed);
      if (fallbackTranslated.isNotEmpty) {
        final result = TranslationResult(
          originalText: text,
          translatedText: fallbackTranslated,
          wasTranslated: true,
          detectedLanguage: detectedLabel,
        );
        _cache[trimmed] = result;
        return result;
      }
    } catch (e) {
      debugPrint('TranslationService secondary provider error: $e');
    }

    // If both failed, return original with error flag
    final fallbackResult = TranslationResult(
      originalText: text,
      translatedText: text,
      wasTranslated: false,
      detectedLanguage: detectedLabel,
      isError: true,
      errorMessage: 'Translation service unavailable',
    );
    _cache[trimmed] = fallbackResult;
    return fallbackResult;
  }

  /// Primary translation provider: Google Translate public endpoint (free, no key required).
  Future<String> _callGoogleTranslateApi(String text) async {
    // If text is very long (e.g. description > 2000 chars), split by paragraphs to preserve formatting
    if (text.length > 1500) {
      final paragraphs = text.split('\n\n');
      final translatedParagraphs = <String>[];
      for (final p in paragraphs) {
        if (p.trim().isEmpty) {
          translatedParagraphs.add(p);
          continue;
        }
        if (isLikelyEnglish(p)) {
          translatedParagraphs.add(p);
        } else {
          final translated = await _translateChunkGoogle(p);
          translatedParagraphs.add(translated.isNotEmpty ? translated : p);
        }
      }
      return translatedParagraphs.join('\n\n');
    }

    return _translateChunkGoogle(text);
  }

  Future<String> _translateChunkGoogle(String chunk) async {
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=en&dt=t&q=${Uri.encodeComponent(chunk)}',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
      final segments = decoded[0] as List;
      final buffer = StringBuffer();
      for (final segment in segments) {
        if (segment is List && segment.isNotEmpty && segment[0] != null) {
          buffer.write(segment[0].toString());
        }
      }
      return buffer.toString().trim();
    }
    return '';
  }

  /// Secondary translation provider: MyMemory public endpoint
  Future<String> _callMyMemoryApi(String text) async {
    final truncated = text.length > 500 ? text.substring(0, 500) : text;
    final uri = Uri.parse(
      'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(truncated)}&langpair=autodetect|en',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['responseData'] is Map) {
        final translated = decoded['responseData']['translatedText']?.toString();
        if (translated != null && translated.isNotEmpty) {
          return translated.trim();
        }
      }
    }
    return '';
  }

  /// Clear the cache (e.g. for testing)
  void clearCache() {
    _cache.clear();
  }
}

