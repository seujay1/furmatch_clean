import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:furmatch_clean/splashscreen.dart';
import 'package:furmatch_clean/reset_password_page.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // -----------------------initialize supabase ---------------------
    await Supabase.initialize(
      url: 'https://kybzldrzgyzkfxtfxtbo.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5YnpsZHJ6Z3l6a2Z4dGZ4dGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyOTMwNjksImV4cCI6MjA3NTg2OTA2OX0.idLam59_a8Hk8G8P-AZI9I4Ev1wdM-XBrhVsCb3Qc7o',
    );

    print('Supabase initialized successfully');
  } catch (e) {
    print('Supabase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final supabase = Supabase.instance.client;
  bool _navigatedToReset = false; // prevent duplicate navigation

  @override
  void initState() {
    super.initState();

    // ---------deep links (for password reset)
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery && !_navigatedToReset) {
        _navigatedToReset = true;
        print("Password recovery link opened!");
        _navigateToResetPassword();
      }
    });
  }

  void _navigateToResetPassword() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
      ).then((_) {
        _navigatedToReset = false; // reset when return
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FurMatch',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const SplashScreen(),
    );
  }
}
