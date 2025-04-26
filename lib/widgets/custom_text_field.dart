// custom_text_field.dart
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label; // Keep both parameter names for backward compatibility
  final String?
  labelText; // with existing screens (LoginScreen and RegisterScreen)
  final String? hint; // Keep both parameter names for backward compatibility
  final String? hintText; // with UploadResumeScreen
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final int? minLines;

  const CustomTextField({
    Key? key,
    required this.controller,
    this.label, // Support old parameter name
    this.labelText, // Support new parameter name
    this.hint, // Support old parameter name
    this.hintText, // Support new parameter name
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLabel = labelText ?? label;
    final effectiveHint = hintText ?? hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (effectiveLabel != null) ...[
          Text(
            effectiveLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: effectiveHint,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface.withOpacity(0.9),
          ),
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          minLines: minLines,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }
}
