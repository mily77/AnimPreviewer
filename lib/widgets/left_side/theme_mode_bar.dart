import 'package:flutter/material.dart';
import 'package:svga_previewer/models/app_theme_mode.dart';
import 'package:svga_previewer/theme/app_theme.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';

class ThemeModeBar extends StatelessWidget {
  final AnimationViewModel viewModel;

  const ThemeModeBar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = context.appThemeColors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
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
          const Text('主题模式:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 4),
              _ThemeModeButton(
                label: '系统',
                icon: Icons.brightness_auto,
                isSelected: viewModel.themeMode == AppThemeMode.system,
                accentColor: colors.accentForeground,
                borderColor: theme.dividerColor,
                onTap: () => viewModel.setThemeMode(AppThemeMode.system),
              ),
              const SizedBox(width: 8),
              _ThemeModeButton(
                label: '浅色',
                icon: Icons.light_mode_outlined,
                isSelected: viewModel.themeMode == AppThemeMode.light,
                accentColor: colors.accentForeground,
                borderColor: theme.dividerColor,
                onTap: () => viewModel.setThemeMode(AppThemeMode.light),
              ),
              const SizedBox(width: 8),
              _ThemeModeButton(
                label: '深色',
                icon: Icons.dark_mode_outlined,
                isSelected: viewModel.themeMode == AppThemeMode.dark,
                accentColor: colors.accentForeground,
                borderColor: theme.dividerColor,
                onTap: () => viewModel.setThemeMode(AppThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ThemeModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? accentColor : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
            color: isSelected ? accentColor.withOpacity(0.08) : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected ? accentColor : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? accentColor : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
