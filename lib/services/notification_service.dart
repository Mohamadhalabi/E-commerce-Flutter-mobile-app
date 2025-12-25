import 'dart:async';
import 'package:flutter/material.dart';
import '../components/custom_notification.dart';

class NotificationService {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String? sku,
    String? image,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
    bool isError = false,
  }) {
    remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 0,
        right: 0,
        child: _AnimatedNotification(
          child: CustomNotification(
            title: title,
            message: message,
            sku: sku,
            image: image,
            isError: isError,
            // ✅ FIX: Pass null if no action is defined, hiding the "View" button
            onPressed: onActionPressed != null
                ? () {
              remove();
              onActionPressed();
            }
                : null,
            onClose: remove,
          ),
        ),
      ),
    );

    if (_overlayEntry != null) {
      Overlay.of(context).insert(_overlayEntry!);
    }

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

class _AnimatedNotification extends StatefulWidget {
  final Widget child;
  const _AnimatedNotification({required this.child});
  @override
  State<_AnimatedNotification> createState() => _AnimatedNotificationState();
}

class _AnimatedNotificationState extends State<_AnimatedNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _offsetAnimation = Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) { return SlideTransition(position: _offsetAnimation, child: widget.child); }
}