import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _veggieMode = false;  // Toggle for organic veggie focus
  bool _darkMode = false;  // Optional theme toggle

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MYgardenai Settings')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('Veggie Mode'),
              subtitle: Text('Organic remedies & harvest tips for edibles'),
              value: _veggieMode,
              onChanged: (value) {
                setState(() { _veggieMode = value; });
                // TODO: Save to local storage (e.g., SharedPreferences) and update app behavior
              },
            ),
            SwitchListTile(
              title: Text('Dark Mode'),
              subtitle: Text('Night-friendly theme for late-night planning'),
              value: _darkMode,
              onChanged: (value) {
                setState(() { _darkMode = value; });
                // TODO: Toggle app theme
              },
            ),
            SizedBox(height: 20),
            Text('App Version: 1.0.0', style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Contact Support'),
              onPressed: () {
                // TODO: Launch email or form
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Support coming soon!')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
