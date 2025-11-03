import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'calendar_screen.dart';

class SoilPhScreen extends StatefulWidget {
  final String? initialPlantName;  // Optional: Pass from scan

  const SoilPhScreen({Key? key, this.initialPlantName}) : super(key: key);

  @override
  _SoilPhScreenState createState() => _SoilPhScreenState();
}

class _SoilPhScreenState extends State<SoilPhScreen> {
  double _testedPh = 7.0;
  String _selectedSoil = 'Loamy';  // Default
  String _selectedPlant = '';
  Map<String, dynamic>? _plantData;
  bool _loading = false;
  String _phAdvice = '';
  String _soilAdvice = '';
  double? _idealPhMin, _idealPhMax;
  List<String>? _preferredSoils;

  final List<String> _soilTypes = ['Sandy', 'Loamy', 'Clay', 'Rocky', 'Silt'];

  @override
  void initState() {
    super.initState();
    if (widget.initialPlantName != null) {
      _selectedPlant = widget.initialPlantName!;
      _fetchPlantData(_selectedPlant);
    }
  }

  Future<void> _fetchPlantData(String plantName) async {
    setState(() { _loading = true; });
    final searchUri = Uri.parse('https://perenual.com/api/species-list?key=YOUR_PERENUAL_KEY&q=${Uri.encodeComponent(plantName)}');
    final searchResponse = await http.get(searchUri);
    if (searchResponse.statusCode == 200) {
      final searchData = json.decode(searchResponse.body);
      if (searchData['data'].isNotEmpty) {
        final plantId = searchData['data'][0]['id'];
        final detailsUri = Uri.parse('https://perenual.com/api/species/details/$plantId?key=YOUR_PERENUAL_KEY');
        final detailsResponse = await http.get(detailsUri);
        if (detailsResponse.statusCode == 200) {
          final data = json.decode(detailsResponse.body);
          setState(() {
            _plantData = data;
            _idealPhMin = data['xWateringPhLevel']?['min']?.toDouble();
            _idealPhMax = data['xWateringPhLevel']?['max']?.toDouble();
            _preferredSoils = List<String>.from(data['soil'] ?? []);
          });
          _analyzePh();
          _analyzeSoil();
        }
      }
    }
    setState(() { _loading = false; });
  }

  void _analyzePh() {
    if (_idealPhMin == null || _idealPhMax == null) {
      setState(() { _phAdvice = 'Ideal pH: 6.0-7.0 (general). Test your soil and compare.'; });
      return;
    }

    if (_testedPh >= _idealPhMin! && _testedPh <= _idealPhMax!) {
      setState(() { _phAdvice = '✅ Optimal pH for ${_plantData?['common_name'] ?? _selectedPlant}! No action needed.'; });
    } else if (_testedPh < _idealPhMin!) {
      final adjustment = _idealPhMin! - _testedPh;
      setState(() {
        _phAdvice = '⚠️ Too acidic (low). Raise by ~$adjustment units. Recommendation: Apply dolomitic lime (1-2 lbs/100 sq ft) in fall; retest in 3 months.';
      });
    } else {
      final adjustment = _testedPh - _idealPhMax!;
      setState(() {
        _phAdvice = '⚠️ Too alkaline (high). Lower by ~$adjustment units. Recommendation: Add elemental sulfur (1 lb/100 sq ft) or aluminum sulfate; retest in 2 months.';
      });
    }
  }

  void _analyzeSoil() {
    if (_preferredSoils == null || _preferredSoils!.isEmpty) {
      setState(() { _soilAdvice = 'Preferred soil: Well-draining (general).'; });
      return;
    }

    final match = _preferredSoils!.any((soil) => season.toLowerCase().contains(_selectedSoil.toLowerCase()));
    if (match) {
      setState(() { _soilAdvice = '✅ ${_selectedSoil} soil matches preferences for ${_plantData?['common_name'] ?? _selectedPlant}! Good for drainage/nutrients.'; });
    } else {
      setState(() {
        _soilAdvice = '⚠️ ${_selectedSoil} may not suit ${_plantData?['common_name'] ?? _selectedPlant} (prefers: ${_preferredSoils!.join(', ')}). Recommendation: ';
        switch (_selectedSoil.toLowerCase()) {
          case 'sandy':
            _soilAdvice += 'Add compost or peat moss to improve water retention.';
            break;
          case 'clay':
            _soilAdvice += 'Mix in gypsum or sand for better drainage; avoid compaction.';
            break;
          case 'rocky':
            _soilAdvice += 'Incorporate topsoil or organic matter to fill gaps and reduce erosion.';
            break;
          case 'silt':
            _soilAdvice += 'Blend with coarse sand to prevent poor aeration.';
            break;
          default:
            _soilAdvice += 'Test drainage and amend with organic matter.';
        }
        _soilAdvice += ' Retest soil structure in spring.';
      });
    }
  }

  void _addAmendmentReminder() {
    final plant = _selectedPlant.isEmpty ? 'your plants' : _selectedPlant;
    final eventSubject = 'Soil Amendment for $plant: $_phAdvice\n$_soilAdvice';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarScreen(initialEvent: eventSubject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Soil pH & Type Test')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter Tested pH (from kit):', style: Theme.of(context).textTheme.headlineSmall),
            Slider(
              value: _testedPh,
              min: 0.0,
              max: 14.0,
              divisions: 140,
              label: _testedPh.toStringAsFixed(1),
              onChanged: (value) {
                setState(() { _testedPh = value; });
                _analyzePh();
              },
            ),
            Text('Tested pH: ${_testedPh.toStringAsFixed(1)}'),
            SizedBox(height: 20),
            Text('Select Soil Type:', style: Theme.of(context).textTheme.headlineSmall),
            DropdownButtonFormField<String>(
              value: _selectedSoil,
              items: _soilTypes.map((soil) => DropdownMenuItem(value: soil, child: Text(soil))).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() { _selectedSoil = value; });
                  _analyzeSoil();
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose soil texture',
              ),
            ),
            SizedBox(height: 20),
            Text('Plant (optional):', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: TextEditingController(text: _selectedPlant),
              onChanged: (value) {
                setState(() { _selectedPlant = value; });
                if (value.isNotEmpty) _fetchPlantData(value);
              },
              decoration: InputDecoration(
                hintText: 'e.g., Tomato',
                border: OutlineInputBorder(),
              ),
            ),
            if (_loading) SizedBox(height: 20, child: CircularProgressIndicator()),
            if (_idealPhMin != null)
              Text('Ideal pH Range: ${_idealPhMin!.toStringAsFixed(1)} - ${_idealPhMax!.toStringAsFixed(1)}'),
            if (_preferredSoils != null && _preferredSoils!.isNotEmpty)
              Text('Preferred Soils: ${_preferredSoils!.join(', ')}'),
            SizedBox(height: 20),
            Text('pH Analysis:', style: Theme.of(context).textTheme.headlineSmall),
            Container(
              padding: EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _phAdvice.startsWith('✅') ? Colors.lightGreen : Colors.lightYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_phAdvice),
            ),
            SizedBox(height: 10),
            Text('Soil Type Analysis:', style: Theme.of(context).textTheme.headlineSmall),
            Container(
              padding: EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _soilAdvice.startsWith('✅') ? Colors.lightGreen : Colors.lightYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_soilAdvice),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Add Amendment Reminder to Calendar'),
              onPressed: _addAmendmentReminder,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            ),
            SizedBox(height: 10),
            Text('Tips: Assess soil by feel (sandy: gritty; clay: sticky). Amendments improve over time—retest annually.'),
          ],
        ),
      ),
    );
  }
}
