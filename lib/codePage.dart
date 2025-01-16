import 'package:flutter/material.dart';

class CodePage extends StatelessWidget {
  final String code; // The generated code to display

  const CodePage({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generated Code")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Your Code: $code",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to the previous screen
              },
              child: const Text("Upload Another PDF"),
            ),
          ],
        ),
      ),
    );
  }
}
