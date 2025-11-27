import 'package:flutter/material.dart';
import 'dart:math';

/// A widget that displays a visualizer animation.
///
/// The visualizer animates more vigorously when [isTalking] is `true`.
class Visualizer extends StatefulWidget {
  /// Whether the visualizer should animate vigorously.
  final bool isTalking;
  const Visualizer({super.key, this.isTalking = false});

  @override
  State<Visualizer> createState() => _VisualizerState();
}

class _VisualizerState extends State<Visualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final double baseHeight = widget.isTalking ? 60 : 10;
              final double minHeight = widget.isTalking ? 20 : 10;

              final height =
                  minHeight +
                  baseHeight *
                      (0.5 + 0.5 * sin(_controller.value * 2 * pi + index));
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0xFFA8C7FA),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA8C7FA).withAlpha(127),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
