import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ViewMode { list, map }

final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.list);
final showFavoritesProvider = StateProvider<bool>((ref) => false);
