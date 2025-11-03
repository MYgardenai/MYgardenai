import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';
import 'photo_history_screen.dart';

class PropertyMapScreen extends StatefulWidget {
  @override
  _PropertyMapScreenState createState() => _PropertyMapScreenState();
}

class _PropertyMapScreenState extends State<PropertyMapScreen> {
  MapController _mapController = MapController();
  List<Map<String, dynamic>> _plants = [];
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _loading = true;
  File? _customMapImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPlantsAndCenter();
  }

  Future<void> _loadPlantsAndCenter() async {
    final dbHelper = DatabaseHelper();
    final plants = await dbHelper.getPlantsWithLocations();
    setState(() {
      _plants = plants;
      _loading = false;
    });

    // Center on first plant or current location
    if (_plants.isNotEmpty) {
      final firstPlant = _plants.first;
      _mapController.move(LatLng(firstPlant['latitude'], firstPlant['longitude']), 16.0);
    } else {
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 16.0);
    }

    _buildMarkers();
  }

  Future<void> _uploadCustomMap() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _customMapImage = File(image.path);
      });
      // TODO: Save to DB for persistence
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Custom map uploaded! Tap to place plants.')));
    }
  }

  void _buildMarkers() async {
    final markers = <Marker>[];
    for (final plant in _plants) {
      final lat = plant['latitude'] as double?;
      final lng = plant['longitude'] as double?;
      if (lat == null || lng == null) continue;

      final photoPath = await _getLatestPhotoPath(plant['id']);
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          child: GestureDetector(
            onTap: () => _showPlantDialog(plant),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: ClipOval(
                child: photoPath != null && File(photoPath).existsSync()
                    ? Image.file(File(photoPath), fit: BoxFit.cover)
                    : Icon(Icons.local_florist, color: Colors.green, size: 30),
              ),
            ),
          ),
        ),
      );
    }
    if (mounted) {
      setState(() { _markers = Set<Marker>.from(markers); });
    }
  }

  Future<String?> _getLatestPhotoPath(int plantId) async {
    final dbHelper = DatabaseHelper();
    final photos = await dbHelper.getPhotosForPlant(plantId);
    if (photos.isNotEmpty) {
      final latestPhoto = photos.first;
      final file = File(latestPhoto['file_path']);
      if (await file.exists()) {
        return latestPhoto['file_path'];
      }
    }
    return null;
  }

  void _showPlantDialog(Map<String, dynamic> plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plant['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Location: ${plant['latitude'].toStringAsFixed(4)}, ${plant['longitude'].toStringAsFixed(4)}'),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('View Photo History'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PhotoHistoryScreen(plantId: plant['id'], plantName: plant['name'])),
              ).then((_) => _loadPlantsAndCenter()),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Edit Location'),
              onPressed: () => _editLocation(plant),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _editLocation(Map<String, dynamic> plant) async {
    Navigator.pop(context);
    final newPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    // TODO: Update DB
    _loadPlantsAndCenter();
  }

  void _addPlantAt(LatLng point) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Add Plant Here'),
          content: TextField(controller: controller, decoration: InputDecoration(hintText: 'Plant Name')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final dbHelper = DatabaseHelper();
                  await dbHelper.insertPlant(controller.text, latitude: point.latitude, longitude: point.longitude);
                }
                Navigator.pop(context);
                _loadPlantsAndCenter();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: Text('Property Map')), body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('MYgardenai Property Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.upload),
            onPressed: _uploadCustomMap,
            tooltip: 'Upload Custom Property Map',
          ),
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () async {
              _currentPosition = await Geolocator.getCurrentPosition();
              _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 16.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_customMapImage != null)
            InteractiveViewer(
              child: Image.file(_customMapImage!, fit: BoxFit.contain),
              onTapDown: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                _addMarkerAtCustom(localPosition.dx / box.size.width, localPosition.dy / box.size.height);
              },
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_currentPosition?.latitude ?? 37.7749, _currentPosition?.longitude ?? -122.4194),
                initialZoom: 16.0,
                onTap: (tapPosition, point) => _addPlantAt(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mygardenai',
                ),
                MarkerLayer(markers: _markers.toList()),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add_location),
        onPressed: () => _addNewPlant(),
      ),
    );
  }

  void _addNewPlant() {
    // Similar to _addPlantAt, but center on current location
  }

  void _addMarkerAtCustom(double relX, double relY) {
    // Prompt for plant name, save relative coords to DB
    _loadPlantsAndCenter();
  }
}
