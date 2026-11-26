import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';

/// Uses native camera/photo selection. Only the chosen photo is read.
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List?> pick({required bool camera}) async {
    final file = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return file == null ? null : _read(file);
  }

  Future<Uint8List> _read(XFile file) async {
    if (await file.length() > 20 * 1024 * 1024) {
      throw const FormatException('Please choose a photo smaller than 20 MB.');
    }
    final bytes = await file.readAsBytes();
    // Reject unsupported/corrupt images before enabling review.
    final image = await decodeImageFromList(bytes);
    image.dispose();
    return bytes;
  }

  /// Android can recreate the activity while the system picker is open.
  Future<Uint8List?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await _picker.retrieveLostData();
    if (response.exception != null) throw response.exception!;
    final files = response.files;
    return files == null || files.isEmpty ? null : _read(files.first);
  }
}
