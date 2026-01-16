// scan_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; // Add this

import 'save_receipt_page.dart';
import 'package:financetrack/pages/main_navigation_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isProcessing = false;
  final textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  final Color primaryColor = const Color(0xFF2E3192);
  final Color secondaryColor = const Color(0xFF00C6FF);

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainNavigationPage(initialIndex: index),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() => _isProcessing = true);
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      if (mounted) {
        final bool? saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => SaveReceiptPage(
              pickedImage: imageFile,
              extractedText: recognizedText.text.isEmpty ? "No text detected" : recognizedText.text,
            ),
          ),
        );

        if (saved == true) {
          _navigateToTab(1);
        }
      }
    } catch (e) {
      debugPrint("OCR Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- Camera Scan ---
  Future<void> _startCameraScan() async {
    try {
      // Cunning provides native camera + auto crop
      List<String>? pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty) {
        await _processImage(File(pictures[0]));
      }
    } catch (e) {
      debugPrint("Scanner Error: $e");
    }
  }

  // --- Gallery & Crop ---
  Future<void> _pickFromGallery() async {
    try {
      // 1. Pick the image
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        // 2. Open Cropper UI for the gallery image
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Receipt',
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: secondaryColor,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Receipt',
            ),
          ],
        );

        if (croppedFile != null) {
          await _processImage(File(croppedFile.path));
        }
      }
    } catch (e) {
      debugPrint("Gallery Pick/Crop Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep your existing UI build method here...
    return Scaffold(
      backgroundColor: const Color(0xFF0F1021),
      body: Stack(
        children: [
          Positioned(
            top: -50, right: -50,
            child: CircleAvatar(radius: 120, backgroundColor: primaryColor.withOpacity(0.15)),
          ),
          Center(
            child: _isProcessing 
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 24),
                    Text("Reading Receipt...", style: TextStyle(color: Colors.grey[300], fontSize: 16)),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: secondaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.document_scanner_rounded, size: 60, color: secondaryColor),
                      ),
                      const SizedBox(height: 24),
                      const Text("Add Receipt", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Choose a method to upload your receipt", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                      const SizedBox(height: 48),
                      _buildActionButton(label: "Scan with Camera", icon: Icons.camera_alt_rounded, onTap: _startCameraScan, color: primaryColor),
                      const SizedBox(height: 16),
                      _buildActionButton(label: "Import from Gallery", icon: Icons.photo_library_rounded, onTap: _pickFromGallery, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 40),
                      TextButton(onPressed: () => _navigateToTab(0), child: const Text("Back to Dashboard", style: TextStyle(color: Colors.white54))),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required VoidCallback onTap, required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}