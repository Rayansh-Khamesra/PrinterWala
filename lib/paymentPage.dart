//-------------------PAYMENT PAGE-------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_application_3/PDFUploader.dart';
import 'package:flutter_application_3/codePage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentPage extends StatefulWidget {
  final String uniqueCode; // The code generated after uploading the PDF

  const PaymentPage({required this.uniqueCode, super.key});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear(); // Clear all listeners to prevent memory leaks
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Fluttertoast.showToast(msg: "Payment Successful!");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CodePage(code: widget.uniqueCode),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment Failed: ${response.message}");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
        msg: "External Wallet Selected: ${response.walletName}");
  }

  void _startPayment() {
    var options = {
      'key': 'rzp_test_COi4jiCnNpJm52', // Replace with your Razorpay test key
      'amount': mult *
          pageCount *
          numCopies *
          100, // Amount in smallest currency unit (e.g., ₹50.00 = 5000 paise)
      'name': 'PDF Printing Service',
      'description': 'Payment for printing services',
      'prefill': {
        'contact': '9876543210',
        'email': 'user@example.com',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      Fluttertoast.showToast(
          msg: "Error initiating payment. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Total Amount: ₹${pageCount * mult * numCopies}', // Calculate amount and display in rupees
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startPayment,
              child: const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }
}
