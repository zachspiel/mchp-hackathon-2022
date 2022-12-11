import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hackathon_2022/section_title.dart';

class LeaderboardTable extends StatefulWidget {
  const LeaderboardTable(
      {super.key, required this.id, required this.leaderboard});
  final String id;
  final Map<String, double> leaderboard;

  @override
  State<LeaderboardTable> createState() => _LeaderboardTableState();
}

class _LeaderboardTableState extends State<LeaderboardTable> {
  Map<String, double> _leaderboard = {};
  final _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _badge = "";
  String _location = "";

  @override
  void initState() {
    super.initState();

    setState(() {
      _leaderboard = widget.leaderboard;
    });
    getBadge();
    getLocation();
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

  String getPlacement(MapEntry<String, double> entry) {
    int index =
        _leaderboard.entries.map((e) => e.key).toList().indexOf(entry.key) + 1;

    return index.toString();
  }

  List<DataRow> getRows() {
    return _leaderboard.entries
        .map((e) => DataRow(cells: [
              DataCell(Text(getPlacement(e))),
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
        body: DataTable(columns: const [
      DataColumn(label: Expanded(child: Text("No."))),
      DataColumn(label: Expanded(child: Text("Badge ID"))),
      DataColumn(label: Expanded(child: Text("Name"))),
      DataColumn(label: Expanded(child: Text("Location"))),
      DataColumn(label: Expanded(child: Text("Total Steps"))),
    ], rows: getRows()));
  }
}
