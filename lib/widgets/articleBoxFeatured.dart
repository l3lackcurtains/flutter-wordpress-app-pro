import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_wordpress_pro/models/article.dart';

Widget articleBoxFeatured(
    BuildContext context, Article article, String heroId) {
  return ConstrainedBox(
    constraints: new BoxConstraints(
        minHeight: 280.0, maxHeight: 290.0, minWidth: 360.0, maxWidth: 360.0),
    child: Stack(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(8),
          child: Container(
            height: 200,
            width: 400,
            child: Card(
              child: Hero(
                tag: heroId,
                child: ClipRRect(
                  borderRadius: new BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: article.image.toString(),
                    placeholder: (context, url) => Container(
                        alignment: Alignment.center,
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 6,
                            backgroundColor:
                                Theme.of(context).secondaryHeaderColor)),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 1,
              margin: EdgeInsets.all(10),
            ),
          ),
        ),
        Positioned(
          left: 20,
          top: 80,
          right: 20,
          child: Container(
            alignment: Alignment.bottomRight,
            height: 200,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Card(
                child: Container(
                  padding: EdgeInsets.fromLTRB(8, 16, 8, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        child: Html(
                              data: article.title!.length > 70
                                  ? "<h4>" +
                                      article.title.toString().substring(0, 70) +
                                      "...</h4>"
                                  : "<h4>" + article.title.toString() + "</h4>",

                                  style: {
                                  "h4": Style(color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.w500, fontSize: FontSize.em(1.02)),
                                }
                              ),
                      ),
                      Container(
                        alignment: Alignment.topLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).canvasColor,
                                  borderRadius: BorderRadius.circular(3)),
                              padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                              margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
                              child: Text(
                                article.category.toString(),
                                style: TextStyle(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.timer,
                                    color: Theme.of(context).canvasColor,
                                    size: 12.0,
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    article.date.toString(),
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        article.video != ""
            ? Positioned(
                left: 18,
                top: 18,
                child: Card(
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.transparent,
                    child: Image.asset("assets/play-button.png"),
                  ),
                  elevation: 18.0,
                  shape: CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                ),
              )
            : Container()
      ],
    ),
  );
}
