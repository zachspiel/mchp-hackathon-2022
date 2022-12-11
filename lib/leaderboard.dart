import 'package:data_table_2/data_table_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hackathon_2022/leaderboard_table.dart';
import 'package:hackathon_2022/section_title.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({super.key, required this.id});
  final String id;

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  final Map<String, double> _dailyScores = {};
  final Map<String, double> _monthlyScores = {};
  final Map<String, double> _yearlyScores = {};
  Map<String, double> _dailyLeaderboard = {};
  Map<String, double> _monthlyLeaderboard = {};
  Map<String, double> _yearlyLeaderboard = {};
  String _location = "";
  String _badge = "";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _activateListeners();
    getBadge();
    getLocation();
  }

  void _activateListeners() {
    _database.child("/users").onValue.listen((event) {
      Map? result = event.snapshot.value as Map;

      if (result.entries.isNotEmpty) {
        result.forEach((key, value) {
          String month = getMonthIndex().toString();
          String year = getYear();
          double dailyScore = result[key]["steps"][getCurrentDate()] ?? 0;
          double monthlyScore = result[key]["months"]["$year-$month"] ?? 0;
          double yearlyScore = result[key]["years"][year] ?? 0;

          setState(() {
            _dailyScores[key] = dailyScore;
            _monthlyScores[key] = monthlyScore;
            _yearlyScores[key] = yearlyScore;
          });
        });

        setState(() {
          _dailyLeaderboard = sortEntries(_dailyScores);
          _monthlyLeaderboard = sortEntries(_monthlyScores);
          _yearlyLeaderboard = sortEntries(_yearlyScores);
        });
      }
    });
  }

  Map<String, double> sortEntries(Map<String, double> map) {
    return Map.fromEntries(
        map.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)));
  }

  String getCurrentDate() {
    DateTime now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);

    return date.toString().split(' ')[0];
  }

  String getMonth() {
    List months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    var month = getMonthIndex();
    return months[month - 1];
  }

  int getMonthIndex() {
    return DateTime.now().month;
  }

  String getYear() {
    return DateTime.now().year.toString();
  }

  String getPlacement(MapEntry<String, double> entry, Map<String, double> map) {
    int index = map.entries.map((e) => e.key).toList().indexOf(entry.key) + 1;

    return index.toString();
  }

  void getBadge() async {
    String path = "users/${_auth.currentUser?.uid ?? ''}/badge";

    final snapshot = await _database.child(path).get();

    if (snapshot.exists) {
      setState(() {
        _badge = snapshot.value as String;
      });
    }
  }

  void getLocation() async {
    String path = "users/${_auth.currentUser?.uid ?? ''}/location";

    final snapshot = await _database.child(path).get();

    if (snapshot.exists) {
      setState(() {
        _location = snapshot.value as String;
      });
    }
  }

  List<DataColumn> getColumns() {
    return const [
      DataColumn(label: Expanded(child: Text("No."))),
      DataColumn(label: Expanded(child: Text("Badge ID"))),
      DataColumn(label: Expanded(child: Text("Name"))),
      DataColumn(label: Expanded(child: Text("Location"))),
      DataColumn(label: Expanded(child: Text("Total Steps"))),
    ];
  }

  List<DataRow> getRows(Map<String, double> leaderboard) {
    return leaderboard.entries
        .map((e) => DataRow(cells: [
              DataCell(Text(getPlacement(e, leaderboard))),
              DataCell(Text(_badge)),
              DataCell(Text(_auth.currentUser?.displayName ?? "")),
              DataCell(Text(_location)),
              DataCell(Text(e.value.toString()))
            ]))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 30,
      direction: Axis.horizontal,
      children: [
        const SectionTitle(title: "Daily Leaderboard"),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: getColumns(),
              rows: getRows(_dailyLeaderboard),
            )),
        SectionTitle(title: "${getMonth()} Leaderboard"),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: getColumns(),
              rows: getRows(_monthlyLeaderboard),
            )),
        SectionTitle(title: "${DateTime.now().year} Leaderboard"),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: getColumns(),
              rows: getRows(_yearlyLeaderboard),
            )),
      ],
    ));
  }
}
