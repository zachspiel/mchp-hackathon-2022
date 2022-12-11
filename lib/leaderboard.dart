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

class LeaderBoardScore {
  LeaderBoardScore(
      {required this.badge,
      required this.location,
      required this.dailyScore,
      required this.monthlyScore,
      required this.yearlyScore});
  final String badge;
  final String location;
  double dailyScore;
  double monthlyScore;
  double yearlyScore;
}

class _LeaderboardState extends State<Leaderboard> {
  List<LeaderBoardScore> _dailyLeaderboard = [];
  List<LeaderBoardScore> _monthlyLeaderboard = [];
  List<LeaderBoardScore> _yearlyLeaderboard = [];

  List<LeaderBoardScore> _scores = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _activateListeners();
  }

  void _activateListeners() async {
    _database.child("/users").onValue.listen((event) {
      Map? result = event.snapshot.value as Map;

      if (result.entries.isNotEmpty) {
        setState(() {
          _scores = [];
        });

        result.forEach((key, value) {
          String month = getMonthIndex().toString();
          String year = getYear();
          String badge = result[key]["badge"];
          String location = result[key]["location"];

          double dailyScore = 0;
          if (result[key].containsKey("steps")) {
            dailyScore = result[key]["steps"][getCurrentDate()] ?? 0;
          }

          double monthlyScore = 0;
          if (result[key].containsKey("months")) {
            monthlyScore = result[key]["months"]["$year-$month"] ?? 0;
          }

          double yearlyScore = 0;
          if (result[key].containsKey("years")) {
            yearlyScore = result[key]["years"][year] ?? 0;
          }

          setState(() {
            _scores.add(LeaderBoardScore(
                badge: badge,
                location: location,
                dailyScore: dailyScore,
                monthlyScore: monthlyScore,
                yearlyScore: yearlyScore));
          });
        });
        setState(() {
          _dailyLeaderboard = sortDailyScores();
          _monthlyLeaderboard = sortMonthlyScores();
          _yearlyLeaderboard = sortYearlyScores();
        });
      }
    });
  }

  List<LeaderBoardScore> sortDailyScores() {
    List<LeaderBoardScore> scoresCopy = [..._scores];
    scoresCopy.sort(
        (score1, score2) => score2.dailyScore.compareTo(score1.dailyScore));

    return scoresCopy;
  }

  List<LeaderBoardScore> sortMonthlyScores() {
    List<LeaderBoardScore> scoresCopy = [..._scores];
    scoresCopy.sort(
        (score1, score2) => score2.monthlyScore.compareTo(score1.monthlyScore));

    return scoresCopy;
  }

  List<LeaderBoardScore> sortYearlyScores() {
    List<LeaderBoardScore> scoresCopy = [..._scores];
    scoresCopy.sort(
        (score1, score2) => score2.yearlyScore.compareTo(score1.yearlyScore));

    return scoresCopy;
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

  String getPlacement(
      LeaderBoardScore score, List<LeaderBoardScore> leaderboard) {
    int index = leaderboard.indexOf(score) + 1;
    return index.toString();
  }

  List<DataColumn> getColumns() {
    return const [
      DataColumn(label: Expanded(child: Text("No."))),
      DataColumn(label: Expanded(child: Text("Badge ID"))),
      DataColumn(label: Expanded(child: Text("Location"))),
      DataColumn(label: Expanded(child: Text("Total Steps"))),
    ];
  }

  List<DataRow> getRows(List<LeaderBoardScore> leaderboard, String key) {
    return leaderboard
        .map((e) => DataRow(cells: [
              DataCell(Text(getPlacement(e, leaderboard))),
              DataCell(Text(e.badge)),
              DataCell(Text(e.location)),
              DataCell(Text(getScoreByType(key, e).toString()))
            ]))
        .toList();
  }

  double getScoreByType(String type, LeaderBoardScore score) {
    if (type == "daily") {
      return score.dailyScore;
    } else if (type == "monthly") {
      return score.monthlyScore;
    }

    return score.yearlyScore;
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
              rows: getRows(_dailyLeaderboard, "daily"),
            )),
        SectionTitle(title: "${getMonth()} Leaderboard"),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: getColumns(),
              rows: getRows(_monthlyLeaderboard, "monthly"),
            )),
        SectionTitle(title: "${DateTime.now().year} Leaderboard"),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: getColumns(),
              rows: getRows(_yearlyLeaderboard, "yearly"),
            )),
      ],
    ));
  }
}
