import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

const _keyPoints = [
  'Your data is yours — we never sell or share it for advertising',
  'All data is stored encrypted in your personal Supabase instance',
  'You can delete your account and all data at any time',
  'Vercel Analytics collects anonymous performance data only',
  'Monk is a personal productivity tool — not financial advice',
];

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Terms of Service',
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.border : AppColors.lightBorder,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Key Takeaways card ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentFaint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentDim),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.verified_outlined,
                      color: AppColors.accent, size: 16),
                  const Gap(8),
                  const Text(
                    'Key Takeaways',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ]),
                const Gap(12),
                for (final point in _keyPoints)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            point,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const Gap(24),

          // ── Effective date ────────────────────────────────────
          Text(
            'Effective Date: April 27, 2026',
            style: TextStyle(
              color: subColor,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),

          const Gap(20),

          // ── Sections ─────────────────────────────────────────
          _Section(
            number: '1.',
            title: 'Acceptance of Terms',
            textColor: textColor,
            subColor: subColor,
            body:
                'By accessing or using Monk (Personal Mastery OS), you agree '
                'to be bound by these Terms of Service. If you do not agree to these '
                'terms, please do not use the application. Your continued use of Monk '
                'constitutes your acceptance of any updates or modifications to these terms.',
          ),

          _Section(
            number: '2.',
            title: 'Eligibility',
            textColor: textColor,
            subColor: subColor,
            body:
                'You must be at least 18 years of age to use Monk. By using the '
                'application, you represent and warrant that you meet this age '
                'requirement. If you are under 18, you are not permitted to use '
                'the application.',
          ),

          _Section(
            number: '3.',
            title: 'Account and Data',
            textColor: textColor,
            subColor: subColor,
            body:
                'You are responsible for maintaining the confidentiality of your '
                'account credentials. All data you enter into Monk — including '
                'financial, health, and personal productivity information — is '
                'stored in your personal Supabase instance and encrypted at rest. '
                'You retain full ownership of your data. You may delete your account '
                'and all associated data at any time by contacting support or using '
                'the in-app account deletion feature.',
          ),

          _Section(
            number: '4.',
            title: 'Acceptable Use',
            textColor: textColor,
            subColor: subColor,
            body:
                'You agree to use Monk only for lawful, personal productivity purposes. '
                'You must not attempt to reverse-engineer, modify, or exploit the '
                'application. You must not use Monk to store or transmit any illegal '
                'content, or attempt to gain unauthorized access to any system or '
                'network connected to Monk.',
          ),

          _Section(
            number: '5.',
            title: 'Intellectual Property',
            textColor: textColor,
            subColor: subColor,
            body:
                'All software, design, code, and content comprising Monk — excluding '
                'data you enter — is the intellectual property of Monk\'s developers. '
                'You are granted a limited, non-exclusive, non-transferable license '
                'to use the application for personal purposes only. You may not copy, '
                'redistribute, or create derivative works from any part of Monk without '
                'explicit written permission.',
          ),

          _Section(
            number: '6.',
            title: 'Disclaimer — Not Financial Advice',
            textColor: textColor,
            subColor: subColor,
            body:
                'Monk is a personal productivity and planning tool. Nothing within the '
                'application — including any investment tracking, net worth calculations, '
                'market data displays, or budget summaries — constitutes financial, '
                'investment, legal, or tax advice. Always consult a qualified professional '
                'before making financial decisions. Market data is provided for informational '
                'purposes only and may not be accurate or up to date.',
          ),

          _Section(
            number: '7.',
            title: 'Limitation of Liability',
            textColor: textColor,
            subColor: subColor,
            body:
                'To the maximum extent permitted by applicable law, Monk and its developers '
                'shall not be liable for any indirect, incidental, special, consequential, '
                'or punitive damages arising from your use of the application. This includes, '
                'but is not limited to, loss of data, financial loss, or any decisions made '
                'based on information displayed in the app. Your use of Monk is entirely at '
                'your own risk.',
          ),

          _Section(
            number: '8.',
            title: 'Changes to Terms',
            textColor: textColor,
            subColor: subColor,
            body:
                'We reserve the right to update these Terms of Service at any time. '
                'Material changes will be communicated via in-app notice or email. '
                'Your continued use of Monk after any such changes constitutes your '
                'acceptance of the revised terms. We encourage you to review these '
                'terms periodically.',
          ),

          _Section(
            number: '9.',
            title: 'Contact',
            textColor: textColor,
            subColor: subColor,
            body:
                'If you have any questions or concerns about these Terms of Service, '
                'please contact us at support@prp-app.website. We will do our best '
                'to respond within a reasonable timeframe.',
          ),

          const Gap(40),
        ],
      ),
    );
  }
}

// ── Reusable section widget ───────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  final Color textColor;
  final Color subColor;

  const _Section({
    required this.number,
    required this.title,
    required this.body,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number $title',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const Gap(8),
          Text(
            body,
            style: TextStyle(
              color: subColor,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
