import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> initDatabasePlatform() async {
  databaseFactory = databaseFactoryFfiWeb;
}

Future<String> resolveDatabasePath(String dbName) async {
  // sqflite_common_ffi_web stores databases inside IndexedDB using the relative database name.
  return dbName;
}

