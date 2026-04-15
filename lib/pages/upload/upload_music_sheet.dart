import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/constants/colors.dart';
import 'package:music_app/presentation/bloc/upload/upload_cubit.dart';
import 'package:music_app/presentation/bloc/upload/upload_state.dart';
import 'package:music_app/presentation/bloc/user_songs/user_songs_cubit.dart';

/// Mở sheet upload nhạc
void showUploadMusicSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<UploadCubit>(),
      child: BlocProvider.value(
        value: context.read<UserSongsCubit>(),
        child: const _UploadMusicSheet(),
      ),
    ),
  );
}

class _UploadMusicSheet extends StatefulWidget {
  const _UploadMusicSheet();

  @override
  State<_UploadMusicSheet> createState() => _UploadMusicSheetState();
}

class _UploadMusicSheetState extends State<_UploadMusicSheet> {
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _albumCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _albumCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadCubit, UploadState>(
      listener: (context, state) async {
        if (state is UploadSuccess) {
          // Reload danh sách bài của user sau khi upload thành công
          await context.read<UserSongsCubit>().loadMySongs();
          if (!context.mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎵 "${state.songTitle}" đã được gửi, đang chờ kiểm duyệt!'),
              backgroundColor: kAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          context.read<UploadCubit>().reset();
        } else if (state is UploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${state.message}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: kAccent.withValues(alpha: 0.3), width: 1),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kAccent, kAccentPink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Upload Nhạc',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            Text('Chia sẻ âm nhạc với cộng đồng',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Khi đang upload, hiển thị progress
                    if (state is UploadInProgress) ...[
                      _buildProgressView(state),
                    ] else ...[
                      // Chọn file
                      _buildFileSelector(context, state),
                      const SizedBox(height: 16),

                      // Form thông tin (chỉ hiện khi đã chọn file)
                      if (state is UploadFilePicked || state is UploadCoverPicked) ...[
                        // Cảnh báo file lớn
                        if (state is UploadFilePicked && state.isLargeFile)
                          _buildLargeFileWarning(state.fileSizeMB),
                        if (state is UploadCoverPicked)
                          _buildCoverPreview(context, state),

                        const SizedBox(height: 12),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildField(
                                controller: _titleCtrl,
                                label: 'Tên bài hát *',
                                icon: Icons.music_note_rounded,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Vui lòng nhập tên bài hát' : null,
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                controller: _artistCtrl,
                                label: 'Ca sĩ / Nghệ sĩ',
                                icon: Icons.person_rounded,
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                controller: _albumCtrl,
                                label: 'Album (tùy chọn)',
                                icon: Icons.album_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nút chọn ảnh bìa
                        if (state is UploadFilePicked)
                          OutlinedButton.icon(
                            onPressed: () => context.read<UploadCubit>().pickCoverImage(),
                            icon: const Icon(Icons.image_rounded, size: 18),
                            label: const Text('Chọn ảnh bìa (tùy chọn)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Nút Upload
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kAccent, kAccentPink],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _submit(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                              label: const Text('Tải lên',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileSelector(BuildContext context, UploadState state) {
    final hasFile = state is UploadFilePicked || state is UploadCoverPicked;

    return GestureDetector(
      onTap: hasFile ? null : () => context.read<UploadCubit>().pickAudioFile(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasFile
              ? kAccent.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile
                ? kAccent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: hasFile
            ? _buildPickedFileInfo(state)
            : Column(
                children: [
                  Icon(Icons.audio_file_rounded,
                    size: 40, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  const Text('Nhấn để chọn file nhạc',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('MP3, M4A, WAV, OGG, FLAC',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                ],
              ),
      ),
    );
  }

  Widget _buildPickedFileInfo(UploadState state) {
    String fileName = '';
    String fileSize = '';
    if (state is UploadFilePicked) {
      fileName = state.fileName;
      fileSize = state.fileSizeMB;
    } else if (state is UploadCoverPicked) {
      fileName = state.audioPath.split('/').last;
      fileSize = '${(state.audioSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: kAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.audio_file_rounded, color: kAccent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fileName,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(fileSize,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.read<UploadCubit>().pickAudioFile(),
          child: const Text('Đổi file', style: TextStyle(color: kAccent, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildCoverPreview(BuildContext context, UploadCoverPicked state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: state.coverBytes != null
                ? Image.memory(
                    state.coverBytes!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.white10,
                    child: const Icon(Icons.image_rounded, color: Colors.white30),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.coverName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => context.read<UploadCubit>().pickCoverImage(),
            child: const Text('D\u1ed5i', style: TextStyle(color: kAccentPink, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeFileWarning(String size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('File lớn ($size) – Upload có thể mất vài phút. Vui lòng giữ app mở.',
              style: const TextStyle(color: Colors.orange, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressView(UploadInProgress state) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [kAccent.withValues(alpha: 0.2), Colors.transparent]),
          ),
          child: const Icon(Icons.cloud_upload_rounded, size: 36, color: kAccent),
        ),
        const SizedBox(height: 20),
        Text(
          state.phase == 'cover' ? 'Đang upload ảnh bìa...' : 'Đang upload nhạc...',
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          '${state.sentMB} / ${state.totalMB}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: state.progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(kAccent),
          ),
        ),
        const SizedBox(height: 8),
        Text('${(state.progress * 100).toStringAsFixed(0)}%',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
        const SizedBox(height: 20),
        Text('Đừng đóng ứng dụng khi đang upload',
          style: TextStyle(color: Colors.orange.withValues(alpha: 0.8), fontSize: 12)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() != true) return;
    context.read<UploadCubit>().upload(
      title: _titleCtrl.text,
      artist: _artistCtrl.text,
      album: _albumCtrl.text.isEmpty ? null : _albumCtrl.text,
    );
  }
}
