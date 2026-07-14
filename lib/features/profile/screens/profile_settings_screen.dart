import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/placeholders.dart';
import '../../../features/auth/providers/auth_provider.dart';

const _prefDateFormat = 'date_format';
const _dateFormats = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'];
const _currencies = ['EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED'];
const _currencySymbols = {
  'EGP': 'EGP (£)',
  'USD': 'USD (\$)',
  'EUR': 'EUR (€)',
  'GBP': 'GBP (£)',
  'SAR': 'SAR (﷼)',
  'AED': 'AED (د.إ)',
};

Future<void> _showEditNameDialog(BuildContext context, WidgetRef ref, String? current) async {
  final ctrl = TextEditingController(text: current ?? '');
  final saved = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit Full Name'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Full name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  if (saved != null && saved.isNotEmpty) {
    await ref.read(authNotifierProvider.notifier).updateName(saved);
  }
}

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  bool _uploadingAvatar = false;
  String _dateFormat = 'DD/MM/YYYY';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dateFormat = prefs.getString(_prefDateFormat) ?? 'DD/MM/YYYY';
    });
  }

  Future<void> _saveDateFormat(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDateFormat, val);
    if (mounted) setState(() => _dateFormat = val);
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await file.readAsBytes();
      // On Flutter web, file.path is a blob URL — use file.name for the extension
      final name = file.name.isNotEmpty ? file.name : file.path;
      final ext = name.contains('.')
          ? name.split('.').last.toLowerCase()
          : 'jpg';
      await ref.read(authNotifierProvider.notifier).updateAvatar(bytes, ext);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _showCurrencyPicker() async {
    final currentCurrency =
        ref.read(currencyNotifierProvider).asData?.value ?? 'EGP';
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Default Currency'),
        children: _currencies
            .map((c) => ListTile(
                  title: Text(_currencySymbols[c] ?? c),
                  trailing: c == currentCurrency
                      ? const Icon(Icons.check_rounded, size: 18)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(c),
                ))
            .toList(),
      ),
    );
    if (picked != null) {
      ref.read(currencyNotifierProvider.notifier).set(picked);
    }
  }

  Future<void> _showLanguagePicker() async {
    final currentLocale = ref.read(localeProvider).asData?.value ?? const Locale('en');
    final picked = await showDialog<Locale>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Language'),
        children: kSupportedLocales
            .map((loc) => ListTile(
                  title: Text(kLocaleNames[loc.languageCode] ?? loc.languageCode),
                  trailing: loc.languageCode == currentLocale.languageCode
                      ? const Icon(Icons.check_rounded, size: 18)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(loc),
                ))
            .toList(),
      ),
    );
    if (picked != null) {
      await ref.read(localeProvider.notifier).setLocale(picked);
    }
  }

  Future<void> _showDateFormatPicker() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Date Format'),
        children: _dateFormats
            .map((f) => ListTile(
                  title: Text(f),
                  trailing: f == _dateFormat
                      ? const Icon(Icons.check_rounded, size: 18)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(f),
                ))
            .toList(),
      ),
    );
    if (picked != null) await _saveDateFormat(picked);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final currency = ref.watch(currencyNotifierProvider).asData?.value ?? 'EGP';
    final currentLocale = ref.watch(localeProvider).asData?.value ?? const Locale('en');
    final currentLanguageName = kLocaleNames[currentLocale.languageCode] ?? 'English';
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;
    final tz = DateTime.now().timeZoneName;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Profile',
              subtitle: 'Your personal information',
            ),
            const Gap(24),

            // Avatar + name card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: accent.withValues(alpha: 0.15),
                          child: user?.avatarUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user!.avatarUrl!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Text(
                                      user.fullName?.isNotEmpty == true
                                          ? user.fullName![0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontFamily: 'PlayfairDisplay',
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Icon(
                                        Icons.person_rounded,
                                        color: accent,
                                        size: 28),
                                  ),
                                )
                              : Text(
                                  user?.fullName?.isNotEmpty == true
                                      ? user!.fullName![0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                        ),
                        if (_uploadingAvatar)
                          Positioned.fill(
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.black38,
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: cardColor, width: 1.5),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(Spacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Gap(4),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: textSecondary),
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppConstants.appStage,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    color: textSecondary,
                    onPressed: () => _showEditNameDialog(context, ref, user?.fullName),
                  ),
                ],
              ),
            ),
            const Gap(24),

            const SectionHeader('Personal Info'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'Full Name',
                subtitle: user?.fullName?.isNotEmpty == true ? user!.fullName! : 'Tap to set your name',
                leading: const Icon(Icons.person_outline, size: 20),
                onTap: () => _showEditNameDialog(context, ref, user?.fullName),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Email Address',
                subtitle: user?.email ?? 'Not set',
                leading: const Icon(Icons.email_outlined, size: 20),
                onTap: () => _showInfo('To change your email, contact support at support@prp-app.website'),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Phone Number',
                subtitle: 'Not supported with email auth',
                leading: const Icon(Icons.phone_outlined, size: 20),
                onTap: () => _showInfo('Phone number login is not available. Use email & password to sign in.'),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Timezone',
                subtitle: tz,
                leading: const Icon(Icons.language_outlined, size: 20),
                onTap: () => _showInfo('Timezone is detected automatically from your browser ($tz).'),
              ),
            ]),
            const Gap(24),

            const SectionHeader('Preferences'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: l.language,
                subtitle: currentLanguageName,
                leading: const Icon(Icons.translate_outlined, size: 20),
                onTap: _showLanguagePicker,
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Currency',
                subtitle: _currencySymbols[currency] ?? currency,
                leading: const Icon(Icons.attach_money_outlined, size: 20),
                onTap: _showCurrencyPicker,
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Date Format',
                subtitle: _dateFormat,
                leading: const Icon(Icons.calendar_today_outlined, size: 20),
                onTap: _showDateFormatPicker,
              ),
            ]),
            const Gap(24),

            const SectionHeader('Help & Support'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'Documentation',
                subtitle: 'Guides and how-to articles',
                leading: const Icon(Icons.menu_book_outlined, size: 20),
                onTap: () => launchUrl(
                  Uri.parse('https://prp-app.website/docs'),
                  mode: LaunchMode.externalApplication,
                ),
                trailing: const Icon(Icons.open_in_new, size: 16),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Download for Windows',
                subtitle: 'Coming soon',
                leading: const Icon(Icons.computer_outlined, size: 20),
                onTap: () => _showInfo('Windows desktop app is coming soon.'),
                trailing: _ComingSoonBadge(),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Android & iOS',
                subtitle: 'Mobile apps — coming soon',
                leading: const Icon(Icons.phone_android_outlined, size: 20),
                onTap: () => _showInfo('Mobile apps are coming soon.'),
                trailing: _ComingSoonBadge(),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'App Version',
                subtitle: 'Monk v${AppConstants.appVersion}',
                leading: const Icon(Icons.info_outline, size: 20),
                onTap: () {},
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Soon',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.warning,
        ),
      ),
    );
  }
}