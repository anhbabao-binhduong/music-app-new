import 'dart:typed_data';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String? currentAvatarUrl;

  const EditProfilePage({
    super.key,
    required this.currentName,
    this.currentAvatarUrl,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  Uint8List? _selectedImageBytes;
  String? _selectedImageExt;
  bool _isLoading = false;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedImageBytes = result.files.single.bytes;
          _selectedImageExt = result.files.single.extension ?? 'png';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên không được để trống')),
      );
      return;
    }

    if (password.isNotEmpty) {
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
        );
        return;
      }
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      String? newAvatarUrl = widget.currentAvatarUrl;

      // Nếu có chọn ảnh mới, upload lên storage
      if (_selectedImageBytes != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${user.id}_$timestamp.$_selectedImageExt';

        await _supabase.storage.from('avatars').uploadBinary(
              path,
              _selectedImageBytes!,
              fileOptions: const FileOptions(upsert: true),
            );
        newAvatarUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      }

      // Cập nhật thông tin trong profiles table
      await _supabase.from('profiles').update({
        'name': name,
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
      }).eq('id', user.id);

      // Cập nhật metadata trong auth
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
          },
          password: password.isNotEmpty ? password : null,
        ),
      );

      // Cập nhật tên hiển thị trong tất cả các bình luận cũ của user
      try {
        await _supabase.from('comments').update({
          'display_name': name,
        }).eq('user_id', user.id);
      } catch (e) {
        debugPrint('Không thể cập nhật tên trong comments: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true để reload profile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.01),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.white38, 
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: enabled ? Colors.white70 : Colors.white38, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current avatar to show
    Widget avatarContent;
    if (_selectedImageBytes != null) {
      avatarContent = Image.memory(_selectedImageBytes!, fit: BoxFit.cover);
    } else if (widget.currentAvatarUrl != null && widget.currentAvatarUrl!.isNotEmpty) {
      avatarContent = CachedNetworkImage(
        imageUrl: widget.currentAvatarUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
        errorWidget: (context, url, error) => const Icon(Icons.person_rounded, size: 60, color: Colors.white54),
      );
    } else {
      avatarContent = Container(
        color: kAccent.withValues(alpha: 0.5),
        alignment: Alignment.center,
        child: Text(
          widget.currentName.isNotEmpty ? widget.currentName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred background based on avatar
                  if (_selectedImageBytes != null)
                    Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                  else if (widget.currentAvatarUrl != null && widget.currentAvatarUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.currentAvatarUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: kAccent),
                  
                  // Blur effect overlay
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            const Color(0xFF121212),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Avatar inside
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: GestureDetector(
                        onTap: _isLoading ? null : _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF121212), width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: avatarContent,
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.4),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thông tin cơ bản
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.person_outline_rounded, color: kAccent),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Thông tin cá nhân',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildTextField(
                          label: 'ĐỊA CHỈ EMAIL',
                          controller: TextEditingController(text: _supabase.auth.currentUser?.email ?? ''),
                          icon: Icons.email_rounded,
                          enabled: false,
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          label: 'TÊN HIỂN THỊ',
                          controller: _nameController,
                          icon: Icons.badge_rounded,
                        ),
                        
                        const SizedBox(height: 48),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 48),

                        // Bảo mật
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shield_outlined, color: Colors.orangeAccent),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Bảo mật',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildTextField(
                          label: 'MẬT KHẨU MỚI (Bỏ trống nếu không đổi)',
                          controller: _passwordController,
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          label: 'XÁC NHẬN MẬT KHẨU MỚI',
                          controller: _confirmPasswordController,
                          icon: Icons.lock_reset_rounded,
                          isPassword: true,
                        ),
                        
                        const SizedBox(height: 56),
                        // Nút lưu
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text(
                                    'LƯU THAY ĐỔI',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
