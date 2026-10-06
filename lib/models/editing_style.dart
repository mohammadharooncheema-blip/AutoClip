import 'package:flutter/material.dart';

enum StyleType {
  clean,
  fast,
  gaming,
  dynamicStyle,
  minimal,
}

class EditingStyle {
  final StyleType type;
  final String id;
  final String name;
  final String tagline;
  final String description;
  final IconData icon;
  final Color accentColor;

  // Video processing preset configurations
  final double zoomIntensity; // 1.0 = none, 1.05 = subtle, 1.15 = punch
  final String zoomMode; // 'subtle', 'fast', 'punch', 'smooth_wave', 'static'
  final double playbackSpeed; // 1.0 = normal, 1.04 = fast pacing
  final String colorFilter; // FFmpeg eq filter
  final String captionStyleKey; // Style key for caption rendering
  final bool enableAudioEnhance; // Audio compression/loudness normalization
  final bool enableActionTransitions;

  const EditingStyle({
    required this.type,
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.zoomIntensity,
    required this.zoomMode,
    this.playbackSpeed = 1.0,
    required this.colorFilter,
    required this.captionStyleKey,
    this.enableAudioEnhance = true,
    this.enableActionTransitions = false,
  });

  /// Preset 1: CLEAN
  /// 9:16 vertical output, clean crop, subtle zoom, clean captions, simple visual adjustments
  static const EditingStyle clean = EditingStyle(
    type: StyleType.clean,
    id: 'clean',
    name: 'Clean',
    tagline: 'Polished & Elegant',
    description: '9:16 crop, subtle slow zoom, elegant captions & balanced color.',
    icon: Icons.auto_awesome,
    accentColor: Color(0xFF38BDF8), // Sky blue
    zoomIntensity: 1.05,
    zoomMode: 'subtle',
    colorFilter: 'eq=contrast=1.05:saturation=1.08:brightness=0.01',
    captionStyleKey: 'clean',
    enableAudioEnhance: true,
  );

  /// Preset 2: FAST
  /// 9:16 vertical output, faster visual pacing, dynamic crop, moderate zoom, caption animation
  static const EditingStyle fast = EditingStyle(
    type: StyleType.fast,
    id: 'fast',
    name: 'Fast',
    tagline: 'High Energy & Pacing',
    description: 'Faster visual tempo, dynamic crop, punchy zoom & animated captions.',
    icon: Icons.bolt,
    accentColor: Color(0xFFFACC15), // Vibrant Yellow
    zoomIntensity: 1.12,
    zoomMode: 'fast',
    playbackSpeed: 1.04,
    colorFilter: 'eq=contrast=1.12:saturation=1.18:gamma=1.02',
    captionStyleKey: 'fast',
    enableAudioEnhance: true,
  );

  /// Preset 3: GAMING
  /// 9:16 vertical output, gaming-style crop, punch zooms, gaming captions, punchy audio
  static const EditingStyle gaming = EditingStyle(
    type: StyleType.gaming,
    id: 'gaming',
    name: 'Gaming',
    tagline: 'Action & Highlights',
    description: 'Action-focused crop, punch zooms, vibrant neon captions & punchy audio.',
    icon: Icons.sports_esports,
    accentColor: Color(0xFFA855F7), // Purple / Magenta
    zoomIntensity: 1.18,
    zoomMode: 'punch',
    colorFilter: 'eq=contrast=1.18:saturation=1.25:gamma=0.96',
    captionStyleKey: 'gaming',
    enableAudioEnhance: true,
    enableActionTransitions: true,
  );

  /// Preset 4: DYNAMIC
  /// 9:16 vertical output, dynamic reframing, smooth zooms, caption animation, subtle transitions
  static const EditingStyle dynamicPreset = EditingStyle(
    type: StyleType.dynamicStyle,
    id: 'dynamic',
    name: 'Dynamic',
    tagline: 'Motion & Fluidity',
    description: 'Smooth reframing, rhythmic wave zooms, pop captions & soft transitions.',
    icon: Icons.waves,
    accentColor: Color(0xFF10B981), // Emerald
    zoomIntensity: 1.08,
    zoomMode: 'smooth_wave',
    colorFilter: 'eq=contrast=1.08:saturation=1.12:brightness=0.01',
    captionStyleKey: 'dynamic',
    enableAudioEnhance: true,
    enableActionTransitions: true,
  );

  /// Preset 5: MINIMAL
  /// 9:16 vertical output, clean crop, minimal effects, simple captions
  static const EditingStyle minimal = EditingStyle(
    type: StyleType.minimal,
    id: 'minimal',
    name: 'Minimal',
    tagline: 'Pure & Unaltered',
    description: 'Exact 9:16 crop, untouched camera motion, clean understated subtitles.',
    icon: Icons.crop_portrait,
    accentColor: Color(0xFF94A3B8), // Cool Slate
    zoomIntensity: 1.0,
    zoomMode: 'static',
    colorFilter: '', // No color distortion
    captionStyleKey: 'minimal',
    enableAudioEnhance: false,
  );

  static const List<EditingStyle> all = [
    clean,
    fast,
    gaming,
    dynamicPreset,
    minimal,
  ];

  static EditingStyle fromType(StyleType type) {
    switch (type) {
      case StyleType.clean:
        return clean;
      case StyleType.fast:
        return fast;
      case StyleType.gaming:
        return gaming;
      case StyleType.dynamicStyle:
        return dynamicPreset;
      case StyleType.minimal:
        return minimal;
    }
  }

  static EditingStyle fromId(String id) {
    return all.firstWhere(
      (s) => s.id == id,
      orElse: () => clean,
    );
  }
}
