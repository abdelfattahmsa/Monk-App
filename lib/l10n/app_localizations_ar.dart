// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Monk';

  @override
  String get tabOverview => 'الرئيسية';

  @override
  String get tabTime => 'الوقت';

  @override
  String get tabFinance => 'المالية';

  @override
  String get tabEnergy => 'الطاقة';

  @override
  String get tabHealth => 'الصحة';

  @override
  String get tabProfile => 'الملف الشخصي';

  @override
  String get subOverview => 'نظرة عامة';

  @override
  String get subCalendar => 'التقويم';

  @override
  String get subSchedule => 'الجدول';

  @override
  String get subTasks => 'المهام';

  @override
  String get subAccounts => 'الحسابات';

  @override
  String get subCards => 'البطاقات';

  @override
  String get subInvest => 'الاستثمار';

  @override
  String get subDebts => 'الديون';

  @override
  String get subTxns => 'المعاملات';

  @override
  String get subFocus => 'التركيز';

  @override
  String get subMood => 'المزاج';

  @override
  String get subGoals => 'الأهداف';

  @override
  String get subIdeas => 'الأفكار';

  @override
  String get subProgress => 'التقدم';

  @override
  String get subFasting => 'الصيام';

  @override
  String get subHabits => 'العادات';

  @override
  String get subBody => 'الجسم';

  @override
  String get subNutrition => 'التغذية';

  @override
  String get subExercise => 'التمرين';

  @override
  String get subAccount => 'الحساب';

  @override
  String get subApp => 'التطبيق';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutTitle => 'تسجيل الخروج؟';

  @override
  String get signOutMessage => 'ستعود إلى شاشة تسجيل الدخول.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get add => 'إضافة';

  @override
  String get close => 'إغلاق';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get done => 'تم';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get language => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get notificationsEnabled => '✓ تم تفعيل الإشعارات';

  @override
  String get enableNotifications => 'تفعيل';

  @override
  String get notificationsPrompt =>
      'فعّل الإشعارات لتذكيرات التركيز والصيام والعادات';

  @override
  String get emailVerifyPrompt => 'يرجى التحقق من بريدك الإلكتروني';

  @override
  String get emailVerifyUnlock => 'لفتح جميع الميزات.';

  @override
  String get resend => 'إعادة الإرسال';

  @override
  String get focusSessionComplete => '🍅 انتهت جلسة التركيز!';

  @override
  String get breakOver => '☕ انتهت فترة الراحة!';

  @override
  String get tapToReturn => 'اضغط للعودة إلى Monk';

  @override
  String get focus => 'تركيز';

  @override
  String get breakLabel => 'راحة';

  @override
  String get support => 'الدعم';

  @override
  String get termsPrivacy => 'الشروط والخصوصية';

  @override
  String get collapse => 'طي القائمة';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get manualEntryOnly => 'الإدخال اليدوي فقط على هذه المنصة';

  @override
  String syncingFrom(String platform) {
    return 'جارٍ المزامنة من $platform…';
  }

  @override
  String get syncFailed => 'فشلت المزامنة';

  @override
  String connectTo(String platform) {
    return 'الاتصال بـ $platform';
  }

  @override
  String get connectDescription =>
      'مزامنة الوزن ومعدل ضربات القلب والخطوات والنوم تلقائياً';

  @override
  String get permissionRequired => 'الإذن مطلوب';

  @override
  String permissionTap(String platform) {
    return 'اضغط لمنح الوصول إلى $platform';
  }

  @override
  String syncedFrom(String platform) {
    return 'تمت المزامنة من $platform';
  }

  @override
  String get grantAccess => 'منح الوصول';

  @override
  String get syncAgain => 'مزامنة مجدداً';

  @override
  String get connect => 'اتصال';
}
