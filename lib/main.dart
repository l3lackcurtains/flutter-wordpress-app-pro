import 'dart:convert';
import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wordpress_pro/common/constants.dart';
import 'package:flutter_wordpress_pro/pages/articles.dart';
import 'package:flutter_wordpress_pro/pages/local_articles.dart';
import 'package:flutter_wordpress_pro/pages/search.dart';
import 'package:flutter_wordpress_pro/pages/settings.dart';
import 'package:flutter_wordpress_pro/pages/single_article.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'common/helpers.dart';
import 'models/article.dart';

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
  Article _deepLinkArticle;

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
    if (ENABLE_DYNAMIC_LINK) _startDynamicLinkService();
    if (ENABLE_ADS) _startAdMob();
  }

  _startAdMob() {
    Admob.initialize(ADMOB_ID);
  }

  _startDynamicLinkService() async {
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    _handleDeepLink(data);

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      _handleDeepLink(dynamicLink);
    }, onError: (OnLinkErrorException e) async {
      print('Link Failed: ${e.message}');
    });
  }

  void _handleDeepLink(PendingDynamicLinkData data) async {
    final Uri deepLink = data?.link;
    if (deepLink != null) {
      print('_handleDeepLink | deeplink: $deepLink');

      var isPost = deepLink.pathSegments.contains('post');

      if (isPost) {
        var postId = deepLink.queryParameters['post_id'];

        if (postId != null) {
          await _fetchDeepLinkArticle(postId);
          if (_deepLinkArticle != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SingleArticle(_deepLinkArticle, postId),
              ),
            );
          }
        }
      }
    }
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
      ONE_SIGNAL_APP_ID,
      iOSSettings: {
        OSiOSSettings.autoPrompt: true,
        OSiOSSettings.inAppLaunchUrl: true
      },
    );
    onesignal.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
    onesignal.setInFocusDisplayType(OSNotificationDisplayType.notification);

    await enableNotification(context, value == 1);

    onesignal.setNotificationOpenedHandler(
        (OSNotificationOpenedResult result) async {
      String url = result.notification.payload.additionalData['url'].toString();
      if (result.action.actionId == "openbrowser") {
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not launch $url';
        }
        return;
      } else if (result.action.actionId == "share") {
        Share.share('$url');
        return;
      }

      String postId =
          result.notification.payload.additionalData['postId'].toString();
      await _fetchNotificationArticle(postId);
      if (_notificationArticle != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SingleArticle(_notificationArticle, postId),
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

  Future<Article> _fetchDeepLinkArticle(String id) async {
    try {
      http.Response response =
          await http.get("$WORDPRESS_URL/wp-json/wp/v2/posts/$id");
      if (this.mounted) {
        if (response.statusCode == 200) {
          Map<String, dynamic> articleRes = json.decode(response.body);
          setState(() {
            _deepLinkArticle = Article.fromJson(articleRes);
          });
          return _deepLinkArticle;
        }
      }
    } on SocketException {
      throw 'No Internet connection';
    }
    return _deepLinkArticle;
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
