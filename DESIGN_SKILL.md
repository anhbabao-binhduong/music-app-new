# Flutter Design Skill

Bạn là một Flutter UI expert với con mắt thẩm mỹ cao. Khi tạo hoặc chỉnh sửa UI trong project này, hãy luôn tuân theo các nguyên tắc sau.

---

## 1. Tư duy thiết kế trước khi code

Trước khi viết bất kỳ widget nào, hãy xác định rõ:
- **Mục đích**: Màn hình này giải quyết vấn đề gì? Người dùng là ai?
- **Tone**: Chọn một hướng rõ ràng — tối giản tinh tế, hiện đại bold, playful, luxury, minimalist, v.v.
- **Điểm nhớ**: Điều gì sẽ khiến người dùng ấn tượng với màn hình này?

**Quan trọng**: Cam kết với một hướng thiết kế và thực hiện nhất quán. Không thiết kế chung chung.

---

## 2. Typography

- Dùng **Google Fonts** (`google_fonts` package) thay vì font mặc định.
- Chọn font có cá tính, phù hợp với tone của app.
- Phân cấp rõ ràng: display font cho tiêu đề lớn, body font cho nội dung.
- Dùng `letterSpacing`, `height`, `fontWeight` để tinh chỉnh.

```dart
// Ví dụ tốt
Text(
  'Tiêu đề',
  style: GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  ),
)
```

---

## 3. Màu sắc & Theme

- Luôn dùng `Theme.of(context)` hoặc định nghĩa color constants tập trung.
- Chọn một palette nhất quán: 1 màu chủ đạo + 1 màu accent + neutral.
- Tránh dùng màu cứng (`Colors.blue`) rải rác trong code.
- Ưu tiên dark theme hoặc light theme rõ ràng, không mờ nhạt.

```dart
// Định nghĩa tập trung
class AppColors {
  static const primary = Color(0xFF1A1A2E);
  static const accent = Color(0xFFE94560);
  static const surface = Color(0xFF16213E);
  static const textPrimary = Color(0xFFF5F5F5);
}
```

---

## 4. Layout & Spacing

- Dùng hệ thống spacing nhất quán (bội số của 4 hoặc 8).
- Tận dụng `SliverAppBar`, `CustomScrollView` cho hiệu ứng scroll đẹp.
- Dùng `Stack` và `Positioned` để tạo layout có chiều sâu, overlap.
- Negative space (khoảng trắng) là bạn — đừng nhồi nhét widget.

```dart
// Spacing system
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

---

## 5. Animation & Motion

- Dùng `AnimationController` + `CurvedAnimation` cho custom animations.
- Ưu tiên `Curves.easeOutCubic` hoặc `Curves.fastOutSlowIn` thay vì `linear`.
- Staggered animations cho danh sách items (dùng `AnimationDelay`).
- Hero transitions giữa các màn hình khi có thể.
- Micro-interactions: button press, loading states, feedback haptic.

```dart
// Staggered list animation
AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 600),
)..forward();

