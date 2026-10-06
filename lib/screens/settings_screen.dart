import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autoclip/models/app_settings.dart';
import 'package:autoclip/providers/autoclip_provider.dart';
import 'package:autoclip/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AutoClipProvider>(
      builder: (context, provider, _) {
        final settings = provider.settings;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 1. Output Quality
                _buildSectionHeader('OUTPUT QUALITY'),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Column(
                    children: VideoQuality.values.map((q) {
                      final isSelected = settings.quality == q;
                      return RadioListTile<VideoQuality>(
                        value: q,
                        groupValue: settings.quality,
                        onChanged: (newQ) {
                          if (newQ != null) {
                            provider.updateSettings(
                              settings.copyWith(quality: newQ),
                            );
                          }
                        },
                        activeColor: AppTheme.accent,
                        title: Text(
                          q.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          q == VideoQuality.high1080p
                              ? 'Default vertical 9:16 portrait standard'
                              : q == VideoQuality.standard720p
                                  ? 'Faster processing, balanced size'
                                  : 'Fastest processing on older phones',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Save Location
                _buildSectionHeader('SAVE LOCATION'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.folder_outlined, color: AppTheme.accent, size: 24),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Gallery > AutoClip Album',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Movies/AutoClip/{StyleName}/',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Auto Gallery Save & Caption On/Off Toggles
                _buildSectionHeader('AUTOMATION'),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      // Auto Gallery Save
                      SwitchListTile(
                        value: settings.autoGallerySave,
                        onChanged: (val) {
                          provider.updateSettings(
                            settings.copyWith(autoGallerySave: val),
                          );
                        },
                        activeColor: AppTheme.accent,
                        title: const Text(
                          'Auto Gallery Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: const Text(
                          'Automatically save rendered clips to phone gallery',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),

                      // Caption On/Off
                      SwitchListTile(
                        value: settings.captionsEnabled,
                        onChanged: (val) {
                          provider.updateSettings(
                            settings.copyWith(captionsEnabled: val),
                          );
                        },
                        activeColor: AppTheme.accent,
                        title: const Text(
                          'Captions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: const Text(
                          'Burn styled captions into videos according to selected preset',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // App Info
                const Center(
                  child: Text(
                    'AutoClip v1.0.0 • Clean & Fast Video Clipper',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
