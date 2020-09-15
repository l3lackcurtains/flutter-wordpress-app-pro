import 'dart:math';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wordpress_pro/common/constants.dart';
import 'package:flutter_wordpress_pro/common/helpers.dart';
import 'package:flutter_wordpress_pro/models/article.dart';
import 'package:flutter_wordpress_pro/pages/single_Article.dart';
import 'package:flutter_wordpress_pro/widgets/articleBox.dart';
import 'package:loading/indicator/ball_beat_indicator.dart';
import 'package:loading/loading.dart';

class CategoryArticles extends StatefulWidget {
  final int id;
  final String name;
  CategoryArticles(this.id, this.name, {Key key}) : super(key: key);
  @override
  _CategoryArticlesState createState() => _CategoryArticlesState();
}

class _CategoryArticlesState extends State<CategoryArticles> {
  List<dynamic> categoryArticles = [];
  Future<List<dynamic>> _futureCategoryArticles;
  ScrollController _controller;
  int page = 1;
  bool _infiniteStop;

  @override
  void initState() {
    super.initState();
    _futureCategoryArticles = fetchCategoryArticles(1);
    _controller =
        ScrollController(initialScrollOffset: 0.0, keepScrollOffset: true);
    _controller.addListener(_scrollListener);
    _infiniteStop = false;
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<List<dynamic>> fetchCategoryArticles(int page) async {
    if (!this.mounted) return categoryArticles;

    try {
      String requestUrl = "$WORDPRESS_URL/wp-json/wp/v2/posts?categories[]=" +
          widget.id.toString() +
          "&page=$page&per_page=10&_fields=id,date,title,content,custom,link";
      Response response = await customDio.get(
        requestUrl,
        options: buildCacheOptions(Duration(days: 3),
            maxStale: Duration(days: 7), forceRefresh: false),
      );

      if (response.statusCode == 200) {
        setState(() {
          categoryArticles
              .addAll(response.data.map((m) => Article.fromJson(m)).toList());
          if (categoryArticles.length % 10 != 0) {
            _infiniteStop = true;
          }
        });

        return categoryArticles;
      }
    } on DioError catch (e) {
      if (DioErrorType.RECEIVE_TIMEOUT == e.type ||
          DioErrorType.CONNECT_TIMEOUT == e.type) {
        throw ("Server is not reachable. Please verify your internet connection and try again");
      } else if (DioErrorType.RESPONSE == e.type) {
        if (e.response.statusCode == 400) {
          setState(() {
            _infiniteStop = true;
          });
        } else {
          print(e.message);
          print(e.request);
        }
      } else if (DioErrorType.DEFAULT == e.type) {
        if (e.message.contains('SocketException')) {
          throw ('No Internet Connection.');
        }
      } else {
        throw ("Problem connecting to the server. Please try again.");
      }
    }

    return categoryArticles;
  }

  _scrollListener() {
    if (!this.mounted) return;
    var isEnd = _controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange;
    if (isEnd) {
      setState(() {
        page += 1;
        _futureCategoryArticles = fetchCategoryArticles(page);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Theme.of(context).primaryColorDark,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(widget.name,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.headline2),
        elevation: 5,
        backgroundColor: Theme.of(context).backgroundColor,
      ),
      body: Container(
        child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.vertical,
            child: Column(
                children: <Widget>[categoryPosts(_futureCategoryArticles)])),
      ),
    );
  }

  Widget categoryPosts(Future<List<dynamic>> categoryArticles) {
    return FutureBuilder<List<dynamic>>(
      future: categoryArticles,
      builder: (context, articleSnapshot) {
        if (articleSnapshot.hasData) {
          if (articleSnapshot.data.length == 0) return Container();
          return Column(
            children: <Widget>[
              ListView.builder(
                  itemCount: articleSnapshot.data.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    Article item = articleSnapshot.data[index];
                    Random random = new Random();
                    final randNum = random.nextInt(10000);
                    final heroId = item.id.toString() + randNum.toString();
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SingleArticle(item, heroId),
                          ),
                        );
                      },
                      child: Column(
                        children: <Widget>[
                          ENABLE_ADS && index % 5 == 0
                              ? Container(
                                  margin: EdgeInsets.fromLTRB(10, 4, 4, 0),
                                  child: Card(
                                    elevation: 6,
                                    child: AdmobBanner(
                                      adUnitId: ADMOB_BANNER_ID_1,
                                      adSize: AdmobBannerSize.LEADERBOARD,
                                    ),
                                  ),
                                )
                              : Container(),
                          articleBox(context, item, heroId),
                        ],
                      ),
                    );
                  }),
              !_infiniteStop
                  ? Container(
                      alignment: Alignment.center,
                      height: 30,
                      child: Loading(
                          indicator: BallBeatIndicator(),
                          size: 60.0,
                          color: Theme.of(context).accentColor))
                  : Container()
            ],
          );
        } else if (articleSnapshot.hasError) {
          return Container(
              height: 500,
              alignment: Alignment.center,
              child: Text("${articleSnapshot.error}"));
        }
        return Container(
          alignment: Alignment.center,
          height: 400,
          child: Loading(
              indicator: BallBeatIndicator(),
              size: 60.0,
              color: Theme.of(context).accentColor),
        );
      },
    );
  }
}