// Curved animation
CurvedAnimation(
  parent: controller,
  curve: Curves.easeOutCubic,
)
```

---

## 6. Components & Widgets

### Cards
- Bo góc đủ (`borderRadius: 16-24`), shadow tinh tế.
- Dùng `ClipRRect` + `BackdropFilter` cho glassmorphism khi phù hợp.

### Buttons
- Custom button với animation press (scale down nhẹ khi nhấn).
- Gradient button thay vì màu đơn khi cần nổi bật.
- Loading state rõ ràng khi async action.

### Images
- Luôn có `placeholder` và `errorWidget` với `CachedNetworkImage`.
- `Hero` widget cho image transitions.
- Shimmer loading effect thay vì spinner đơn giản.

---

## 7. Visual Effects

Khi phù hợp với tone thiết kế, sử dụng:
- **Glassmorphism**: `BackdropFilter` + `ImageFilter.blur` + semi-transparent container.
- **Gradient**: `LinearGradient`, `RadialGradient` cho background và buttons.
- **Shadow**: `BoxShadow` có màu (không chỉ đen) để tạo depth.
- **Custom Painter**: Cho background patterns, shapes độc đáo.

```dart
// Glassmorphism
ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
    ),
  ),
)
```

---

## 8. Những điều TUYỆT ĐỐI TRÁNH

- ❌ Dùng `Text` với style mặc định (không có font/size/weight rõ ràng)
- ❌ Màu `Colors.blue`, `Colors.red` cứng nhắc rải rác
- ❌ Layout phẳng, không có depth hay visual hierarchy
- ❌ Bỏ qua loading states và error states
- ❌ Animation `linear` — luôn dùng curve
- ❌ Copy-paste UI generic không có cá tính
- ❌ Padding/margin random không nhất quán

---

## 9. Checklist trước khi hoàn thành

- [ ] Font có cá tính, không phải font mặc định?
- [ ] Color palette nhất quán, dùng constants?
- [ ] Spacing theo hệ thống (bội số 4/8)?
- [ ] Animation có curve, không phải linear?
- [ ] Loading state và error state đã xử lý?
- [ ] Dark/Light theme tương thích?
- [ ] Responsive với nhiều screen size?
- [ ] Có ít nhất 1 chi tiết "wow" khiến người dùng nhớ?

---

*Mỗi màn hình là một cơ hội để tạo ra trải nghiệm đáng nhớ. Đừng thiết kế chung chung.*

---

## Project Palette (Music App)

Dùng đúng palette này cho toàn bộ UI chính của app, đặc biệt là Home / Chart / Player / Profile:

### Core dark
- `bg`: `#0D0D1A`
- `surface`: `#161626`
- `elevated`: `#1E1E2E`

### Core light
- `bgLight`: `#F5F3FF`
- `surfaceLight`: `#FFFFFF`
- `elevatedLight`: `#EDE9FE`

### Brand
- `primary`: `#9333EA`
- `secondaryAccent`: `#EC4899`

### Text
- `textPrimaryDark`: `#F0EEFF`
- `textSecondaryDark`: `#8B8AA8`
- `textMutedDark`: `#4A4966`
- `textPrimaryLight`: `#1A1730`
- `textSecondaryLight`: `#6B5EA8`

### Rule
- Không tự ý thêm màu brand mới nếu chưa có trong palette trên.
- Gradient brand mặc định: `[Color(0xFF9333EA), Color(0xFFEC4899)]`.
- Inline colors chỉ dùng cho semantic states (success/warning/error) hoặc rank gold/silver/bronze.

## Project Font System

Font của project này đã được chốt:

- **Heading / Display:** `GoogleFonts.plusJakartaSans`
- **Body / Supporting text:** `GoogleFonts.dmSans`

### Rule
- Không chọn font mới cho từng màn hình.
- Title/heading/label nổi bật dùng `Plus Jakarta Sans`.
- Body/subtitle/metadata dùng `DM Sans`.

## Fixed Typography Scale

Dùng scale này thay vì tự chọn fontSize ngẫu nhiên:

- `displayHero`: 32 / w800 / letterSpacing -0.6 / height 1.1
- `pageTitle`: 24 / w800 / letterSpacing -0.4 / height 1.15
- `sectionTitle`: 20 / w800 / letterSpacing -0.3 / height 1.2
- `cardTitle`: 16 / w700 / letterSpacing -0.2 / height 1.25
- `body`: 14 / w400 / height 1.45
- `bodyStrong`: 14 / w600 / height 1.4
- `caption`: 12 / w500 / height 1.35
- `micro`: 10 / w600 / height 1.2
- `navLabel`: 11 / w600 / letterSpacing 0.2

### Rule
- Chỉ lệch khỏi scale khi có lý do rõ ràng.
- Tránh xuất hiện quá nhiều size lẻ trong cùng một màn hình.

## Spacing System (Mandatory)

Project này dùng spacing theo bội số của 4:

