import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/picker_theme.dart';

class PulsingSkeletonGrid extends StatefulWidget {
  final PickerTheme theme;

  const PulsingSkeletonGrid({super.key, required this.theme});

  @override
  State<PulsingSkeletonGrid> createState() => _PulsingSkeletonGridState();
}

class _PulsingSkeletonGridState extends State<PulsingSkeletonGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const aspectRatios = [
      1.0,
      0.75,
      1.3,
      0.8,
      1.0,
      0.6,
      1.2,
      1.0,
      0.75,
      1.0,
      1.4,
      0.8,
      0.75,
      1.0,
      1.1,
    ];

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final color = Color.lerp(
          widget.theme.shimmerBase,
          widget.theme.shimmerHighlight,
          _anim.value,
        )!;

        return MasonryGridView.builder(
          padding: const EdgeInsets.all(1.5),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          mainAxisSpacing: 1.5,
          crossAxisSpacing: 1.5,
          itemCount: aspectRatios.length,
          itemBuilder: (_, i) => AspectRatio(
            aspectRatio: aspectRatios[i],
            child: ColoredBox(color: color),
          ),
        );
      },
    );
  }
}
