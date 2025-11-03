import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CareDetailsScreen extends StatefulWidget {
  final String plantName;
  CareDetailsScreen({required this.plantName});

  @override
  _CareDetailsScreenState createState() => _CareDetailsScreenState();
}

class _CareDetailsScreenState extends State<CareDetailsScreen> {
  Map<String, dynamic>? _plantData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlantDetails();
  }

  Future<void> _fetchPlantDetails() async {
    // First, search for plant ID by name
    final searchUri = Uri.parse('https://perenual.com/api/species-list?key=YOUR_PERENUAL_KEY&q=${widget.plantName}');  // Replace key
    final searchResponse = await http.get(searchUri);
    if (searchResponse.statusCode == 200) {
      final searchData = json.decode(searchResponse.body);
      if (searchData['data'].isNotEmpty) {
        final plantId = searchData['data'][0]['id'];
        // Fetch details
        final detailsUri = Uri.parse('https://perenual.com/api/species/details/$plantId?key=YOUR_PERENUAL_KEY');
        final detailsResponse = await http.get(detailsUri);
        if (detailsResponse.statusCode == 200) {
          setState(() {
            _plantData = json.decode(detailsResponse.body);
            _loading = false;
          });
        }
      }
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: Text('Loading...')), body: Center(child: CircularProgressIndicator()));

    final data = _plantData;
    if (data == null) return Scaffold(appBar: AppBar(title: Text('No Data')), body: Center(child: Text('Plant not found')));

    return Scaffold(
      appBar: AppBar(title: Text(data['common_name'] ?? 'Unknown Plant')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Light Needs:', style: Theme.of(context).textTheme.headlineSmall),
            Text(data['sunlight']?.join(', ') ?? 'N/A' + ' (e.g., ${data['xSunlightDuration']?['min'] ?? ''} hours min)'),
            SizedBox(height: 16),
            Text('Water Needs:', style: Theme.of(context).textTheme.headlineSmall),
            Text('${data['watering'] ?? 'N/A'} (every ${data['watering_general_benchmark'] ?? ''} days)'),
            SizedBox(height: 16),
            Text('Temperature Range:', style: Theme.of(context).textTheme.headlineSmall),
            Text('Min: ${data['hardiness']?['min'] ?? ''}°C, Max: ${data['hardiness']?['max'] ?? ''}°C'),
            SizedBox(height: 16),
            Text('Propagation Methods:', style: Theme.of(context).textTheme.headlineSmall),
            Text(data['propagation']?.join(', ') ?? 'N/A (e.g., seeds, cuttings)'),
            SizedBox(height: 32),
            ElevatedButton(
              child: Text('Add Feeding Schedule'),
              onPressed: () {
                // TODO: Pass data to calendar and add event (e.g., weekly)
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Schedule added for ${data['common_name']}')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
