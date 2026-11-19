import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:unpaged/core/platform/external_link_channel.dart';
import 'package:unpaged/l10n/gen/app_localizations.dart';

/// An entry of the ⋮ menu in the app bar.
@immutable
class MenuEntry {
  const new({
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
}

/// The app bar actions of every screen: the GitHub link and a ⋮ menu that
/// holds all other actions ([entries]); without entries only the link.
List<Widget> appBarActions(List<MenuEntry> entries) => [
  const GitHubButton(),
  if (entries.isNotEmpty) _OverflowMenu(entries),
];

class _OverflowMenu extends StatelessWidget {
  const new(this.entries);

  final List<MenuEntry> entries;

  @override
  Widget build(BuildContext context) => PopupMenuButton<MenuEntry>(
    tooltip: AppLocalizations.of(context).moreOptions,
    icon: const Icon(Icons.more_vert),
    onSelected: (entry) => entry.onSelected(),
    itemBuilder: (_) => [
      for (final e in entries)
        PopupMenuItem(
          value: e,
          child: ListTile(leading: Icon(e.icon), title: Text(e.label)),
        ),
    ],
  );
}

/// Opens the app's source code on GitHub in the browser.
class GitHubButton extends ConsumerWidget {
  const new({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(externalLinkChannelProvider).open(gitHubUrl);
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).linkUnavailable)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: AppLocalizations.of(context).gitHub,
    icon: const GitHubIcon(),
    onPressed: () => unawaited(_open(context, ref)),
  );
}

/// The GitHub mark, drawn in the colour and size of the surrounding
/// [IconTheme].
///
/// Outline from Primer Octicons `mark-github-24.svg`
/// (https://github.com/primer/octicons), MIT License,
/// Copyright (c) 2026 GitHub Inc.; converted to absolute path commands.
class GitHubIcon extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MarkPainter(theme.color ?? const Color(0xFF000000)),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const new(this.color);

  final Color color;

  /// Outline on a 24 × 24 grid.
  static final _mark = Path()
    ..moveTo(10.226, 17.284)
    ..cubicTo(7.261, 16.924, 5.172, 14.791, 5.172, 12.028)
    ..cubicTo(5.172, 10.905, 5.576, 9.692, 6.25, 8.884)
    ..cubicTo(5.958, 8.143, 6.003, 6.57, 6.34, 5.919)
    ..cubicTo(7.238, 5.807, 8.451, 6.279, 9.17, 6.929)
    ..cubicTo(10.023, 6.66, 10.922, 6.525, 12.023, 6.525)
    ..cubicTo(13.123, 6.525, 14.022, 6.66, 14.83, 6.907)
    ..cubicTo(15.526, 6.278, 16.762, 5.807, 17.66, 5.919)
    ..cubicTo(17.975, 6.525, 18.02, 8.098, 17.727, 8.861)
    ..cubicTo(18.447, 9.715, 18.828, 10.861, 18.828, 12.028)
    ..cubicTo(18.828, 14.791, 16.739, 16.88, 13.73, 17.262)
    ..cubicTo(14.493, 17.756, 15.01, 18.834, 15.01, 20.069)
    ..lineTo(15.01, 22.405)
    ..cubicTo(15.01, 23.079, 15.571, 23.461, 16.245, 23.191)
    ..cubicTo(20.311, 21.641, 23.5, 17.576, 23.5, 12.545)
    ..cubicTo(23.5, 6.188, 18.334, 1, 11.978, 1)
    ..cubicTo(5.62, 1, 0.5, 6.188, 0.5, 12.545)
    ..cubicTo(0.5, 17.531, 3.667, 21.665, 7.935, 23.214)
    ..cubicTo(8.541, 23.439, 9.125, 23.034, 9.125, 22.428)
    ..lineTo(9.125, 20.63)
    ..cubicTo(8.783, 20.773, 8.417, 20.849, 8.047, 20.854)
    ..cubicTo(6.564, 20.854, 5.688, 20.046, 5.06, 18.541)
    ..cubicTo(4.813, 17.934, 4.543, 17.575, 4.026, 17.508)
    ..cubicTo(3.756, 17.485, 3.667, 17.373, 3.667, 17.238)
    ..cubicTo(3.667, 16.968, 4.117, 16.767, 4.565, 16.767)
    ..cubicTo(5.217, 16.767, 5.778, 17.171, 6.362, 18.002)
    ..cubicTo(6.812, 18.653, 7.283, 18.945, 7.845, 18.945)
    ..cubicTo(8.406, 18.945, 8.765, 18.743, 9.282, 18.226)
    ..cubicTo(9.664, 17.845, 9.956, 17.508, 10.226, 17.283);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..scale(size.width / 24, size.height / 24)
      ..drawPath(_mark, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}
