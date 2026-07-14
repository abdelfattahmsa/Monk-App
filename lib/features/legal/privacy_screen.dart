import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

const _keyPoints = [
  'We collect only what\'s needed: your email, name, and the data you enter',
  'We NEVER sell your data or share it with advertisers',
  'Your financial, health, and personal data stays private',
  'You can export or delete your data at any time',
  'Vercel Analytics: anonymous page-view counts only (no fingerprinting)',
];

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          'Privacy Policy',
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
            title: 'Information We Collect',
            textColor: textColor,
            subColor: subColor,
            body:
                'We collect the minimum information necessary to provide you with '
                'a high-quality experience:\n\n'
                '• Account information: your email address and display name, '
                'provided during sign-up.\n\n'
                '• App data you enter: financial records, health metrics, goals, '
                'tasks, habits, and any other information you choose to add to Monk.\n\n'
                '• Anonymous analytics: Vercel Analytics collects aggregated, '
                'anonymous page-view counts and performance metrics. No personal '
                'identifiers, device fingerprints, or behavioral profiles are '
                'collected through analytics.',
          ),

          _Section(
            number: '2.',
            title: 'How We Use Your Information',
            textColor: textColor,
            subColor: subColor,
            body:
                'The information we collect is used solely to:\n\n'
                '• Provide, maintain, and improve the Monk application.\n\n'
                '• Authenticate your identity and protect your account.\n\n'
                '• Send transactional emails such as password resets and sign-in '
                'confirmations (via Supabase Auth).\n\n'
                '• Understand aggregate usage patterns to improve performance '
                'and user experience (via anonymous analytics only).\n\n'
                'We do not use your data for advertising, profiling, or any '
                'purpose beyond operating and improving Monk.',
          ),

          _Section(
            number: '3.',
            title: 'What We Never Do',
            textColor: textColor,
            subColor: subColor,
            body:
                'We are committed to the following absolute privacy guarantees:\n\n'
                '• We will NEVER sell your personal data to any third party.\n\n'
                '• We will NEVER share your data with advertisers or ad networks.\n\n'
                '• We will NEVER build behavioral profiles about you for commercial '
                'purposes.\n\n'
                '• We will NEVER use your financial, health, or personal productivity '
                'data for any purpose other than providing the app to you.',
          ),

          _Section(
            number: '4.',
            title: 'Data Storage & Security',
            textColor: textColor,
            subColor: subColor,
            body:
                'Your data is stored in a PostgreSQL database hosted on Supabase. '
                'Supabase implements row-level security (RLS), ensuring that each '
                'user can only access their own data. All data is encrypted at rest '
                'and in transit using industry-standard TLS encryption.\n\n'
                'The application is hosted on Vercel, which provides infrastructure-level '
                'security and compliance. We follow security best practices including '
                'secure authentication flows and regular dependency updates.',
          ),

          _Section(
            number: '5.',
            title: 'Your Rights',
            textColor: textColor,
            subColor: subColor,
            body:
                'You have full control over your data at all times:\n\n'
                '• Access: You can view all data you have entered in the app at any time.\n\n'
                '• Export: Contact support to request a full export of your data.\n\n'
                '• Deletion: You can delete your account and all associated data at any time '
                'via the in-app account deletion feature or by contacting support.\n\n'
                'To exercise any of these rights, email us at support@prp-app.website.',
          ),

          _Section(
            number: '6.',
            title: 'Cookies',
            textColor: textColor,
            subColor: subColor,
            body:
                'Monk uses session cookies only — these are strictly necessary for '
                'keeping you logged in and maintaining your session state. We do not '
                'use tracking cookies, advertising cookies, or any third-party cookies '
                'that monitor your browsing activity across other websites.',
          ),

          _Section(
            number: '7.',
            title: 'Third-Party Services',
            textColor: textColor,
            subColor: subColor,
            body:
                'Monk relies on the following third-party services, each with their '
                'own privacy practices:\n\n'
                '• Supabase (database and authentication): https://supabase.com/privacy\n\n'
                '• Vercel (hosting and analytics): https://vercel.com/legal/privacy-policy\n\n'
                'We encourage you to review their privacy policies. We do not share '
                'your personal data with any other third-party services.',
          ),

          _Section(
            number: '8.',
            title: 'Children\'s Privacy',
            textColor: textColor,
            subColor: subColor,
            body:
                'Monk is not intended for use by anyone under the age of 13. We do '
                'not knowingly collect personal information from children under 13. '
                'If you believe a child has provided us with personal information, '
                'please contact us immediately at support@prp-app.website and we '
                'will take steps to delete such information.',
          ),

          _Section(
            number: '9.',
            title: 'Changes to This Policy',
            textColor: textColor,
            subColor: subColor,
            body:
                'We may update this Privacy Policy from time to time to reflect '
                'changes in our practices or legal requirements. Material changes '
                'will be communicated via in-app notice or email to your registered '
                'address. We encourage you to review this policy periodically. '
                'Continued use of Monk after changes constitutes your acceptance of '
                'the updated policy.',
          ),

          _Section(
            number: '10.',
            title: 'Contact',
            textColor: textColor,
            subColor: subColor,
            body:
                'If you have any questions, concerns, or requests regarding this '
                'Privacy Policy or how your data is handled, please contact us at '
                'support@prp-app.website. We are committed to addressing your '
                'privacy concerns promptly and transparently.',
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
