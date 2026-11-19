import 'package:material_ui/material_ui.dart';

/// A grip at the right edge of [child] for scrolling through long content
/// quickly: its position shows [fraction] (0 = start, 1 = end), dragging
/// reports the new fraction to [onDrag].
///
/// The grip shows [label] of its position; while dragging, [dragLabel]
/// appears next to it as a larger bubble.
class FastScrollThumb extends StatefulWidget {
  const new({
    required this.fraction,
    required this.onDrag,
    required this.label,
    required this.dragLabel,
    required this.child,
    super.key,
  });

  final double fraction;
  final ValueChanged<double> onDrag;
  final String Function(double fraction) label;
  final String Function(double fraction) dragLabel;
  final Widget child;

  static const thumbSize = Size(48, 36);

  @override
  State<FastScrollThumb> createState() => _FastScrollThumbState();
}

class _FastScrollThumbState extends State<FastScrollThumb> {
  /// Position while the user drags; `null` otherwise.
  double? _dragging;

  void _moveBy(double dy, double track) {
    if (track <= 0) return;
    final f = ((_dragging ?? widget.fraction) + dy / track).clamp(0.0, 1.0);
    setState(() => _dragging = f);
    widget.onDrag(f);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const size = FastScrollThumb.thumbSize;
        final track = constraints.maxHeight - size.height;
        final f = (_dragging ?? widget.fraction).clamp(0.0, 1.0);
        final top = track <= 0 ? 0.0 : f * track;
        return Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (_dragging != null)
              Positioned(
                right: size.width + 8,
                top: top,
                height: size.height,
                child: Material(
                  color: scheme.inverseSurface,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: Text(
                        widget.dragLabel(f),
                        style: text.titleSmall?.copyWith(
                          color: scheme.onInverseSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              top: top,
              width: size.width,
              height: size.height,
              child: GestureDetector(
                key: const ValueKey('fast-scroll-thumb'),
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (_) =>
                    setState(() => _dragging = widget.fraction),
                onVerticalDragUpdate: (d) => _moveBy(d.delta.dy, track),
                onVerticalDragEnd: (_) => setState(() => _dragging = null),
                onVerticalDragCancel: () => setState(() => _dragging = null),
                child: Material(
                  color: scheme.secondaryContainer,
                  elevation: 2,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      widget.label(f),
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
