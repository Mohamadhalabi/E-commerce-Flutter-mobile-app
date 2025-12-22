import 'dart:async';
import 'package:flutter/material.dart';
import '../components/custom_notification.dart';

class NotificationService {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  /// Shows a custom notification at the top of the screen
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String? image,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    // 1. Remove any existing notification immediately
    remove();

    // 2. Create the OverlayEntry
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10, // Top SafeArea + padding
        left: 0,
        right: 0,
        child: _AnimatedNotification(
          child: CustomNotification(
            title: title,
            message: message,
            image: image,
            onPressed: () {
              remove();
              if (onActionPressed != null) onActionPressed();
            },
            onClose: remove,
          ),
        ),
      ),
    );

    // 3. Insert into the screen
    if (_overlayEntry != null) {
      Overlay.of(context).insert(_overlayEntry!);
    }

    // 4. Start Auto-Close Timer
    _timer = Timer(duration, () {
      remove();
    });
  }

  static void remove() {
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// Internal Helper for Slide Animation
class _AnimatedNotification extends StatefulWidget {
  final Widget child;
  const _AnimatedNotification({required this.child});

  @override
  State<_AnimatedNotification> createState() => _AnimatedNotificationState();
}

class _AnimatedNotificationState extends State<_AnimatedNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0), // Start from above screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Bouncy effect
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}