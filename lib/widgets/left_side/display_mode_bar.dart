import 'package:flutter/material.dart';
import 'package:svga_previewer/models/display_mode.dart';
import 'package:svga_previewer/theme/app_theme.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';
import 'package:svgaplayer_flutter/player.dart';

class DisplayModeBar extends StatelessWidget {
  final AnimationViewModel viewModel;
  final SVGAAnimationController controller;

  const DisplayModeBar(
      {super.key, required this.viewModel, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('排版模式', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _ModeButton(
                mode: DisplayMode.showAll,
                isSelected: viewModel.mode == DisplayMode.showAll,
                onTap: () {
                  // DisplayMode oldMode = viewModel.mode;
                  viewModel.setMode(DisplayMode.showAll);
                  // 📌 切换回来会重新创建SVGAPreview重新播放，这里就不用控制动画了，后续再优化
                  // print("fffffff videoItem: ${controller.videoItem != null}, isAnimating: ${controller.isAnimating}");
                  // if (controller.videoItem != null && oldMode == DisplayMode.showBottom && controller.isAnimating == false) {
                  //   if (controller.isCompleted == true) {
                  //     controller.reset();
                  //   }
                  //   controller.repeat();
                  // }
                },
              ),
              const SizedBox(width: 10),
              _ModeButton(
                mode: DisplayMode.showTop,
                isSelected: viewModel.mode == DisplayMode.showTop,
                onTap: () {
                  // DisplayMode oldMode = viewModel.mode;
                  viewModel.setMode(DisplayMode.showTop);
                  // 📌 切换回来会重新创建SVGAPreview重新播放，这里就不用控制动画了，后续再优化
                  // print("fffffff videoItem: ${controller.videoItem != null}, isAnimating: ${controller.isAnimating}");
                  // if (controller.videoItem != null && oldMode == DisplayMode.showBottom && controller.isAnimating == false) {
                  //   if (controller.isCompleted == true) {
                  //     controller.reset();
                  //   }
                  //   controller.repeat();
                  // }
                },
              ),
              const SizedBox(width: 10),
              _ModeButton(
                mode: DisplayMode.showBottom,
                isSelected: viewModel.mode == DisplayMode.showBottom,
                onTap: () {
                  // print("fffffff videoItem: ${controller.videoItem != null}, isAnimating: ${controller.isAnimating}");
                  if (controller.videoItem != null &&
                      controller.isAnimating == true) {
                    controller.stop();
                  }
                  viewModel.setMode(DisplayMode.showBottom);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final DisplayMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appThemeColors;
    final color = isSelected ? colors.accentForeground : theme.dividerColor;

    IconData? icon;
    switch (mode) {
      case DisplayMode.showAll:
        icon = Icons.vertical_align_center;
        break;
      case DisplayMode.showTop:
        icon = Icons.vertical_align_bottom;
        break;
      case DisplayMode.showBottom:
        icon = Icons.vertical_align_top;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentForeground.withOpacity(0.14)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}
