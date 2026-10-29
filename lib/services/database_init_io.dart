import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<void> initDatabasePlatform() async {
  // Mobile / Desktop native default sqflite factory is already set.
}

Future<String> resolveDatabasePath(String dbName) async {
  final String databasesPath = await getDatabasesPath();
  return p.join(databasesPath, dbName);
}

