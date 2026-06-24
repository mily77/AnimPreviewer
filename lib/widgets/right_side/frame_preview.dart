import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui show Image;
import 'package:svga_previewer/theme/app_theme.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';

class FramePreview extends StatelessWidget {
  const FramePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appThemeColors;

    return Consumer<AnimationViewModel>(
      builder: (context, viewModel, child) {
        return Stack(
          children: [
            Container(
              margin: const EdgeInsets.all(6),
              child: Center(
                child: viewModel.currentFrame == null
                    ? const Text('无预览内容')
                    : Container(
                        decoration: BoxDecoration(
                          color: viewModel.previewBackgroundColor,
                          border: viewModel.showBorder
                              ? Border.all(
                                  color: theme.dividerColor,
                                  width: 1,
                                )
                              : null,
                          borderRadius: viewModel.showBorder
                              ? BorderRadius.circular(6)
                              : null,
                        ),
                        child: Image.file(
                          viewModel.currentFrame!,
                          key: ValueKey(
                              'preview_${viewModel.currentFileName}_${viewModel.currentFrameIndex}'),
                          fit: BoxFit.contain,
                          cacheWidth: null,
                          cacheHeight: null,
                          gaplessPlayback: false,
                        ),
                      ),
              ),
            ),
            if (viewModel.currentFrame != null)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _cardBackgroundColor(colors.infoPanelBackground),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.55),
                      width: 1,
                    ),
                  ),
                  child: viewModel.currentFrameInfo != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viewModel.currentFrame!.uri.pathSegments.last,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '图片: ${viewModel.currentFrameIndex + 1}  •  尺寸: ${viewModel.currentFrameInfo!.width} × ${viewModel.currentFrameInfo!.height}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '文件大小: ${viewModel.currentFrameInfo!.fileSizeText}  •  内存: ${viewModel.currentFrameInfo!.memoryUsageMB.toStringAsFixed(2)}MB',
                              style: TextStyle(
                                color: colors.warningText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        )
                      : FutureBuilder<ui.Image>(
                          future: viewModel.currentFrame!
                              .readAsBytes()
                              .then((bytes) => decodeImageFromList(bytes)),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final image = snapshot.data!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    viewModel
                                        .currentFrame!.uri.pathSegments.last,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '图片: ${viewModel.currentFrameIndex + 1}  •  尺寸: ${image.width} × ${image.height}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _cardBackgroundColor(Color baseColor) {
    return baseColor.withOpacity((baseColor.opacity * 0.68).clamp(0.16, 0.68));
  }
}
