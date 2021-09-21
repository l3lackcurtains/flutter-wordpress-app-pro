import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_wordpress_pro/common/constants.dart';
import 'package:flutter_wordpress_pro/common/helpers.dart';
import 'package:flutter_wordpress_pro/models/article.dart';
import 'package:flutter_wordpress_pro/pages/comments.dart';
import 'package:flutter_wordpress_pro/widgets/articleBox.dart';
import 'package:share/share.dart';

class SingleArticle extends StatefulWidget {
  final Article article;
  final String heroId;

  const SingleArticle(this.article, this.heroId, {Key? key}) : super(key: key);

  @override
  _SingleArticleState createState() => _SingleArticleState();
}

class _SingleArticleState extends State<SingleArticle> {
  List<dynamic> relatedArticles = [];
  Future<List<dynamic>>? _futureRelatedArticles;

  @override
  void initState() {
    super.initState();
    _futureRelatedArticles = fetchRelatedArticles();
  }

  Future<List<dynamic>> fetchRelatedArticles() async {
    if (!this.mounted) return relatedArticles;

    try {
      String postId = widget.article.id.toString();
      String catId = widget.article.catId.toString();

      String requestUrl =
          "$WORDPRESS_URL/wp-json/wp/v2/posts?exclude=$postId&categories[]=$catId&per_page=3";

      Response response = await customDio.get(
        requestUrl,
        options: buildCacheOptions(Duration(days: 3),
            maxStale: Duration(days: 7), forceRefresh: false),
      );
      if (response.statusCode == 200) {
        setState(() {
          relatedArticles =
              response.data.map((m) => Article.fromJson(m)).toList();
        });

        return relatedArticles;
      }
    } on DioError catch (e) {
      print(e);
    }
    return relatedArticles;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Article article = widget.article;
    final heroId = widget.heroId;
    final articleVideo = widget.article.video;
    String youtubeUrl = "";
    String dailymotionUrl = "";
    if (articleVideo!.contains("youtube")) {
      youtubeUrl = articleVideo.split('?v=')[1];
    }
    if (articleVideo.contains("dailymotion")) {
      dailymotionUrl = articleVideo.split("/video/")[1];
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
          child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: <Widget>[
            Stack(
              children: <Widget>[
                Container(
                  child: Hero(
                    tag: heroId,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.only(bottomLeft: Radius.circular(60.0)),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3), BlendMode.overlay),
                        child: articleVideo != ""
                            ? articleVideo.contains("youtube")
                                ? Container(
                                    padding: EdgeInsets.fromLTRB(
                                        0,
                                        MediaQuery.of(context).padding.top,
                                        0,
                                        0),
                                    decoration:
                                        BoxDecoration(color: Colors.black),
                                    child: HtmlWidget(
                                      """
                                      <iframe src="https://www.youtube.com/embed/$youtubeUrl" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
                                      """,
                                      webView: true,
                                    ),
                                  )
                                : articleVideo.contains("dailymotion")
                                    ? Container(
                                        padding: EdgeInsets.fromLTRB(
                                            0,
                                            MediaQuery.of(context).padding.top,
                                            0,
                                            0),
                                        decoration:
                                            BoxDecoration(color: Colors.black),
                                        child: HtmlWidget(
                                          """
                                      <iframe frameborder="0"
                                      src="https://www.dailymotion.com/embed/video/$dailymotionUrl?autoplay=1&mute=1"
                                      allowfullscreen allow="autoplay">
                                      </iframe>
                                      """,
                                          webView: true,
                                        ),
                                      )
                                    : Container(
                                        padding: EdgeInsets.fromLTRB(
                                            0,
                                            MediaQuery.of(context).padding.top,
                                            0,
                                            0),
                                        decoration:
                                            BoxDecoration(color: Colors.black),
                                        child: HtmlWidget(
                                          """
                                      <video autoplay="" playsinline="" controls>
                                      <source type="video/mp4" src="$articleVideo">
                                      </video>
                                      """,
                                          webView: true,
                                        ),
                                      )
                            : CachedNetworkImage(
                                imageUrl: article.image.toString(),
                                placeholder: (context, url) => Container(
                                    alignment: Alignment.center,
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 6,
                                        backgroundColor: Theme.of(context)
                                            .secondaryHeaderColor)),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back),
                    color: Theme.of(context).primaryColorDark,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Html(
                      data: article.title!.length > 70
                          ? "<h2>" +
                              article.title.toString().substring(0, 70) +
                              "...</h2>"
                          : "<h2>" + article.title.toString() + "</h2>",
                      style: {
                        "h2": Style(
                            color: Theme.of(context).primaryColorDark,
                            fontWeight: FontWeight.w500,
                            fontSize: FontSize.em(1.8),
                            padding: EdgeInsets.all(4)),
                      }),
                  Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).canvasColor,
                        borderRadius: BorderRadius.circular(3)),
                    padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                    margin: EdgeInsets.all(16),
                    child: Text(
                      article.category.toString(),
                      style: TextStyle(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: 11),
                    ),
                  ),
                  SizedBox(
                    height: 45,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(article.avatar.toString()),
                      ),
                      title: Text(
                        "By " + article.author.toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        article.date.toString(),
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 36, 16, 50),
                    child: HtmlWidget(
                      article.content.toString(),
                      webView: true,
                      textStyle:
                          Theme.of(context).textTheme.bodyText1 as TextStyle,
                    ),
                  ),
                ],
              ),
            ),
            relatedPosts(_futureRelatedArticles as Future<List<dynamic>>),
          ],
        ),
      )),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 50,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).backgroundColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                child: IconButton(
                  padding: EdgeInsets.all(0),
                  icon: Icon(
                    Icons.comment,
                    color: Colors.blue,
                    size: 24.0,
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Comments(article.id ?? -1),
                          fullscreenDialog: true,
                        ));
                  },
                ),
              ),
              Container(
                child: IconButton(
                  padding: EdgeInsets.all(0),
                  icon: Icon(
                    Icons.share,
                    color: Colors.green,
                    size: 24.0,
                  ),
                  onPressed: () {
                    Share.share('Share the news: ' + article.link.toString());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget relatedPosts(Future<List<dynamic>> latestArticles) {
    return FutureBuilder<List<dynamic>>(
      future: latestArticles,
      builder: (context, articleSnapshot) {
        if (articleSnapshot.hasData) {
          if (articleSnapshot.data!.length == 0) return Container();
          return Column(
            children: <Widget>[
              Container(
                alignment: Alignment.topLeft,
                padding: EdgeInsets.all(16),
                child: Text(
                  "Related Posts",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: "Poppins"),
                ),
              ),
              Column(
                children: articleSnapshot.data!.map((item) {
                  final heroId = item.id.toString() + "-related";
                  return InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SingleArticle(item, heroId),
                        ),
                      );
                    },
                    child: articleBox(context, item, heroId),
                  );
                }).toList(),
              ),
              SizedBox(
                height: 24,
              )
            ],
          );
        } else if (articleSnapshot.hasError) {
          return Container(
              height: 500,
              alignment: Alignment.center,
              child: Text("${articleSnapshot.error}"));
        }
        return Container();
      },
    );
  }
}
