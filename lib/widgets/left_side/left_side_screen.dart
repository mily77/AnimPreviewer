import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:svga_previewer/models/animation_type.dart';
import 'package:svga_previewer/models/display_mode.dart';
import 'package:svga_previewer/theme/app_theme.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';
import 'package:svga_previewer/widgets/left_side/background_color_bar.dart';
import 'package:svga_previewer/widgets/left_side/display_mode_bar.dart';
import 'package:svga_previewer/widgets/left_side/frames_list.dart';
import 'package:svga_previewer/widgets/left_side/svga_control_bar.dart';
import 'package:svga_previewer/widgets/left_side/theme_mode_bar.dart';
import 'package:svga_previewer/widgets/left_side/toggle_border_bar.dart';
import 'package:svgaplayer_flutter/player.dart';

class LeftSideScreen extends StatefulWidget {
  final SVGAAnimationController controller;

  const LeftSideScreen({super.key, required this.controller});

  @override
  State<LeftSideScreen> createState() => _LeftSideScreenState();
}

class _LeftSideScreenState extends State<LeftSideScreen> {
  static const double _groupRadius = 18;
  static const double _jointRadius = 10;
  bool _isSettingsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appThemeColors;

    return Consumer<AnimationViewModel>(
      builder: (context, viewModel, child) {
        final showPlaybackControls =
            (viewModel.svgaFile != null || viewModel.lottieFile != null) &&
                viewModel.mode != DisplayMode.showBottom;
        final bottomGroupColor = theme.colorScheme.surfaceContainerLow;
        final handleColor = colors.infoPanelBackground.withOpacity(
          theme.brightness == Brightness.dark ? 0.64 : 0.88,
        );
        final expandedGroupShadow = [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.16 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ];

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: ClipRect(
                  child: viewModel.frames.isEmpty
                      ? _buildPlaceholder(viewModel)
                      : FramesList(viewModel: viewModel),
                ),
              ),
            ),
            if (showPlaybackControls)
              Container(
                margin: EdgeInsets.fromLTRB(
                  10,
                  0,
                  10,
                  _isSettingsExpanded ? 0 : 5,
                ),
                decoration: BoxDecoration(
                  color: bottomGroupColor,
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(_groupRadius),
                    bottom: Radius.circular(
                      _isSettingsExpanded ? _jointRadius : _groupRadius,
                    ),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor.withOpacity(0.55),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: theme.dividerColor.withOpacity(0.55),
                      width: 1,
                    ),
                    right: BorderSide(
                      color: theme.dividerColor.withOpacity(0.55),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: theme.dividerColor.withOpacity(
                        _isSettingsExpanded ? 0.20 : 0.55,
                      ),
                      width: 1,
                    ),
                  ),
                  boxShadow: _isSettingsExpanded
                      ? null
                      : theme.brightness == Brightness.light
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
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(_groupRadius),
                    bottom: Radius.circular(
                      _isSettingsExpanded ? _jointRadius : _groupRadius,
                    ),
                  ),
                  child: SVGAControlBar(
                    viewModel: viewModel,
                    controller: widget.controller,
                  ),
                ),
              ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSettingsExpanded = !_isSettingsExpanded;
                });
              },
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  10,
                  0,
                  10,
                  _isSettingsExpanded ? 0 : 8,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: _isSettingsExpanded ? 7 : 8,
                ),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      showPlaybackControls ? _jointRadius : _groupRadius - 2,
                    ),
                    bottom: Radius.circular(
                      _isSettingsExpanded ? _jointRadius : _groupRadius - 2,
                    ),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor.withOpacity(
                        showPlaybackControls ? 0.18 : 0.45,
                      ),
                      width: showPlaybackControls ? 0.8 : 1,
                    ),
                    left: BorderSide(
                      color: theme.dividerColor.withOpacity(0.45),
                      width: 1,
                    ),
                    right: BorderSide(
                      color: theme.dividerColor.withOpacity(0.45),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: theme.dividerColor.withOpacity(
                        _isSettingsExpanded ? 0.18 : 0.45,
                      ),
                      width: _isSettingsExpanded ? 0.8 : 1,
                    ),
                  ),
                  boxShadow: !showPlaybackControls && !_isSettingsExpanded
                      ? expandedGroupShadow
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.55),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        Icons.tune,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '显示设置',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isSettingsExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        size: 17,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _isSettingsExpanded
                  ? Container(
                      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        color: bottomGroupColor.withOpacity(
                          theme.brightness == Brightness.dark ? 0.92 : 0.97,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(_groupRadius),
                        ),
                        border: Border(
                          left: BorderSide(
                            color: theme.dividerColor.withOpacity(0.55),
                            width: 1,
                          ),
                          right: BorderSide(
                            color: theme.dividerColor.withOpacity(0.55),
                            width: 1,
                          ),
                          bottom: BorderSide(
                            color: theme.dividerColor.withOpacity(0.55),
                            width: 1,
                          ),
                        ),
                        boxShadow: expandedGroupShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(_groupRadius),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ToggleBorderBar(viewModel: viewModel),
                              _buildSectionDivider(theme),
                              BackgroundColorBar(viewModel: viewModel),
                              _buildSectionDivider(theme),
                              ThemeModeBar(viewModel: viewModel),
                              _buildSectionDivider(theme),
                              DisplayModeBar(
                                viewModel: viewModel,
                                controller: widget.controller,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder(AnimationViewModel viewModel) {
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
    }

    final animationType = viewModel.animationType;
    final fileType = animationType == AnimationType.lottie ? 'Lottie' : 'SVGA';
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 182),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withOpacity(0.55),
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

  Widget _buildSectionDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.dividerColor.withOpacity(0.45),
    );
  }
}
