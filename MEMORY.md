# MEMORY.md

- Initialized long-term memory file.
- Current active project context: Flutter music app using hybrid layered architecture with Supabase integration.

## Flutter Patterns — Lessons Learned

### Navigation
- Dùng GoRouter, không dùng Navigator.push trực tiếp (mất context khi pop)
- Named routes: /home, /player, /library, /profile, /admin

### State Management
- Không dùng setState ngoài widget đơn giản không có async
- Luôn check `if (!mounted) return` sau await trong State class
- Cubit emit state mới, không mutate state cũ

### Performance
- List dài: dùng ListView.builder, không ListView với children
- Image: dùng cached_network_image, set memCacheHeight/Width
- Không gọi Supabase trực tiếp từ build() — chỉ gọi từ Cubit/Repository

### Common Mistakes
- MediaQuery.of(context) sâu trong widget tree → pass xuống hoặc dùng LayoutBuilder
- Column trong SingleChildScrollView mà không có shrinkWrap → overflow
- Quên dispose AnimationController, TextEditingController, ScrollController