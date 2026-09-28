#!/usr/bin/env bash
# يشغّل اختبارات الأيام التقويمية تحت مناطق زمنية ذات توقيت صيفي.
#
# Dart يقرأ المنطقة الزمنية من متغيّر البيئة TZ عند بدء العملية ولا يمكن تغييرها
# داخل الاختبار، فنشغّل الملف مرة لكل منطقة. الدار البيضاء تؤخّر ساعتها حول رمضان،
# والقاهرة وبيروت تنتقلان عند منتصف الليل، ولندن مرجع أوروبي.
#
# الاستخدام: tool/test_dst.sh [ملفات اختبار إضافية...]
set -euo pipefail
cd "$(dirname "$0")/.."

files=("test/core/dst_test.dart" "$@")
zones=(Africa/Casablanca Africa/Cairo Asia/Beirut Europe/London)

for zone in "${zones[@]}"; do
  echo "== TZ=$zone"
  TZ="$zone" flutter test "${files[@]}" 2>&1 | tail -n 1
done
