import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:autoclip/models/clip_segment.dart';

class GalleryService {
  static const MethodChannel _channel = MethodChannel('com.autoclip.app/native');
  static const String albumName = 'AutoClip';

  /// Save rendered MP4 clip to the public Movies/AutoClip folder and scan it
  /// so it appears in the phone gallery right away.
  /// Formats filenames as Clean_01.mp4, Gaming_02.mp4, etc.
  /// NOTE: The old `gal` plugin was removed because its Android build
  /// (gal 2.3.3) breaks the release build on AGP 8 / Flutter 3.22
  /// ("compileSdkVersion is not specified"). The native scan below gives
  /// the same visible result: the clip lands in Movies/AutoClip and shows
  /// in Gallery / Google Photos.
  static Future<String> saveClipToGallery(ClipSegment clip) async {
    final file = File(clip.outputPath!);
    if (!await file.exists()) {
      throw Exception('Rendered video file not found at ${clip.outputPath}');
    }

    final storageDir = await getAutoClipDirectory(styleFolder: clip.style.name);
    final targetPath = p.join(storageDir.path, clip.fileName);
    await file.copy(targetPath);

    // Scan the copied file so it appears in the gallery immediately
    try {
      await _channel.invokeMethod('scanMediaFile', {'filePath': targetPath});
    } catch (_) {}

    return 'Saved to Gallery ($albumName/${clip.fileName})';
  }

  /// Launch the device's native Gallery app
  static Future<void> openDeviceGallery() async {
    try {
      await _channel.invokeMethod('openGallery');
    } catch (e) {
      throw Exception('Could not open device gallery: $e');
    }
  }

  /// Get or create the local AutoClip storage directory organized by style
  static Future<Directory> getAutoClipDirectory({String? styleFolder}) async {
    String? nativePath;
    try {
      nativePath = await _channel.invokeMethod<String>('getAutoClipStorageDir');
    } catch (_) {}

    final basePath = nativePath ?? '/storage/emulated/0/Movies/AutoClip';
    final targetPath = styleFolder != null ? p.join(basePath, styleFolder) : basePath;

    final dir = Directory(targetPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
