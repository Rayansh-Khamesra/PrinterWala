// ignore_for_file: prefer_const_constructors

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/PDFUploader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyAUpecSWqNfrBf0hFenIUCeSWjsiAt_Dh8",
            authDomain: "printerwala-96cf5.firebaseapp.com",
            projectId: "printerwala-96cf5",
            storageBucket: "printerwala-96cf5.firebasestorage.app",
            messagingSenderId: "198061567130",
            appId: "1:198061567130:web:cb59521a764097d4170323",
            measurementId: "G-6W70M5V5TP"));
  } else {
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: pdf_uploader(),
    );
  }
}
