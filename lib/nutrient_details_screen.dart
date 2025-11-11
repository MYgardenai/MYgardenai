import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'calendar_screen.dart';

class NutrientDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> deficiencyData;

  const NutrientDetailsScreen({Key? key, required this.deficiencyData}) : super(key: key);

  void _addToCalendar(BuildContext context) {
    final name = deficiencyData['class'] ?? 'Unknown Deficiency';
    final treatment = deficiencyData['details']?['treatment'] ?? 'Apply appropriate fertilizer.';
    final eventSubject = 'Correct $name: $treatment';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarScreen(initialEvent: eventSubject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = deficiencyData['class'] ?? 'Unknown Nutrient Deficiency';
    final probability = (deficiencyData['probability'] * 100).toStringAsFixed(1);
    final commonNames = deficiencyData['details']?['common_names']?.join(', ') ?? 'N/A';
    final description = deficiencyData['details']?['description'] ?? 'Description unavailable.';
    final symptoms = deficiencyData['details']?['symptoms'] ?? 'Symptoms unavailable.';
    final treatment = deficiencyData['details']?['treatment'] ?? 'No specific treatment found. Test soil and consult an expert.';
    final wikiUrl = deficiencyData['details']?['url'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('Nutrient Deficiency: $name')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confidence: $probability%', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Text('Common Names: $commonNames'),
            SizedBox(height: 16),
            Text('Description:', style: Theme.of(context).textTheme.headlineSmall),
            Text(description),
            SizedBox(height: 16),
            Text('Symptoms:', style: Theme.of(context).textTheme.headlineSmall),
            Text(symptoms),
            SizedBox(height: 16),
            Text('Recommended Treatment:', style: Theme.of(context).textTheme.headlineSmall),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.lightGreen, borderRadius: BorderRadius.circular(8)),
              child: Text(treatment, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 16),
            if (wikiUrl.isNotEmpty)
              ElevatedButton(
                child: Text('Learn More'),
                onPressed: () async {
                  final url = Uri.parse(wikiUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            SizedBox(height: 8),
            ElevatedButton(
              child: Text('Add Correction Reminder to Calendar'),
              onPressed: () => _addToCalendar(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
