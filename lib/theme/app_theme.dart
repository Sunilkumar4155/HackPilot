import 'package:flutter/material.dart';

@immutable
class HubPalette {
  const HubPalette({
    required this.id,
    required this.name,
    required this.background,
    required this.accent,
    required this.ink,
    this.secondary,
    this.tertiary,
    this.violet,
  });

  final String id;
  final String name;
  final Color background;
  final Color accent;
  final Color ink;
  final Color? secondary;
  final Color? tertiary;
  final Color? violet;

  static const electricCobalt = HubPalette(
    id: 'electric_cobalt',
    name: 'Electric Cobalt',
    background: Color(0xFFF5F7FC),
    accent: Color(0xFF2563EB),
    ink: Color(0xFF173A70),
    secondary: Color(0xFFFF9B54),
    tertiary: Color(0xFF0D9488),
    violet: Color(0xFF7C3AED),
  );
  static const hackathonNight = HubPalette(
    id: 'hackathon_night',
    name: 'Hackathon Night',
    background: Color(0xFF07090D),
    accent: Color(0xFFFF6818),
    ink: Color(0xFFF5F7FA),
    secondary: Color(0xFF00D9E8),
    tertiary: Color(0xFF00D6A0),
    violet: Color(0xFFFF4655),
  );
  static const sageCream = HubPalette(
    id: 'sage_cream', name: 'Sage & Cream',
    background: Color(0xFFF5F3EA), accent: Color(0xFF879780), ink: Color(0xFF3F5144),
  );
  static const champagneLuxe = HubPalette(
    id: 'champagne_luxe', name: 'Champagne Luxe',
    background: Color(0xFFFAF6EF), accent: Color(0xFFC6A875), ink: Color(0xFF453A32),
  );
  static const darkAcademia = HubPalette(
    id: 'dark_academia', name: 'Dark Academia',
    background: Color(0xFF29231F), accent: Color(0xFF754739), ink: Color(0xFFE9DDC9),
  );
  static const scandinavian = HubPalette(
    id: 'scandinavian', name: 'Scandinavian',
    background: Color(0xFFF7F8F7), accent: Color(0xFFA8BBC7), ink: Color(0xFF344653),
  );
  static const oldMoney = HubPalette(
    id: 'old_money', name: 'Old Money',
    background: Color(0xFFF4F0E6), accent: Color(0xFFB7A16B), ink: Color(0xFF244536),
  );
  static const rosewater = HubPalette(
    id: 'rosewater', name: 'Rosewater',
    background: Color(0xFFFBF4F2), accent: Color(0xFFC58F98), ink: Color(0xFF76545C),
  );
  static const wabiSabi = HubPalette(
    id: 'wabi_sabi', name: 'Wabi-Sabi',
    background: Color(0xFFEEE8DC), accent: Color(0xFFAAA08D), ink: Color(0xFF4B4942),
  );
  static const retroEditorial = HubPalette(
    id: 'retro_editorial', name: 'Retro Editorial',
    background: Color(0xFFF3E7CF), accent: Color(0xFFBC633E), ink: Color(0xFF56402E),
    secondary: Color(0xFFB4A15A),
  );

  static const List<HubPalette> values = [
    hackathonNight, electricCobalt, sageCream, champagneLuxe, darkAcademia, scandinavian,
    oldMoney, rosewater, wabiSabi, retroEditorial,
  ];

  static HubPalette byId(String? id) => values.firstWhere(
    (palette) => palette.id == id,
    orElse: () => electricCobalt,
  );
}

@immutable
class HubThemeColors extends ThemeExtension<HubThemeColors> {
  const HubThemeColors({
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.border,
    required this.primary,
    required this.deep,
    required this.positive,
    required this.warning,
    required this.violet,
  });

  final Color background;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color border;
  final Color primary;
  final Color deep;
  final Color positive;
  final Color warning;
  final Color violet;

  @override
  HubThemeColors copyWith({
    Color? background, Color? surface, Color? ink, Color? muted,
    Color? border, Color? primary, Color? deep, Color? positive,
    Color? warning, Color? violet,
  }) => HubThemeColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    border: border ?? this.border,
    primary: primary ?? this.primary,
    deep: deep ?? this.deep,
    positive: positive ?? this.positive,
    warning: warning ?? this.warning,
    violet: violet ?? this.violet,
  );

  @override
  HubThemeColors lerp(ThemeExtension<HubThemeColors>? other, double t) {
    if (other is! HubThemeColors) return this;
    return HubThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      deep: Color.lerp(deep, other.deep, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
    );
  }
}

extension HubThemeContext on BuildContext {
  HubThemeColors get hubColors => Theme.of(this).extension<HubThemeColors>()!;
}

class AppTheme {
  AppTheme._();

