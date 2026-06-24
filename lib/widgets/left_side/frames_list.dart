import 'package:flutter/material.dart';
import 'package:svga_previewer/theme/app_theme.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';

class FramesList extends StatelessWidget {
  final AnimationViewModel viewModel;

  const FramesList({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;

    return GridView.builder(
      key: ValueKey(viewModel.currentFileName),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.88, // 给缩略图主体更多纵向空间
      ),
      itemCount: viewModel.frames.length,
      itemBuilder: (context, index) {
        final frameInfo = viewModel.frameInfos.isNotEmpty
            ? viewModel.frameInfos[index]
            : null;
        return InkWell(
          onTap: () => viewModel.setCurrentFrameIndex(index),
          child: Container(
            decoration: BoxDecoration(
              color: colors.secondaryInfoBackground.withOpacity(0.82),
              border: index == viewModel.currentFrameIndex
                  ? Border.all(
                      color: colors.accentForeground,
                      width: 2,
                    )
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: colors.secondaryInfoBackground,
                    child: Image.file(
                      viewModel.frames[index],
                      key:
                          ValueKey('frame_${viewModel.currentFileName}_$index'),
                      fit: BoxFit.contain,
                      cacheWidth: null,
                      cacheHeight: null,
                      gaplessPlayback: false,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  color: colors.secondaryInfoBackground,
                  child: Column(
                    children: [
                      Text(
                        '图 ${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (frameInfo != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          frameInfo.fileSizeText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.warningText,
                          ),
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
}
