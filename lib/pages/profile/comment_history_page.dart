import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/domain/entities/comment_entity.dart';
import 'package:music_app/domain/repositories/comment_repository.dart';
import 'package:music_app/pages/player/player_page.dart';
import 'package:music_app/presentation/bloc/comment_history/comment_history_cubit.dart';
import 'package:music_app/presentation/bloc/comment_history/comment_history_state.dart';

String timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
  if (diff.inDays < 1) return '${diff.inHours} giờ trước';
  if (diff.inDays < 30) return '${diff.inDays} ngày trước';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

class CommentHistoryPage extends StatelessWidget {
  final String userId;

  const CommentHistoryPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommentHistoryCubit(getIt<CommentRepository>())
        ..loadUserComments(userId),
      child: _CommentHistoryView(userId: userId),
    );
  }
}

class _CommentHistoryView extends StatelessWidget {
  final String userId;

  const _CommentHistoryView({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final muted = scheme.onSurface.withValues(alpha: 0.68);
    final soft = scheme.onSurface.withValues(alpha: 0.45);
    final border = scheme.outline.withValues(alpha: isDark ? 0.35 : 0.55);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                iconTheme: IconThemeData(color: scheme.onSurface),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                  title: Text(
                    'Lịch sử bình luận',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background gradient thích ứng theme
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withValues(alpha: isDark ? 0.55 : 0.35),
                              theme.scaffoldBackgroundColor,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // chi tiết trang trí mờ
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.secondary.withValues(alpha: isDark ? 0.20 : 0.16),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────────────────
              BlocBuilder<CommentHistoryCubit, CommentHistoryState>(
                builder: (context, state) {
                  if (state is CommentHistoryLoading) {
                    return SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: scheme.primary),
                      ),
                    );
                  } else if (state is CommentHistoryError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Lỗi: ${state.message}',
                          style: TextStyle(
                            color: scheme.error,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  } else if (state is CommentHistoryLoaded) {
                    final comments = state.comments;
                    if (comments.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                                  border: Border.all(color: border.withValues(alpha: 0.6)),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 64,
                                  color: soft,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Bạn chưa đăng bình luận nào.',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final comment = comments[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _CommentCard(
                                comment: comment,
                                userId: userId,
                              ),
                            );
                          },
                          childCount: comments.length,
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Comment Card ─────────────────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  final CommentEntity comment;
  final String userId;

  const _CommentCard({required this.comment, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final muted = scheme.onSurface.withValues(alpha: 0.68);
    final soft = scheme.onSurface.withValues(alpha: 0.45);
    final border = scheme.outline.withValues(alpha: isDark ? 0.35 : 0.55);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Song Info Header ──────────────────────────────────────────────
          _SongInfoHeader(comment: comment),

          // ── Divider ───────────────────────────────────────────────────────
          Divider(height: 1, color: border),

          // ── Comment Content ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quote Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.format_quote_rounded,
                    size: 20,
                    color: scheme.primary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 16),
                // Comment Body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.content,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          height: 1.5,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeAgo(comment.createdAt),
                        style: TextStyle(
                          color: soft,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu chỉnh sửa / xóa
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 22,
                    color: muted,
                  ),
                  color: scheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: border.withValues(alpha: 0.7)),
                  ),
                  elevation: 10,
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'view') {
                      showSongComments(
                        context,
                        comment.songId,
                        songTitle: comment.songTitle,
                      );
                    } else if (value == 'edit') {
                      _showEditDialog(context, comment.id, comment.content);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, comment.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: muted,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Xem bình luận',
                            style: TextStyle(color: scheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Chỉnh sửa',
                            style: TextStyle(color: scheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: scheme.error,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Xóa',
                            style: TextStyle(color: scheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String commentId, String oldContent) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final textController = TextEditingController(text: oldContent);
    final cubit = context.read<CommentHistoryCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.55),
          ),
        ),
        title: Text(
          'Chỉnh sửa bình luận',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: textController,
          style: TextStyle(color: scheme.onSurface),
          maxLength: 300,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung mới...',
            hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.35)),
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
            counterStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.45)),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              foregroundColor: scheme.onSurface.withValues(alpha: 0.72),
            ),
            child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            onPressed: () {
              final newContent = textController.text.trim();
              if (newContent.isNotEmpty) {
                cubit.editComment(commentId, userId, newContent);
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String commentId) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cubit = context.read<CommentHistoryCubit>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.55),
          ),
        ),
        title: Text(
          'Xóa bình luận',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa bình luận này không?',
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.72),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              foregroundColor: scheme.onSurface.withValues(alpha: 0.72),
            ),
            child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            onPressed: () {
              cubit.deleteComment(commentId, userId);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ─── Song Info Header ─────────────────────────────────────────────────────────

class _SongInfoHeader extends StatelessWidget {
  final CommentEntity comment;

  const _SongInfoHeader({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final hasSongInfo = comment.songTitle != null;
    final border = scheme.outline.withValues(alpha: isDark ? 0.28 : 0.45);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.42 : 0.8),
      ),
      child: Row(
        children: [
          // Artwork
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasSongInfo && comment.songArtUrl != null
                  ? Image.network(
                      comment.songArtUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultArt(),
                    )
                  : _defaultArt(),
            ),
          ),
          const SizedBox(width: 14),
          // Song name + artist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSongInfo ? comment.songTitle! : 'Bài hát không xác định',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasSongInfo && comment.songArtist != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    comment.songArtist!,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Music note badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.14),
                  scheme.secondary.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.music_note_rounded,
                  size: 14,
                  color: scheme.primary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  'BÀI HÁT',
                  style: TextStyle(
                    color: scheme.primary.withValues(alpha: 0.9),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultArt() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ThemeData().colorScheme.primary,
              ThemeData().colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
      );
}