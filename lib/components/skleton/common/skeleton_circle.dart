import 'package:flutter/material.dart';

class SkeletonCircle extends StatefulWidget {
  final double size;

  const SkeletonCircle({super.key, this.size = 72});

  @override
  State<SkeletonCircle> createState() => _SkeletonCircleState();
}

class _SkeletonCircleState extends State<SkeletonCircle> {
  double _opacity = 0.3;

  @override
  void initState() {
    super.initState();
    _animate();
  }

  void _animate() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _opacity = _opacity == 0.3 ? 1.0 : 0.3;
      });
      _animate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _opacity,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}