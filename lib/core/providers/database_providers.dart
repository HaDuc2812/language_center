import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database_helper.dart';

part 'database_providers.g.dart';

@Riverpod(keepAlive: true)
DatabaseHelper databaseHelper(Ref ref) {
  final helper = DatabaseHelper();
  ref.onDispose(helper.close);
  return helper;
}
