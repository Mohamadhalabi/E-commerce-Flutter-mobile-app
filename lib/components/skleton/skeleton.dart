import 'package:flutter/material.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.height, required this.width, this.layer = 1});

  final double height, width;
  final int layer;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      padding: const EdgeInsets.all(16 / 2),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04 * widget.layer),
          borderRadius: const BorderRadius.all(Radius.circular(16))),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // FIXED: Removed 'widget.' here.
                // We access '_animation' directly because it is in this State class.
                begin: Alignment(_animation.value - 1, 0),
                end: Alignment(_animation.value, 0),
                colors: [
                  Colors.grey[200]!,
                  Colors.grey[100]!,
                  Colors.grey[200]!,
                ],
                stops: const [0.4, 0.5, 0.6],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}