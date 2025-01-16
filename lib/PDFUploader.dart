import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_pdf_reader/dart_pdf_reader.dart' as pdfx;
import 'package:flutter_application_3/lodingPage.dart';

int pageCount = 0;
int mult = 2;
int isBackToBack = 0;
int numCopies = 1;
int orientation = 0; // 0 for Portrait, 1 for Landscape
String selectedPageRange = "All Pages";

void main() {
  runApp(const pdf_uploader());
}

class pdf_uploader extends StatelessWidget {
  const pdf_uploader({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PDF Uploader with Code',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedPrintType = "Black and White";
  String _selectedPrintStyle = "Normal";
  String _selectedOrientation = "Portrait";
  TextEditingController _copiesController = TextEditingController(text: "1");
  TextEditingController _pageRangeController = TextEditingController();
  String _selectedPageRange = "All Pages";
  int _totalPdfPages = 0;
  File? _selectedPdfFile;

  /// Validates the page range input
  bool _validatePageRange(String pageRange, int totalPages) {
    if (pageRange.trim().isEmpty) {
      return false;
    }

    if (_selectedPageRange == "All Pages") {
      return true;
    }

    // Split the range and validate
    try {
      List<String> rangeParts = pageRange.split('-');
      if (rangeParts.length != 2) {
        return false;
      }

      int startPage = int.parse(rangeParts[0].trim());
      int endPage = int.parse(rangeParts[1].trim());

      // Check if range is valid
      return startPage > 0 && endPage <= totalPages && startPage <= endPage;
    } catch (e) {
      return false;
    }
  }

  /// Handles the PDF upload and saves print settings in Firestore
  Future<String> _uploadPDF() async {
    // Allow user to pick a PDF file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Restrict to PDF files
    );

    if (result == null) {
      throw Exception("No file selected");
    }

    // Verify file path exists
    if (result.files.single.path == null) {
      throw Exception("Invalid file path");
    }

    // Set the selected PDF file
    _selectedPdfFile = File(result.files.single.path!);

    // Determine total PDF pages
    _totalPdfPages = await _getPdfPageCount(_selectedPdfFile!);

    // Validate page range if not "All Pages"
    if (_selectedPageRange != "All Pages") {
      if (!_validatePageRange(_pageRangeController.text, _totalPdfPages)) {
        Fluttertoast.showToast(
          msg: "Invalid page range. Please check and try again.",
          toastLength: Toast.LENGTH_LONG,
        );
        return ""; // This will prevent further navigation
      }

      // Calculate page count based on range
      if (_selectedPageRange == "Custom Range") {
        List<String> rangeParts = _pageRangeController.text.split('-');
        int startPage = int.parse(rangeParts[0].trim());
        int endPage = int.parse(rangeParts[1].trim());
        pageCount = endPage - startPage + 1;
      }
    } else {
      pageCount = _totalPdfPages;
    }

    // Generate a random code for the uploaded PDF
    String randomCode = _generateRandomCode(6);
    print("Generated random code: $randomCode");

    FirebaseStorage storage = FirebaseStorage.instance;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Upload file
    print("Uploading file using file path...");
    Reference ref =
        storage.ref().child("pdfs/$randomCode-${result.files.single.name}");
    await ref.putFile(_selectedPdfFile!);
    String downloadURL = await ref.getDownloadURL();

    print("File uploaded successfully. URL: $downloadURL");

    // Save print settings in Firestore
    await firestore.collection("print_jobs").doc(randomCode).set({
      "pdf_url": downloadURL,
      "color_mode": _selectedPrintType,
      "back_to_back": isBackToBack,
      "num_copies": numCopies,
      "orientation": _selectedOrientation,
      "page_range":
          _selectedPageRange == "All Pages" ? "All" : _pageRangeController.text,
      "timestamp": DateTime.now().toIso8601String(),
      "pdf_path": "pdfs/$randomCode-${result.files.single.name}"
    });

    // Return the random code for the uploaded PDF
    return randomCode;
  }

  // Get PDF page count
  Future<int> _getPdfPageCount(File file) async {
    final stream = pdfx.FileStream(file.openSync());
    final doc = await pdfx.PDFParser(stream).parse();
    final catalog = await doc.catalog;
    final pages = await catalog.getPages();
    return pages.pageCount;
  }

  /// Generates a random alphanumeric code
  static String _generateRandomCode(int length) {
    const characters = 'ABCD0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length)),
      ),
    );
  }

  /// Validates and sets the number of copies
  void _validateCopies(String value) {
    int enteredValue = int.tryParse(value) ?? 1;

    if (enteredValue < 1) {
      enteredValue = 1;
      Fluttertoast.showToast(
        msg: "Minimum copies allowed is 1",
        toastLength: Toast.LENGTH_SHORT,
      );
    } else if (enteredValue > 100) {
      enteredValue = 100;
      Fluttertoast.showToast(
        msg: "Maximum copies allowed is 100",
        toastLength: Toast.LENGTH_SHORT,
      );
    }

    // Update the state and controller text
    setState(() {
      numCopies = enteredValue;
    });
    Fluttertoast.showToast(
      msg: "no of compies selected is $numCopies",
      toastLength: Toast.LENGTH_SHORT,
    );

    _copiesController.text = enteredValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF Uploader")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Existing dropdowns...
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedPrintType,
                  decoration: const InputDecoration(
                    labelText: "Select Print Type",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: "Black and White",
                        child: Text("Black and White")),
                    DropdownMenuItem(value: "Colored", child: Text("Colored")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPrintType = value ?? "Black and White";
                      mult = _selectedPrintType == "Colored" ? 10 : 2;
                    });
                    Fluttertoast.showToast(
                      msg: "$_selectedPrintType Print Selected",
                      toastLength: Toast.LENGTH_SHORT,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Existing print style dropdown...
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedPrintStyle,
                  decoration: const InputDecoration(
                    labelText: "Select Print Style",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Normal", child: Text("Normal")),
                    DropdownMenuItem(
                        value: "Back to Back", child: Text("Back to Back")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPrintStyle = value ?? "Normal";
                      isBackToBack =
                          _selectedPrintStyle == "Back to Back" ? 1 : 0;
                    });
                    Fluttertoast.showToast(
                      msg: "$_selectedPrintStyle Style Selected",
                      toastLength: Toast.LENGTH_SHORT,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Existing orientation dropdown...
              DropdownButtonFormField<String>(
                value: _selectedOrientation,
                decoration: const InputDecoration(
                  labelText: "Select Orientation",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Portrait", child: Text("Portrait")),
                  DropdownMenuItem(
                      value: "Landscape", child: Text("Landscape")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedOrientation = value ?? "Portrait";
                    orientation = _selectedOrientation == "Landscape" ? 1 : 0;
                  });
                  Fluttertoast.showToast(
                    msg: "$_selectedOrientation Orientation Selected",
                    toastLength: Toast.LENGTH_SHORT,
                  );
                },
              ),
              const SizedBox(height: 20),
              // New Page Range Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedPageRange,
                  decoration: const InputDecoration(
                    labelText: "Page Selection",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: "All Pages", child: Text("All Pages")),
                    DropdownMenuItem(
                        value: "Custom Range", child: Text("Custom Range")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPageRange = value ?? "All Pages";
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Conditional Page Range Input
              if (_selectedPageRange == "Custom Range")
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                    controller: _pageRangeController,
                    decoration: const InputDecoration(
                      labelText: "Enter Page Range (e.g., 1-5)",
                      hintText: "Start Page - End Page",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
              const SizedBox(height: 20),
              // Existing copies input...
              TextFormField(
                controller: _copiesController,
                decoration: const InputDecoration(
                  labelText: "Number of Copies",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onEditingComplete: () {
                  _validateCopies(_copiesController.text);
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  try {
                    Future<String> codeFuture = _uploadPDF();
                    String resultCode = await codeFuture;

                    // Only navigate if a valid code was returned
                    if (resultCode.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              LoadingPage(fetchCode: Future.value(resultCode)),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Upload failed: $e")),
                    );
                  }
                },
                child: const Text("Upload PDF"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
