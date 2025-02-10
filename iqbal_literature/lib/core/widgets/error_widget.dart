import 'package:flutter/material.dart';
import '../constants/asset_constants.dart';
import '../constants/text_constants.dart';

class CustomErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const CustomErrorWidget({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AssetConstants.errorIllustration,
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? TextConstants.unknownError,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text(TextConstants.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