  // Electric Cobalt compatibility aliases for code that has not yet moved to
  // Theme.of(context).hubColors.
  static const Color navy = Color(0xFF173A70);
  static const Color blue = Color(0xFF2563EB);
  static const Color teal = Color(0xFF0D9488);
  static const Color violet = Color(0xFF7C3AED);
  static const Color background = Color(0xFFF5F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color orange = Color(0xFFFF9B54);
  static const Color ink = Color(0xFF172033);
  static const Color muted = Color(0xFF667085);
  static const Color border = Color(0xFFE4E9F2);

  static ThemeData get light => lightFor(HubPalette.electricCobalt);
  static ThemeData get dark => darkFor(HubPalette.electricCobalt);

  static ThemeData lightFor(HubPalette palette) {
    final secondary = palette.secondary ?? palette.accent;
    final tertiary = palette.tertiary ?? palette.accent;
    final violet = palette.violet ?? palette.accent;
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: Brightness.light,
      primary: palette.accent,
      onPrimary: _bestForeground(palette.accent, palette.ink),
      secondary: secondary,
      onSecondary: _bestForeground(secondary, palette.ink),
      tertiary: tertiary,
      surface: Colors.white,
      onSurface: palette.ink,
      error: const Color(0xFFB42318),
      onError: Colors.white,
    );
    final colors = HubThemeColors(
      background: palette.background,
      surface: Colors.white,
      ink: palette.ink,
      muted: _mix(palette.ink, palette.background, .28),
      border: _mix(palette.ink, palette.background, .14),
      primary: palette.accent,
      deep: palette.ink,
      positive: tertiary,
      warning: secondary,
      violet: violet,
    );
    return _baseTheme(scheme, colors, palette.background);
  }

  static ThemeData darkFor(HubPalette palette) {
    if (palette.id == HubPalette.hackathonNight.id) {
      const background = Color(0xFF07090D);
      const surface = Color(0xFF0B1017);
      const foreground = Color(0xFFF5F7FA);
      const primary = Color(0xFFFF6818);
      const secondary = Color(0xFF00D9E8);
      const tertiary = Color(0xFF00D6A0);
      const violet = Color(0xFFFF4655);
      const border = Color(0xFF202A35);
      const scheme = ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: background,
        tertiary: tertiary,
        surface: surface,
        onSurface: foreground,
        error: violet,
        onError: Colors.white,
      );
      const colors = HubThemeColors(
        background: background,
        surface: surface,
        ink: foreground,
        muted: Color(0xFFA1B1C4),
        border: border,
        primary: primary,
        deep: foreground,
        positive: tertiary,
        warning: secondary,
        violet: violet,
      );
      return _baseTheme(scheme, colors, background).copyWith(
        scaffoldBackgroundColor: background,
        cardTheme: const CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: border),
          ),
        ),
      );
    }
    final background = _mix(palette.ink, const Color(0xFF111111), .48);
    final surface = _mix(background, palette.ink, .2);
    final foreground = _mix(palette.background, Colors.white, .65);
    final primary = _mix(palette.accent, Colors.white, .3);
    final secondary = _mix(palette.secondary ?? palette.accent, Colors.white, .3);
    final tertiary = _mix(palette.tertiary ?? palette.accent, Colors.white, .3);
    final violet = _mix(palette.violet ?? palette.accent, Colors.white, .3);
    final border = _mix(surface, foreground, .18);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: _bestForeground(primary, background),
      secondary: secondary,
      onSecondary: _bestForeground(secondary, background),
      tertiary: tertiary,
      surface: surface,
      onSurface: foreground,
      error: const Color(0xFFFF8A80),
      onError: const Color(0xFF3B1010),
    );
    final colors = HubThemeColors(
      background: background,
      surface: surface,
      ink: foreground,
      muted: _mix(foreground, background, .38),
      border: border,
      primary: primary,
      deep: foreground,
      positive: tertiary,
      warning: secondary,
      violet: violet,
    );
    return _baseTheme(scheme, colors, background);
  }

  static ThemeData _baseTheme(
    ColorScheme scheme,
    HubThemeColors colors,
    Color background,
  ) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: [colors],
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      hintStyle: TextStyle(color: colors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: colors.ink, fontSize: 20, fontWeight: FontWeight.w700),
      contentTextStyle: TextStyle(color: colors.ink, fontSize: 14, height: 1.45),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.ink,
      contentTextStyle: TextStyle(color: colors.background),
    ),
    dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
  );

  static Color _bestForeground(Color color, Color preferred) {
    final whiteContrast = _contrast(color, Colors.white);
    final preferredContrast = _contrast(color, preferred);
    if (whiteContrast >= 4.5 || whiteContrast >= preferredContrast) {
      return Colors.white;
    }
    return preferred;
  }

  static double _contrast(Color a, Color b) {
    final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
    final darker = identical(lighter, a) ? b : a;
    return (lighter.computeLuminance() + .05) / (darker.computeLuminance() + .05);
  }

  static Color _mix(Color a, Color b, double amount) => Color.lerp(a, b, amount)!;
}
