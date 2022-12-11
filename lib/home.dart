import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fitness/fitness.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hackathon_2022/section_title.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.id});
  final String id;

  @override
  State<Home> createState() => _HomeState();
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}

class _HomeState extends State<Home> {
  final _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final myController = TextEditingController();
  final _focusInput = FocusNode();
  final List<_ChartData> _data = [
    _ChartData("Target Steps", 6000),
    _ChartData("Steps", 0)
  ];
  double _steps = 0;
  double _monthlySteps = 0;
  double _yearlySteps = 0;
  int _stepsToAdd = 0;

  @override
  void initState() {
    super.initState();
    _activateListeners();
    myController.addListener(_handleChange);
  }

  void _requestPermission() async {
    final result = await Fitness.requestPermission();
  }

  void _read() async {
    final now = DateTime.now();
    final results = await Fitness.read(
      timeRange: TimeRange(
        start: now.subtract(const Duration(days: 3)),
        end: now,
      ),
      bucketByTime: 1,
      timeUnit: TimeUnit.days,
    );

    print(results);
  }

  void _handleChange() {
    setState(() {
      if (myController.text.isNotEmpty) {
        _stepsToAdd = int.parse(myController.text);
      }
    });
  }

  void _activateListeners() {
    String path = getDatabasePath();

    _database.child(path).onValue.listen((event) {
      Map? result = event.snapshot.value as Map;
      DateTime now = DateTime.now();
      DateTime date = DateTime(now.year, now.month, now.day);

      final dateString = date.toString().split(' ')[0];
      double dailySteps = result["steps"][dateString] ?? 0;
      double monthlySteps = result["months"]["${now.year}-${now.month}"] ?? 0;
      double yearlySteps = result["years"]["${now.year}"] ?? 0;

      if (result.isNotEmpty) {
        setState(() {
          _steps = dailySteps;
          _monthlySteps = monthlySteps;
          _yearlySteps = yearlySteps;
          _data[1] = _ChartData("Target Steps", 6000 - dailySteps);
          _data[1] = _ChartData("Steps", dailySteps);
        });
      }
    });
  }

  void updateSteps() async {
    String path = getDatabasePath();
    String dailyPath = "$path/steps/${getPathToToday()}";
    String monthPath = "$path/months/${getPathToMonth()}";
    String yearPath = "$path/years/${DateTime.now().year}";
    DatabaseReference stepsRef = FirebaseDatabase.instance.ref(dailyPath);
    DatabaseReference monthsRef = FirebaseDatabase.instance.ref(monthPath);
    DatabaseReference yearRef = FirebaseDatabase.instance.ref(yearPath);

    await stepsRef.set(_steps + _stepsToAdd);
    await monthsRef.set(_monthlySteps + _stepsToAdd);
    await yearRef.set(_yearlySteps + _stepsToAdd);

    setState(() {
      myController.text = "";
      _stepsToAdd = 0;
    });
  }

  String getDatabasePath() {
    return "users/${_auth.currentUser?.uid ?? ''}";
  }

  String getPathToToday() {
    DateTime now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);

    return date.toString().split(' ')[0];
  }

  String getPathToMonth() {
    DateTime now = DateTime.now();
    return "${now.year}-${now.month}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: GridView.count(crossAxisCount: 2, children: [
      Column(children: [
        const SectionTitle(title: "Today's Activity"),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(title: Text("Total Steps: $_steps")),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SfCircularChart(
                  series: [
                    DoughnutSeries<_ChartData, String>(
                      dataSource: _data,
                      radius: "35%",
                      xValueMapper: (_ChartData data, _) => data.x,
                      yValueMapper: (_ChartData data, _) => data.y,
                    )
                  ],
                )
              ],
            )
          ]),
        ),
        Column(children: [
          const SectionTitle(title: "Add Steps"),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: myController,
                  focusNode: _focusInput,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: "Enter Steps",
                    contentPadding: const EdgeInsets.all(12),
                    errorBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                  ),
                )),
                ElevatedButton(
                  onPressed: () {
                    updateSteps();
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ])
      ])
    ]));
  }
}
