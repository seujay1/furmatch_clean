import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'petprofile.dart';
import 'userprofile.dart';
import 'services/pet_service.dart';
import 'services/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PetService _petService = PetService();
  final SupabaseClient _client = SupabaseService.client;

  List<Map<String, dynamic>> _pets = [];
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  RealtimeChannel? _profileChannel;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _profileChannel?.unsubscribe();
    super.dispose();
  }

  /// ----------------------USER AND PET, INITIALIZE DATA-------------------------
  Future<void> _initializeData() async {
    await _loadUserProfile();
    await _loadPets();
    _subscribeToProfileChanges();
  }

  /// --------------------------LOAD USER PROFILE---------------------------------
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
//----------------load from SUPABASE OR SHARED
      if (profile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', jsonEncode(profile));

        if (mounted) {
          setState(() {
            _userProfile = Map<String, dynamic>.from(profile);
            _isLoading = false;
          });
        }
        return;
      }

      //---------------FALLBACK TO CACHE------------------
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('user_profile');
      if (cached != null) {
        final parsed = jsonDecode(cached);
        if (mounted) {
          setState(() {
            _userProfile = parsed;
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _userProfile = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  /// -------------------REALTIME PROFILE CHANGES-----------------------
  void _subscribeToProfileChanges() {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _profileChannel?.unsubscribe();

    _profileChannel = _client
        .channel('profile-changes-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: user.id,
          ),
          callback: (payload) async {
            final updated = payload.newRecord;
            if (updated.isNotEmpty && mounted) {
              setState(() {
                _userProfile = Map<String, dynamic>.from(updated);
              });

              // --------------update cached profile so when mag reload makita new name
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_profile', jsonEncode(updated));
            }
          },
        )
        .subscribe();
  }

  ///--------------------------------LOAD PETS-------------------------------------
  Future<void> _loadPets() async {
    try {
      final pets = await _petService.getAllPets();
      if (mounted) {
        setState(() {
          _pets = pets;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pets: $e')),
        );
      }
    }
  }

  /// -------------------------GO TO petprofile---------------------------
  Future<void> _navigateToPetForm({Map<String, dynamic>? pet}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetInfoScreen(
          petData: pet,
          petId: pet?['id'],
        ),
      ),
    );

    if (result == true) _loadPets(); // refresh pets when mag return
  }

  /// ----------------------GO TO USER PROFILE FORM--------------------------
  Future<void> _navigateToUserProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
    );

    if (result == true) await _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final userName = (_userProfile != null &&
            _userProfile!['full_name'] != null &&
            (_userProfile!['full_name'] as String).trim().isNotEmpty)
        ? _userProfile!['full_name'] as String
        : 'User';

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        onPressed: () => _navigateToPetForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadUserProfile();
                await _loadPets();
              },
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _navigateToUserProfile,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    "Welcome, $userName 🐾",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // header and image
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -13,
                        left: 0,
                        right: 0,
                        child: Image.asset(
                          'assets/Logos/dog_cat.png',
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 180),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.brown[300],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(120),
                            topRight: Radius.circular(120),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(30, 90, 30, 30),
                        child: const Text(
                          'Connect, care, and share the joy of pets! Explore your pets below or add a new one 🐶',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

// ------------------------------PET LIST sa HOMEPAGE----------------------------
                  Expanded(
                    child: _pets.isEmpty
                        ? const Center(
                            child: Text(
                              "No pets added yet 🐾\nTap '+' to add one!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _pets.length,
                            itemBuilder: (context, index) {
                              final pet = _pets[index];
                              final imageUrl = pet['image_url'] ?? '';

                              // format age in months or years
                              String formatAge(int? months) {
                                if (months == null) return 'N/A';
                                if (months < 12) {
                                  return '$months month${months > 1 ? 's' : ''}';
                                }
                                final years = months ~/ 12;
                                return '$years year${years > 1 ? 's' : ''}';
                              }

                              // format weight with kg
                              String formatWeight(dynamic weight) {
                                if (weight == null) return 'N/A';
                                return '$weight kg';
                              }

                              final petImageWidget = imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.network(
                                        imageUrl,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.asset(
                                        'assets/Logos/MAINPAGE.png',
                                        width: 65,
                                        height: 65,
                                        fit: BoxFit.cover,
                                      ),
                                    );

                              return GestureDetector(
                                onTap: () => _navigateToPetForm(pet: pet),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          // ignore: deprecated_member_use
                                          color: Colors.brown.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 6,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      leading: petImageWidget,
                                      title: Text(
                                        pet['name'] ?? 'Unknown Pet',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "Breed: ${pet['breed'] ?? 'N/A'}"),
                                          Text(
                                              "Gender: ${pet['gender'] ?? 'N/A'}"),
                                          Text("Age: ${formatAge(pet['age'])}"),
                                          Text(
                                              "Weight: ${formatWeight(pet['weight'])}"),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
