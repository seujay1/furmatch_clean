import 'package:flutter/material.dart';
import 'package:furmatch_clean/loginpage.dart';
import 'package:furmatch_clean/rootpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});


  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen> {
  final supabase = Supabase.instance.client;


  @override
  void initState() {
    super.initState();
    _initializeApp();
  }


  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 1)); //  delay
    await _checkSession();
  }


  Future<void> _checkSession() async {
    try {
      final session = supabase.auth.currentSession;


      if (session != null) {
        final user = session.user;
        debugPrint("User already logged in: ${user.email}");


//-----------------------CHECK OR CREATE PROFILE-----------------------------
        final response = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();


        if (response == null) {
          debugPrint("No profile found for user, creating one...");
          await supabase.from('profiles').insert({
            'id': user.id,
            'email': user.email,
          });
        }


        _navigateTo(const RootPage());
      } else {
        debugPrint("No active session found.");
        _navigateTo(const LoginPage());
      }
    } catch (e) {
      debugPrint("ERROR checking session: $e");
      _navigateTo(const LoginPage());
    }
  }


  void _navigateTo(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9E9DB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Logos/MAINPAGE.png',
              width: 160,
              height: 160,
            ),
            const SizedBox(height: 30),
            const Text(
              'Welcome to FurMatch!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.brown,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}



