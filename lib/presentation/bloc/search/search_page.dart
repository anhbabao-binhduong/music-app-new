import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/song_entity.dart';
import '../../bloc/search/search_cubit.dart';
import '../../bloc/search/search_state.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: _SearchBar(
          controller: _controller,
          onChanged: (q) =>
              context.read<SearchCubit>().onQueryChanged(q),
          onClear: () {
            _controller.clear();
            context.read<SearchCubit>().clearSearch();
          },
        ),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) => switch (state) {
          SearchInitial() => _EmptyPrompt(),
          SearchLoading() => const Center(child: CircularProgressIndicator()),
          SearchSuccess s => _ResultList(results: s.results, query: s.query),
          SearchEmpty   s => _NoResults(query: s.query),
          SearchError   s => _ErrorView(message: s.message),
          _               => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search songs, artists, albums…',
        hintStyle: TextStyle(color: cs.outline),
        prefixIcon: Icon(Icons.search_rounded, color: cs.outline),
        suffixIcon: ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, v, __) => v.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: cs.outline),
                  onPressed: onClear,
                )
              : const SizedBox.shrink(),
        ),
        border: InputBorder.none,
        filled: false,
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  final List<SongEntity> results;
  final String query;
  const _ResultList({required this.results, required this.query});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final s = results[i];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: s.artUrl != null
                ? Image.network(s.artUrl!, width: 48, height: 48, fit: BoxFit.cover)
                : Container(
                    width: 48, height: 48,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: const Icon(Icons.music_note_rounded),
                  ),
          ),
          title: _HighlightText(text: s.title, query: query),
          subtitle: _HighlightText(text: s.artist, query: query, isSubtitle: true),
          onTap: () { /* dispatch LoadPlaylistEvent */ },
        );
      },
    );
  }
}

/// Highlights matching query text in results
class _HighlightText extends StatelessWidget {
  final String text, query;
  final bool isSubtitle;
  const _HighlightText({required this.text, required this.query, this.isSubtitle = false});

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final tt  = Theme.of(context).textTheme;
    final idx = text.toLowerCase().indexOf(query.toLowerCase());

    if (idx == -1) {
      return Text(text, style: isSubtitle ? tt.titleMedium : tt.titleLarge);
    }

    return Text.rich(TextSpan(children: [
      TextSpan(
        text: text.substring(0, idx),
        style: isSubtitle ? tt.titleMedium : tt.titleLarge,
      ),
      TextSpan(
        text: text.substring(idx, idx + query.length),
        style: (isSubtitle ? tt.titleMedium : tt.titleLarge)?.copyWith(
          color: cs.primary, fontWeight: FontWeight.w700,
        ),
      ),
      TextSpan(
        text: text.substring(idx + query.length),
        style: isSubtitle ? tt.titleMedium : tt.titleLarge,
      ),
    ]));
  }
}

class _EmptyPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_rounded, size: 64,
            color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text('Search your music', style: Theme.of(context).textTheme.titleMedium),
      ]));
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('No results for "$query"',
          style: Theme.of(context).textTheme.titleMedium));
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(message, style: const TextStyle(color: Colors.redAccent)));
}