import 'dart:io';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:autoclip/models/clip_segment.dart';

class GalleryService {
  static const MethodChannel _channel = MethodChannel('com.autoclip.app/native');
  static const String albumName = 'AutoClip';

  /// Save rendered MP4 clip to the Android MediaStore / Gallery under the AutoClip album.
  /// Formats filenames as Clean_01.mp4, Gaming_02.mp4, etc.
  static Future<String> saveClipToGallery(ClipSegment clip) async {
    final file = File(clip.outputPath!);
    if (!await file.exists()) {
      throw Exception('Rendered video file not found at ${clip.outputPath}');
    }

    try {
      // 1. Check & request Gal access permission
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      // 2. Save video to system gallery under 'AutoClip' album
      await Gal.putVideo(
        file.path,
        album: albumName,
      );

      // 3. Inform native MediaScanner to ensure instant visibility
      try {
        await _channel.invokeMethod('scanMediaFile', {'filePath': file.path});
      } catch (_) {
        // Native channel fallback ignored
      }

      return 'Saved to Gallery ($albumName/${clip.fileName})';
    } catch (e) {
      // Fallback: Copy to public Movies/AutoClip directory if direct Gal plugin fails
      try {
        final storageDir = await getAutoClipDirectory(styleFolder: clip.style.name);
        final targetPath = p.join(storageDir.path, clip.fileName);
        await file.copy(targetPath);

        // Scan the copied file
        try {
          await _channel.invokeMethod('scanMediaFile', {'filePath': targetPath});
        } catch (_) {}

        return targetPath;
      } catch (fallbackError) {
        throw Exception('Failed to save to gallery: $e (Fallback: $fallbackError)');
      }
    }
  }

  /// Launch the device's native Gallery app
  static Future<void> openDeviceGallery() async {
    try {
      await _channel.invokeMethod('openGallery');
    } catch (e) {
      // Fallback: Gal.open()
      try {
        await Gal.open();
      } catch (e2) {
        throw Exception('Could not open device gallery: $e2');
      }
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
