import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autoclip/models/editing_style.dart';
import 'package:autoclip/providers/autoclip_provider.dart';
import 'package:autoclip/screens/processing_screen.dart';
import 'package:autoclip/screens/settings_screen.dart';
import 'package:autoclip/theme/app_theme.dart';
import 'package:autoclip/widgets/clip_length_selector.dart';
import 'package:autoclip/widgets/style_card.dart';
import 'package:autoclip/widgets/video_preview_card.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AutoClipProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AutoClip',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Turn one video into multiple ready-to-use clips.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. ADD VIDEO / Selected Video Preview
                        VideoPreviewCard(
                          videoFile: provider.selectedVideoFile,
                          fileName: provider.videoFileName,
                          duration: provider.videoDuration,
                          thumbnailPath: provider.videoThumbnailPath,
                          fileSizeBytes: provider.videoFileSizeBytes,
                          onAddVideo: () => provider.pickVideo(),
                          onClearVideo: () => provider.clearSelectedVideo(),
                        ),

                        const SizedBox(height: 24),

                        // 2. CLIP LENGTH
                        ClipLengthSelector(
                          selectedSeconds: provider.selectedClipDurationSec,
                          onSelected: (sec) => provider.setClipDuration(sec),
                        ),

                        const SizedBox(height: 28),

                        // 3. EDITING STYLES
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'EDITING STYLES',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '${provider.selectedStyles.length} selected',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Ready-made style cards
                        ...EditingStyle.all.map((style) {
                          final isSelected = provider.selectedStyles.contains(style.type);
                          return StyleCard(
                            style: style,
                            isSelected: isSelected,
                            onTap: () => provider.toggleStyle(style.type),
                          );
                        }),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // 4. CREATE CLIPS BUTTON (Sticky at bottom)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(
                      top: BorderSide(color: AppTheme.surfaceBorder, width: 1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: provider.canCreateClips
                              ? () {
                                  provider.startCreatingClips();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProcessingScreen(),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: provider.canCreateClips
                                ? AppTheme.primary
                                : AppTheme.surfaceBorder,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.surfaceElevated,
                            disabledForegroundColor: AppTheme.textMuted,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 20,
                                color: provider.canCreateClips
                                    ? Colors.white
                                    : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                provider.canCreateClips && provider.estimatedClipCount > 0
                                    ? 'CREATE ${provider.estimatedClipCount} CLIPS'
                                    : 'CREATE CLIPS',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!provider.canCreateClips) ...[
                        const SizedBox(height: 8),
                        Text(
                          _getDisabledReason(provider),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDisabledReason(AutoClipProvider provider) {
    if (provider.selectedVideoFile == null) {
      return 'Add a video to begin';
    }
    if (provider.selectedStyles.isEmpty) {
      return 'Select at least one editing style';
    }
    return '';
  }
}