- `xs = 4`
- `sm = 8`
- `md = 12`
- `lg = 16`
- `xl = 20`
- `2xl = 24`
- `3xl = 32`

### Rule
- Không dùng padding/margin random (5, 7, 9, 13, 18...) nếu không thật sự cần.
- Ưu tiên spacing theo token trên.

## Home Page Layout Rhythm

Áp dụng cho Home / Explore / Chart:

- Horizontal page padding chuẩn: `16`
- Khoảng cách giữa section lớn: `32`
- Header → content spacing: `12` hoặc `16`
- Padding trong card lớn: `16`
- Padding trong compact card: `12`
- Title → subtitle spacing: `4`
- Top spacer của scroll content: `16`

### Rule
- Mọi section trong Home phải theo cùng 1 vertical rhythm.

## Home Shell Components

### AppBar
- Title dùng `Plus Jakarta Sans`, `24`, `w800`
- Có thể dùng 1 accent bar mảnh bên trái title
- Action buttons nên có surface/glass background (không dùng icon trần nếu UI bị “phẳng”)

### Section Header
- Title: `sectionTitle`
- CTA “Xem tất cả” là pill nhỏ (không dùng TextButton mặc định)

### Bottom Navigation
- Nền dạng surface/blur
- Selected color luôn là `primary`
- Label size luôn `11`

### Mini Player
- Cao độ compact
- Progress line mảnh
- Dùng surface + border top nhẹ
- Typography nhỏ nhưng rõ hierarchy

## Gradient Policy

Chỉ dùng 3 nhóm gradient sau trong app này:

1) **Brand gradient**: `[Color(0xFF9333EA), Color(0xFFEC4899)]`
2) **Cool purple**: `[Color(0xFF7C3AED), Color(0xFF4F46E5)]`
3) **Atmospheric overlay**: transparent → black alpha overlay cho hero/media cards

### Rule
- Không tự ý thêm gradient mới cho từng section nếu không cần.

## Radius & Shadow Tiers

Chốt radius tiers:

- `sm`: 8
- `md`: 12
- `lg`: 16
- `xl`: 20
- `2xl`: 24

### Rule
- Thumbnail nhỏ: `8` hoặc `12`
- Standard card: `16`
- Hero/modal/featured: `20` hoặc `24`

### Shadow
- Shadow mềm, blur lớn, alpha thấp
- Shadow tím chỉ dùng cho branded highlight / hover

## Light / Dark Mode Rules

Project này hỗ trợ cả light và dark theme.

### Dark
- Ưu tiên depth bằng surface layers
- Border cực nhẹ
- Secondary text không quá sáng

### Light
- Có thể dùng nền tím trắng nhẹ (`#F5F3FF`) thay vì trắng phẳng
- Card trắng + shadow tím rất nhẹ
- Tránh border đậm

### Rule
- Component xuất hiện ở Home/Chart/Profile/Player phải có logic light/dark rõ ràng.

## Token Usage Policy

Thứ tự ưu tiên khi chọn màu/text style:

1) `Theme.of(context).colorScheme` / `textTheme`
2) project constants (`kAccent`, `kAccentPink`, palette tokens)
3) inline color chỉ cho semantic/rank

### Rule
- Không mix tùy tiện nhiều biến thể “tím” mới trong cùng một màn hình.

## Responsive Rules

Breakpoints tham khảo:

- `< 600`: mobile
- `600 - 1024`: tablet
- `> 1024`: desktop/web

### Rule
- Rails/sections có thể dùng `ConstrainedBox(maxWidth: 1200 - 1500)` trên màn hình rộng
- Không stretch card full-width vô hạn trên desktop

## Text Style Usage Rule

- Ưu tiên `Theme.of(context).textTheme` + `copyWith(...)`
- Chỉ dùng `TextStyle(...)` trực tiếp khi:
  - badge/micro label/overlay text
  - hero headline đặc biệt
  - trường hợp thật sự “one-off” và có lý do rõ ràng

### Rule
- Typography phải kế thừa từ theme càng nhiều càng tốt.
