import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rootpage.dart';
import 'userprofile.dart';

class CheckProfilePage extends StatefulWidget {
  const CheckProfilePage({super.key});

  @override
  State<CheckProfilePage> createState() => _CheckProfilePageState();
}

class _CheckProfilePageState extends State<CheckProfilePage> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        // SEND BACK TO LOGIN page if not LOGIN
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        // if no profile yet, need to make one
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserProfileScreen()),
        );
      } else {
        // profile exists? go back to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RootPage()),
        );
      }
    } catch (e) {
      print('ERROR checking profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ERROR checking profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text("Redirecting..."),
      ),
    );
  }
}
