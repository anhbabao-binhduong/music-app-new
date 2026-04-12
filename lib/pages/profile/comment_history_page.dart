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
      create: (_) =>
          CommentHistoryCubit(getIt<CommentRepository>())..loadUserComments(userId),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Lịch sử bình luận',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<CommentHistoryCubit, CommentHistoryState>(
          builder: (context, state) {
            if (state is CommentHistoryLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
            } else if (state is CommentHistoryError) {
              return Center(
                child: Text('Lỗi: ${state.message}',
                    style: const TextStyle(color: Colors.redAccent)),
              );
            } else if (state is CommentHistoryLoaded) {
              final comments = state.comments;
              if (comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 16),
                      const Text(
                        'Bạn chưa đăng bình luận nào.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return _CommentCard(
                    comment: comment,
                    userId: userId,
                  );
                },
              );
            }
            return const SizedBox();
          },
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Song Info Header ──────────────────────────────────────────────
          _SongInfoHeader(comment: comment),

          // ── Divider ───────────────────────────────────────────────────────
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),

          // ── Comment Content ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote_rounded,
                    size: 18, color: Colors.deepPurpleAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeAgo(comment.createdAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu chỉnh sửa / xóa
                  PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 20, color: Colors.white.withValues(alpha: 0.4)),
                  color: const Color(0xFF2A2A2E),
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
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white70),
                          SizedBox(width: 10),
                          Text('Xem bình luận', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: Colors.deepPurpleAccent),
                          SizedBox(width: 10),
                          Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                          SizedBox(width: 10),
                          Text('Xóa', style: TextStyle(color: Colors.redAccent)),
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
    final textController = TextEditingController(text: oldContent);
    final cubit = context.read<CommentHistoryCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Chỉnh sửa bình luận',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          maxLength: 300,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung mới...',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterStyle: const TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final newContent = textController.text.trim();
              if (newContent.isNotEmpty) {
                cubit.editComment(commentId, userId, newContent);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Lưu',
                style: TextStyle(
                    color: Colors.deepPurpleAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String commentId) {
    final cubit = context.read<CommentHistoryCubit>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa bình luận',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bình luận này không?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              cubit.deleteComment(commentId, userId);
              Navigator.pop(ctx);
            },
            child: const Text('Xóa',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
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
    final hasSongInfo = comment.songTitle != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          // Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasSongInfo && comment.songArtUrl != null
                ? Image.network(
                    comment.songArtUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultArt(),
                  )
                : _defaultArt(),
          ),
          const SizedBox(width: 12),
          // Song name + artist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSongInfo ? comment.songTitle! : 'Bài hát không xác định',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasSongInfo && comment.songArtist != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    comment.songArtist!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note_rounded,
                    size: 12, color: Colors.deepPurpleAccent),
                SizedBox(width: 3),
                Text('Bài hát',
                    style: TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultArt() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 20),
      );
}
