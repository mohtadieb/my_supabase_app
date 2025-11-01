import 'package:flutter/material.dart';

/*

INPUT ALERT BOX

This is an alert dialog box that has a text field where the user can type in.
Will use this for things like editing bio, posting a new message, etc.

--------------------------------------------------------------------------------

To use this widget, you need:

- text controller (To access what the user typed)
- hint text (e.g. "Empty bio..")
- a function (e.g. SaveBio())
- text (e.g. "Save")

*/

class MyInputAlertBox extends StatelessWidget {
  final TextEditingController textController;
  final String hintText;
  final void Function()? onPressed;
  final String onPressedText;

  const MyInputAlertBox({
    super.key,
    required this.textController,
    required this.hintText,
    required this.onPressed,
    required this.onPressedText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Rounded corners
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
      ),

      // Background color
      backgroundColor: Theme.of(context).colorScheme.surface,

      // Content: Text field
      content: TextField(
        controller: textController,
        maxLength: 140,
        maxLines: 3,
        decoration: InputDecoration(
          // Border when unselected
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary),
            borderRadius: BorderRadius.circular(14),
          ),
          // Border when focused
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(14),
          ),
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          fillColor: Theme.of(context).colorScheme.secondary,
          filled: true,
          counterStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),

      // Actions
      actions: [
        // Cancel button
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close box
            textController.clear(); // Clear controller
          },
          child: const Text("Cancel"),
        ),

        // Confirm button
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close box
            onPressed?.call(); // Execute passed function
            textController.clear(); // Clear controller
          },
          child: Text(onPressedText),
        ),
      ],
    );
  }
}