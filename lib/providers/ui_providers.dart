import 'package:flutter_riverpod/flutter_riverpod.dart';

/// التبويب الظاهر في `MainShell` — التبويبات تبقى حيّة بعد زيارتها، فمن يستهلك
/// موارد (كحسّاسات القبلة) يراقب هذا ليتوقّف حين لا يكون ظاهراً.
final activeTabProvider = StateProvider<int>((ref) => 0);

/// ترتيب تبويب القبلة في `MainShell`.
const int kQiblaTabIndex = 2;
