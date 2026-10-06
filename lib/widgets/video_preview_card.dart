import 'dart:io';
import 'package:flutter/material.dart';
import 'package:autoclip/theme/app_theme.dart';

class VideoPreviewCard extends StatelessWidget {
  final File? videoFile;
  final String? fileName;
  final Duration? duration;
  final String? thumbnailPath;
  final int fileSizeBytes;
  final VoidCallback onAddVideo;
  final VoidCallback onClearVideo;

  const VideoPreviewCard({
    super.key,
    required this.videoFile,
    required this.fileName,
    required this.duration,
    required this.thumbnailPath,
    required this.fileSizeBytes,
    required this.onAddVideo,
    required this.onClearVideo,
  });

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (videoFile == null) {
      // Empty state: Large ADD VIDEO button
      return InkWell(
        onTap: onAddVideo,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryLight.withOpacity(0.4),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.video_library_rounded,
                  color: AppTheme.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '+ ADD VIDEO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select any video from your phone gallery',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Selected state: Thumbnail, Filename, Duration, Size
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          // Thumbnail or Video placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              color: Colors.black38,
              child: thumbnailPath != null && File(thumbnailPath!).existsSync()
                  ? Image.file(
                      File(thumbnailPath!),
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.movie_creation_outlined,
                      color: AppTheme.accent,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName ?? 'Selected Video',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (fileSizeBytes > 0)
                      Text(
                        _formatFileSize(fileSizeBytes),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Change or Clear button
          IconButton(
            onPressed: onClearVideo,
            tooltip: 'Remove video',
            icon: const Icon(
              Icons.close_rounded,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
