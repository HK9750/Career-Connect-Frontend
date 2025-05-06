import 'package:flutter/material.dart';

/// A customizable action button used throughout the app.
///
/// Displays a label with an optional icon, background color, disables itself
/// when [isActive] is false, and calls [onPressed] when tapped.
class ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onPressed;
  final IconData? icon;
  final double iconSize;
  final double spacing;

  const ActionButton({
    Key? key,
    required this.label,
    required this.color,
    this.isActive = true,
    required this.onPressed,
    this.icon,
    this.iconSize = 18.0,
    this.spacing = 8.0,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize),
            SizedBox(width: spacing),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
