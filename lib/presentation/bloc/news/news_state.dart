import 'package:equatable/equatable.dart';
import '../../../domain/entities/news_article_entity.dart';

abstract class NewsState extends Equatable {
  const NewsState();

  @override
  List<Object?> get props => [];
}

class NewsInitial extends NewsState {
  const NewsInitial();
}

class NewsLoading extends NewsState {
  const NewsLoading();
}

class NewsLoaded extends NewsState {
  final List<NewsArticleEntity> articles;
  final String? activeSource; // null = "Tất cả"

  const NewsLoaded({required this.articles, this.activeSource});

  @override
  List<Object?> get props => [articles, activeSource];
}

class NewsError extends NewsState {
  final String message;

  const NewsError(this.message);

  @override
  List<Object?> get props => [message];
}