import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../core/date_calc.dart';
import '../core/format_utils.dart';
import '../l10n/l10n.dart';
import '../theme.dart';

// ملاحظة: التحويل هنا «هجري خام» (تقويم أم القرى في الحزمة دون تعديلات الرؤية)،
// بخلاف جدول التقويم أعلاه الذي يطبّق التصحيحات الغروبية — بناءً على اختيار المستخدم.

/// المدى الصالح لجدول أم القرى في حزمة `hijri`: ١٣٥٦–١٥٠٠ هـ ⇔ ١٩٣٧–٢٠٧٧م.
const int _minHijriYear = 1356;
const int _maxHijriYear = 1500;
final DateTime _minGregorian = DateTime(1937, 3, 14);
final DateTime _maxGregorian = DateTime(2077, 11, 16);

// ───────────────────────── بطاقة عامة ─────────────────────────

/// حاوية بطاقة موحّدة (حدّ ذهبي رفيع + ترويسة بأيقونة) لأدوات التاريخ.
class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// حقل تاريخ قابل للنقر (يشبه زر إدخال) بعنوان صغير ونصّ التاريخ.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.nightTop.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── بطاقة التحويل ─────────────────────────

/// تحويل التاريخ في الاتجاهين (ميلادي↔هجري) داخل بطاقة واحدة — هجري خام.
class HijriConverterCard extends StatefulWidget {
  const HijriConverterCard({super.key});

  @override
  State<HijriConverterCard> createState() => _HijriConverterCardState();
}

class _HijriConverterCardState extends State<HijriConverterCard> {
  bool _gregToHijri = true;
  late DateTime _greg;
  late int _hy;
  late int _hm;
  late int _hd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _greg = DateTime(now.year, now.month, now.day);
    final h = HijriCalendar.fromDate(_greg);
    _hy = h.hYear;
    _hm = h.hMonth;
    _hd = h.hDay;
  }

  Future<void> _pickGregorian() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _greg,
      firstDate: _minGregorian,
      lastDate: _maxGregorian,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            surface: AppColors.surface,
            onSurface: AppColors.onDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _greg = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickHijri() async {
    final result = await showHijriDatePicker(
      context: context,
      year: _hy,
      month: _hm,
      day: _hd,
    );
    if (result != null) {
      setState(() {
        _hy = result.$1;
        _hm = result.$2;
        _hd = result.$3;
      });
    }
  }

  String _weekdayLine(DateTime d) => weekdayName(d.weekday);

  @override
  Widget build(BuildContext context) {
    // المصدر والنتيجة حسب الاتجاه — مع التقاط أخطاء المدى.
    String sourceLabel;
    String sourceValue;
    VoidCallback onPickSource;
    String resultMain;
    String resultSub;

    final l10n = context.l10n;
    try {
      if (_gregToHijri) {
        sourceLabel = l10n.gregorianDateLabel;
        sourceValue = formatGregorianDate(_greg);
        onPickSource = _pickGregorian;
        final h = HijriCalendar.fromDate(_greg);
        resultMain = formatHijriDate(h.hDay, h.hMonth, h.hYear);
        resultSub = _weekdayLine(_greg);
      } else {
        sourceLabel = l10n.hijriDateLabel;
        sourceValue = formatHijriDate(_hd, _hm, _hy);
        onPickSource = _pickHijri;
        final g = HijriCalendar().hijriToGregorian(_hy, _hm, _hd);
        resultMain = formatGregorianDate(g);
        resultSub = _weekdayLine(g);
      }
    } catch (_) {
      sourceLabel =
          _gregToHijri ? l10n.gregorianDateLabel : l10n.hijriDateLabel;
      sourceValue = '—';
      onPickSource = _gregToHijri ? _pickGregorian : _pickHijri;
      resultMain = l10n.outOfRange;
      resultSub = localDigits('$_minHijriYear – $_maxHijriYear $hijriEra');
    }

    return _ToolCard(
      icon: Icons.swap_horiz_rounded,
      title: l10n.converterTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DirectionToggle(
            gregToHijri: _gregToHijri,
            onChanged: (v) => setState(() => _gregToHijri = v),
          ),
          const SizedBox(height: 14),
          _DateField(
            label: sourceLabel,
            value: sourceValue,
            onTap: onPickSource,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Icon(Icons.arrow_downward_rounded,
                color: AppColors.muted, size: 20),
          ),
          _ResultBox(main: resultMain, sub: resultSub),
        ],
      ),
    );
  }
}

