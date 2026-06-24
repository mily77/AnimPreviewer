import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:svga_previewer/models/animation_type.dart';
import 'package:svga_previewer/theme/app_theme.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';

class SVGAInfoBar extends StatelessWidget {
  const SVGAInfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimationViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.currentFileName == null) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final colors = context.appThemeColors;

        return Container(
          margin: const EdgeInsets.fromLTRB(6, 6, 6, 4),
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          decoration: BoxDecoration(
            color: _cardBackgroundColor(colors.infoPanelBackground),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.55),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(viewModel.animationType == AnimationType.lottie
                  ? Icons.animation
                  : Icons.movie_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          viewModel.currentFileName!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                viewModel.animationType == AnimationType.lottie
                                    ? colors.tagLottie
                                    : colors.tagSvga,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            viewModel.animationType == AnimationType.lottie
                                ? 'Lottie'
                                : 'SVGA',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.tagForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _infoText(viewModel),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fileSizeText(viewModel),
                      style: TextStyle(
                        color: colors.warningText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _totalFramesText(viewModel),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _infoText(AnimationViewModel viewModel) {
    return '帧率: ${viewModel.fps.toStringAsFixed(1)} FPS  •  时长: ${viewModel.duration.toStringAsFixed(2)}秒  •  分辨率: ${viewModel.frameWidth}x${viewModel.frameHeight}';
  }

  String _fileSizeText(AnimationViewModel viewModel) {
    final fileType =
        viewModel.animationType == AnimationType.lottie ? 'Lottie文件' : 'SVGA文件';
    return '$fileType: ${viewModel.svgaFileSizeText}  •  临时文件: ${viewModel.totalFileSizeMB.toStringAsFixed(1)}MB  •  内存: ${viewModel.memoryUsage.toStringAsFixed(1)}MB';
  }

  String _totalFramesText(AnimationViewModel viewModel) {
    return '总帧数: ${viewModel.totalFrames}';
  }

  Color _cardBackgroundColor(Color baseColor) {
    return baseColor.withOpacity((baseColor.opacity * 0.72).clamp(0.18, 0.72));
  }
}
