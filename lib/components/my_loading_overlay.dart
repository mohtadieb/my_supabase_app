import 'package:flutter/material.dart';

/// Full-screen loading overlay that avoids overflow issues
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;

  const LoadingOverlay({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const CircularProgressIndicator(),

            const SizedBox(height: 28),

          ],
        ),
      ),
    );
  }
}
