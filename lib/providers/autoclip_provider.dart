import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:autoclip/models/app_settings.dart';
import 'package:autoclip/models/clip_segment.dart';
import 'package:autoclip/models/editing_style.dart';
import 'package:autoclip/services/ffmpeg_service.dart';
import 'package:autoclip/services/gallery_service.dart';
import 'package:autoclip/services/video_analyzer_service.dart';

enum ProcessingPhase {
  idle,
  analyzing,
  findingClips,
  applyingStyles,
  rendering,
  savingToGallery,
  completed,
  cancelled,
  error,
}

class AutoClipProvider extends ChangeNotifier {
  // Source Video State
  File? _selectedVideoFile;
  String? _videoFileName;
  Duration? _videoDuration;
  String? _videoThumbnailPath;
  int _videoFileSizeBytes = 0;

  // Configuration State
  int _selectedClipDurationSec = 25; // Allowed: 20, 25, 30. Default: 25.
  final Set<StyleType> _selectedStyles = {StyleType.clean};
  AppSettings _settings = const AppSettings();

  // Processing State
  ProcessingPhase _phase = ProcessingPhase.idle;
  String _statusMessage = '';
  double _overallProgress = 0.0;
  int _currentClipIndex = 0;
  int _totalClipsToRender = 0;
  bool _isCancelled = false;

  // Results State
  List<ClipSegment> _generatedClips = [];

  // Getters
  File? get selectedVideoFile => _selectedVideoFile;
  String? get videoFileName => _videoFileName;
  Duration? get videoDuration => _videoDuration;
  String? get videoThumbnailPath => _videoThumbnailPath;
  int get videoFileSizeBytes => _videoFileSizeBytes;
  int get selectedClipDurationSec => _selectedClipDurationSec;
  Set<StyleType> get selectedStyles => _selectedStyles;
  AppSettings get settings => _settings;
  ProcessingPhase get phase => _phase;
  String get statusMessage => _statusMessage;
  double get overallProgress => _overallProgress;
  int get currentClipIndex => _currentClipIndex;
  int get totalClipsToRender => _totalClipsToRender;
  List<ClipSegment> get generatedClips => _generatedClips;

  bool get isProcessing =>
      _phase == ProcessingPhase.analyzing ||
      _phase == ProcessingPhase.findingClips ||
      _phase == ProcessingPhase.applyingStyles ||
      _phase == ProcessingPhase.rendering ||
      _phase == ProcessingPhase.savingToGallery;

  /// Button is enabled ONLY when:
  /// 1. A video has been selected
  /// 2. A clip duration has been selected
  /// 3. At least one editing style has been selected
  bool get canCreateClips =>
      _selectedVideoFile != null &&
      _selectedClipDurationSec > 0 &&
      _selectedStyles.isNotEmpty &&
      !isProcessing;

  /// Estimated number of clips that will be produced
  int get estimatedClipCount {
    if (_videoDuration == null || _selectedStyles.isEmpty) return 0;
    final totalSec = _videoDuration!.inSeconds;
    final cuts = (totalSec / _selectedClipDurationSec).ceil().clamp(1, 100);
    return cuts * _selectedStyles.length;
  }

  // Actions

  /// Pick video from phone gallery
  Future<void> pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(hours: 2),
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      _selectedVideoFile = file;
      _videoFileName = p.basename(file.path);
      _videoFileSizeBytes = await file.length();

      // Probe metadata
      final metadata = await VideoAnalyzerService.probeVideo(file.path);
      _videoDuration = metadata.duration;

      // Generate preview thumbnail
      try {
        _videoThumbnailPath = await FFmpegService.generateThumbnail(
          file.path,
          'source_preview',
        );
      } catch (_) {}

