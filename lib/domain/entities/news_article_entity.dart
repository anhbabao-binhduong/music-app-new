import 'package:equatable/equatable.dart';

class NewsArticleEntity extends Equatable {
  final String title;
  final String link;
  final String pubDate;
  final String? imageUrl;
  final String? description;
  final String source;

  const NewsArticleEntity({
    required this.title,
    required this.link,
    required this.pubDate,
    this.imageUrl,
    this.description,
    required this.source,
  });

  @override
  List<Object?> get props => [title, link, pubDate, imageUrl, description, source];
}