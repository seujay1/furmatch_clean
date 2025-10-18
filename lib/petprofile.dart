import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:furmatch_clean/services/pet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PetInfoScreen extends StatefulWidget {
  final Map<String, dynamic>? petData; // for editing
  final String? petId; // db

  const PetInfoScreen({super.key, this.petData, this.petId});

  @override
  State<PetInfoScreen> createState() => _PetInfoScreenState();
}

class _PetInfoScreenState extends State<PetInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final PetService _petService = PetService();

  File? _imageFile;
  String? _petName;
  String? _breed;
  String? _gender = 'Male';
  int? _age; // stored in months
  String _ageUnit = 'years'; // for input
  double? _weight;
  String _ownerRole = 'Pet Owner';

  bool isSaving = false;
  bool get isEditing => widget.petData != null;

  @override
  void initState() {
    super.initState();
    _loadUserRole();

    if (isEditing) {
      final pet = widget.petData!;
      _petName = pet['name'];
      _breed = pet['breed'];
      _gender = pet['gender'] ?? 'Male';
      _weight = (pet['weight'] != null)
          ? double.tryParse(pet['weight'].toString())
          : null;

      // convert months to years or months for displaying
      if (pet['age'] != null) {
        int months = pet['age'];
        if (months >= 12) {
          _ageUnit = 'years';
          _age = months ~/ 12;
        } else {
          _ageUnit = 'months';
          _age = months;
        }
      }

      _imageFile = null; 
    }
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userProfile = prefs.getString('user_profile');
    if (userProfile != null) {
      try {
        final data = jsonDecode(userProfile);
        setState(() {
          _ownerRole = (data['userType'] as String?) ?? 'Pet Owner';
        });
      } catch (_) {}
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  /// ---------------------SAVE OR UPDATE PET IN SUPABASE-----------------------
  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isSaving = true);

    try {
      // Convert age to months
      int ageInMonths = (_age ?? 0) * (_ageUnit == 'years' ? 12 : 1);

      final petData = {
        'name': _petName,
        'breed': _breed,
        'gender': _gender,
        'age': ageInMonths,
        'weight': _weight,
        'description': null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isEditing && widget.petId != null) {
        await _petService.updatePet(widget.petId!, petData,
            imageFile: _imageFile);
      } else {
        await _petService.addPet(petData, imageFile: _imageFile);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Pet updated successfully!'
                  : 'Pet added successfully!',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving pet: $e')),
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (!isEditing || widget.petId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text(
            'Are you sure you want to delete "${_petName ?? 'this pet'}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _petService.deletePet(widget.petId!);
        if (context.mounted) Navigator.pop(context, true);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting pet: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Pet Info" : "Enter Pet Information"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ////// image picker
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.brown[100],
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (isEditing
                          ? NetworkImage(widget.petData?['image_url'] ?? '')
                              as ImageProvider
                          : null),
                  child: (_imageFile == null &&
                          (widget.petData?['image_url'] == null ||
                              widget.petData?['image_url'] == ''))
                      ? const Icon(Icons.add_a_photo,
                          size: 40, color: Colors.brown)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // ----------PET NAME---------------
              TextFormField(
                initialValue: _petName,
                decoration: const InputDecoration(
                    labelText: 'Pet Name', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter pet name' : null,
                onSaved: (v) => _petName = v?.trim(),
              ),
              const SizedBox(height: 15),

              // ------------Breed-------------
              TextFormField(
                initialValue: _breed,
                decoration: const InputDecoration(
                    labelText: 'Breed', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter breed' : null,
                onSaved: (v) => _breed = v?.trim(),
              ),
              const SizedBox(height: 15),

              // ------------Gender----------------
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                    labelText: 'Gender', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 15),

              // ----------------Age----------------
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: _age?.toString(),
                      decoration: const InputDecoration(
                          labelText: 'Age', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter age' : null,
                      onSaved: (v) => _age = int.tryParse(v?.trim() ?? '0'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _ageUnit,
                      decoration: const InputDecoration(
                          labelText: 'Unit', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'years', child: Text('Years')),
                        DropdownMenuItem(
                            value: 'months', child: Text('Months')),
                      ],
                      onChanged: (v) => setState(() => _ageUnit = v ?? 'years'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // ----------------Weight----------------
              TextFormField(
                initialValue: _weight?.toString(),
                decoration: const InputDecoration(
                    labelText: 'Weight (kg)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onSaved: (v) => _weight = double.tryParse(v?.trim() ?? '0'),
              ),
              const SizedBox(height: 25),

              // ------------------Owner--------------------
              Text("Listed by: $_ownerRole",
                  style: const TextStyle(
                      color: Colors.brown, fontWeight: FontWeight.w600)),
              const SizedBox(height: 25),

              // ----------------SAVE BUTTON----------------------
              ElevatedButton(
                onPressed: isSaving ? null : _savePet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  isSaving
                      ? 'Saving...'
                      : (isEditing ? 'Save Changes' : 'Save Pet'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
