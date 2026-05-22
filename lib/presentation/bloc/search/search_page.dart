import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../data/local_music_data.dart';
import '../../../domain/entities/song_entity.dart';
import '../../../widgets/auth_guard.dart';
import '../../bloc/search/search_cubit.dart';
import '../../bloc/search/search_state.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  late final stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  void _playSong(BuildContext ctx, SongEntity song) {
    final index = localPlaylist.indexWhere((m) => m.id == song.audioUrl);
    if (index == -1) return;
    playWithAuthGuard(ctx, playlist: localPlaylist, index: index);
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    // Web: browser will request mic permission itself.
    // Mobile/Desktop: request permission via permission_handler.
    if (!kIsWeb) {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) return;
    }

    _speechAvailable = await _speech.initialize(
      onError: (e) {
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );

    if (!_speechAvailable) return;

    if (mounted) setState(() => _isListening = true);

    await _speech.listen(
      localeId: 'vi_VN',
      listenMode: stt.ListenMode.search,
      partialResults: true,
      onResult: (result) {
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) return;

        _controller.value = TextEditingValue(
          text: recognized,
          selection: TextSelection.collapsed(offset: recognized.length),
        );

        context.read<SearchCubit>().onQueryChanged(recognized);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _SearchBar(
          controller: _controller,
          isListening: _isListening,
          onVoiceTap: _toggleVoice,
          onChanged: (q) => context.read<SearchCubit>().onQueryChanged(q),
          onClear: () {
            _controller.clear();
            context.read<SearchCubit>().clearSearch();
          },
        ),
        automaticallyImplyLeading: true,
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) => switch (state) {
          SearchInitial() => const _EmptyPrompt(),
          SearchLoading() => const Center(child: CircularProgressIndicator()),
          SearchSuccess s => _ResultList(
              results: s.results,
              query: s.query,
              onTap: (song) => _playSong(context, song),
            ),
          SearchEmpty s => _NoResults(query: s.query),
          SearchError s => _ErrorView(message: s.message),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final VoidCallback onVoiceTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({
    required this.controller,
    required this.isListening,
    required this.onVoiceTap,
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
        hintText: 'Tìm bài hát, nghệ sĩ hoặc nhập lời bài hát...',
        hintStyle: TextStyle(color: cs.outline),
        prefixIcon: Icon(Icons.search_rounded, color: cs.outline),
        suffixIcon: ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, v, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: isListening ? 'Dừng ghi âm' : 'Tìm bằng giọng nói',
                icon: Icon(
                  isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: isListening ? cs.primary : cs.outline,
                ),
                onPressed: onVoiceTap,
              ),
              if (v.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear_rounded, color: cs.outline),
                  onPressed: onClear,
                ),
            ],
          ),
        ),
        border: InputBorder.none,
        filled: false,
      ),
    );
  }
}

// ── Result List ───────────────────────────────────────────────────────────────

class _ResultList extends StatelessWidget {
  final List<SongEntity> results;
  final String query;
  final ValueChanged<SongEntity> onTap;
  const _ResultList({required this.results, required this.query, required this.onTap});

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
                ? Image.network(s.artUrl!, width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _artPlaceholder(context))
                : _artPlaceholder(context),
          ),
          title:    _HighlightText(text: s.title,  query: query),
          subtitle: _HighlightText(text: s.artist, query: query, isSubtitle: true),
          trailing: const Icon(Icons.play_arrow_rounded, color: Colors.white54),
          onTap: () => onTap(s),
        );
      },
    );
  }

  Widget _artPlaceholder(BuildContext context) => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Icon(Icons.music_note_rounded),
  );
}

// ── Highlight matching text ───────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text, query;
  final bool isSubtitle;
  const _HighlightText({required this.text, required this.query, this.isSubtitle = false});

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final tt  = Theme.of(context).textTheme;
    final idx = text.toLowerCase().indexOf(query.toLowerCase());

    final base = isSubtitle ? tt.titleMedium : tt.titleLarge;

    if (idx == -1) return Text(text, style: base);

    return Text.rich(TextSpan(children: [
      TextSpan(text: text.substring(0, idx), style: base),
      TextSpan(
        text: text.substring(idx, idx + query.length),
        style: base?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
      ),
      TextSpan(text: text.substring(idx + query.length), style: base),
    ]));
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_rounded, size: 64, color: Theme.of(context).colorScheme.outline),
      const SizedBox(height: 16),
      Text('Tìm kiếm bài hát', style: Theme.of(context).textTheme.titleMedium),
    ]),
  );
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});
  @override
  Widget build(BuildContext context) => Center(
    child: Text('Không tìm thấy "$query"', style: Theme.of(context).textTheme.titleMedium),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(message, style: const TextStyle(color: Colors.redAccent)));
}