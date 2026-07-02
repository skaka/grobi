import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format_utils.dart';
import '../services/announcements_api.dart' show kAnnouncementsBaseUrl;
import '../theme.dart';

/// بريد التواصل للملاحظات والدعم (يُؤكَّد/يُعدّل حسب الحاجة).
const String _contactEmail = 'info@misoor.com';

/// صفحة «عن التطبيق»: الشعار والاسم والوصف والإصدار ورقم البناء وروابط التواصل.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: backgroundGradient(false)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: AppColors.onDark),
          title: const Text('عن التطبيق',
              style: TextStyle(
                  color: AppColors.gold, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          top: false,
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/icon/icon.png',
                          width: 110,
                          height: 110,
                          errorBuilder: (_, _, _) => const Icon(
                              Icons.wb_twilight,
                              size: 96,
                              color: AppColors.gold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text('التوقيت الغروبي',
                          style: TextStyle(
                              color: AppColors.onDark,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        info == null
                            ? '…'
                            : 'الإصدار ${toArabicDigits(info.version)}'
                                '  •  بناء ${toArabicDigits(info.buildNumber)}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _card(
                      child: const Text(
                        'التوقيت الغروبي تطبيق يعرض الساعة الغروبية والتقويم '
                        'الهجري ومواقيت الصلاة بحساب فلكي دقيق يراعي موقعك '
                        'وارتفاعك عن سطح البحر، مع اتجاه القبلة والمناسبات '
                        'الإسلامية.',
                        style: TextStyle(
                            color: AppColors.onDark, height: 1.7, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('التواصل'),
                    _linkCard(
                      icon: Icons.language,
                      label: 'الموقع الإلكتروني',
                      value: 'grobi.misoor.com',
                      onTap: () => _launch(Uri.parse(kAnnouncementsBaseUrl)),
                    ),
                    const SizedBox(height: 10),
                    _linkCard(
                      icon: Icons.email_outlined,
                      label: 'تواصل معنا',
                      value: _contactEmail,
                      onTap: () =>
                          _launch(Uri(scheme: 'mailto', path: _contactEmail)),
                    ),
                    if (info != null) ...[
                      const SizedBox(height: 16),
                      _sectionTitle('معلومات فنية'),
                      _infoCard('المعرّف', info.packageName),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, top: 4, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.gold,
              fontSize: 16,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }

  Widget _linkCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return _card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: AppColors.muted)),
              const Spacer(),
              Flexible(
                child: Text(value,
                    textDirection: TextDirection.ltr,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.onDark, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.open_in_new, color: AppColors.muted, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return _card(
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          Text(value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  color: AppColors.onDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
