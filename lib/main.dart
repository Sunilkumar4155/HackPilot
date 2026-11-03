import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/main_navigation.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider()..load(),
      child: const AIHackathonFinder(),
    ),
  );
}

class AIHackathonFinder extends StatelessWidget {
  const AIHackathonFinder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HACKPILOT',
      debugShowCheckedModeBanner: false,
      theme: context.watch<ThemeProvider>().lightTheme,
      darkTheme: context.watch<ThemeProvider>().darkTheme,
      themeMode: context.watch<ThemeProvider>().themeMode,

      home: const MainNavigation(),
    );
  }
}
