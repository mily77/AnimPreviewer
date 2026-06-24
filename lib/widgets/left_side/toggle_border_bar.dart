import 'package:flutter/cupertino.dart';
import 'package:svga_previewer/theme/app_theme.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';

class ToggleBorderBar extends StatelessWidget {
  final AnimationViewModel viewModel;

  const ToggleBorderBar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
      child: Row(
        children: [
          const Expanded(
            child: Text('显示边框', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Transform.scale(
            scale: 0.66,
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
