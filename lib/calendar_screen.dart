import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarScreen extends StatefulWidget {
  final String? initialEvent;  // For dynamic additions

  const CalendarScreen({Key? key, this.initialEvent}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Appointment> _appointments = [
    Appointment(
      startTime: DateTime.now().add(Duration(days: 1)),
      endTime: DateTime.now().add(Duration(days: 1, hours: 1)),
      subject: 'Feed Monstera Fertilizer',
      color: Colors.green,
      recurrenceRule: 'FREQ=WEEKLY;COUNT=52',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialEvent != null) {
      _addAppointment(widget.initialEvent!);
    }
  }

  void _addAppointment(String subject) {
    setState(() {
      _appointments.add(
        Appointment(
          startTime: DateTime.now().add(Duration(days: 7)),  // Start next week
          endTime: DateTime.now().add(Duration(days: 7, hours: 1)),
          subject: subject,
          color: Colors.orange,
          recurrenceRule: 'FREQ=WEEKLY;INTERVAL=1;COUNT=12',  // Weekly for 3 months
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added: $subject')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MYgardenai Calendar')),
      body: SfCalendar(
        view: CalendarView.month,
        dataSource: AppointmentDataSource(_appointments),
        appointmentBuilder: (context, details) {
          return Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(details['Appointment']!.subject, style: TextStyle(fontSize: 12)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddEventDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Event'),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: 'e.g., Water Plants')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addAppointment(controller.text);
              }
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
