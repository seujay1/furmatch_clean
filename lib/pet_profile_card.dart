import 'package:flutter/material.dart';
import 'package:furmatch_clean/messaging_person.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PetProfileCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final bool isExpanded;
  final VoidCallback onCardTap;

  const PetProfileCard({
    super.key,
    required this.pet,
    required this.isExpanded,
    required this.onCardTap,
  });

  Future<void> _saveContact(String name, String image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, String>> contacts = [];

      final savedContacts = prefs.getString('contacts');
      if (savedContacts != null) {
        final List<dynamic> decoded = jsonDecode(savedContacts);
        contacts = decoded.map<Map<String, String>>((c) {
          return {
            'name': c['name'].toString(),
            'image': c['image'].toString(),
            'activeTime': c['activeTime'].toString(),
          };
        }).toList();
      }

      if (!contacts.any((c) => c['name'] == name)) {
        contacts.add({
          "name": name,
          "activeTime": DateTime.now().toIso8601String(),
          "image": image,
        });
        await prefs.setString('contacts', jsonEncode(contacts));
      }
    } catch (e, st) {
      print('_saveContact ERROR!: $e\n$st');
    }
  }

  String formatAge(dynamic ageInMonths) {
    if (ageInMonths == null) return 'N/A';
    if (ageInMonths is! int) return ageInMonths.toString();
    if (ageInMonths >= 12) {
      final years = ageInMonths ~/ 12;
      final months = ageInMonths % 12;
      return months == 0
          ? '$years yr${years > 1 ? 's' : ''}'
          : '$years yr${years > 1 ? 's' : ''} $months mo${months > 1 ? 's' : ''}';
    } else {
      return '$ageInMonths mo${ageInMonths > 1 ? 's' : ''}';
    }
  }

  String formatWeight(dynamic weight) {
    if (weight == null) return 'N/A';
    if (weight is String && weight.endsWith('kg')) return weight;
    return '$weight kg';
  }

  @override
  Widget build(BuildContext context) {
    final String petName = (pet['name'] ?? 'Unknown Pet').toString();
    final String petId = (pet['id'] ?? '').toString();
    final String ownerId = (pet['owner_id'] ?? pet['user_id'] ?? '').toString();
    final String petImageUrl = (pet['image_url'] ?? '').toString();
//debugging
    print(
        'PetProfileCard debug: petId=$petId, ownerId=$ownerId, petName=$petName, imageUrl=$petImageUrl');

    final Widget petImageWidget = ClipOval(
      child: petImageUrl.isNotEmpty && petImageUrl.startsWith('http')
          ? Image.network(
              petImageUrl,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/Logos/MAINPAGE.png',
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
            )
          : Image.asset(
              'assets/Logos/MAINPAGE.png',
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onCardTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isExpanded ? 230 : 140,
            decoration: BoxDecoration(
              color: const Color(0xFFC2B39C),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                    padding: const EdgeInsets.all(10.0), child: petImageWidget),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isExpanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Text(
                          petName,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (!isExpanded)
                          Text(
                            "Age: ${formatAge(pet['age'])}, Weight: ${formatWeight(pet['weight'])}",
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 14),
                          ),
                        if (isExpanded) ...[
                          Text("Gender: ${pet['gender'] ?? 'Not specified'}",
                              style: const TextStyle(color: Colors.black)),
                          Text("Age: ${formatAge(pet['age'])}",
                              style: const TextStyle(color: Colors.black)),
                          Text("Breed: ${pet['breed'] ?? 'Unknown'}",
                              style: const TextStyle(color: Colors.black)),
                          Text("Weight: ${formatWeight(pet['weight'])}",
                              style: const TextStyle(color: Colors.black)),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.message),
                              label: const Text('Message Owner'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: ownerId.isNotEmpty
                                  ? () {
                                      final String imageToSend =
                                          petImageUrl.isNotEmpty
                                              ? petImageUrl
                                              : 'assets/Logos/MAINPAGE.png';
                                      _saveContact(petName, imageToSend);
                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MessagingPerson(
                                              petId: petId,
                                              ownerId: ownerId,
                                              petName: petName,
                                              petImage: imageToSend,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
