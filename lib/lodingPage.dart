import 'package:flutter/material.dart';
import 'package:flutter_application_3/paymentPage.dart';

class LoadingPage extends StatefulWidget {
  final Future<String> fetchCode; // A future to fetch the generated code

  const LoadingPage({super.key, required this.fetchCode});

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fetchAndNavigate();
  }

  Future<void> _fetchAndNavigate() async {
    try {
      // Ensure we're not navigating multiple times
      if (_isNavigating) return;

      print("Starting _fetchAndNavigate method");

      // Wait for the upload process and code generation to complete
      String code = await widget.fetchCode;

      print("Received code in _fetchAndNavigate: $code");

      // Set flag to prevent multiple navigations
      setState(() {
        _isNavigating = true;
      });

      // Delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Use Navigator.push instead of pushReplacement
      if (mounted) {
        print("Attempting to navigate to PaymentPage");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) {
              print("Building PaymentPage");
              return PaymentPage(uniqueCode: code);
            },
          ),
        );
      } else {
        print("Widget is not mounted");
      }
    } catch (e) {
      print("Error in _fetchAndNavigate: $e");

      if (mounted) {
        // Show an error and go back to the main page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Uploading PDF... Please wait."),
          ],
        ),
      ),
    );
  }
}
