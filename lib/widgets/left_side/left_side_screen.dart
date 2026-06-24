import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:svga_previewer/models/animation_type.dart';
import 'package:svga_previewer/models/display_mode.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';
import 'package:svga_previewer/widgets/left_side/background_color_bar.dart';
import 'package:svga_previewer/widgets/left_side/display_mode_bar.dart';
import 'package:svga_previewer/widgets/left_side/frames_list.dart';
import 'package:svga_previewer/widgets/left_side/svga_control_bar.dart';
import 'package:svga_previewer/widgets/left_side/theme_mode_bar.dart';
import 'package:svga_previewer/widgets/left_side/toggle_border_bar.dart';
import 'package:svgaplayer_flutter/player.dart';

class LeftSideScreen extends StatelessWidget {
  final SVGAAnimationController controller;

  const LeftSideScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AnimationViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: _buildWidgets(context, viewModel, controller, theme),
        );
      },
    );
  }

  List<Widget> _buildWidgets(
    BuildContext context,
    AnimationViewModel viewModel,
    SVGAAnimationController controller,
    ThemeData theme,
  ) {
    List<Widget> list = [
      // 动画图片列表
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: ClipRect(
            child: viewModel.frames.isEmpty
                ? _buildPlaceholder(viewModel)
                : FramesList(
                    viewModel: viewModel,
                  ),
          ),
        ),
      ),
    ];
    final settingsChildren = <Widget>[
      if ((viewModel.svgaFile != null || viewModel.lottieFile != null) &&
          viewModel.mode != DisplayMode.showBottom) ...[
        SVGAControlBar(viewModel: viewModel, controller: controller),
        _buildSectionDivider(theme),
      ],
      ToggleBorderBar(viewModel: viewModel),
      _buildSectionDivider(theme),
      BackgroundColorBar(viewModel: viewModel),
      _buildSectionDivider(theme),
      ThemeModeBar(viewModel: viewModel),
      _buildSectionDivider(theme),
      DisplayModeBar(viewModel: viewModel, controller: controller),
    ];

    list.add(
      Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.55),
            width: 1,
          ),
          boxShadow: theme.brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(children: settingsChildren),
        ),
      ),
    );
    return list;
  }

  Widget _buildPlaceholder(AnimationViewModel viewModel) {
    // 判断是否有加载的动画文件
    final hasAnimationFile =
        viewModel.svgaFile != null || viewModel.lottieFile != null;

    if (!hasAnimationFile) {
      return const Center(
        child: Text(
          '图片列表',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    } else {
      // 根据动画类型显示不同的提示
      final animationType = viewModel.animationType;
      final fileType =
          animationType == AnimationType.lottie ? 'Lottie' : 'SVGA';
      return Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 182),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceContainerHigh.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '该$fileType文件并未包含图片',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildSectionDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.dividerColor.withOpacity(0.45),
    );
  }
}
