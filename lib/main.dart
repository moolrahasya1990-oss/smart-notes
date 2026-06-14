import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/ads/ad_service.dart';
import 'core/theme/app_theme.dart';
import 'features/notes/presentation/providers/theme_provider.dart';
import 'features/notes/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdMob SDK
  await AdService.initialize();

  // Initialize Local DB Hive
  try {
    await Hive.initFlutter();
  } catch (e) {
    developer.log('Hive initialization failed: $e');
  }

  // Gracefully initiate Firebase to protect application startup
  try {
    // If the firebase config elements aren't present (e.g. initial compile), this throws cleanly.
    await Firebase.initializeApp();
    developer.log('Firebase services completed successfully');
  } catch (e) {
    developer.log('Firebase configuration skipped or missing: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Smart Notes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
