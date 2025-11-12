import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'calendar_screen.dart';
import 'sunlight_screen.dart';
import 'soil_ph_screen.dart';
import 'plant_list_screen.dart';
import 'property_map_screen.dart';
import 'pest_screen.dart';
import 'pest_details_screen.dart';
import 'disease_screen.dart';
import 'disease_details_screen.dart';
import 'nutrient_screen.dart';
import 'nutrient_details_screen.dart';
import 'settings_screen.dart';

void main() {
  runApp(MYgardenAIApp());
}

class MYgardenAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MYgardenai',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MYgardenai')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Scan Plant'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CameraScreen())),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('View Calendar'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen())),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Sunlight Map'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SunlightScreen())),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Soil pH Test'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SoilPhScreen())),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Plant History'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlantListScreen())),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Property Map'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyMapScreen())),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Scan for Pests'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PestScreen())),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Scan for Diseases'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiseaseScreen())),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Scan for Nutrient Deficiencies'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NutrientScreen())),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Settings'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
