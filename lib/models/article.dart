import 'package:intl/intl.dart';

class Article {
  final int id;
  final String title;
  final String content;
  final String image;
  final String video;
  final String author;
  final String avatar;
  final String category;
  final String date;
  final String link;
  final int catId;

  Article(
      {this.id,
      this.title,
      this.content,
      this.image,
      this.video,
      this.author,
      this.avatar,
      this.category,
      this.date,
      this.link,
      this.catId});

  factory Article.fromJson(Map<String, dynamic> json) {
    String content = json['content'] != null ? json['content']['rendered'] : "";
    String date = DateFormat('dd MMMM, yyyy', 'en_US')
        .format(DateTime.parse(json["date"]))
        .toString();
    String title = json['title']['rendered'];
    String link = json["link"];
    int id = -1;

    String image =
        "https://flutterblog.crumet.com/wp-content/uploads/2020/06/36852.jpg";
    String video = "";
    String author = "";
    String avatar = "";
    String category = "";
    int catId = -1;

    if (json['custom'] != null) {
      if (json['custom']["featured_image"] != "") {
        image = json['custom']["featured_image"].toString();
      }

      video = json['custom']["td_video"];

      author = json['custom']["author"]["name"];

      avatar = json['custom']["author"]["avatar"];

      if (json["custom"]["categories"] != "") {
        category = json["custom"]["categories"][0]["name"].toString();
      }

      if (json["custom"]["categories"] != "") {
        catId = json["custom"]["categories"][0]["cat_ID"];
      }

      id = json['id'];
    }

    return Article(
        id: id,
        title: title,
        content: content,
        image: image,
        video: video,
        author: author,
        avatar: avatar,
        category: category,
        date: date,
        link: link,
        catId: catId);
  }

  factory Article.fromDatabaseJson(Map<String, dynamic> data) => Article(
      id: data['id'],
      title: data['title'],
      content: data['content'],
      image: data['image'],
      video: data['video'],
      author: data['author'],
      avatar: data['avatar'],
      category: data['category'],
      date: data['date'],
      link: data['link'],
      catId: data["catId"]);

  Map<String, dynamic> toDatabaseJson() => {
        'id': this.id,
        'title': this.title,
        'content': this.content,
        'image': this.image,
        'video': this.video,
        'author': this.author,
        'avatar': this.avatar,
        'category': this.category,
        'date': this.date,
        'link': this.link,
        'catId': this.catId
      };
}
