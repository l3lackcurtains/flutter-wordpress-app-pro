import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_wordpress_app/common/constants.dart';
import 'package:flutter_wordpress_app/pages/articles.dart';
import 'package:flutter_wordpress_app/pages/local_articles.dart';
import 'package:flutter_wordpress_app/pages/search.dart';
import 'package:flutter_wordpress_app/pages/settings.dart';
import 'package:flutter_wordpress_app/pages/single_article.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/helpers.dart';
import 'models/article.dart';

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
  Article _notificationArticle;

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
    _startOneSignal();
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

  _startOneSignal() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notification';
    final value = prefs.getInt(key) ?? 1;

    onesignal.init(
      "45e71839-7d7b-445a-b325-b9009d92171e",
      iOSSettings: {
        OSiOSSettings.autoPrompt: true,
        OSiOSSettings.inAppLaunchUrl: true
      },
    );
    onesignal.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
    onesignal.setInFocusDisplayType(OSNotificationDisplayType.notification);

    await enableNotification(context, value == 1);

    onesignal.setNotificationReceivedHandler((OSNotification notification) {
      print(notification.jsonRepresentation().replaceAll("\\n", "\n"));
    });

    onesignal.setNotificationOpenedHandler(
        (OSNotificationOpenedResult result) async {
      String postId =
          result.notification.payload.additionalData['postId'].toString();
      await _fetchNotificationArticle(postId);
      if (_notificationArticle != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SingleArticle(_notificationArticle, "123456"),
          ),
        );
      }
    });
  }

  Future<Article> _fetchNotificationArticle(String id) async {
    try {
      http.Response response =
          await http.get("$WORDPRESS_URL/wp-json/wp/v2/posts/$id");
      if (this.mounted) {
        if (response.statusCode == 200) {
          Map<String, dynamic> articleRes = json.decode(response.body);
          setState(() {
            _notificationArticle = Article.fromJson(articleRes);
          });
          return _notificationArticle;
        }
      }
    } on SocketException {
      throw 'No Internet connection';
    }
    return _notificationArticle;
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
        ),
        _isLoading
            ? Scaffold(backgroundColor: Theme.of(context).primaryColor)
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
