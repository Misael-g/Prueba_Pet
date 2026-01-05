import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageRemoteDatasource {
  final SupabaseClient client;

  StorageRemoteDatasource(this.client);

  Future<String> uploadMascotaImage(File file) async {
    final fileName = '${const Uuid().v4()}.jpg';

    await client.storage
        .from('mascotas-imagenes')
        .upload(fileName, file);

    return client.storage
        .from('mascotas-imagenes')
        .getPublicUrl(fileName);
  }
}
