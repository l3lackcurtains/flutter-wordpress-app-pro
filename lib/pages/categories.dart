import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_wordpress_pro/common/constants.dart';
import 'package:flutter_wordpress_pro/models/Category.dart';
import 'package:flutter_wordpress_pro/pages/category_articles.dart';
import 'package:http/http.dart' as http;

class Categories extends StatefulWidget {
  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  Future<List<dynamic>>? _futureCategories;
  List<dynamic> categories = [];

  @override
  void initState() {
    super.initState();
    _futureCategories = fetchCategories();
  }

  Future<List<dynamic>> fetchCategories() async {
    if (!this.mounted) return categories;
    try {
      var response = await http
          .get(Uri.parse("$WORDPRESS_URL/wp-json/wp/v2/categories?per_page=100"));

      if (response.statusCode == 200) {
        setState(() {
          categories = json
              .decode(response.body)
              .map((m) => Category.fromJson(m))
              .toList();
        });

        return categories;
      }
    } on SocketException {
      throw 'No Internet connection';
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Categories', style: Theme.of(context).textTheme.headline2),
        elevation: 5,
        backgroundColor: Theme.of(context).backgroundColor,
      ),
      body: Container(
        child: getCategoriesList(_futureCategories as Future<List<dynamic>>),
      ),
    );
  }

  Widget getCategoriesList(Future<List<dynamic>> categories) {
    return FutureBuilder<List<dynamic>>(
      future: categories,
      builder: (context, categorySnapshot) {
        if (categorySnapshot.hasData) {
          if (categorySnapshot.data!.length == 0) return Container();
          return ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: categorySnapshot.data!.length,
              itemBuilder: (BuildContext ctxt, int index) {
                Category category = categorySnapshot.data![index];
                if (category.parent == 0) {
                  return Card(
                      elevation: 1,
                      margin: EdgeInsets.all(8),
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        backgroundColor: Color(0xFFF9F9F9),
                        title: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryArticles(
                                    int.parse(category.id.toString()), category.name.toString()),
                              ),
                            );
                          },
                          child: Text(
                            category.name.toString(),
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(4.0),
                            child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: categorySnapshot.data!.length,
                                itemBuilder: (BuildContext ctxt2, int index2) {
                                  Category subCategory =
                                      categorySnapshot.data![index2];
                                  if (subCategory.parent == category.id) {
                                    return InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CategoryArticles(
                                                      int.parse(subCategory.id.toString()),
                                                      subCategory.name.toString()),
                                            ),
                                          );
                                        },
                                        child: ListTile(
                                          title: Text(subCategory.name.toString()),
                                        ));
                                  }
                                  return Container();
                                }),
                          ),
                        ],
                      ));
                }
                return Container();
              });
        } else if (categorySnapshot.hasError) {
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
                    _futureCategories = fetchCategories();
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
