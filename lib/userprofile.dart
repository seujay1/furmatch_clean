import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rootpage.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  bool isEditing = false;
  bool _isSaving = false;
  bool _isLoading = false;
  File? _image;
  String? selectedGender;
  String? selectedUserType;

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _pickImage() async {
    if (!isEditing) return;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _saveInformation() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final profileData = {
      'id': user.id,
      'full_name': nameController.text.trim(),
      'address': addressController.text.trim(),
      'contact': contactController.text.trim(),
      'email': emailController.text.trim(),
      'age': ageController.text.trim(),
      'gender': selectedGender,
      'userType': selectedUserType,
      'image': _image?.path ?? '',
    };

    try {
      await _client.from('profiles').upsert(profileData, onConflict: 'id');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', jsonEncode(profileData));

      if (!mounted) return;
      setState(() {
        isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RootPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      print('Fetching profile for user: ${user.id}');
      print('Response from Supabase: $data');

      if (data != null && mounted) {
        setState(() {
          nameController.text = data['full_name'] ?? '';
          addressController.text = data['address'] ?? '';
          contactController.text = data['contact'] ?? '';
          emailController.text = data['email'] ?? '';
          ageController.text = data['age'] ?? '';
          selectedGender = data['gender'];
          selectedUserType = data['userType'];
          if (data['image'] != null && data['image'].toString().isNotEmpty) {
            _image = File(data['image']);
          }
          isEditing = false;
        });
      } else if (mounted) {
        setState(() => isEditing = true);
      }
    } catch (e) {
      print('ERROR loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text('Are you sure you want to delete your profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = _client.auth.currentUser;
        if (user != null) {
          await _client.from('profiles').delete().eq('id', user.id);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_profile');

        if (!mounted) return;
        setState(() {
          isEditing = true;
          _image = null;
          nameController.clear();
          addressController.clear();
          contactController.clear();
          emailController.clear();
          ageController.clear();
          selectedGender = null;
          selectedUserType = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile deleted successfully!'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ERROR deleting profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("User Profile", style: GoogleFonts.jost(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.brown),
            onPressed: _isLoading
                ? null
                : () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refreshing profile...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    await _loadUserProfile();
                  },
          ),
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteProfile,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        color: Colors.brown,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.brown))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: isEditing ? _pickImage : null,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECECEC),
                            borderRadius: BorderRadius.circular(16),
                            image: _image != null
                                ? DecorationImage(
                                    image: FileImage(_image!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _image == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt,
                                        color: Colors.black54, size: 50),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Add Photo',
                                      style: GoogleFonts.jost(
                                        color: Colors.black54,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (!isEditing)
                        Text(
                          nameController.text,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.jost(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[800],
                          ),
                        ),
                      const SizedBox(height: 15),

                      // 🟢 Edit/Save Button placed above Full Name field
                      Center(
                        child: SizedBox(
                          width: 250,
                          height: 35,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : (isEditing
                                    ? _saveInformation
                                    : () => setState(() => isEditing = true)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isSaving ? Colors.grey : Colors.green[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _isSaving
                                  ? "Saving..."
                                  : isEditing
                                      ? "Save"
                                      : "Edit",
                              style: GoogleFonts.jost(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      _buildCardTextField(
                          nameController, "Full Name", isEditing),
                      _buildCardTextField(
                          addressController, "Address", isEditing),
                      _buildCardTextField(
                        contactController,
                        "Contact Number",
                        isEditing,
                        keyboard: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Required field';
                          if (!RegExp(r'^\d+$').hasMatch(val))
                            return 'Numbers only';
                          return null;
                        },
                      ),
                      _buildCardTextField(
                        emailController,
                        "Email Address",
                        isEditing,
                        keyboard: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Required field';
                          if (!_isValidEmail(val))
                            return 'INVALID email format';
                          return null;
                        },
                      ),
                      _buildCardTextField(
                        ageController,
                        "Age",
                        isEditing,
                        keyboard: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Required field';
                          if (!RegExp(r'^\d+$').hasMatch(val))
                            return 'Numbers only';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Text("Gender:", style: GoogleFonts.jost(fontSize: 16)),
                      Wrap(spacing: 10, children: [
                        _chipOption("Male", Colors.lightBlue, selectedGender,
                            (val) => setState(() => selectedGender = val)),
                        _chipOption("Female", Colors.pinkAccent, selectedGender,
                            (val) => setState(() => selectedGender = val)),
                      ]),
                      const SizedBox(height: 10),
                      Text("User Type:", style: GoogleFonts.jost(fontSize: 16)),
                      Wrap(spacing: 10, children: [
                        _chipOption(
                            "Pet Owner",
                            Colors.orange,
                            selectedUserType,
                            (val) => setState(() => selectedUserType = val)),
                        _chipOption(
                            "Pet Breeder",
                            Colors.green,
                            selectedUserType,
                            (val) => setState(() => selectedUserType = val)),
                      ]),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCardTextField(
    TextEditingController controller,
    String label,
    bool editable, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E6),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: !editable,
        keyboardType: keyboard,
        validator: validator,
        style: GoogleFonts.jost(fontSize: 16, color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.jost(fontSize: 14, color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  ChoiceChip _chipOption(
    String label,
    Color color,
    String? selected,
    Function(String?) onSelect,
  ) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.jost(
          color: selected == label ? Colors.white : Colors.black,
        ),
      ),
      selected: selected == label,
      selectedColor: color,
      backgroundColor: const Color(0xFFECECEC),
      onSelected: isEditing ? (bool val) => onSelect(val ? label : null) : null,
    );
  }
}
