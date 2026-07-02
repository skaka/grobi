/// المناسبات الأربع المُعلَنة بالرؤية (تطابق أنواع الخادم).
enum IslamicEventType { hijriNewYear, ramadan, eidFitr, dhulHijjah }

extension IslamicEventTypeX on IslamicEventType {
  /// المعرّف المطابق لحقل event_type في الخادم.
  String get id {
    switch (this) {
      case IslamicEventType.hijriNewYear:
        return 'hijri_new_year';
      case IslamicEventType.ramadan:
        return 'ramadan';
      case IslamicEventType.eidFitr:
        return 'eid_fitr';
      case IslamicEventType.dhulHijjah:
        return 'dhul_hijjah';
    }
  }

  String get arabicName {
    switch (this) {
      case IslamicEventType.hijriNewYear:
        return 'رأس السنة الهجرية';
      case IslamicEventType.ramadan:
        return 'دخول رمضان';
      case IslamicEventType.eidFitr:
        return 'عيد الفطر';
      case IslamicEventType.dhulHijjah:
        return 'دخول ذي الحجة';
    }
  }

  /// رقم الشهر الهجري الذي تُعلَن بدايته بهذه المناسبة (1..12) — للمعايرة.
  int get hijriMonth {
    switch (this) {
      case IslamicEventType.hijriNewYear:
        return 1; // محرّم
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

/// إعلان مناسبة مؤكّد (من الخادم/الرؤية) لدولة معيّنة.
class EventAnnouncement {
  final IslamicEventType type;
  final int hijriYear;
  final DateTime gregorianDate; // أول يوم للمناسبة
  final String? note;

  const EventAnnouncement({
    required this.type,
    required this.hijriYear,
    required this.gregorianDate,
    this.note,
  });

  /// مفتاح فريد (نوع+سنة) لكشف الإعلانات الجديدة.
  String get key => '${type.id}_$hijriYear';

  Map<String, dynamic> toJson() => {
        'type': type.id,
        'hijriYear': hijriYear,
        'gregorianDate': gregorianDate.toIso8601String(),
        'note': note,
      };

  static EventAnnouncement? fromJson(Map<String, dynamic> json) {
    final type = IslamicEventTypeX.fromId(json['type'] as String? ?? '');
    final dateStr = json['gregorianDate'] as String?;
    if (type == null || dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    return EventAnnouncement(
      type: type,
      hijriYear: (json['hijriYear'] as num?)?.toInt() ?? 0,
      gregorianDate: date,
      note: json['note'] as String?,
    );
  }

  /// من استجابة الخادم: {event_type, hijri_year, gregorian_date, note}.
  static EventAnnouncement? fromServer(Map<String, dynamic> json) {
    final type = IslamicEventTypeX.fromId(json['event_type'] as String? ?? '');
    final dateStr = json['gregorian_date'] as String?;
    if (type == null || dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    return EventAnnouncement(
      type: type,
      hijriYear: (json['hijri_year'] as num?)?.toInt() ?? 0,
      gregorianDate: date,
      note: json['note'] as String?,
    );
  }

  /// من حمولة `data` لرسالة FCM: {type, hijri_year, gregorian_date}.
  /// (تختلف عن [fromServer] بأن مفتاح النوع هنا `type` لا `event_type`، وكل
  /// القيم نصوص لأن FCM يرسل `data` نصوصاً.)
  static EventAnnouncement? fromPushData(Map<String, dynamic> data) {
    final type = IslamicEventTypeX.fromId(data['type'] as String? ?? '');
    final dateStr = data['gregorian_date'] as String?;
    if (type == null || dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    return EventAnnouncement(
      type: type,
      hijriYear: int.tryParse('${data['hijri_year'] ?? ''}') ?? 0,
      gregorianDate: date,
      note: data['note'] as String?,
    );
  }
}
