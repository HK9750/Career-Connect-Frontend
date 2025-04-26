import 'package:flutter/material.dart';

/// A customizable action button used throughout the app.
///
/// Displays a label with a background color, disables itself
/// when [isActive] is false, and calls [onPressed] when tapped.
class ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onPressed;

  const ActionButton({
    Key? key,
    required this.label,
    required this.color,
    this.isActive = true,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isActive ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withOpacity(0.5),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: isActive ? 2 : 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
