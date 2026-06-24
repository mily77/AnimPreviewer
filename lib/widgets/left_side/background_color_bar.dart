import 'package:flutter/material.dart';
import 'package:svga_previewer/theme/app_theme.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';

class BackgroundColorBar extends StatelessWidget {
  final AnimationViewModel viewModel;

  const BackgroundColorBar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appThemeColors;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('背景颜色:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ColorButton(
                color: Colors.transparent,
                isSelected: viewModel.previewBackgroundColor == Colors.transparent,
                onTap: () async => await viewModel.setPreviewBackgroundColor(Colors.transparent),
              ),
              _ColorButton(
                color: Colors.black,
                isSelected: viewModel.previewBackgroundColor == Colors.black,
                onTap: () async => await viewModel.setPreviewBackgroundColor(Colors.black),
              ),
              _ColorButton(
                color: Colors.white,
                isSelected: viewModel.previewBackgroundColor == Colors.white,
                onTap: () async => await viewModel.setPreviewBackgroundColor(Colors.white),
              ),
              _ColorButton(
                color: Colors.grey,
                isSelected: viewModel.previewBackgroundColor == Colors.grey,
                onTap: () async => await viewModel.setPreviewBackgroundColor(Colors.grey),
              ),
              _ColorButton(
                color: Colors.deepPurpleAccent.shade100,
                isSelected: viewModel.previewBackgroundColor == Colors.deepPurpleAccent.shade100,
                onTap: () async => await viewModel.setPreviewBackgroundColor(Colors.deepPurpleAccent.shade100),
                selectedColor: colors.accentForeground,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (selectedColor ?? theme.colorScheme.primary)
                : theme.dividerColor,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: color == Colors.transparent ? Center(
          child: Transform.rotate(
            angle: -0.785398,
            child: Container(
              width: 28,
              height: 2,
              color: Colors.red,
            ),
          ),
        ) : null,
      ),
    );
  }
} 
