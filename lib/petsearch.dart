import 'package:flutter/material.dart';
import 'package:furmatch_clean/pet_profile_card.dart';
import 'package:furmatch_clean/services/pet_service.dart';

class SearchPet extends StatefulWidget {
  const SearchPet({super.key});

  @override
  State<SearchPet> createState() => _SearchPetState();
}

class _SearchPetState extends State<SearchPet> {
  final PetService _petService = PetService();
  List<Map<String, dynamic>> pets = [];
  int? expandedCardIndex;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _petService.getAllOtherPets();

      setState(() {
        pets = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load pets: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9E9DB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Pet Profiles',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadPets,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : pets.isEmpty
                  ? const Center(
                      child: Text(
                        'No pets found',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        final pet = pets[index];

                        // -----making sure petid and image_url are present
                        final String petId = pet['id']?.toString() ?? '';
                        final String ownerId =
                            (pet['owner_id'] ?? pet['user_id'])?.toString() ??
                                '';
                        final String petName = pet['name'] ?? 'Unknown';
                        final String petImage = (pet['image_url'] != null &&
                                pet['image_url'].toString().isNotEmpty)
                            ? pet['image_url'].toString()
                            : 'assets/Logos/MAINPAGE.png';

                        return PetProfileCard(
                          pet: {
                            'id': petId, // for messaging
                            'owner_id': ownerId,
                            'name': petName,
                            'gender': pet['gender'] ?? '',
                            'age': pet['age'], // integer format
                            'breed': pet['breed'] ?? '',
                            'weight': pet['weight'],
                            'image_url': petImage, // db should match
                          },
                          isExpanded: expandedCardIndex == index,
                          onCardTap: () {
                            setState(() {
                              expandedCardIndex =
                                  expandedCardIndex == index ? null : index;
                            });
                          },
                        );
                      },
                    ),
    );
  }
}
