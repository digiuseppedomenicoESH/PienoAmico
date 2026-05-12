import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ViewMode { list, map }
enum AppTab { vicino, viaggio }

final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.list);
final showFavoritesProvider = StateProvider<bool>((ref) => false);
final activeTabProvider = StateProvider<AppTab>((ref) => AppTab.vicino);
