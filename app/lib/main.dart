import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    _initLocalStorage(),
    MobileAds.instance.initialize(),
    Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    ),
  ]);

  runApp(
    const ProviderScope(
      child: PienoAmicoApp(),
    ),
  );
}

Future<void> _initLocalStorage() async {
  await Hive.initFlutter();
  final settings = await Hive.openBox('settings');

  final info = await PackageInfo.fromPlatform();
  final current = '${info.version}+${info.buildNumber}';
  final stored = settings.get('app_version') as String?;

  if (stored != current) {
    final fuel = await Hive.openBox('fuel_cache');
    await fuel.clear();
    await settings.put('app_version', current);
  }
}
