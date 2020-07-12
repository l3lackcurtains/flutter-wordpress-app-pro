import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wordpress_app/common/constants.dart';
import 'package:flutter_wordpress_app/pages/articles.dart';
import 'package:flutter_wordpress_app/pages/local_articles.dart';
import 'package:flutter_wordpress_app/pages/search.dart';
import 'package:flutter_wordpress_app/pages/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/helpers.dart';

void main() => runApp(
      ChangeNotifierProvider<AppStateNotifier>(
        create: (context) => AppStateNotifier(),
        child: MyApp(),
      ),
    );

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(builder: (context, appState, child) {
      return MaterialApp(
        title: 'Icilome',
        theme: ThemeData(
            brightness: Brightness.light,
            primaryColorLight: Colors.white,
            primaryColorDark: Colors.black,
            primaryColor: Color(0xFF385C7B),
            accentColor: Color(0xFFE74C3C),
            canvasColor: Color(0xFFE3E3E3),
            textTheme: TextTheme(
              headline1: TextStyle(
                fontSize: 17,
                color: Colors.black,
                height: 1.2,
                fontWeight: FontWeight.w500,
                fontFamily: "Soleil",
              ),
              headline2: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Poppins'),
              caption: TextStyle(color: Colors.black45, fontSize: 10),
              bodyText1: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
              bodyText2: TextStyle(
                fontSize: 14,
                height: 1.2,
                color: Colors.black54,
              ),
            ),
            backgroundColor: Colors.white,
            scaffoldBackgroundColor: Colors.white),
        darkTheme: ThemeData(
          primaryColorLight: Colors.black,
          primaryColorDark: Colors.white,
          primaryColor: Color(0xFF385C7B),
          accentColor: Color(0xFFE74C3C),
          brightness: Brightness.dark,
          canvasColor: Color(0xFF333333),
          textTheme: TextTheme(
            headline1: TextStyle(
              fontSize: 17,
              color: Colors.white,
              height: 1.2,
              fontWeight: FontWeight.w500,
              fontFamily: "Soleil",
            ),
            headline2: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                fontFamily: 'Poppins'),
            caption: TextStyle(color: Colors.white70, fontSize: 10),
            bodyText1: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.white70,
            ),
            bodyText2: TextStyle(
              fontSize: 14,
              height: 1.2,
              color: Colors.white70,
            ),
          ),
          backgroundColor: Color(0xFF121212),
          scaffoldBackgroundColor: Colors.black,
          cardColor: Color(0xFF121212),
        ),
        themeMode: appState.getThemeMode() ? ThemeMode.dark : ThemeMode.light,
        home: MyHomePage(),
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Firebase Cloud Messeging setup
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  int _selectedIndex = 0;
  bool _isLoading = true;
  final List<Widget> _widgetOptions = [
    Articles(),
    LocalArticles(),
    Search(),
    Settings()
  ];

  @override
  void initState() {
    super.initState();
    _checkDarkTheme();
  }

  _checkDarkTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'darktheme';
    final platformTheme = MediaQuery.of(context).platformBrightness;
    final platformThemeCode = platformTheme == Brightness.dark ? 1 : 0;
    final value = prefs.getInt(key) ?? platformThemeCode;
    await changeToDarkTheme(context, value == 1);
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
  }

  startFirebase() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notification';
    final value = prefs.getInt(key) ?? 0;
    if (value == 1) {
      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  message["notification"]["title"],
                  style: TextStyle(fontFamily: "Soleil", fontSize: 18),
                ),
                content: Text(message["notification"]["body"]),
                actions: <Widget>[
                  FlatButton(
                    child: new Text("Dismiss"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        onLaunch: (Map<String, dynamic> message) async {
          // print("onLaunch: $message");
        },
        onResume: (Map<String, dynamic> message) async {
          // print("onResume: $message");
        },
      );
      _firebaseMessaging.getToken().then((token) {
        // print("Firebase Token:" + token);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: Theme.of(context).primaryColor);
    }

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Theme.of(context).backgroundColor,
          selectedLabelStyle:
              TextStyle(fontWeight: FontWeight.w500, fontFamily: "Soleil"),
          unselectedLabelStyle: TextStyle(fontFamily: "Soleil"),
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.home), title: Text('Home')),
            BottomNavigationBarItem(
                icon: Icon(Icons.flare), title: Text(PAGE2_CATEGORY_NAME)),
            BottomNavigationBarItem(
                icon: Icon(Icons.search), title: Text('Search')),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu), title: Text('More')),
          ],
          currentIndex: _selectedIndex,
          fixedColor: Theme.of(context).primaryColor,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
