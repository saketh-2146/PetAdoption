import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Your Supabase Storage bucket
  static const String bucketName = 'petsselling';

  /// Uploads a pet image to Supabase Storage
  /// and returns the public image URL.
  Future<String> uploadPetImage({
    required XFile imageFile,
    required String userId,
    required String petId,
    required String fileName,
  }) async {
    try {
      debugPrint('===== SUPABASE IMAGE UPLOAD =====');

      // Read image as bytes
      final bytes = await imageFile.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('Selected image file is empty.');
      }

      // Path inside the petsselling bucket
      final path = 'pets/$petId/$fileName';

      debugPrint('Bucket: $bucketName');
      debugPrint('Path: $path');
      debugPrint('File name: $fileName');
      debugPrint('File size: ${bytes.length} bytes');

      // Upload image to Supabase Storage
      await _supabase.storage.from(bucketName).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );

      debugPrint('Upload completed successfully');

      // Get public URL
      final publicUrl =
          _supabase.storage.from(bucketName).getPublicUrl(path);

      debugPrint('Public URL: $publicUrl');

      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('===== SUPABASE STORAGE ERROR =====');
      debugPrint('Message: ${e.message}');
      debugPrint('Status code: ${e.statusCode}');
      debugPrint('Error: $e');

      throw Exception(
        'Supabase upload failed: ${e.message} '
        '(Status: ${e.statusCode})',
      );
    } catch (e) {
      debugPrint('===== GENERAL UPLOAD ERROR =====');
      debugPrint('$e');

      throw Exception('Image upload failed: $e');
    }
  }

  /// Deletes all images belonging to a pet.
  Future<void> deleteFolder({
    required String userId,
    required String petId,
  }) async {
    try {
      final folderPath = 'pets/$petId';

      // List files inside the pet folder
      final List<FileObject> objects =
          await _supabase.storage.from(bucketName).list(
                path: folderPath,
              );

      if (objects.isEmpty) {
        debugPrint('No images found for pet $petId');
        return;
      }

      // Create file paths
      final List<String> filePaths = objects
          .map((obj) => '$folderPath/${obj.name}')
          .toList();

      // Delete files
      await _supabase.storage.from(bucketName).remove(filePaths);

      debugPrint(
        'Deleted ${filePaths.length} images for pet $petId',
      );
    } catch (e) {
      debugPrint('Failed to delete pet images: $e');
      rethrow;
    }
  }
}
