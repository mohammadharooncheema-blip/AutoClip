enum VideoQuality {
  high1080p,
  standard720p,
  fast540p,
}

extension VideoQualityExt on VideoQuality {
  String get label {
    switch (this) {
      case VideoQuality.high1080p:
        return 'High (1080 × 1920)';
      case VideoQuality.standard720p:
        return 'Standard (720 × 1280)';
      case VideoQuality.fast540p:
        return 'Fast (540 × 960)';
    }
  }

  int get width {
    switch (this) {
      case VideoQuality.high1080p:
        return 1080;
      case VideoQuality.standard720p:
        return 720;
      case VideoQuality.fast540p:
        return 540;
    }
  }

  int get height {
    switch (this) {
      case VideoQuality.high1080p:
        return 1920;
      case VideoQuality.standard720p:
        return 1280;
      case VideoQuality.fast540p:
        return 960;
    }
  }

  String get videoBitrate {
    switch (this) {
      case VideoQuality.high1080p:
        return '6000k';
      case VideoQuality.standard720p:
        return '3500k';
      case VideoQuality.fast540p:
        return '1800k';
    }
  }
}

class AppSettings {
  final VideoQuality quality;
  final String saveLocation;
  final bool autoGallerySave;
  final bool captionsEnabled;

  const AppSettings({
    this.quality = VideoQuality.high1080p,
    this.saveLocation = 'Phone Gallery > AutoClip',
    this.autoGallerySave = true,
    this.captionsEnabled = true,
  });

  AppSettings copyWith({
    VideoQuality? quality,
    String? saveLocation,
    bool? autoGallerySave,
    bool? captionsEnabled,
  }) {
    return AppSettings(
      quality: quality ?? this.quality,
      saveLocation: saveLocation ?? this.saveLocation,
      autoGallerySave: autoGallerySave ?? this.autoGallerySave,
      captionsEnabled: captionsEnabled ?? this.captionsEnabled,
    );
  }
}
