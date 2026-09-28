import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/cities.dart';
import '../core/countries.dart';
import '../core/app_language.dart';
import '../core/format_utils.dart';
import '../l10n/l10n.dart';
import '../models/location_data.dart';
import '../providers/countries_provider.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';

/// «المدينة، الدولة» بلغة الواجهة.
String cityLabel(City city) {
  final country = countryName(city.countryCode) ?? city.countryCode;
  return AppLanguage.isArabic
      ? '${city.name}، $country'
      : '${city.name}, $country';
}

/// وصف مختصر لمصدر الموقع الحالي (للبطاقات والشريط التنبيهي) بلغة الواجهة.
String locationSourceLabel(LocationData loc) {
  final city = cityById(loc.cityId);
  switch (loc.source) {
    case LocationSource.fallback:
      return tr.sourceFallback(city?.name ?? tr.meccaName);
    case LocationSource.gps:
      return tr.sourceGps;
    case LocationSource.manual:
      if (city != null) return cityLabel(city);
      return loc.label ?? tr.sourceManual;
  }
}

/// ورقة تحديد الموقع: GPS، أو مدينة من القائمة المضمَّنة، أو إحداثيات يدوية.
Future<void> showLocationPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _LocationPickerSheet(),
  );
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  const _LocationPickerSheet();

  @override
  ConsumerState<_LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  late String _countryCode;
  bool _locating = false;
  GpsResult? _gpsFailure;

  @override
  void initState() {
    super.initState();
    // دولة الإعلانات إن اختيرت، وإلا أول دولة لها مدن مضمَّنة.
    _countryCode = ref.read(settingsProvider).countryCode ?? kCities.first.countryCode;
  }

  Future<void> _useGps() async {
    setState(() {
      _locating = true;
      _gpsFailure = null;
    });
    final result = await ref.read(locationProvider.notifier).requestGps();
    if (!mounted) return;
    if (result == GpsResult.ok) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _locating = false;
      _gpsFailure = result;
    });
  }

  void _pickCity(City city) {
    ref
        .read(locationProvider.notifier)
        .setManual(city.latitude, city.longitude, cityId: city.id);
    Navigator.pop(context);
  }

  Future<void> _enterCoordinates() async {
    final current = ref.read(locationProvider);
    final coords = await showDialog<(double, double)>(
      context: context,
      builder: (_) => _CoordinatesDialog(
        latitude: current.latitude,
        longitude: current.longitude,
      ),
    );
    if (coords == null || !mounted) return;
    ref.read(locationProvider.notifier).setManual(coords.$1, coords.$2);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final countries = ref.watch(countriesProvider);
    final loc = ref.watch(locationProvider);
    final cities = citiesOf(_countryCode);
    final selectedName = countryName(_countryCode, countries) ?? _countryCode;
    // الدول التي لها مدن مضمَّنة + دولة المستخدم (قد تكون أحدث من القائمة المضمَّنة).
    final pickable = [
      for (final c in countries)
        if (citiesOf(c.code).isNotEmpty || c.code == _countryCode) c,
    ];
    if (!pickable.any((c) => c.code == _countryCode)) {
      pickable.add(Country(_countryCode, selectedName));
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.pickerTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold)),
              const SizedBox(height: 4),
              Text(l10n.currentLocation(locationSourceLabel(loc)),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 8),
              ListTile(
                leading: _locating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, color: AppColors.gold),
                title: Text(l10n.useGps,
                    style: const TextStyle(color: AppColors.onDark)),
                onTap: _locating ? null : _useGps,
              ),
              if (_gpsFailure != null) _gpsFailureNote(_gpsFailure!),
              const Divider(color: AppColors.muted, height: 16),
              Row(
                children: [
                  const Icon(Icons.location_city, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Text(l10n.orPickCityIn,
                      style: const TextStyle(color: AppColors.onDark)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _countryCode,
                      dropdownColor: AppColors.surface,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(
                          color: AppColors.gold, fontFamily: 'Cairo'),
                      items: [
                        for (final c in pickable)
                          DropdownMenuItem(value: c.code, child: Text(c.name)),
                      ],
                      onChanged: (code) {
                        if (code != null) setState(() => _countryCode = code);
                      },
                    ),
                  ),
                ],
              ),
              Flexible(
                child: cities.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(l10n.noCitiesForCountry,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.muted)),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final city in cities)
                            ListTile(
                              dense: true,
                              title: Text(city.name,
                                  style:
                                      const TextStyle(color: AppColors.onDark)),
                              trailing: Text(
                                  localDigits(
                                      '${city.latitude.toStringAsFixed(2)}°، '
                                      '${city.longitude.toStringAsFixed(2)}°'),
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 12)),
                              onTap: () => _pickCity(city),
                            ),
                        ],
                      ),
              ),
              const Divider(color: AppColors.muted, height: 16),
              ListTile(
                leading:
                    const Icon(Icons.edit_location_alt, color: AppColors.gold),
                title: Text(l10n.enterCoordinates,
                    style: const TextStyle(color: AppColors.onDark)),
                onTap: _enterCoordinates,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gpsFailureNote(GpsResult result) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(gpsResultMessage(result) ?? '',
                style: const TextStyle(color: AppColors.gold, fontSize: 13)),
          ),
          if (result == GpsResult.deniedForever)
            TextButton(
              onPressed: Geolocator.openAppSettings,
              child: Text(context.l10n.openAppSettings),
            ),
          if (result == GpsResult.serviceDisabled)
            TextButton(
              onPressed: Geolocator.openLocationSettings,
              child: Text(context.l10n.turnOn),
            ),
        ],
      ),
    );
  }
}

/// حوار إدخال خط العرض والطول (يقبل الأرقام العربية والفاصلة «٫»).
class _CoordinatesDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  const _CoordinatesDialog({required this.latitude, required this.longitude});

  @override
  State<_CoordinatesDialog> createState() => _CoordinatesDialogState();
}

class _CoordinatesDialogState extends State<_CoordinatesDialog> {
  late final TextEditingController _lat;
  late final TextEditingController _lon;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lat = TextEditingController(text: widget.latitude.toStringAsFixed(4));
    _lon = TextEditingController(text: widget.longitude.toStringAsFixed(4));
  }

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  void _save() {
    final lat = parseLocalizedDouble(_lat.text);
    final lon = parseLocalizedDouble(_lon.text);
    if (lat == null || lat < -90 || lat > 90) {
      setState(() => _error = context.l10n.latitudeRange);
      return;
    }
    if (lon == null || lon < -180 || lon > 180) {
      setState(() => _error = context.l10n.longitudeRange);
      return;
    }
    Navigator.pop(context, (lat, lon));
  }

  @override
  Widget build(BuildContext context) {
    const numeric =
        TextInputType.numberWithOptions(signed: true, decimal: true);
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.coordinatesTitle,
          style: const TextStyle(color: AppColors.onDark, fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _lat,
            keyboardType: numeric,
            style: const TextStyle(color: AppColors.onDark),
            decoration: InputDecoration(
                labelText: l10n.latitudeLabel, hintText: l10n.latitudeHint),
          ),
          TextField(
            controller: _lon,
            keyboardType: numeric,
            style: const TextStyle(color: AppColors.onDark),
            decoration: InputDecoration(
                labelText: l10n.longitudeLabel, hintText: l10n.longitudeHint),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.gold)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
