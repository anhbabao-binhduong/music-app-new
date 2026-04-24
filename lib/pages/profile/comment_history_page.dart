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
      create: (_) => CommentHistoryCubit(getIt<CommentRepository>())..loadUserComments(userId),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Màn hình nền mờ Header ───────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  backgroundColor: const Color(0xFF121212),
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                    title: const Text(
                      'Lịch sử bình luận',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background gradient nghệ thuật
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4A148C), Color(0xFF121212)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        // Thêm chi tiết trang trí mờ
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEC4899).withValues(alpha: 0.2),
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

                // ── Nội dung danh sách ───────────────────────────────────────────
                BlocBuilder<CommentHistoryCubit, CommentHistoryState>(
                  builder: (context, state) {
                    if (state is CommentHistoryLoading) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFF9333EA)),
                        ),
                      );
                    } else if (state is CommentHistoryError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'Lỗi: ${state.message}',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
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
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Bạn chưa đăng bình luận nào.',
                                  style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
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
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),

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
                    color: const Color(0xFF9333EA).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.format_quote_rounded,
                    size: 20,
                    color: Color(0xFFD8B4FE), // Light purple
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeAgo(comment.createdAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu chỉnh sửa / xóa
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 22, color: Colors.white.withValues(alpha: 0.5)),
                  color: const Color(0xFF2A2A2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
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
                          Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white70),
                          SizedBox(width: 12),
                          Text('Xem bình luận', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18, color: Color(0xFFD8B4FE)),
                          SizedBox(width: 12),
                          Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                          SizedBox(width: 12),
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Chỉnh sửa bình luận',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          maxLength: 300,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung mới...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF9333EA), width: 1.5),
            ),
            counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text('Hủy', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              final newContent = textController.text.trim();
              if (newContent.isNotEmpty) {
                cubit.editComment(commentId, userId, newContent);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.w700)),
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa bình luận',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bình luận này không?',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text('Hủy', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              cubit.deleteComment(commentId, userId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.w700)),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
      ),
      child: Row(
        children: [
          // Artwork
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
                  const Color(0xFF9333EA).withValues(alpha: 0.2),
                  const Color(0xFFEC4899).withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_note_rounded, size: 14, color: Color(0xFFD8B4FE)),
                const SizedBox(width: 4),
                Text(
                  'BÀI HÁT',
                  style: TextStyle(
                    color: const Color(0xFFD8B4FE).withValues(alpha: 0.9),
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
          gradient: const LinearGradient(
            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
      );
}
