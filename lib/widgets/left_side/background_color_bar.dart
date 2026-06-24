import 'package:flutter/material.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';
import 'package:svga_previewer/widgets/shared/preview_background_color_dialog.dart';

class BackgroundColorBar extends StatelessWidget {
  final AnimationViewModel viewModel;

  const BackgroundColorBar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('背景颜色', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _ColorPreview(color: viewModel.previewBackgroundColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatColorLabel(viewModel.previewBackgroundColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () => _openColorPicker(context),
            icon: const Icon(Icons.palette_outlined, size: 16),
            label: const Text('选择'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(76, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  String _formatColorLabel(Color color) {
    if (color.alpha == 0) {
      return '透明';
    }
    final hex = '#'
            '${color.red.toRadixString(16).padLeft(2, '0')}'
            '${color.green.toRadixString(16).padLeft(2, '0')}'
            '${color.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
    final alpha = '${((color.alpha / 255) * 100).round()}%';
    return '$hex  ·  $alpha';
  }

  Future<void> _openColorPicker(BuildContext context) async {
    final initialColor = viewModel.previewBackgroundColor;
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => PreviewBackgroundColorDialog(
        initialColor: initialColor,
        onPreviewChanged: viewModel.setPreviewBackgroundColorTemporarily,
      ),
    );

    if (selectedColor == null) {
      viewModel.setPreviewBackgroundColorTemporarily(initialColor);
      return;
    }

    await viewModel.setPreviewBackgroundColor(selectedColor);
  }
}

class _ColorPreview extends StatelessWidget {
  final Color color;

  const _ColorPreview({required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CheckerboardBackground(dividerColor: theme.dividerColor),
          if (color.alpha > 0)
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
              ),
            ),
          if (color.alpha == 0)
            Center(
              child: Transform.rotate(
                angle: -0.785398,
                child: Container(
                  width: 24,
                  height: 2,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckerboardBackground extends StatelessWidget {
  final Color dividerColor;

  const _CheckerboardBackground({required this.dividerColor});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CheckerboardPainter(
        light: Theme.of(context).colorScheme.surface,
        dark: dividerColor.withOpacity(0.45),
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  final Color light;
  final Color dark;

  const _CheckerboardPainter({
    required this.light,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const tile = 6.0;
    final lightPaint = Paint()..color = light;
    final darkPaint = Paint()..color = dark;

    for (double y = 0; y < size.height; y += tile) {
      for (double x = 0; x < size.width; x += tile) {
        final paint = (((x / tile).floor() + (y / tile).floor()) % 2 == 0)
            ? lightPaint
            : darkPaint;
        canvas.drawRect(Rect.fromLTWH(x, y, tile, tile), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter other) {
    return other.light != light || other.dark != dark;
  }
}
