import 'package:flutter/material.dart';
import 'dart:io';
import 'database_helper.dart';

class PhotoHistoryScreen extends StatefulWidget {
  final int plantId;
  final String plantName;

  const PhotoHistoryScreen({Key? key, required this.plantId, required this.plantName}) : super(key: key);

  @override
  _PhotoHistoryScreenState createState() => _PhotoHistoryScreenState();
}

class _PhotoHistoryScreenState extends State<PhotoHistoryScreen> {
  List<Map<String, dynamic>> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final dbHelper = DatabaseHelper();
    final photos = await dbHelper.getPhotosForPlant(widget.plantId);
    setState(() {
      _photos = photos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: Text('${widget.plantName} History')), body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.plantName} Photo History')),
      body: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          final file = File(photo['file_path']);
          final date = DateTime.fromMillisecondsSinceEpoch(photo['captured_at']);
          final type = photo['type'].toUpperCase();

          return Stack(
            children: [
              if (file.existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(file, fit: BoxFit.cover),
                )
              else
                Container(color: Colors.grey, child: Icon(Icons.image_not_supported)),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  color: Colors.black54,
                  child: Column(
                    children: [
                      Text(date.toString().split(' ')[0], style: TextStyle(color: Colors.white, fontSize: 10)),  // Date
                      Text(type, style: TextStyle(color: Colors.white, fontSize: 8)),  // Type
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
