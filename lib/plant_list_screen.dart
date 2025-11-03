import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'photo_history_screen.dart';

class PlantListScreen extends StatefulWidget {
  @override
  _PlantListScreenState createState() => _PlantListScreenState();
}

class _PlantListScreenState extends State<PlantListScreen> {
  List<Map<String, dynamic>> _plants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final dbHelper = DatabaseHelper();
    final plants = await dbHelper.getPlants();
    setState(() {
      _plants = plants;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: Text('Plant History')), body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Select Plant')),
      body: ListView.builder(
        itemCount: _plants.length,
        itemBuilder: (context, index) {
          final plant = _plants[index];
          return ListTile(
            title: Text(plant['name']),
            subtitle: Text('Photos: ${plant['photo_count'] ?? 0}'),  // TODO: Add count query if needed
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoHistoryScreen(plantId: plant['id'], plantName: plant['name']),
              ),
            ),
          );
        },
      ),
    );
  }
}