      notifyListeners();
    }
  }

  void clearSelectedVideo() {
    _selectedVideoFile = null;
    _videoFileName = null;
    _videoDuration = null;
    _videoThumbnailPath = null;
    _videoFileSizeBytes = 0;
    notifyListeners();
  }

  /// Clip Length: Only 20, 25, 30 allowed
  void setClipDuration(int seconds) {
    if (seconds == 20 || seconds == 25 || seconds == 30) {
      _selectedClipDurationSec = seconds;
      notifyListeners();
    }
  }

  /// Toggle Editing Style selection
  void toggleStyle(StyleType style) {
    if (_selectedStyles.contains(style)) {
      if (_selectedStyles.length > 1) {
        _selectedStyles.remove(style);
      }
      // Keep at least one selected if tapped again, or toggle
    } else {
      _selectedStyles.add(style);
    }
    notifyListeners();
  }

  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  /// Cancel current processing
  Future<void> cancelProcessing() async {
    _isCancelled = true;
    _phase = ProcessingPhase.cancelled;
    _statusMessage = 'Processing cancelled';
    notifyListeners();

    await FFmpegService.cancelActiveSession();
  }

  /// Main creation pipeline
  Future<void> startCreatingClips() async {
    if (!canCreateClips) return;

    _isCancelled = false;
    _overallProgress = 0.0;
    _currentClipIndex = 0;
    _generatedClips = [];

    try {
      // Step 1: Analyzing video
      _phase = ProcessingPhase.analyzing;
      _statusMessage = 'Analyzing video...';
      _overallProgress = 0.05;
      notifyListeners();

      final naturalCuts = await VideoAnalyzerService.detectNaturalCutPoints(
        _selectedVideoFile!.path,
      );

      if (_isCancelled) return;

      // Step 2: Finding clips
      _phase = ProcessingPhase.findingClips;
      _statusMessage = 'Finding clips with natural cut points...';
      _overallProgress = 0.15;
      notifyListeners();

      final cutBoundaries = VideoAnalyzerService.calculateOptimalCuts(
        totalDuration: _videoDuration!,
        targetDurationSeconds: _selectedClipDurationSec,
        naturalCutPoints: naturalCuts,
      );

      if (_isCancelled) return;

      // Step 3: Applying styles (build clip segments matrix: cuts × styles)
      _phase = ProcessingPhase.applyingStyles;
      _statusMessage = 'Applying styles...';
      _overallProgress = 0.20;
      notifyListeners();

      final clipsToRender = <ClipSegment>[];
      int cutNumber = 1;

      for (final cut in cutBoundaries) {
        for (final styleType in _selectedStyles) {
          final style = EditingStyle.fromType(styleType);
          clipsToRender.add(
            ClipSegment(
              id: 'clip_${cutNumber}_${style.id}',
              cutIndex: cutNumber,
              startTime: cut.start,
              endTime: cut.end,
              duration: cut.duration,
              style: style,
            ),
          );
        }
        cutNumber++;
      }

      _totalClipsToRender = clipsToRender.length;
      _generatedClips = List.from(clipsToRender);
      notifyListeners();

      if (_isCancelled) return;

      // Step 4: Rendering and Saving clips
      _phase = ProcessingPhase.rendering;
      _statusMessage = 'Rendering clips...';
      notifyListeners();

      const baseProgress = 0.25;
      const renderBudget = 0.70; // 25% to 95%

      for (int i = 0; i < clipsToRender.length; i++) {
        if (_isCancelled) return;

        final clip = clipsToRender[i];
        _currentClipIndex = i + 1;
        clip.status = ClipStatus.rendering;
        _statusMessage =
            'Rendering clip $_currentClipIndex of $_totalClipsToRender (${clip.style.name})...';
        notifyListeners();

        try {
          // Render video through FFmpeg
          final renderedFile = await FFmpegService.renderClip(
            sourceVideoPath: _selectedVideoFile!.path,
            clip: clip,
            settings: _settings,
            onProgress: (clipProgress) {
              final stepProgress = (i + clipProgress) / _totalClipsToRender;
              _overallProgress = baseProgress + (stepProgress * renderBudget);
              clip.renderProgress = clipProgress;
              notifyListeners();
            },
          );

          clip.outputPath = renderedFile.path;

          // Extract thumbnail
          try {
            clip.thumbnailPath = await FFmpegService.generateThumbnail(
              renderedFile.path,
              clip.id,
            );
          } catch (_) {}

          // Step 5: Save to Gallery
          if (_settings.autoGallerySave) {
            clip.status = ClipStatus.saving;
            _statusMessage =
                'Saving clip $_currentClipIndex (${clip.style.name}) to Gallery...';
            notifyListeners();

            try {
              final galleryPath = await GalleryService.saveClipToGallery(clip);
              clip.galleryUri = galleryPath;
            } catch (galleryError) {
              debugPrint('Gallery save notice: $galleryError');
            }
          }

          clip.status = ClipStatus.completed;
          clip.renderProgress = 1.0;
        } catch (clipError) {
          // Robust error handling: Mark this clip failed, continue remaining
          clip.status = ClipStatus.failed;
          clip.errorMessage = clipError.toString();
          debugPrint('Failed to render ${clip.fileName}: $clipError');
        }

        final stepProgress = (i + 1) / _totalClipsToRender;
        _overallProgress = baseProgress + (stepProgress * renderBudget);
        notifyListeners();
      }

      if (_isCancelled) return;

      // Finished!
      _phase = ProcessingPhase.completed;
      _overallProgress = 1.0;
      _statusMessage = 'Done!';
      notifyListeners();
    } catch (e) {
      if (!_isCancelled) {
        _phase = ProcessingPhase.error;
        _statusMessage = 'Error creating clips: $e';
        notifyListeners();
      }
    }
  }

  /// Reset state to create more clips
  void resetForNewClips() {
    _phase = ProcessingPhase.idle;
    _statusMessage = '';
    _overallProgress = 0.0;
    _currentClipIndex = 0;
    _totalClipsToRender = 0;
    _isCancelled = false;
    _generatedClips = [];
    notifyListeners();
  }
}
