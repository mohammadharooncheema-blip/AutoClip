import 'package:autoclip/models/editing_style.dart';

enum ClipStatus {
  pending,
  analyzing,
  rendering,
  saving,
  completed,
  failed,
}

class ClipSegment {
  final String id;
  final int cutIndex; // 1-based source segment cut number (e.g. 1, 2, 3)
  final Duration startTime;
  final Duration endTime;
  final Duration duration;
  final EditingStyle style;
  
  ClipStatus status;
  double renderProgress; // 0.0 to 1.0
  String? outputPath;
  String? thumbnailPath;
  String? galleryUri;
  String? errorMessage;

  ClipSegment({
    required this.id,
    required this.cutIndex,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.style,
    this.status = ClipStatus.pending,
    this.renderProgress = 0.0,
    this.outputPath,
    this.thumbnailPath,
    this.galleryUri,
    this.errorMessage,
  });

  /// Name of the finished file conforming to specification:
  /// e.g. Clean_01.mp4, Gaming_02.mp4
  String get fileName {
    final paddedIndex = cutIndex.toString().padLeft(2, '0');
    return '${style.name}_$paddedIndex.mp4';
  }

  String get formattedDuration {
    final seconds = duration.inMilliseconds / 1000.0;
    return '${seconds.toStringAsFixed(1)}s';
  }

  String get timeRangeLabel {
    final startStr = _formatTime(startTime);
    final endStr = _formatTime(endTime);
    return '$startStr - $endStr';
  }

  static String _formatTime(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  ClipSegment copyWith({
    ClipStatus? status,
    double? renderProgress,
    String? outputPath,
    String? thumbnailPath,
    String? galleryUri,
    String? errorMessage,
  }) {
    return ClipSegment(
      id: id,
      cutIndex: cutIndex,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      style: style,
      status: status ?? this.status,
      renderProgress: renderProgress ?? this.renderProgress,
      outputPath: outputPath ?? this.outputPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      galleryUri: galleryUri ?? this.galleryUri,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
