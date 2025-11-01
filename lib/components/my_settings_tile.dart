import 'package:flutter/material.dart';

/*

SETTINGS LIST TILE

A reusable tile for the settings page.

Features:
- Full width tile
- Rounded corners
- Reduced padding
- Title uses theme primary color
- Flexible action widget (e.g., switch, button)

*/

class MySettingsTile extends StatelessWidget {
  final String title;
  final Widget onTap;

  const MySettingsTile({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onTap,
        ],
      ),
    );
  }
}