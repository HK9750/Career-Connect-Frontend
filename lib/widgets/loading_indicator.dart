import 'package:flutter/material.dart';

// Loading Indicator Widget with theme support
class LoadingIndicator extends StatelessWidget {
  final String? text;

  const LoadingIndicator({Key? key, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(
              text!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
