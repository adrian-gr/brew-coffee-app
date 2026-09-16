import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this.db);
  final Database db;

  static Future<AppDatabase> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final database = await openDatabase(join(directory.path, 'brew_coffee.db'),
        version: 2,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
                'CREATE TABLE baskets (id TEXT PRIMARY KEY, machine_id TEXT NOT NULL REFERENCES brew_methods(id) ON DELETE CASCADE, name TEXT NOT NULL)');
            await db.execute(
                'ALTER TABLE brew_logs ADD COLUMN basket_id TEXT REFERENCES baskets(id) ON DELETE SET NULL');
          }
        },
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
              'CREATE TABLE coffees (id TEXT PRIMARY KEY, roaster TEXT NOT NULL, name TEXT NOT NULL, roast_level TEXT NOT NULL, roast_date INTEGER, bag_weight_grams REAL, is_archived INTEGER NOT NULL DEFAULT 0)');
          await db.execute(
              'CREATE TABLE grinders (id TEXT PRIMARY KEY, brand TEXT NOT NULL, model TEXT NOT NULL, burr_type TEXT, step_type TEXT NOT NULL)');
          await db.execute(
              'CREATE TABLE brew_methods (id TEXT PRIMARY KEY, method_type TEXT NOT NULL, name TEXT NOT NULL, portafilter_size_mm REAL)');
          await db.execute(
              'CREATE TABLE baskets (id TEXT PRIMARY KEY, machine_id TEXT NOT NULL REFERENCES brew_methods(id) ON DELETE CASCADE, name TEXT NOT NULL)');
          await db.execute(
              'CREATE TABLE brew_logs (id TEXT PRIMARY KEY, created_at INTEGER NOT NULL, coffee_id TEXT NOT NULL REFERENCES coffees(id) ON DELETE RESTRICT, grinder_id TEXT NOT NULL REFERENCES grinders(id) ON DELETE RESTRICT, method_id TEXT NOT NULL REFERENCES brew_methods(id) ON DELETE RESTRICT, basket_id TEXT REFERENCES baskets(id) ON DELETE SET NULL, dose_grams REAL NOT NULL CHECK(dose_grams >= 0), yield_grams REAL NOT NULL CHECK(yield_grams >= 0), grind_setting TEXT NOT NULL, water_temp_celsius REAL CHECK(water_temp_celsius IS NULL OR water_temp_celsius >= 0), pre_infusion_seconds INTEGER CHECK(pre_infusion_seconds IS NULL OR pre_infusion_seconds >= 0), total_extraction_seconds INTEGER NOT NULL CHECK(total_extraction_seconds >= 0), rating REAL NOT NULL CHECK(rating >= 1 AND rating <= 5), flavor_notes TEXT NOT NULL DEFAULT "[]", notes TEXT)');
          await db.execute(
              'CREATE INDEX idx_brew_logs_created_at ON brew_logs(created_at DESC)');
          await db.insert('coffees', {
            'id': 'seed-coffee',
            'roaster': 'Dabov',
            'name': 'Ethiopia Bombe',
            'roast_level': 'light',
            'bag_weight_grams': 250.0
          });
          await db.insert('grinders', {
            'id': 'seed-grinder',
            'brand': 'Comandante',
            'model': 'C40',
            'burr_type': 'Conical',
            'step_type': 'stepped'
          });
          await db.insert('brew_methods', {
            'id': 'seed-method',
            'method_type': 'v60',
            'name': 'V60 02',
            'portafilter_size_mm': null
          });
        });
    return AppDatabase._(database);
  }
}
