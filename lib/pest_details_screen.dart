import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'calendar_screen.dart';

class PestDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> pestData;

  const PestDetailsScreen({Key? key, required this.pestData}) : super(key: key);

  @override
  _PestDetailsScreenState createState() => _PestDetailsScreenState();
}

class _PestDetailsScreenState extends State<PestDetailsScreen> {
  Map<String, dynamic>? _perenualData;
  bool _loading = true;
  String _remedy = 'No specific remedy found. Consult a local expert.';
  String _description = 'Description unavailable.';
  String? _pestImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchRemedy();
  }

  Future<void> _fetchRemedy() async {
    final commonName = widget.pestData['details']?['common_names']?.first ?? '';
    final scientificName = widget.pestData['name'] ?? '';

    final searchTerm = commonName.isNotEmpty ? commonName : scientificName;
    final searchUri = Uri.parse('https://perenual.com/api/pest-disease-list?key=YOUR_PERENUAL_KEY&q=${Uri.encodeComponent(searchTerm)}');
    final response = await http.get(searchUri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['data'] as List;
      if (items.isNotEmpty) {
        final match = items[0];
        setState(() {
          _perenualData = match;
          _description = match['description'] ?? _description;
          _remedy = match['solution'] ?? _remedy;
          _pestImageUrl = match['images']?.isNotEmpty == true ? match['images'][0]['regular_url'] : null;
        });
      }
    }
    setState(() { _loading = false; });
  }

  void _addToCalendar() {
    final name = widget.pestData['name'] ?? 'Unknown Pest';
    final eventSubject = 'Treat $name: $_remedy';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarScreen(initialEvent: eventSubject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.pestData['name'] ?? 'Unknown Pest';
    final probability = (widget.pestData['probability'] * 100).toStringAsFixed(1);
    final commonNames = widget.pestData['details']?['common_names']?.join(', ') ?? 'N/A';
    final wikiUrl = widget.pestData['details']?['url'] ?? '';

    if (_loading) {
      return Scaffold(appBar: AppBar(title: Text('Identified Pest')), body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Pest: $name')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confidence: $probability%', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Text('Common Names: $commonNames'),
            SizedBox(height: 16),
            if (_pestImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(_pestImageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            SizedBox(height: 16),
            Text('Description:', style: Theme.of(context).textTheme.headlineSmall),
            Text(_description),
            SizedBox(height: 16),
            Text('Recommended Remedy:', style: Theme.of(context).textTheme.headlineSmall),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.lightYellow, borderRadius: BorderRadius.circular(8)),
              child: Text(_remedy, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 16),
            if (wikiUrl.isNotEmpty)
              ElevatedButton(
                child: Text('Learn More on Wikipedia'),
                onPressed: () async {
                  final url = Uri.parse(wikiUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            SizedBox(height: 8),
            ElevatedButton(
              child: Text('Add Remedy Reminder to Calendar'),
              onPressed: _addToCalendar,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}
