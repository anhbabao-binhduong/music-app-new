import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

/// A question/answer pair shown in the detail page.
class HelpEntry {
  final String question;
  final String answer;

  const HelpEntry({required this.question, required this.answer});
}

/// Generic detail page for help & feedback items.
class HelpDetailPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<HelpEntry> entries;

  const HelpDetailPage({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero app bar ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: scheme.onSurface,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withValues(alpha: isDark ? 0.8 : 0.9),
                      kAccentPink.withValues(alpha: isDark ? 0.6 : 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = entries[index];
                  return _EntryCard(
                      entry: entry, scheme: scheme, isDark: isDark);
                },
                childCount: entries.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final HelpEntry entry;
  final ColorScheme scheme;
  final bool isDark;

  const _EntryCard({
    required this.entry,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Text(
            entry.question,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          iconColor: kAccent,
          collapsedIconColor: scheme.onSurface.withValues(alpha: 0.4),
          children: [
            Text(
              entry.answer,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Static data factories ────────────────────────────────────────────────────

/// Pre-built pages for each help item.
abstract class HelpPages {
  static HelpDetailPage faq() => const HelpDetailPage(
        title: 'Câu hỏi thường gặp',
        icon: Icons.help_outline_rounded,
        iconColor: kAccent,
        entries: [
          HelpEntry(
            question: 'Làm thế nào để tìm kiếm bài hát?',
            answer:
                'Nhấn vào biểu tượng kính lúp ở thanh điều hướng phía dưới, sau đó gõ tên bài hát, nghệ sĩ hoặc album mà bạn muốn tìm.',
          ),
          HelpEntry(
            question: 'Tôi có thể tải bài hát về nghe offline không?',
            answer:
                'Hiện tại ứng dụng đang phát triển tính năng nghe offline. Bạn vui lòng kết nối internet để thưởng thức âm nhạc chất lượng cao.',
          ),
          HelpEntry(
            question: 'Làm thế nào để thêm bài hát vào danh sách yêu thích?',
            answer:
                'Nhấn giữ hoặc nhấn vào biểu tượng trái tim trên bài hát bạn muốn để thêm vào danh sách yêu thích. Bạn có thể xem lại trong mục Thư viện.',
          ),
          HelpEntry(
            question: 'Làm thế nào để tạo playlist cá nhân?',
            answer:
                'Vào mục Thư viện → Playlist → Nhấn nút "+" để tạo playlist mới. Sau đó bạn có thể thêm bài hát vào playlist tùy ý.',
          ),
          HelpEntry(
            question: 'Tôi quên mật khẩu, phải làm sao?',
            answer:
                'Tại màn hình đăng nhập, nhấn "Quên mật khẩu?" và nhập email đã đăng ký. Hệ thống sẽ gửi link đặt lại mật khẩu về email của bạn.',
          ),
          HelpEntry(
            question: 'Tại sao âm thanh bị gián đoạn?',
            answer:
                'Âm thanh có thể bị gián đoạn do kết nối mạng không ổn định. Hãy kiểm tra lại wifi hoặc dữ liệu di động của bạn. Nếu vấn đề vẫn tiếp tục, hãy khởi động lại ứng dụng.',
          ),
        ],
      );

  static HelpDetailPage feedback() => const HelpDetailPage(
        title: 'Gửi phản hồi',
        icon: Icons.rate_review_outlined,
        iconColor: Color(0xFF06B6D4),
        entries: [
          HelpEntry(
            question: 'Tôi muốn đề xuất tính năng mới',
            answer:
                'Chúng tôi luôn lắng nghe ý kiến từ người dùng. Hãy mô tả chi tiết tính năng bạn muốn và chúng tôi sẽ xem xét trong các phiên bản tiếp theo.',
          ),
          HelpEntry(
            question: 'Giao diện cần cải thiện điểm nào?',
            answer:
                'Mọi góp ý về thiết kế, màu sắc, bố cục đều được chúng tôi trân trọng. Phản hồi của bạn giúp ứng dụng ngày càng đẹp hơn và dễ dùng hơn.',
          ),
          HelpEntry(
            question: 'Làm thế nào để đánh giá ứng dụng?',
            answer:
                'Bạn có thể đánh giá ứng dụng trên Google Play Store hoặc App Store. Mỗi đánh giá tích cực là động lực rất lớn cho đội ngũ phát triển.',
          ),
          HelpEntry(
            question: 'Phản hồi của tôi có được xem xét không?',
            answer:
                'Mọi phản hồi đều được đọc và ghi nhận. Chúng tôi ưu tiên những vấn đề được nhiều người dùng phản ánh nhất để cải thiện trong thời gian sớm nhất.',
          ),
        ],
      );

  static HelpDetailPage bugReport() => const HelpDetailPage(
        title: 'Báo cáo sự cố',
        icon: Icons.bug_report_outlined,
        iconColor: Color(0xFFF59E0B),
        entries: [
          HelpEntry(
            question: 'Ứng dụng bị crash đột ngột',
            answer:
                'Vui lòng cung cấp thông tin: thiết bị sử dụng, hệ điều hành, phiên bản ứng dụng và các bước tái hiện lỗi. Chúng tôi sẽ xử lý trong thời gian sớm nhất.',
          ),
          HelpEntry(
            question: 'Bài hát không phát được',
            answer:
                'Kiểm tra kết nối mạng, thử phát bài hát khác, hoặc xóa cache ứng dụng. Nếu vấn đề vẫn còn, hãy báo cáo tên bài hát cụ thể để chúng tôi kiểm tra.',
          ),
          HelpEntry(
            question: 'Lỗi hiển thị giao diện',
            answer:
                'Chụp màn hình lỗi và mô tả chi tiết bước xảy ra lỗi. Thông tin thiết bị và phiên bản hệ điều hành sẽ giúp chúng tôi tái hiện và sửa lỗi nhanh hơn.',
          ),
          HelpEntry(
            question: 'Vấn đề với tài khoản hoặc đăng nhập',
            answer:
                'Thử đăng xuất và đăng nhập lại. Nếu vẫn không được, liên hệ hỗ trợ kèm địa chỉ email đăng ký để chúng tôi xác minh và hỗ trợ khôi phục tài khoản.',
          ),
        ],
      );

  static HelpDetailPage privacyPolicy() => const HelpDetailPage(
        title: 'Chính sách & Quyền riêng tư',
        icon: Icons.shield_outlined,
        iconColor: Color(0xFF10B981),
        entries: [
          HelpEntry(
            question: 'Ứng dụng thu thập những dữ liệu gì?',
            answer:
                'Chúng tôi chỉ thu thập thông tin cần thiết: email đăng ký, lịch sử nghe nhạc để cá nhân hóa trải nghiệm, và dữ liệu kỹ thuật để cải thiện ứng dụng. Chúng tôi không bao giờ bán thông tin cá nhân của bạn.',
          ),
          HelpEntry(
            question: 'Dữ liệu của tôi có được bảo mật không?',
            answer:
                'Toàn bộ dữ liệu được mã hóa và lưu trữ an toàn trên hệ thống Supabase với tiêu chuẩn bảo mật cao. Chỉ bạn mới có thể truy cập thông tin cá nhân của mình.',
          ),
          HelpEntry(
            question: 'Tôi có thể xóa tài khoản và dữ liệu không?',
            answer:
                'Bạn có quyền yêu cầu xóa toàn bộ dữ liệu cá nhân bất kỳ lúc nào. Liên hệ với chúng tôi qua email hỗ trợ và chúng tôi sẽ xử lý yêu cầu trong vòng 7 ngày làm việc.',
          ),
          HelpEntry(
            question: 'Ứng dụng có chia sẻ dữ liệu với bên thứ ba không?',
            answer:
                'Chúng tôi không chia sẻ thông tin cá nhân với bất kỳ bên thứ ba nào vì mục đích thương mại. Một số dịch vụ kỹ thuật (như phân tích sự cố) có thể nhận dữ liệu ẩn danh để cải thiện ứng dụng.',
          ),
          HelpEntry(
            question: 'Quyền truy cập thiết bị',
            answer:
                'Ứng dụng chỉ yêu cầu quyền truy cập bộ nhớ (để lưu playlist) và thông báo (để điều khiển phát nhạc từ màn hình khóa). Không có quyền nào được yêu cầu mà không có lý do rõ ràng.',
          ),
        ],
      );
}