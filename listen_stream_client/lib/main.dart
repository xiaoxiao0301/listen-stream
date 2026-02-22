import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/local/isar_service.dart';
import 'data/local/user_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.init();
  await UserDataService.initTables();
  runApp(const ProviderScope(child: ListenStreamApp()));
}
