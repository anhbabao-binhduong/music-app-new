import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../data/repositories/news_repository_impl.dart';
import '../../presentation/bloc/news/news_cubit.dart';
import '../../presentation/bloc/news/news_state.dart';
import '../../presentation/bloc/player/player_bloc.dart';
import '../../presentation/bloc/player/player_state.dart';
import '../../widgets/mini_player_bar.dart';
import 'widgets/news_article_card.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final List<String> _sources = [
    'Tất cả',
    ...NewsRepositoryImpl.rssSources.keys,
  ];
  String _activeSource = 'Tất cả';

  @override
  void initState() {
    super.initState();
    context.read<NewsCubit>().loadNews();
  }

  Future<void> _openArticle(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _filterBySource(String source) {
    setState(() => _activeSource = source);
    final cubit = context.read<NewsCubit>();
    if (source == 'Tất cả') {
      cubit.loadNews();
    } else {
      cubit.loadNews(source: source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme, isLight),
        bottomSheet: const MiniPlayerBar(),
        body: Column(
          children: [
            _buildSourceFilter(theme, isLight),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isLight) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 3,
            height: 22,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kAccent, kAccentPink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Tin tức',
            style: GoogleFonts.plusJakartaSans(
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => _filterBySource(_activeSource),
        ),
      ],
    );
  }

  Widget _buildSourceFilter(ThemeData theme, bool isLight) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _sources.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final src = _sources[index];
          final isActive = _activeSource == src;
          return GestureDetector(
            onTap: () => _filterBySource(src),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [kAccent, kAccentPink],
                      )
                    : null,
                color: isActive
                    ? null
                    : (isLight
                        ? theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6)
                        : kCard),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                src,
                style: GoogleFonts.dmSans(
                  color: isActive
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        print('[UI] state = $state');
        if (state is NewsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: kAccent),
          );
        }

        if (state is NewsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: kSubText,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: kSubText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _filterBySource(_activeSource),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kAccent, kAccentPink],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Thử lại',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is NewsLoaded) {
          if (state.articles.isEmpty) {
            return Center(
              child: Text(
                'Không có bài viết nào',
                style: GoogleFonts.dmSans(color: kSubText, fontSize: 14),
              ),
            );
          }
          return BlocBuilder<PlayerBloc, PlayerState>(
            builder: (context, playerState) {
              final hasPlayer =
                  playerState is PlayerPlaying || playerState is PlayerPaused;
              return ListView.builder(
                padding: EdgeInsets.only(
                  top: 4,
                  bottom: hasPlayer ? 80.0 : 16.0,
                ),
                itemCount: state.articles.length,
                itemBuilder: (_, index) {
                  final article = state.articles[index];
                  return NewsArticleCard(
                    article: article,
                    onTap: () => _openArticle(article.link),
                  );
                },
              );
            },
          );
        }

        // NewsInitial
        return const SizedBox.shrink();
      },
    );
  }
}