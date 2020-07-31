import 'package:flutter/material.dart';
import 'package:flutter_wordpress_pro/blocs/favArticleBloc.dart';
import 'package:flutter_wordpress_pro/models/article.dart';
import 'package:flutter_wordpress_pro/pages/single_Article.dart';
import 'package:flutter_wordpress_pro/widgets/articleBox.dart';
import 'package:loading/indicator/ball_beat_indicator.dart';
import 'package:loading/loading.dart';

class FavouriteArticles extends StatefulWidget {
  FavouriteArticles({Key key}) : super(key: key);
  @override
  _FavouriteArticlesState createState() => _FavouriteArticlesState();
}

class _FavouriteArticlesState extends State<FavouriteArticles> {
  final FavArticleBloc favArticleBloc = FavArticleBloc();

  @override
  void initState() {
    super.initState();
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
        title: Text("Favourite",
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.headline2),
        elevation: 5,
        backgroundColor: Theme.of(context).backgroundColor,
      ),
      body: Container(
        child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(children: <Widget>[categoryPosts()])),
      ),
    );
  }

  Widget categoryPosts() {
    return FutureBuilder<List<Article>>(
      future: favArticleBloc.getFavArticles(),
      builder: (context, AsyncSnapshot<List<Article>> articleSnapshot) {
        if (articleSnapshot.hasData) {
          if (articleSnapshot.data.length == 0) return Container();
          return Column(
              children: articleSnapshot.data.map((item) {
            final heroId = item.id.toString() + "-favpost";
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
          }).toList());
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
