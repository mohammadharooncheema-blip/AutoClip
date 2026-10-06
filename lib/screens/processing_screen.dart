import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autoclip/models/editing_style.dart';
import 'package:autoclip/providers/autoclip_provider.dart';
import 'package:autoclip/screens/results_screen.dart';
import 'package:autoclip/theme/app_theme.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _hasNavigatedToResults = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AutoClipProvider>(
      builder: (context, provider, _) {
        // Auto-navigate to ResultsScreen upon completion
        if (provider.phase == ProcessingPhase.completed && !_hasNavigatedToResults) {
          _hasNavigatedToResults = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ResultsScreen()),
            );
          });
        }

        return WillPopScope(
          onWillPop: () async {
            if (provider.isProcessing) {
              return await _showCancelConfirmDialog(context, provider);
            }
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Creating your clips...'),
              automaticallyImplyLeading: false,
              actions: [
                if (provider.isProcessing)
                  TextButton(
                    onPressed: () => _showCancelConfirmDialog(context, provider),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Card: Source video, Selected duration, Selected styles
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.video_file_outlined,
                                color: AppTheme.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.videoFileName ?? 'Source Video',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${provider.selectedClipDurationSec} SEC',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Selected Styles:',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: provider.selectedStyles.map((type) {
                              final style = EditingStyle.fromType(type);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: style.accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: style.accentColor.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  style.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: style.accentColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Overall Progress Bar & Percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${(provider.overallProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: provider.overallProgress,
                        minHeight: 12,
                        backgroundColor: AppTheme.surfaceElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Active Clip Counter (e.g. Rendering clip 3 of 12)
                    if (provider.totalClipsToRender > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Clip ${provider.currentClipIndex} of ${provider.totalClipsToRender}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 28),

                    // Progress Stages List
                    const Text(
                      'PROCESSING PIPELINE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStageItem(
                            title: 'Analyzing video...',
                            subtitle: 'Probing dimensions, scene changes & speech pauses',
                            isCompleted: provider.phase.index > ProcessingPhase.analyzing.index,
                            isActive: provider.phase == ProcessingPhase.analyzing,
                          ),
                          _buildStageItem(
                            title: 'Finding clips...',
                            subtitle: 'Splitting around ${provider.selectedClipDurationSec}s using natural cut points',
                            isCompleted: provider.phase.index > ProcessingPhase.findingClips.index,
                            isActive: provider.phase == ProcessingPhase.findingClips,
                          ),
                          _buildStageItem(
                            title: 'Applying styles...',
                            subtitle: 'Preparing 9:16 crop, zoompan and caption layers',
                            isCompleted: provider.phase.index > ProcessingPhase.applyingStyles.index,
                            isActive: provider.phase == ProcessingPhase.applyingStyles,
                          ),
                          _buildStageItem(
                            title: 'Rendering...',
                            subtitle: 'Encoding 1080×1920 MP4 video and AAC audio',
                            isCompleted: provider.phase.index > ProcessingPhase.rendering.index,
                            isActive: provider.phase == ProcessingPhase.rendering,
                          ),
                          _buildStageItem(
                            title: 'Saving to Gallery...',
                            subtitle: 'Adding directly to AutoClip album on device',
                            isCompleted: provider.phase == ProcessingPhase.completed,
                            isActive: provider.phase == ProcessingPhase.savingToGallery,
                          ),
                        ],
                      ),
                    ),

                    if (provider.phase == ProcessingPhase.error)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.statusMessage,
                                style: const TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
  }) {
    Color iconColor;
    Widget iconWidget;

    if (isCompleted) {
      iconColor = AppTheme.success;
      iconWidget = const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 22);
    } else if (isActive) {
      iconColor = AppTheme.accent;
      iconWidget = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: AppTheme.accent,
        ),
      );
    } else {
      iconColor = AppTheme.textMuted;
      iconWidget = Icon(Icons.circle_outlined, color: AppTheme.surfaceBorder, size: 22);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 2),
            child: iconWidget,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? Colors.white
                        : isCompleted
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? AppTheme.textSecondary : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showCancelConfirmDialog(BuildContext context, AutoClipProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Cancel Processing?'),
        content: const Text(
          'Video processing will stop and partial clips will be discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Processing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (result == true) {
      await provider.cancelProcessing();
      if (context.mounted) {
        Navigator.pop(context);
      }
      return true;
    }
    return false;
  }
}
