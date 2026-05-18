import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kAccent = Color(0xFF7C3AED);
const _kAccentPink = Color(0xFFEC4899);
const _kGreen = Color(0xFF1DB954); // Spotify green

// ─── Genre chips ──────────────────────────────────────────────────────────────
const _kGenres = [
  'Pop', 'Rock', 'R&B', 'Hip-Hop', 'Jazz', 'Classical',
  'Electronic', 'Country', 'Lo-fi', 'K-Pop', 'V-Pop', 'Indie',
  'Metal', 'Blues', 'Folk', 'Soul', 'Reggae', 'Latin',
];

const _kLanguages = [
  'Tiếng Việt', 'English', '日本語', '한국어', '中文', 'Français',
  'Español', 'Deutsch', 'Português',
];

const _kMusicLevels = [
  'Mới bắt đầu',
  'Nghiệp dư',
  'Trung cấp',
  'Nâng cao',
  'Chuyên nghiệp',
];

const _kListeningMoods = [
  '🎧 Thư giãn', '💪 Tập luyện', '📚 Học tập', '🚗 Di chuyển',
  '🎉 Tiệc tùng', '😴 Trước khi ngủ', '💼 Làm việc', '❤️ Lãng mạn',
];

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfilePage({
    super.key,
    required this.profileData,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  // Controllers
  late final TextEditingController _emailController;
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _websiteController;
  late final TextEditingController _phoneController;
  late final TextEditingController _occupationController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _facebookController;
  late final TextEditingController _instagramController;
  late final TextEditingController _twitterController;
  late final TextEditingController _youtubeController;
  late final TextEditingController _tiktokController;
  late final TextEditingController _spotifyUrlController;
  late final TextEditingController _countryController;
  late final TextEditingController _mottoController;

  final _supabase = Supabase.instance.client;

  Map<String, dynamic> _profileData = {};

  Uint8List? _selectedImageBytes;
  String? _selectedImageExt;
  String? _selectedGender;
  String? _selectedLanguage;
  String? _selectedMusicLevel;
  final Set<String> _selectedGenres = {};
  final Set<String> _selectedMoods = {};
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  static const List<String> _genderOptions = [
    'Nam', 'Nữ', 'Khác', 'Không muốn tiết lộ',
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final user = _supabase.auth.currentUser;
    _profileData = Map<String, dynamic>.from(widget.profileData);

    _emailController = TextEditingController(text: user?.email ?? '');
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _websiteController = TextEditingController();
    _phoneController = TextEditingController();
    _occupationController = TextEditingController();
    _birthDateController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _facebookController = TextEditingController();
    _instagramController = TextEditingController();
    _twitterController = TextEditingController();
    _youtubeController = TextEditingController();
    _tiktokController = TextEditingController();
    _spotifyUrlController = TextEditingController();
    _countryController = TextEditingController();
    _mottoController = TextEditingController();

    _applyProfileData(_profileData);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      setState(() => _isLoading = true);
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null || !mounted) return;

      setState(() {
        _applyProfileData(Map<String, dynamic>.from(profile));
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Không thể tải hồ sơ: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyProfileData(Map<String, dynamic> profile) {
    _profileData = {..._profileData, ...profile};

    _nameController.text =
        (_profileData['display_name'] ?? _profileData['name'] ?? '')
            .toString();
    _bioController.text = _profileData['bio']?.toString() ?? '';
    _locationController.text = _profileData['location']?.toString() ?? '';
    _websiteController.text =
        (_profileData['website_url'] ?? _profileData['website'] ?? '')
            .toString();
    _phoneController.text = _profileData['phone']?.toString() ?? '';
    _occupationController.text = _profileData['occupation']?.toString() ?? '';
    _birthDateController.text = _normalizeBirthDate(_profileData['birth_date']);
    _facebookController.text = _profileData['facebook']?.toString() ?? '';
    _instagramController.text = _profileData['instagram']?.toString() ?? '';
    _twitterController.text = _profileData['twitter']?.toString() ?? '';
    _youtubeController.text = _profileData['youtube']?.toString() ?? '';
    _tiktokController.text = _profileData['tiktok']?.toString() ?? '';
    _spotifyUrlController.text = _profileData['spotify_url']?.toString() ?? '';
    _countryController.text = _profileData['country']?.toString() ?? '';
    _mottoController.text = _profileData['motto']?.toString() ?? '';

    final gender = _profileData['gender']?.toString();
    _selectedGender = _genderOptions.contains(gender) ? gender : null;

    final language = _profileData['preferred_language']?.toString();
    _selectedLanguage = _kLanguages.contains(language) ? language : null;

    final level = _profileData['music_level']?.toString();
    _selectedMusicLevel = _kMusicLevels.contains(level) ? level : null;

    _selectedGenres
      ..clear()
      ..addAll(_extractAllowedValues(_profileData['favorite_genres'], _kGenres));

    _selectedMoods
      ..clear()
      ..addAll(
        _extractAllowedValues(_profileData['listening_moods'], _kListeningMoods),
      );
  }

  Set<String> _extractAllowedValues(dynamic rawValues, List<String> allowed) {
    final values = <String>{};

    if (rawValues is List) {
      for (final value in rawValues) {
        final normalized = value.toString().trim();
        if (allowed.contains(normalized)) values.add(normalized);
      }
    } else if (rawValues is String && rawValues.isNotEmpty) {
      for (final value in rawValues.split(',')) {
        final normalized = value.trim();
        if (allowed.contains(normalized)) values.add(normalized);
      }
    }

    return values;
  }

  String _normalizeBirthDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.contains('/')) return raw;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    return _formatDate(parsed);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _youtubeController.dispose();
    _tiktokController.dispose();
    _spotifyUrlController.dispose();
    _countryController.dispose();
    _mottoController.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  double get _profileCompletion {
    final fields = [
      _nameController.text.trim(),
      _bioController.text.trim(),
      _locationController.text.trim(),
      _phoneController.text.trim(),
      _websiteController.text.trim(),
      _occupationController.text.trim(),
      _birthDateController.text.trim(),
      _countryController.text.trim(),
      _mottoController.text.trim(),
      _selectedGender ?? '',
      _selectedLanguage ?? '',
      _selectedMusicLevel ?? '',
    ];
    final filled = fields.where((f) => f.isNotEmpty).length;
    final socialFilled = [
      _facebookController.text.trim(),
      _instagramController.text.trim(),
      _twitterController.text.trim(),
      _youtubeController.text.trim(),
      _tiktokController.text.trim(),
      _spotifyUrlController.text.trim(),
    ].where((f) => f.isNotEmpty).length;
    final genresFilled = _selectedGenres.isNotEmpty ? 1 : 0;
    final moodsFilled = _selectedMoods.isNotEmpty ? 1 : 0;
    final avatarFilled = (_selectedImageBytes != null ||
            (_profileData['avatar_url']?.toString().isNotEmpty ?? false))
        ? 1
        : 0;
    final total = fields.length + 6 + 1 + 1 + 1; // fields + socials + genres + moods + avatar
    return (filled + socialFilled + genresFilled + moodsFilled + avatarFilled) / total;
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
      if (!mounted) return;
      _showSnack('Không thể chọn ảnh: $e', isError: true);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _parseBirthDate() ?? DateTime(now.year - 18, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: _kAccent,
            surface: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) {
      _birthDateController.text = _formatDate(picked);
      if (mounted) setState(() {});
    }
  }

  DateTime? _parseBirthDate() {
    final text = _birthDateController.text.trim();
    if (text.isEmpty) return null;
    final parts = text.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _showSnack(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : isSuccess
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : isSuccess
                ? const Color(0xFF2E7D32)
                : _kAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  // ─── Save ───────────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final location = _locationController.text.trim();
    final website = _websiteController.text.trim();
    final phone = _phoneController.text.trim();
    final occupation = _occupationController.text.trim();
    final birthDate = _birthDateController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final facebook = _facebookController.text.trim();
    final instagram = _instagramController.text.trim();
    final twitter = _twitterController.text.trim();
    final youtube = _youtubeController.text.trim();
    final tiktok = _tiktokController.text.trim();
    final spotifyUrl = _spotifyUrlController.text.trim();
    final country = _countryController.text.trim();
    final motto = _mottoController.text.trim();

    if (name.isEmpty) {
      _showSnack('Tên hiển thị không được để trống', isError: true);
      return;
    }
    if (website.isNotEmpty &&
        !website.startsWith('http://') &&
        !website.startsWith('https://')) {
      _showSnack('Website phải bắt đầu bằng http:// hoặc https://', isError: true);
      return;
    }
    if (phone.isNotEmpty && phone.length < 9) {
      _showSnack('Số điện thoại chưa hợp lệ', isError: true);
      return;
    }
    if (birthDate.isNotEmpty && _parseBirthDate() == null) {
      _showSnack('Ngày sinh không đúng định dạng dd/mm/yyyy', isError: true);
      return;
    }
    if (password.isNotEmpty) {
      if (password != confirmPassword) {
        _showSnack('Mật khẩu xác nhận không khớp', isError: true);
        return;
      }
      if (password.length < 6) {
        _showSnack('Mật khẩu phải có ít nhất 6 ký tự', isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      String? newAvatarUrl = _profileData['avatar_url']?.toString();
      if (_selectedImageBytes != null) {
        final path = 'public/${user.id}.${_selectedImageExt ?? 'png'}';
        await _supabase.storage.from('avatars').uploadBinary(
              path,
              _selectedImageBytes!,
              fileOptions: const FileOptions(upsert: true),
            );
        final rawUrl = _supabase.storage.from('avatars').getPublicUrl(path);
        newAvatarUrl = '$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      final profileUpsert = <String, dynamic>{
        'id': user.id,
        'name': name,
        'display_name': name,
        'email': user.email,
        'avatar_url': newAvatarUrl,
        'gender': _selectedGender,
        'birth_date': birthDate.isEmpty ? null : birthDate,
        'preferred_language': _selectedLanguage,
        'music_level': _selectedMusicLevel,
        'favorite_genres': _selectedGenres.toList(),
        'listening_moods': _selectedMoods.toList(),
        'bio': bio,
        'motto': motto,
        'location': location,
        'country': country,
        'website_url': website,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final metadataUpdates = <String, dynamic>{
        ..._profileData,
        'name': name,
        'display_name': name,
        'bio': bio,
        'location': location,
        'website': website,
        'website_url': website,
        'avatar_url': newAvatarUrl,
        'phone': phone,
        'occupation': occupation,
        'birth_date': birthDate,
        'gender': _selectedGender,
        'facebook': facebook,
        'instagram': instagram,
        'twitter': twitter,
        'youtube': youtube,
        'tiktok': tiktok,
        'spotify_url': spotifyUrl,
        'country': country,
        'motto': motto,
        'preferred_language': _selectedLanguage,
        'music_level': _selectedMusicLevel,
        'favorite_genres': _selectedGenres.toList(),
        'listening_moods': _selectedMoods.toList(),
      };

      await _supabase.from('profiles').upsert(profileUpsert);
      await _supabase.auth.updateUser(UserAttributes(
        data: metadataUpdates,
        password: password.isNotEmpty ? password : null,
      ));

      try {
        await _supabase
            .from('comments')
            .update({'display_name': name}).eq('user_id', user.id);
      } catch (e) {
        debugPrint('Không thể cập nhật tên trong comments: $e');
      }

      if (!mounted) return;
      setState(() {
        _profileData = {
          ..._profileData,
          ...profileUpsert,
          ...metadataUpdates,
        };
      });
      _showSnack('Cập nhật hồ sơ thành công', isSuccess: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Lỗi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Widget builders ────────────────────────────────────────────────────────

  Widget _sectionCard({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE8E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : _kAccent.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F0F1A),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : const Color(0xFF6B7280),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    String? hint,
    bool isPassword = false,
    bool enabled = true,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    Widget? suffixIcon,
    Color? iconColor,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F0F1A);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF6B7280);
    final inputBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF8F8FC);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            label,
            style: TextStyle(
              color: subColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: enabled ? inputBg : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF0F0F5)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            enabled: enabled,
            readOnly: readOnly,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onTap: onTap,
            style: TextStyle(
              color: enabled ? textColor : subColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFB0B7C3),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: iconColor ?? subColor,
                size: 20,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: maxLines > 1 ? 16 : 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
    required bool isDark,
    String? hint,
  }) {
    return _field(
      label: label,
      controller: controller,
      icon: Icons.lock_outline_rounded,
      isDark: isDark,
      hint: hint,
      isPassword: !show,
      suffixIcon: IconButton(
        icon: Icon(
          show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: isDark
              ? Colors.white.withValues(alpha: 0.45)
              : const Color(0xFF6B7280),
          size: 20,
        ),
        onPressed: onToggle,
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    required bool isDark,
    String? hint,
  }) {
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF6B7280);
    final inputBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF8F8FC);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF0F0F1A);
    final dropdownBg = isDark ? const Color(0xFF1C1C2E) : Colors.white;

    Text dropdownText(String text, {Color? color}) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            label,
            style: TextStyle(
              color: subColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonFormField<T>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: subColor, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
            dropdownColor: dropdownBg,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: subColor),
            hint: hint != null
                ? dropdownText(
                    hint,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : const Color(0xFFB0B7C3),
                  )
                : null,
            selectedItemBuilder: (context) => items
                .map((item) => Align(
                      alignment: Alignment.centerLeft,
                      child: dropdownText(itemLabel(item)),
                    ))
                .toList(),
            items: items
                .map((item) => DropdownMenuItem<T>(
                      value: item,
                      child: dropdownText(itemLabel(item)),
                    ))
                .toList(),
            onChanged: _isLoading ? null : onChanged,
          ),
        ),
      ],
    );
  }

  Widget _responsiveFieldRow({
    required Widget left,
    required Widget right,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              left,
              const SizedBox(height: 14),
              right,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _genreChips({required bool isDark}) {
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF6B7280);
    final unselBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF8F8FC);
    final unselBorder = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'THỂ LOẠI YÊU THÍCH',
            style: TextStyle(
              color: subColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kGenres.map((genre) {
            final selected = _selectedGenres.contains(genre);
            return GestureDetector(
              onTap: _isLoading
                  ? null
                  : () => setState(() {
                        if (selected) {
                          _selectedGenres.remove(genre);
                        } else {
                          _selectedGenres.add(genre);
                        }
                      }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [_kAccent, _kAccentPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selected ? null : unselBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected ? Colors.transparent : unselBorder,
                    width: 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _kAccent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      genre,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : const Color(0xFF6B7280)),
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _moodChips({required bool isDark}) {
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF6B7280);
    final unselBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF8F8FC);
    final unselBorder = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'NGHE NHẠC KHI NÀO',
            style: TextStyle(
              color: subColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kListeningMoods.map((mood) {
            final selected = _selectedMoods.contains(mood);
            return GestureDetector(
              onTap: _isLoading
                  ? null
                  : () => setState(() {
                        if (selected) {
                          _selectedMoods.remove(mood);
                        } else {
                          _selectedMoods.add(mood);
                        }
                      }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? _kAccent.withValues(alpha: isDark ? 0.25 : 0.12)
                      : unselBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected ? _kAccent : unselBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  mood,
                  style: TextStyle(
                    color: selected
                        ? _kAccent
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : const Color(0xFF6B7280)),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? accentColor,
  }) {
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF8F8FC);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor ?? _kAccent, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : const Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F0F1A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF2F2F8);

    final currentAvatarUrl = _profileData['avatar_url']?.toString();
    final currentName =
        (_profileData['display_name'] ?? _profileData['name'])?.toString() ?? '';
    final memberSince = _profileData['created_at']?.toString();
    final accountRole = _profileData['role']?.toString() ?? 'Người dùng';
    final completion = _profileCompletion;

    // Avatar widget
    Widget avatarWidget;
    if (_selectedImageBytes != null) {
      avatarWidget = Image.memory(_selectedImageBytes!, fit: BoxFit.cover);
    } else if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty) {
      avatarWidget = CachedNetworkImage(
        imageUrl: currentAvatarUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
        errorWidget: (_, __, ___) =>
            const Icon(Icons.person_rounded, size: 60, color: Colors.white54),
      );
    } else {
      avatarWidget = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kAccent, _kAccentPink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          currentName.isNotEmpty ? currentName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Collapsible header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFF3A0F7A),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Save icon in AppBar (collapsed state)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Lưu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: const Text(
                'Chỉnh sửa hồ sơ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred avatar as background
                  if (_selectedImageBytes != null)
                    Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                  else if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty)
                    CachedNetworkImage(imageUrl: currentAvatarUrl, fit: BoxFit.cover)
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3A0F7A), Color(0xFF1A0533)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  // Blur overlay
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            (isDark ? const Color(0xFF0F0F1A) : const Color(0xFF3A0F7A))
                                .withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Avatar + camera
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kAccent.withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: avatarWidget,
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_kAccent, _kAccentPink],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _kAccent.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 16),
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
                constraints: const BoxConstraints(maxWidth: 780),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  child: Column(
                    children: [
                      // ── Profile Completion Card ────────────────────────────
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Circular completion indicator
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: completion,
                                        strokeWidth: 5,
                                        backgroundColor: isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : const Color(0xFFE8E8F0),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          completion >= 0.8
                                              ? const Color(0xFF1DB954)
                                              : completion >= 0.5
                                                  ? Colors.orange
                                                  : const Color(0xFFE53935),
                                        ),
                                      ),
                                      Text(
                                        '${(completion * 100).round()}%',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF0F0F1A),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Độ hoàn thiện hồ sơ',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF0F0F1A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        completion >= 0.8
                                            ? '🌟 Hồ sơ của bạn rất ấn tượng!'
                                            : completion >= 0.5
                                                ? '✨ Tiếp tục điền thêm thông tin'
                                                : '📝 Hãy bổ sung thêm để nổi bật hơn',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.55)
                                              : const Color(0xFF6B7280),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: completion >= 0.8
                                        ? const Color(0xFF1DB954).withValues(alpha: isDark ? 0.2 : 0.1)
                                        : completion >= 0.5
                                            ? Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1)
                                            : const Color(0xFFE53935).withValues(alpha: isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    completion >= 0.8
                                        ? 'Xuất sắc'
                                        : completion >= 0.5
                                            ? 'Tốt'
                                            : 'Cần thêm',
                                    style: TextStyle(
                                      color: completion >= 0.8
                                          ? const Color(0xFF1DB954)
                                          : completion >= 0.5
                                              ? Colors.orange.shade700
                                              : const Color(0xFFE53935),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Info chips
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _infoChip(
                                  icon: Icons.verified_user_outlined,
                                  label: 'VAI TRÒ',
                                  value: accountRole,
                                  isDark: isDark,
                                  accentColor: _kAccent,
                                ),
                                _infoChip(
                                  icon: Icons.email_outlined,
                                  label: 'EMAIL',
                                  value: _emailController.text.isEmpty
                                      ? 'Chưa cập nhật'
                                      : _emailController.text,
                                  isDark: isDark,
                                  accentColor: const Color(0xFF0288D1),
                                ),
                                _infoChip(
                                  icon: Icons.calendar_month_rounded,
                                  label: 'THAM GIA',
                                  value: memberSince == null || memberSince.isEmpty
                                      ? 'Chưa rõ'
                                      : memberSince.split('T').first,
                                  isDark: isDark,
                                  accentColor: const Color(0xFF7B1FA2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Personal Info ──────────────────────────────────────
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            _sectionHeader(
                              icon: Icons.person_outline_rounded,
                              title: 'Thông tin cá nhân',
                              subtitle: 'Tên, tiểu sử, vị trí và thông tin liên hệ',
                              accent: _kAccent,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 22),
                            _field(
                              label: 'ĐỊA CHỈ EMAIL',
                              controller: _emailController,
                              icon: Icons.email_rounded,
                              isDark: isDark,
                              enabled: false,
                            ),
                            const SizedBox(height: 14),
                            _field(
                              label: 'TÊN HIỂN THỊ *',
                              controller: _nameController,
                              icon: Icons.badge_rounded,
                              isDark: isDark,
                              hint: 'Ví dụ: Nguyễn Minh Anh',
                              iconColor: _kAccent,
                            ),
                            const SizedBox(height: 14),
                            _field(
                              label: 'TIỂU SỬ',
                              controller: _bioController,
                              icon: Icons.article_outlined,
                              isDark: isDark,
                              hint: 'Giới thiệu ngắn về bạn, gu âm nhạc hoặc lĩnh vực hoạt động...',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 14),
                            _field(
                              label: 'CHÂM NGÔN / MOTTO',
                              controller: _mottoController,
                              icon: Icons.format_quote_rounded,
                              isDark: isDark,
                              hint: '"Music is the shorthand of emotion" - Tolstoy',
                              iconColor: _kAccentPink,
                            ),
                            const SizedBox(height: 14),
                            _responsiveFieldRow(
                              left: _field(
                                label: 'VỊ TRÍ',
                                controller: _locationController,
                                icon: Icons.location_on_outlined,
                                isDark: isDark,
                                hint: 'TP. Hồ Chí Minh',
                              ),
                              right: _field(
                                label: 'QUỐC GIA',
                                controller: _countryController,
                                icon: Icons.flag_outlined,
                                isDark: isDark,
                                hint: 'Việt Nam',
                              ),
                            ),
                            const SizedBox(height: 14),
                            _responsiveFieldRow(
                              left: _field(
                                label: 'NGHỀ NGHIỆP',
                                controller: _occupationController,
                                icon: Icons.work_outline_rounded,
                                isDark: isDark,
                                hint: 'Producer, Singer...',
                              ),
                              right: _field(
                                label: 'SỐ ĐIỆN THOẠI',
                                controller: _phoneController,
                                icon: Icons.phone_outlined,
                                isDark: isDark,
                                hint: '09xxxxxxxx',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _responsiveFieldRow(
                              left: _dropdownField<String>(
                                label: 'GIỚI TÍNH',
                                value: _selectedGender,
                                items: _genderOptions,
                                itemLabel: (g) => g,
                                onChanged: (v) => setState(() => _selectedGender = v),
                                icon: Icons.wc_rounded,
                                isDark: isDark,
                                hint: 'Chọn giới tính',
                              ),
                              right: _field(
                                label: 'NGÀY SINH',
                                controller: _birthDateController,
                                icon: Icons.cake_outlined,
                                isDark: isDark,
                                hint: 'dd/mm/yyyy',
                                readOnly: true,
                                onTap: _pickBirthDate,
                                suffixIcon: Icon(
                                  Icons.calendar_today_rounded,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.45)
                                      : const Color(0xFF6B7280),
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _responsiveFieldRow(
                              left: _field(
                                label: 'WEBSITE / PORTFOLIO',
                                controller: _websiteController,
                                icon: Icons.link_rounded,
                                isDark: isDark,
                                hint: 'https://your-site.com',
                                keyboardType: TextInputType.url,
                              ),
                              right: _dropdownField<String>(
                                label: 'NGÔN NGỮ ƯA THÍCH',
                                value: _selectedLanguage,
                                items: _kLanguages,
                                itemLabel: (l) => l,
                                onChanged: (v) => setState(() => _selectedLanguage = v),
                                icon: Icons.language_rounded,
                                isDark: isDark,
                                hint: 'Chọn ngôn ngữ',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Music Preferences ──────────────────────────────────
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                              icon: Icons.music_note_rounded,
                              title: 'Sở thích âm nhạc',
                              subtitle: 'Trình độ, thể loại và thói quen nghe nhạc',
                              accent: const Color(0xFF7B1FA2),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 22),
                            _dropdownField<String>(
                              label: 'TRÌNH ĐỘ ÂM NHẠC',
                              value: _selectedMusicLevel,
                              items: _kMusicLevels,
                              itemLabel: (l) => l,
                              onChanged: (v) => setState(() => _selectedMusicLevel = v),
                              icon: Icons.equalizer_rounded,
                              isDark: isDark,
                              hint: 'Chọn trình độ của bạn',
                            ),
                            const SizedBox(height: 18),
                            _genreChips(isDark: isDark),
                            const SizedBox(height: 18),
                            _moodChips(isDark: isDark),
                          ],
                        ),
                      ),

                      // ── Social Links ───────────────────────────────────────
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            _sectionHeader(
                              icon: Icons.share_rounded,
                              title: 'Mạng xã hội',
                              subtitle: 'Kết nối để mọi người dễ tìm thấy bạn',
                              accent: const Color(0xFF0288D1),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 22),
                            _field(
                              label: 'FACEBOOK',
                              controller: _facebookController,
                              icon: Icons.facebook_rounded,
                              isDark: isDark,
                              hint: 'https://facebook.com/username',
                              keyboardType: TextInputType.url,
                              iconColor: const Color(0xFF1877F2),
                            ),
                            const SizedBox(height: 14),
                            _field(
                              label: 'INSTAGRAM',
                              controller: _instagramController,
                              icon: Icons.camera_alt_outlined,
                              isDark: isDark,
                              hint: '@username',
                              iconColor: const Color(0xFFE1306C),
                            ),
                            const SizedBox(height: 14),
                            _field(
                              label: 'X (TWITTER)',
                              controller: _twitterController,
                              icon: Icons.alternate_email_rounded,
                              isDark: isDark,
                              hint: '@username',
                              iconColor: isDark ? Colors.white : const Color(0xFF0F0F1A),
                            ),
                            const SizedBox(height: 14),
                            _field(
                              label: 'YOUTUBE',
                              controller: _youtubeController,
                              icon: Icons.play_circle_outline_rounded,
                              isDark: isDark,
                              hint: 'https://youtube.com/@channel',
                              keyboardType: TextInputType.url,
                              iconColor: const Color(0xFFFF0000),
                            ),
                            const SizedBox(height: 14),
                            _responsiveFieldRow(
                              left: _field(
                                label: 'TIKTOK',
                                controller: _tiktokController,
                                icon: Icons.music_video_rounded,
                                isDark: isDark,
                                hint: '@username',
                                iconColor: isDark
                                    ? Colors.white
                                    : const Color(0xFF010101),
                              ),
                              right: _field(
                                label: 'SPOTIFY',
                                controller: _spotifyUrlController,
                                icon: Icons.headphones_rounded,
                                isDark: isDark,
                                hint: 'https://open.spotify.com/...',
                                keyboardType: TextInputType.url,
                                iconColor: _kGreen,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Security ───────────────────────────────────────────
                      _sectionCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            _sectionHeader(
                              icon: Icons.shield_outlined,
                              title: 'Bảo mật tài khoản',
                              subtitle: 'Để trống nếu không muốn đổi mật khẩu',
                              accent: Colors.orange,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 22),
                            _passwordField(
                              label: 'MẬT KHẨU MỚI',
                              controller: _passwordController,
                              show: _showPassword,
                              isDark: isDark,
                              onToggle: () =>
                                  setState(() => _showPassword = !_showPassword),
                              hint: 'Tối thiểu 6 ký tự',
                            ),
                            const SizedBox(height: 14),
                            _passwordField(
                              label: 'XÁC NHẬN MẬT KHẨU MỚI',
                              controller: _confirmPasswordController,
                              show: _showConfirmPassword,
                              isDark: isDark,
                              onToggle: () => setState(
                                  () => _showConfirmPassword = !_showConfirmPassword),
                              hint: 'Nhập lại mật khẩu mới',
                            ),
                          ],
                        ),
                      ),

                      // ── Save Button ────────────────────────────────────────
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: _isLoading
                              ? null
                              : const LinearGradient(
                                  colors: [_kAccent, _kAccentPink],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: _isLoading
                              ? (_kAccent.withValues(alpha: 0.45))
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _isLoading
                              ? null
                              : [
                                  BoxShadow(
                                    color: _kAccent.withValues(alpha: 0.45),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _saveProfile,
                            borderRadius: BorderRadius.circular(18),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save_rounded,
                                            color: Colors.white, size: 20),
                                        SizedBox(width: 10),
                                        Text(
                                          'LƯU THAY ĐỔI',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
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