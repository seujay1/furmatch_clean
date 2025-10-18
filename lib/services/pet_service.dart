import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class PetService {
  final SupabaseClient client = SupabaseService.client;
  final String tableName = 'pets';
  final String storageBucket = 'pet_images';

  Future<String?> uploadPetImage(File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

    try {
      await client.storage.from(storageBucket).upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          client.storage.from(storageBucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllPets() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final response = await client
        .from(tableName)
        .select()
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllOtherPets() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final response = await client
        .from(tableName)
        .select()
        .neq('owner_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addPet(Map<String, dynamic> petData, {File? imageFile}) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    String? imageUrl = petData['image_url'];
    if (imageFile != null) {
      imageUrl = await uploadPetImage(imageFile);
    }

    final dataWithOwner = {
      ...petData,
      'owner_id': user.id,
      'image_url': imageUrl,
    };

    await client.from(tableName).insert(dataWithOwner);
  }

  Future<void> updatePet(String id, Map<String, dynamic> petData,
      {File? imageFile}) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    String? imageUrl = petData['image_url'];
    if (imageFile != null) {
      imageUrl = await uploadPetImage(imageFile);
    }

    final dataToUpdate = {
      ...petData,
      if (imageUrl != null) 'image_url': imageUrl,
    };

    await client
        .from(tableName)
        .update(dataToUpdate)
        .eq('id', id)
        .eq('owner_id', user.id);
  }

  Future<void> deletePet(String id) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await client.from(tableName).delete().eq('id', id).eq('owner_id', user.id);
  }
}