/// مفتاح تبديل اتجاه التحويل (شريحتان منزلقتان).
class _DirectionToggle extends StatelessWidget {
  const _DirectionToggle({required this.gregToHijri, required this.onChanged});

  final bool gregToHijri;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.nightTop.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _segment(context.l10n.gregToHijri, gregToHijri, () => onChanged(true)),
          _segment(
              context.l10n.hijriToGreg, !gregToHijri, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.nightTop : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// صندوق النتيجة الكبير (النص الرئيسي بالذهبي + سطر اليوم).
class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.main, required this.sub});

  final String main;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.18),
            AppColors.gold.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            main,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.onDark),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── بطاقة حساب المدة ─────────────────────────

/// حساب المدة/العمر بين تاريخين — الفرق معروض بالتقويمين الميلادي والهجري.
class DateDifferenceCard extends StatefulWidget {
  const DateDifferenceCard({super.key});

  @override
  State<DateDifferenceCard> createState() => _DateDifferenceCardState();
}

class _DateDifferenceCardState extends State<DateDifferenceCard> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = DateTime(now.year - 20, now.month, now.day);
  }

  Future<void> _pick(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: _minGregorian,
      lastDate: _maxGregorian,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            surface: AppColors.surface,
            onSurface: AppColors.onDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final d = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      if (isFrom) {
        _from = d;
      } else {
        _to = d;
      }
    });
  }

  String _fmtG(DateTime d) => formatGregorianDate(d, withEra: false);

  @override
  Widget build(BuildContext context) {
    final r = durationBetween(_from, _to);
    final l10n = context.l10n;
    return _ToolCard(
      icon: Icons.hourglass_bottom_rounded,
      title: l10n.durationTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: l10n.fromLabel,
                  value: _fmtG(_from),
                  onTap: () => _pick(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateField(
                  label: l10n.toLabel,
                  value: _fmtG(_to),
                  onTap: () => _pick(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () {
                final now = DateTime.now();
                setState(
                    () => _to = DateTime(now.year, now.month, now.day));
              },
              icon: const Icon(Icons.today_rounded,
                  size: 16, color: AppColors.gold),
              label: Text(l10n.setToToday,
                  style: const TextStyle(fontSize: 12, color: AppColors.gold)),
            ),
          ),
          const SizedBox(height: 6),
          _DiffResult(diff: r.gregorian, calendarLabel: l10n.gregorianCalendar),
          const SizedBox(height: 10),
          _DiffResult(diff: r.hijri, calendarLabel: l10n.hijriCalendar),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.nightTop.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.totalDaysWeeks(
                  localDigits('${r.totalDays}'), localDigits('${r.totalWeeks}')),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.onDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// سطر نتيجة الفرق: وسم التقويم + ثلاث خانات (سنوات/أشهر/أيام).
class _DiffResult extends StatelessWidget {
  const _DiffResult({required this.diff, required this.calendarLabel});

  final YmdDiff diff;
  final String calendarLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            calendarLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _cell(diff.years, context.l10n.unitYears)),
        Expanded(child: _cell(diff.months, context.l10n.unitMonths)),
        Expanded(child: _cell(diff.days, context.l10n.unitDays)),
      ],
    );
  }

  Widget _cell(int value, String unit) {
    return Column(
      children: [
        Text(
          localDigits('$value'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.onDark,
          ),
        ),
        Text(unit,
            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }
}

// ───────────────────────── منتقي هجري مصمّم ─────────────────────────

/// منتقي تاريخ هجري (عجلات يوم/شهر/سنة) بورقة سفلية مطابقة للسمة.
/// يعيد `(سنة, شهر, يوم)` أو `null` عند الإلغاء. يُثبَّت اليوم ضمن طول الشهر.
Future<(int, int, int)?> showHijriDatePicker({
  required BuildContext context,
  required int year,
  required int month,
  required int day,
}) {
  return showModalBottomSheet<(int, int, int)>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _HijriPickerSheet(year: year, month: month, day: day),
  );
}

class _HijriPickerSheet extends StatefulWidget {
  const _HijriPickerSheet({
    required this.year,
    required this.month,
    required this.day,
  });

  final int year;
  final int month;
  final int day;

  @override
  State<_HijriPickerSheet> createState() => _HijriPickerSheetState();
}

class _HijriPickerSheetState extends State<_HijriPickerSheet> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    _year = widget.year.clamp(_minHijriYear, _maxHijriYear);
    _month = widget.month.clamp(1, 12);
    _day = widget.day.clamp(1, 30);
  }

  int get _daysInMonth => HijriCalendar().getDaysInMonth(_year, _month);

  @override
  Widget build(BuildContext context) {
    // نثبّت اليوم ضمن طول الشهر الحالي قبل العرض.
    final maxDay = _daysInMonth;
    final clampedDay = _day > maxDay ? maxDay : _day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            context.l10n.pickHijriDate,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _WheelHeader(context.l10n.dayHeader)),
              Expanded(child: _WheelHeader(context.l10n.monthHeader)),
              Expanded(child: _WheelHeader(context.l10n.yearHeader)),
            ],
          ),
          SizedBox(
            height: 170,
            child: Row(
              children: [
                Expanded(
                  child: _Wheel(
                    itemCount: maxDay,
                    selectedIndex: clampedDay - 1,
                    labelBuilder: (i) => localDigits('${i + 1}'),
                    onChanged: (i) => setState(() => _day = i + 1),
                  ),
                ),
                Expanded(
                  child: _Wheel(
                    itemCount: 12,
                    selectedIndex: _month - 1,
                    labelBuilder: (i) => hijriMonthName(i + 1),
                    onChanged: (i) => setState(() => _month = i + 1),
                  ),
                ),
                Expanded(
                  child: _Wheel(
                    itemCount: _maxHijriYear - _minHijriYear + 1,
                    selectedIndex: _year - _minHijriYear,
                    labelBuilder: (i) =>
                        localDigits('${_minHijriYear + i}'),
                    onChanged: (i) =>
                        setState(() => _year = _minHijriYear + i),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.nightTop,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                final d = _day > _daysInMonth ? _daysInMonth : _day;
                Navigator.of(context).pop((_year, _month, d));
              },
              child: Text(context.l10n.confirm,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelHeader extends StatelessWidget {
  const _WheelHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: AppColors.muted),
    );
  }
}

/// عجلة اختيار واحدة (Cupertino) بنمط السمة.
class _Wheel extends StatefulWidget {
  const _Wheel({
    required this.itemCount,
    required this.selectedIndex,
    required this.labelBuilder,
    required this.onChanged,
  });

  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onChanged;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        FixedExtentScrollController(initialItem: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(covariant _Wheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // عند تقلّص عدد العناصر (طول الشهر) يُعاد التموضع ضمن المدى الجديد،
    // بعد اكتمال الإطار لتفادي التعديل أثناء البناء.
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _controller.hasClients &&
            _controller.selectedItem != widget.selectedIndex) {
          _controller.jumpToItem(widget.selectedIndex);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      scrollController: _controller,
      itemExtent: 40,
      diameterRatio: 1.2,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onSelectedItemChanged: widget.onChanged,
      children: [
        for (var i = 0; i < widget.itemCount; i++)
          Center(
            child: Text(
              widget.labelBuilder(i),
              style: const TextStyle(fontSize: 16, color: AppColors.onDark),
            ),
          ),
      ],
    );
  }
}
