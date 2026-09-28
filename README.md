# التوقيت الغروبي · Ghuroubi Time

تطبيق Flutter يعرض **الساعة الغروبية** (ساعات متساوية تُعدّ من الغروب، المغرب = ١٢:٠٠)،
والتوقيت الزوالي الحقيقي، ومواقيت الصلاة (أم القرى افتراضياً)، والتقويم الهجري الديني
لكل دولة (جدول أم القرى مصحَّحاً بإعلانات رؤية تلك الدولة)، واتجاه القبلة، وإشعارات
المناسبات. الواجهة بالعربية والإنجليزية.

- المعرّف: `com.misoor.grobi` · الموقع: <https://grobi.misoor.com>
- الخادم (PHP + MySQL + FCM) **ليس في هذا المستودع**.

## البنية

| المجلد | المحتوى |
|---|---|
| `lib/core/` | الحساب النقيّ: الفلك، الساعة الغروبية، المواقيت، تثبيت الأشهر الهجرية (`umm_alqura_corrections.dart`)، الأيام التقويمية (`date_utils.dart`)، التنسيق بلغة الواجهة |
| `lib/providers/` | الحالة (Riverpod): الإعدادات، الموقع، الإعلانات، المواقيت |
| `lib/screens/`, `lib/widgets/` | الواجهة |
| `lib/services/` | FCM، التنبيهات المحلية، الخادم، تقارير الأعطال، سجل التشخيص |
| `lib/l10n/` | نصوص الواجهة `app_ar.arb` (القالب) و`app_en.arb` — تُولَّد تلقائياً عند البناء |
| `test/` | اختبارات الوحدة والواجهة |
| `tool/test_dst.sh` | إعادة اختبارات الأيام تحت مناطق زمنية ذات توقيت صيفي |

## التشغيل الأوّل (نسخة مستنسخة جديدة)

ملفات Firebase والتوقيع **غير مرفوعة** عمداً، فأنشئها محلياً:

1. Flutter **3.44** (Dart 3.12).
2. ملفات Firebase (مشروع `timer-grobi`):
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=timer-grobi --platforms=android,ios \
       --android-package-name=com.misoor.grobi --ios-bundle-id=com.misoor.grobi
   ```
   يولّد `lib/firebase_options.dart` و`android/app/google-services.json`
   (و`ios/Runner/GoogleService-Info.plist` — على لينكس قد يلزم إنشاؤه عبر
   `firebase apps:sdkconfig`).
3. توقيع نسخة المتجر (اختياري للتطوير): `android/key.properties`
   ```properties
   storePassword=…
   keyPassword=…
   keyAlias=upload
   storeFile=/مسار/مطلق/إلى/grobi-upload.jks
   ```
   بدونه تُوقَّع نسخة الإصدار بمفتاح debug (تعمل للتجربة ولا تُقبل في المتجر).
   **احفظ ملف المفتاح وكلمة مروره في مكان آمن خارج هذا المستودع العام.**

## الأوامر

```bash
flutter analyze
flutter test
tool/test_dst.sh                         # جهاز المطوّر بتوقيت الرياض (بلا توقيت صيفي)
flutter build apk --release              # للتجربة على جهاز
flutter build appbundle --release        # للرفع إلى Google Play
```

## ملاحظات

- **منطقة الجهاز الزمنية مهمة للاختبارات:** `flutter test` وحده على منطقة بلا توقيت صيفي
  لا يكشف أخطاء حساب الأيام؛ `tool/test_dst.sh` يعيدها تحت الدار البيضاء والقاهرة
  وبيروت ولندن.
- **نصوص الإشعارات على أندرويد** في `android/app/src/main/res/values*/strings.xml`
  (مفاتيح `notif_*` يرسلها الخادم)، ومحميّة من مقلِّص الموارد بـ`res/raw/keep.xml`.
- **iOS** يُبنى عبر Codemagic (`codemagic.yaml`) ويحتاج مفتاح APNs في Firebase.
