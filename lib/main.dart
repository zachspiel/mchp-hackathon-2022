import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hackathon_2022/history.dart';
import 'package:hackathon_2022/home.dart';
import 'package:hackathon_2022/leaderboard.dart';
import 'package:hackathon_2022/login.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
      ChangeNotifierProvider(create: (context) => DarkMode(), child: MyApp()));
}

class DarkMode with ChangeNotifier {
  bool darkMode = true;
  changeMode() {
    darkMode = !darkMode;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<DarkMode>(context);
    return MaterialApp(
        title: 'Hackathon 2022',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        darkTheme:
            ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
        themeMode: themeMode.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: _auth.currentUser != null
            ? MyHomePage(
                title: 'Micro Steps for Macro Health', user: _auth.currentUser!)
            : Login());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.user});

  final String title;
  final User user;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _database = FirebaseDatabase.instance.ref();
  int _selectedIndex = 0;
  late User _currentUser;

  static const List<Widget> _widgetOptions = <Widget>[
    Home(id: ""),
    Leaderboard(id: ""),
    History(id: ""),
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<DarkMode>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: () {
                  themeMode.changeMode();
                },
                child: Icon(
                    themeMode.darkMode ? Icons.dark_mode : Icons.light_mode),
              ))
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              title: Text(_currentUser.displayName ?? ""),
              leading: Icon(Icons.person, color: Colors.blue[500]),
            ),
            ListTile(
              title: Text(_currentUser.email ?? ""),
              leading: Icon(Icons.email, color: Colors.blue[500]),
            ),
            ListTile(
              title: const Text("Settings"),
              leading: Icon(Icons.settings, color: Colors.grey[500]),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {});
                await FirebaseAuth.instance.signOut();

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => Login(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Sign out',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[500],
        onTap: _onItemTapped,
      ),
    );
  }
}
