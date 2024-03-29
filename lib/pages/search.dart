import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_wordpress_pro/common/constants.dart';
import 'package:flutter_wordpress_pro/models/article.dart';
import 'package:flutter_wordpress_pro/pages/single_article.dart';
import 'package:flutter_wordpress_pro/widgets/articleBox.dart';
import 'package:flutter_wordpress_pro/widgets/searchBoxes.dart';
import 'package:http/http.dart' as http;


class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  String _searchText = "";
  List<dynamic> searchedArticles = [];
  Future<List<dynamic>>? _futureSearchedArticles;
  ScrollController? _scrollController;

  final TextEditingController _textFieldController =
      new TextEditingController();

  int page = 1;
  bool _infiniteStop = false;

  @override
  void initState() {
    super.initState();
    _futureSearchedArticles =
        fetchSearchedArticles(_searchText, _searchText == "", page, false);
    _scrollController =
        ScrollController(initialScrollOffset: 0.0, keepScrollOffset: true);
    _scrollController!.addListener(_scrollListener);
    _infiniteStop = false;
  }

  Future<List<dynamic>> fetchSearchedArticles(
      String searchText, bool empty, int page, bool scrollUpdate) async {
    if (!this.mounted) return searchedArticles;
    try {
      if (empty) {
        return searchedArticles;
      }

      var response = await http.get(
          Uri.parse("$WORDPRESS_URL/wp-json/wp/v2/posts?search=$searchText&page=$page&per_page=10&_fields=id,date,title,content,custom,link"));

      if (response.statusCode == 200) {
        setState(() {
          if (scrollUpdate) {
            searchedArticles.addAll(json
                .decode(response.body)
                .map((m) => Article.fromJson(m))
                .toList());
          } else {
            searchedArticles = json
                .decode(response.body)
                .map((m) => Article.fromJson(m))
                .toList();
          }

          if (searchedArticles.length % 10 != 0) {
            _infiniteStop = true;
          }
        });

        return searchedArticles;
      }
      setState(() {
        _infiniteStop = true;
      });
    } on SocketException {
      throw 'No Internet connection';
    }
    return searchedArticles;
  }

  _scrollListener() {
    if (!this.mounted) return;
    var isEnd = _scrollController!.offset >=
            _scrollController!.position.maxScrollExtent &&
        !_scrollController!.position.outOfRange;
    if (isEnd) {
      setState(() {
        page += 1;
        _futureSearchedArticles =
            fetchSearchedArticles(_searchText, _searchText == "", page, true);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _textFieldController.dispose();
    _scrollController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Search', style: Theme.of(context).textTheme.headline2),
        elevation: 5,
        backgroundColor: Theme.of(context).backgroundColor,
      ),
      body: Container(
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Card(
                  elevation: 6,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: TextField(
                        controller: _textFieldController,
                        decoration: InputDecoration(
                          labelText: 'Search news',
                          suffixIcon: _searchText == ""
                              ? Icon(Icons.search)
                              : IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    _textFieldController.clear();
                                    setState(() {
                                      _searchText = "";
                                      _futureSearchedArticles =
                                          fetchSearchedArticles(_searchText,
                                              _searchText == "", page, false);
                                    });
                                  },
                                ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (text) {
                          setState(() {
                            _searchText = text;
                            page = 1;
                            _futureSearchedArticles = fetchSearchedArticles(
                                _searchText, _searchText == "", page, false);
                          });
                        }),
                  ),
                ),
              ),
              searchPosts(_futureSearchedArticles as Future<List<dynamic>>)
            ],
          ),
        ),
      ),
    );
  }

  Widget searchPosts(Future<List<dynamic>> articles) {
    return FutureBuilder<List<dynamic>>(
      future: articles,
      builder: (context, articleSnapshot) {
        if (articleSnapshot.hasData) {
          if (articleSnapshot.data!.length == 0) {
            return Column(
              children: <Widget>[
                searchBoxes(context),
              ],
            );
          }
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
                      child: articleBox(context, item, heroId),
                    );
                  }),
              !_infiniteStop
                  ? Container(
                      )
                  : Container()
            ],
          );
        } else if (articleSnapshot.hasError) {
          return Container(
            alignment: Alignment.center,
            margin: EdgeInsets.fromLTRB(0, 60, 0, 0),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: <Widget>[
                Image.asset(
                  "assets/no-internet.png",
                  width: 250,
                ),
                Text("No Internet Connection."),
                TextButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text("Reload"),
                  onPressed: () {
                    _futureSearchedArticles = fetchSearchedArticles(
                        _searchText, _searchText == "", page, false);
                  },
                )
              ],
            ),
          );
        }
        return Container(
            );
      },
    );
  }
}
