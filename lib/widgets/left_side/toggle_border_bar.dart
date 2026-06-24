import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:svga_previewer/theme/app_theme.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';

class ToggleBorderBar extends StatelessWidget {
  final AnimationViewModel viewModel;

  const ToggleBorderBar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appThemeColors;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 0, 2),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text('显示边框:', style: TextStyle(fontSize: 12)),
          const Spacer(),
          Transform.scale(
            scale: 0.7,
            child: CupertinoSwitch(
              value: viewModel.showBorder,
              onChanged: (value) async => await viewModel.setShowBorder(value),
              activeColor: colors.accentForeground,
            ),
          ),
        ],
      ),
    );
  }
}
