import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'pest_details_screen.dart';

class PestScreen extends StatefulWidget {
  @override
  _PestScreenState createState() => _PestScreenState();
}

class _PestScreenState extends State<PestScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _controller = CameraController(camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      final identifiedPest = await _identifyPest(image.path);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PestDetailsScreen(pestData: identifiedPest),
        ),
      );
    } catch (e) {
      setState(() { _result = 'Error: $e'; });
    }
  }

  Future<Map<String, dynamic>> _identifyPest(String imagePath) async {
    // Encode image to base64
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    final uri = Uri.parse('https://insect.kindwise.com/api/v1/identification');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Api-Key': 'YOUR_INSECT_ID_KEY',  // Replace with your key
      },
      body: json.encode({
        'images': [base64Image],
        'similar_images': true,
      }),
      encoding: Encoding.getByName('utf-8'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final suggestions = data['result']['classification']['suggestions'];
      if (suggestions.isNotEmpty) {
        return suggestions[0];  // Top match
      }
    }
    throw Exception('Pest identification failed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan for Pests')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller!)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _takePicture,
                      child: Text('Capture & Identify Pest'),
                      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                    ),
                  ),
                ),
                if (_result.isNotEmpty)
                  Positioned(
                    top: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      color: Colors.red.withOpacity(0.8),
                      child: Text(_result, style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
