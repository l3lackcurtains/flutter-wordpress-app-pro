import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wordpress_pro/common/constants.dart';
import 'package:flutter_wordpress_pro/common/helpers.dart';
import 'package:flutter_wordpress_pro/models/article.dart';
import 'package:flutter_wordpress_pro/pages/single_Article.dart';
import 'package:flutter_wordpress_pro/widgets/articleBox.dart';
class LocalArticles extends StatefulWidget {
  @override
  _LocalArticlesState createState() => _LocalArticlesState();
}

class _LocalArticlesState extends State<LocalArticles> {
  List<dynamic> articles = [];
  Future<List<dynamic>>? _futureArticles;

  ScrollController? _controller;
  int page = 1;
  bool _infiniteStop = false;

  @override
  void initState() {
    super.initState();
    _futureArticles = fetchLocalArticles(1);
    _controller =
        ScrollController(initialScrollOffset: 0.0, keepScrollOffset: true);
    _controller!.addListener(_scrollListener);
    _infiniteStop = false;
  }

  @override
  void dispose() {
    super.dispose();
    _controller!.dispose();
  }

  Future<List<dynamic>> fetchLocalArticles(int page) async {
    if (!this.mounted) return articles;

    try {
      String requestUrl =
          "$WORDPRESS_URL/wp-json/wp/v2/posts/?categories[]=$PAGE2_CATEGORY_ID&page=$page&per_page=10&_fields=id,date,title,content,custom,link";
      Response response = await customDio.get(
        requestUrl,
        options: buildCacheOptions(Duration(days: 3),
            maxStale: Duration(days: 7), forceRefresh: false),
      );
      if (response.statusCode == 200) {
        setState(() {
          articles
              .addAll(response.data.map((m) => Article.fromJson(m)).toList());
          if (articles.length % 10 != 0) {
            _infiniteStop = true;
          }
        });

        return articles;
      }
    } on DioError catch (e) {
      if (DioErrorType.receiveTimeout == e.type ||
          DioErrorType.connectTimeout == e.type) {
        throw ("Server is not reachable. Please verify your internet connection and try again");
      } else if (DioErrorType.response == e.type) {
        if (e.response!.statusCode == 400) {
          setState(() {
            _infiniteStop = true;
          });
        } else {
          print(e.message);
        }
      } else if (DioErrorType.other == e.type) {
        if (e.message.contains('SocketException')) {
          throw ('No Internet Connection.');
        }
      } else {
        throw ("Problem connecting to the server. Please try again.");
      }
    }

    return articles;
  }

  _scrollListener() {
    if (!this.mounted) return;
    var isEnd = _controller!.offset >= _controller!.position.maxScrollExtent &&
        !_controller!.position.outOfRange;
    if (isEnd) {
      setState(() {
        page += 1;
        _futureArticles = fetchLocalArticles(page);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          PAGE2_CATEGORY_NAME,
          style: Theme.of(context).textTheme.headline2,
        ),
        elevation: 5,
        backgroundColor: Theme.of(context).backgroundColor,
      ),
      body: Container(
        child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            controller: _controller,
            child: Column(
              children: <Widget>[
                categoryPosts(_futureArticles as Future<List<dynamic>>),
              ],
            )),
      ),
    );
  }

  Widget categoryPosts(Future<List<dynamic>> futureArticles) {
    return FutureBuilder<List<dynamic>>(
      future: futureArticles,
      builder: (context, articleSnapshot) {
        if (articleSnapshot.hasData) {
          if (articleSnapshot.data!.length == 0) return Container();
          return Column(
            children: <Widget>[
              ListView.builder(
                  itemCount: articleSnapshot.data!.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    Article item = articleSnapshot.data![index];
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
                          articleBox(context, item, heroId),
                        ],
                      ),
                    );
                  }),
              !_infiniteStop
                  ? Container(
                      )
                  : Container()
            ],
          );
        } else if (articleSnapshot.hasError) {
          return Container();
        }
        return Container(
            );
      },
    );
  }
}
