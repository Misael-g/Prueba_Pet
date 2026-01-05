import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageRemoteDatasource {
  final SupabaseClient client;

  StorageRemoteDatasource(this.client);

  Future<String> uploadMascotaImage(File file) async {
    final fileName = '${const Uuid().v4()}.jpg';

    await client.storage.from('mascotas-imagenes').upload(
          fileName,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    return client.storage.from('mascotas-imagenes').getPublicUrl(fileName);
  }

  Future<List<String>> uploadMultipleImages(List<File> files) async {
    final urls = <String>[];

    for (final file in files) {
      final url = await uploadMascotaImage(file);
      urls.add(url);
    }

    return urls;
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extraer el nombre del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;

      await client.storage.from('mascotas-imagenes').remove([fileName]);
    } catch (e) {
      print('Error al eliminar imagen: $e');
    }
  }
}