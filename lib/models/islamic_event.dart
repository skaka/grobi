/// المناسبات الخمس المُعلَنة بالرؤية (تطابق أنواع الخادم).
enum IslamicEventType { hijriNewYear, shaban, ramadan, eidFitr, dhulHijjah }

extension IslamicEventTypeX on IslamicEventType {
  /// المعرّف المطابق لحقل event_type في الخادم.
  String get id {
    switch (this) {
      case IslamicEventType.hijriNewYear:
        return 'hijri_new_year';
      case IslamicEventType.shaban:
        return 'shaban';
      case IslamicEventType.ramadan:
        return 'ramadan';
      case IslamicEventType.eidFitr:
        return 'eid_fitr';
      case IslamicEventType.dhulHijjah:
        return 'dhul_hijjah';
    }
  }

  /// رقم الشهر الهجري الذي تُعلَن بدايته بهذه المناسبة (1..12).
  int get hijriMonth {
    switch (this) {
      case IslamicEventType.hijriNewYear:
        return 1; // محرّم
      case IslamicEventType.shaban:
        return 8; // شعبان
      case IslamicEventType.ramadan:
        return 9; // رمضان
      case IslamicEventType.eidFitr:
        return 10; // شوّال (غُرّته عيد الفطر)
      case IslamicEventType.dhulHijjah:
        return 12; // ذو الحجة
    }
  }

  static IslamicEventType? fromId(String id) {
    for (final t in IslamicEventType.values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// إعلان مؤكّد (من الخادم/الرؤية) لبداية شهر هجري في دولة معيّنة.
///
/// الأشهر الخمسة المسمّاة لها [type] وتُنبِّه المستخدم؛ وأي شهر آخر يصل
/// **تثبيتاً صامتاً** ([type] = null) يصحّح التقويم دون إشعار.
class EventAnnouncement {
  final IslamicEventType? type;
  final int hijriYear;
  final int hijriMonth; // 1..12
  final DateTime gregorianDate; // أول يوم في الشهر
  final String? note;

  /// false = نشره المشرف صامتاً عمداً، فلا يُنبَّه عنه حتى لو فات إشعاره وجاء
  /// عبر المزامنة. (الخوادم الأقدم لا ترسله ⇒ true.)
  final bool notify;

  /// [hijriMonth] يُشتقّ من [type] إن وُجد (الخادم يربطهما دائماً)، وإلا يلزم
  /// تمريره للتثبيت الصامت.
  EventAnnouncement({
    this.type,
    required this.hijriYear,
    int? hijriMonth,
    required this.gregorianDate,
    this.note,
    this.notify = true,
  }) : hijriMonth = type?.hijriMonth ?? hijriMonth ?? 0;

  /// تثبيت صامت (بلا مناسبة مسمّاة ولا إشعار).
  bool get isSilent => type == null;

  /// مفتاح فريد لكشف الجديد. يبقى `نوع_سنة` للمناسبات المسمّاة كما كان (كي لا
  /// تُعاد تنبيهات قديمة بعد التحديث)، و`mشهر_سنة` للتثبيت الصامت.
  String get key =>
      type != null ? '${type!.id}_$hijriYear' : 'm${hijriMonth}_$hijriYear';

  Map<String, dynamic> toJson() => {
        'type': type?.id,
        'hijriYear': hijriYear,
        'hijriMonth': hijriMonth,
        'gregorianDate': gregorianDate.toIso8601String(),
        'note': note,
        'notify': notify,
      };

  /// يبني إعلاناً من نوع نصّي (قد يكون فارغاً) وشهر؛ يُعيد null إن لم يكن نوعاً
  /// معروفاً ولا شهراً صالحاً، أو إن تعذّر تحليل التاريخ.
  static EventAnnouncement? _build({
    required String? typeId,
    required int? month,
    required int year,
    required String? dateStr,
    required String? note,
    bool notify = true,
  }) {
    // النوع المعروف هو المرجع للشهر. وبلا نوع معروف (تثبيت صامت، أو نوع أحدث من
    // هذه النسخة) يُقبل الإعلان تثبيتاً صامتاً ما دام شهره صالحاً.
    final type = IslamicEventTypeX.fromId(typeId ?? '');
    if (type == null && (month == null || month < 1 || month > 12)) {
      return null;
    }
    if (dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    return EventAnnouncement(
      type: type,
      hijriYear: year,
      hijriMonth: month,
      gregorianDate: DateTime(date.year, date.month, date.day),
      note: note,
      notify: notify,
    );
  }

  /// قيمة notify من JSON/خادم/FCM: 0 أو '0' أو false ⇒ false، وغيابها ⇒ true.
  static bool _notifyFlag(Object? v) =>
      !(v == 0 || v == '0' || v == false || v == 'false');

  static EventAnnouncement? fromJson(Map<String, dynamic> json) => _build(
        typeId: json['type'] as String?,
        month: (json['hijriMonth'] as num?)?.toInt(),
        year: (json['hijriYear'] as num?)?.toInt() ?? 0,
        dateStr: json['gregorianDate'] as String?,
        note: json['note'] as String?,
        notify: _notifyFlag(json['notify']),
      );

  /// من استجابة الخادم: {event_type, hijri_month, hijri_year, gregorian_date, note}.
  /// صفوف التثبيت الصامت يكون event_type فيها null.
  static EventAnnouncement? fromServer(Map<String, dynamic> json) => _build(
        typeId: json['event_type'] as String?,
        month: int.tryParse('${json['hijri_month'] ?? ''}'),
        year: int.tryParse('${json['hijri_year'] ?? ''}') ?? 0,
        dateStr: json['gregorian_date'] as String?,
        note: json['note'] as String?,
        notify: _notifyFlag(json['notify']),
      );

  /// من حمولة `data` لرسالة FCM: {type?, hijri_month, hijri_year, gregorian_date}.
  /// (مفتاح النوع هنا `type` لا `event_type`، ويغيب في رسائل التثبيت الصامت؛ وكل
  /// القيم نصوص لأن FCM يرسل `data` نصوصاً.)
  static EventAnnouncement? fromPushData(Map<String, dynamic> data) => _build(
        typeId: data['type'] as String?,
        month: int.tryParse('${data['hijri_month'] ?? ''}'),
        year: int.tryParse('${data['hijri_year'] ?? ''}') ?? 0,
        dateStr: data['gregorian_date'] as String?,
        note: data['note'] as String?,
        notify: _notifyFlag(data['notify']),
      );
}
