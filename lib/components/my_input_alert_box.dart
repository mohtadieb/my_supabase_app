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
- optional extra widget (e.g. image picker preview or buttons)

*/

class MyInputAlertBox extends StatelessWidget {
  final TextEditingController textController;
  final String hintText;
  final void Function()? onPressed;
  final String onPressedText;
  final Widget? extraWidget; // 🆕 optional extra widget (e.g., image picker)

  const MyInputAlertBox({
    super.key,
    required this.textController,
    required this.hintText,
    required this.onPressed,
    required this.onPressedText,
    this.extraWidget, // 🆕 pass in optional widget
  });

  @override
  Widget build(BuildContext context) {
    // Alert dialog
    return AlertDialog(
      // Rounded corners
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
      ),

      // Background color
      backgroundColor: Theme.of(context).colorScheme.surface,

      // Content: Text field and optional extra widget
      content: Column(
        mainAxisSize: MainAxisSize.min, // Shrink dialog to fit content
        children: [
          // Text field
          TextField(
            controller: textController,

            // Limit characters
            maxLength: 140,
            maxLines: 3,

            decoration: InputDecoration(

              // Border when text field is unselected
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary),
                borderRadius: BorderRadius.circular(14),
              ),

              // Border when text field is focused
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(14),
              ),

              // hint text
              hintText: hintText,
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),

              // Color inside of text field
              fillColor: Theme.of(context).colorScheme.secondary,
              filled: true,
              counterStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),

          // 🆕 Include extra widget if provided
          if (extraWidget != null) ...[
            const SizedBox(height: 10), // spacing between text field and extra widget
            extraWidget!,
          ],
        ],
      ),

      // Actions
      actions: [
        // Cancel button
        TextButton(
          onPressed: () {
            // close box
            Navigator.pop(context);

            // clear controller
            textController.clear();

          },
          child: const Text("Cancel"),
        ),

        // Confirm button
        TextButton(
          onPressed: () {
            // close box
            Navigator.pop(context);

            // execute function
            onPressed!.call();

            // clear controller
            textController.clear();
          },
          child: Text(onPressedText),
        ),
      ],
    );
  }
}
