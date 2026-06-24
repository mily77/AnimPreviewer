import 'dart:math' as math;

import 'package:flutter/material.dart';

class PreviewBackgroundColorDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onPreviewChanged;

  const PreviewBackgroundColorDialog({
    super.key,
    required this.initialColor,
    required this.onPreviewChanged,
  });

  @override
  State<PreviewBackgroundColorDialog> createState() =>
      _PreviewBackgroundColorDialogState();
}

class _PreviewBackgroundColorDialogState
    extends State<PreviewBackgroundColorDialog> {
  late HSVColor _hsvColor;
  late double _alpha;
  late bool _isTransparent;

  @override
  void initState() {
    super.initState();
    _isTransparent = widget.initialColor.alpha == 0;
    final baseColor = _isTransparent
        ? const Color(0xFFFFFFFF)
        : widget.initialColor.withAlpha(255);
    _hsvColor = HSVColor.fromColor(baseColor);
    _alpha = widget.initialColor.alpha / 255;
  }

  Color get _effectiveColor {
    if (_isTransparent) {
      return Colors.transparent;
    }
    final color = _hsvColor.toColor();
    return Color.fromARGB(
      (_alpha * 255).round().clamp(0, 255),
      color.red,
      color.green,
      color.blue,
    );
  }

  String get _colorLabel {
    if (_isTransparent) {
      return '透明';
    }
    final color = _effectiveColor;
    return '#'
            '${color.red.toRadixString(16).padLeft(2, '0')}'
            '${color.green.toRadixString(16).padLeft(2, '0')}'
            '${color.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  String get _alphaLabel {
    if (_isTransparent) {
      return '0%';
    }
    return '${(_alpha * 100).round()}%';
  }

  void _updatePreview() {
    widget.onPreviewChanged(_effectiveColor);
  }

  void _setPalettePosition(Offset position, Size size) {
    final width = math.max(size.width, 1);
    final height = math.max(size.height, 1);
    final dx = position.dx.clamp(0.0, width);
    final dy = position.dy.clamp(0.0, height);

    setState(() {
      _isTransparent = false;
      _hsvColor =
          _hsvColor.withSaturation(dx / width).withValue(1 - (dy / height));
      if (_alpha == 0) {
        _alpha = 1;
      }
    });
    _updatePreview();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '选择背景颜色',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _ColorSwatch(color: _effectiveColor, size: 34),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$_colorLabel  ·  透明度 $_alphaLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilterChip(
                    label: const Text('透明'),
                    selected: _isTransparent,
                    onSelected: (selected) {
                      setState(() {
                        _isTransparent = selected;
                        if (!selected && _alpha == 0) {
                          _alpha = 1;
                        }
                      });
                      _updatePreview();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ColorPalette(
                hue: _hsvColor.hue,
                saturation: _hsvColor.saturation,
                value: _hsvColor.value,
                enabled: !_isTransparent,
                onChanged: _setPalettePosition,
              ),
              const SizedBox(height: 12),
              _ColorSlider(
                label: '色相',
                value: _hsvColor.hue,
                max: 360,
                activeColor:
                    HSVColor.fromAHSV(1, _hsvColor.hue, 1, 1).toColor(),
                onChanged: _isTransparent
                    ? null
                    : (value) {
                        setState(() {
                          _hsvColor = _hsvColor.withHue(value);
                        });
                        _updatePreview();
                      },
              ),
              const SizedBox(height: 8),
              _ColorSlider(
                label: '透明度',
                value: _alpha,
                max: 1,
                activeColor: _hsvColor.toColor(),
                onChanged: _isTransparent
                    ? null
                    : (value) {
                        setState(() {
                          _alpha = value;
                        });
                        _updatePreview();
                      },
              ),
              const SizedBox(height: 14),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(64, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(_effectiveColor),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPalette extends StatelessWidget {
  final double hue;
  final double saturation;
  final double value;
  final bool enabled;
  final void Function(Offset position, Size size) onChanged;

  const _ColorPalette({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

    return LayoutBuilder(
      builder: (context, constraints) {
        const height = 148.0;
        const markerSize = 18.0;
        final width = constraints.maxWidth;
        final cursorX = saturation * width;
        final cursorY = (1 - value) * height;

        return GestureDetector(
          onPanDown: enabled
              ? (details) =>
                  onChanged(details.localPosition, Size(width, height))
              : null,
          onPanUpdate: enabled
              ? (details) =>
                  onChanged(details.localPosition, Size(width, height))
              : null,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(color: baseColor),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.transparent],
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black],
                            ),
                          ),
                        ),
                        if (!enabled)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color:
                                  theme.colorScheme.surface.withOpacity(0.45),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: (cursorX - markerSize / 2)
                      .clamp(0.0, math.max(width - markerSize, 0.0)),
                  top: (cursorY - markerSize / 2)
                      .clamp(0.0, height - markerSize),
                  child: IgnorePointer(
                    child: Container(
                      width: markerSize,
                      height: markerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.24),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
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

class _ColorSlider extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color activeColor;
  final ValueChanged<double>? onChanged;

  const _ColorSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Slider(
          value: value.clamp(0, max),
          max: max,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorSwatch({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _CheckerboardBackground(),
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
                  width: size * 1.2,
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
  const _CheckerboardBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CheckerboardPainter(
        light: Theme.of(context).colorScheme.surface,
        dark: Theme.of(context).dividerColor.withOpacity(0.5),
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
    const tile = 8.0;
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
