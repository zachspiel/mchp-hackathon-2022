import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hackathon_2022/section_title.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:table_calendar/table_calendar.dart';

class History extends StatefulWidget {
  const History({super.key, required this.id});
  final String id;

  @override
  State<History> createState() => _HistoryState();
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}

class Event {
  final String title;

  const Event(this.title);

  @override
  String toString() => title;
}

class _HistoryState extends State<History> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  final _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<String, double> _steps = {};

  @override
  void initState() {
    super.initState();

    _activateListeners();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  void _activateListeners() {
    String path = getDatabasePath();

    _database.child(path).onValue.listen((event) {
      Map? result = event.snapshot.value as Map;
      if (result.isNotEmpty) {
        result.forEach(((key, value) {
          setState(() {
            _steps[key] = value;
          });
        }));
      }
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    String path = day.toString().split(' ')[0];
    double steps = _steps[path] ?? 0;
    return [
      Event(steps.toString()),
    ];
  }

  String getDatabasePath() {
    return "users/${_auth.currentUser?.uid ?? ''}/steps";
  }

  String getPathToToday() {
    DateTime now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);

    return date.toString().split(' ')[0];
  }

  double getStepsForSelectedDay() {
    String date = _selectedDay.toString().split(' ')[0];
    return _steps[date] ?? 0;
  }

  String getPathToMonth() {
    DateTime now = DateTime.now();
    return "${now.year}-${now.month}";
  }

  DateTime getFirstDay() {
    return DateTime(2022, 12, 10);
  }

  DateTime getLastDay() {
    DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: [
      TableCalendar<Event>(
        firstDay: getFirstDay(),
        lastDay: getLastDay(),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
      const SizedBox(height: 8.0),
      Expanded(
        child: ValueListenableBuilder<List<Event>>(
          valueListenable: _selectedEvents,
          builder: (context, value, _) {
            return ListView.builder(
              itemCount: value.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    title: Text(getStepsForSelectedDay().toString()),
                  ),
                );
              },
            );
          },
        ),
      )
    ]));
  }
}
