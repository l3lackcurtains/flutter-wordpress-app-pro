
import 'package:flutter/material.dart';
import 'package:flutter_wordpress_pro/common/constants.dart';
import 'package:flutter_wordpress_pro/pages/articles.dart';
import 'package:flutter_wordpress_pro/pages/local_articles.dart';
import 'package:flutter_wordpress_pro/pages/search.dart';
import 'package:flutter_wordpress_pro/pages/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/helpers.dart';

void main() {
  runApp(
    ChangeNotifierProvider<AppStateNotifier>(
      create: (context) => AppStateNotifier(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(builder: (context, appState, child) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Icilome',
        theme: ThemeData(
            brightness: Brightness.light,
            primaryColorLight: Colors.white,
            primaryColorDark: Colors.black,
            primaryColor: Color(0xFF385C7B),
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
                fontWeight: FontWeight.normal,
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
              fontWeight: FontWeight.normal,
              color: Color(0xFFF2F2F2),
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
        themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
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
                    icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.flare), label: PAGE2_CATEGORY_NAME),
                BottomNavigationBarItem(
                    icon: Icon(Icons.search), label: 'Search'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.menu), label: 'More'),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed),
        ),
        _isLoading
            ? Scaffold(backgroundColor: Colors.white)
            : Center()
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
