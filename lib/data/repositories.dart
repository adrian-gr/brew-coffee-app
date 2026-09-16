import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/enums.dart';
import 'app_database.dart';
import 'models.dart';

class CoffeeRepository {
  CoffeeRepository(this.database);
  final AppDatabase database;
  Future<List<CoffeeBean>> all() async => (await database.db
          .query('coffees', where: 'is_archived = 0', orderBy: 'roaster, name'))
      .map((r) => CoffeeBean(
          id: r['id'] as String,
          roaster: r['roaster'] as String,
          name: r['name'] as String,
          roastLevel: RoastLevel.values.byName(r['roast_level'] as String),
          roastDate: r['roast_date'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(r['roast_date'] as int),
          bagWeightGrams: r['bag_weight_grams'] as double?))
      .toList();
  Future<void> insert(CoffeeBean item) => database.db.insert('coffees', {
        'id': item.id,
        'roaster': item.roaster,
        'name': item.name,
        'roast_level': item.roastLevel.name,
        'roast_date': item.roastDate?.millisecondsSinceEpoch,
        'bag_weight_grams': item.bagWeightGrams
      });
  Future<void> update(CoffeeBean item) => database.db.update(
      'coffees',
      {
        'roaster': item.roaster,
        'name': item.name,
        'roast_level': item.roastLevel.name,
        'roast_date': item.roastDate?.millisecondsSinceEpoch,
        'bag_weight_grams': item.bagWeightGrams,
        'is_archived': item.isArchived ? 1 : 0
      },
      where: 'id = ?',
      whereArgs: [item.id]);
  Future<void> delete(String id) async {
    if (await _isUsed('coffee_id', id)) {
      throw StateError('Delete or edit brews using this coffee first.');
    }
    await database.db.delete('coffees', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> _isUsed(String column, String id) async =>
      (Sqflite.firstIntValue(await database.db.rawQuery(
              'SELECT COUNT(*) FROM brew_logs WHERE $column = ?', [id])) ??
          0) >
      0;
}

class GrinderRepository {
  GrinderRepository(this.database);
  final AppDatabase database;
  Future<List<Grinder>> all() async => (await database.db
          .query('grinders', orderBy: 'brand, model'))
      .map((r) => Grinder(
          id: r['id'] as String,
          brand: r['brand'] as String,
          model: r['model'] as String,
          burrType: r['burr_type'] as String?,
          stepType: GrinderStepType.values.byName(r['step_type'] as String)))
      .toList();
  Future<void> insert(Grinder item) => database.db.insert('grinders', {
        'id': item.id,
        'brand': item.brand,
        'model': item.model,
        'burr_type': item.burrType,
        'step_type': item.stepType.name
      });
  Future<void> update(Grinder item) => database.db.update(
      'grinders',
      {
        'brand': item.brand,
        'model': item.model,
        'burr_type': item.burrType,
        'step_type': item.stepType.name
      },
      where: 'id = ?',
      whereArgs: [item.id]);
  Future<void> delete(String id) async {
    if (await _isUsed(id)) {
      throw StateError('Delete or edit brews using this grinder first.');
    }
    await database.db.delete('grinders', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> _isUsed(String id) async =>
      (Sqflite.firstIntValue(await database.db.rawQuery(
              'SELECT COUNT(*) FROM brew_logs WHERE grinder_id = ?', [id])) ??
          0) >
      0;
}

class BrewMethodRepository {
  BrewMethodRepository(this.database);
  final AppDatabase database;
  Future<List<BrewMethod>> all() async => (await database.db
          .query('brew_methods', orderBy: 'name'))
      .map((r) => BrewMethod(
          id: r['id'] as String,
          methodType: BrewMethodType.values.byName(r['method_type'] as String),
          name: r['name'] as String,
          portafilterSizeMm: r['portafilter_size_mm'] as double?))
      .toList();
  Future<void> insert(BrewMethod item) => database.db.insert('brew_methods', {
        'id': item.id,
        'method_type': item.methodType.name,
        'name': item.name,
        'portafilter_size_mm': item.portafilterSizeMm
      });
  Future<void> update(BrewMethod item) => database.db.update(
      'brew_methods',
      {
        'method_type': item.methodType.name,
        'name': item.name,
        'portafilter_size_mm': item.portafilterSizeMm
      },
      where: 'id = ?',
      whereArgs: [item.id]);
  Future<void> delete(String id) async {
    if (await _isUsed(id)) {
      throw StateError('Delete or edit brews using this method first.');
    }
    await database.db.delete('brew_methods', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> _isUsed(String id) async =>
      (Sqflite.firstIntValue(await database.db.rawQuery(
              'SELECT COUNT(*) FROM brew_logs WHERE method_id = ?', [id])) ??
          0) >
      0;
}

class BasketRepository {
  BasketRepository(this.database);
  final AppDatabase database;

  Future<List<Basket>> forMachine(String machineId) async =>
      (await database.db.query('baskets',
              where: 'machine_id = ?', whereArgs: [machineId], orderBy: 'name'))
          .map((r) => Basket(
              id: r['id'] as String,
              machineId: r['machine_id'] as String,
              name: r['name'] as String))
          .toList();

  Future<void> insert(Basket item) => database.db.insert('baskets',
      {'id': item.id, 'machine_id': item.machineId, 'name': item.name});

  Future<void> delete(String id) =>
      database.db.delete('baskets', where: 'id = ?', whereArgs: [id]);
}

class BrewLogRepository {
  BrewLogRepository(this.database);
  final AppDatabase database;
  Future<List<Map<String, Object?>>> recent() => database.db.rawQuery(
      'SELECT brew_logs.*, coffees.roaster, coffees.name AS coffee_name, grinders.brand AS grinder_brand, grinders.model AS grinder_model, brew_methods.name AS method_name, baskets.name AS basket_name FROM brew_logs JOIN coffees ON coffees.id = brew_logs.coffee_id JOIN grinders ON grinders.id = brew_logs.grinder_id JOIN brew_methods ON brew_methods.id = brew_logs.method_id LEFT JOIN baskets ON baskets.id = brew_logs.basket_id ORDER BY created_at DESC');
  Future<void> insert(BrewLog item) => database.db.insert('brew_logs', {
        'id': item.id,
        'created_at': item.createdAt.millisecondsSinceEpoch,
        'coffee_id': item.coffeeId,
        'grinder_id': item.grinderId,
        'method_id': item.methodId,
        'basket_id': item.basketId,
        'dose_grams': item.doseGrams,
        'yield_grams': item.yieldGrams,
        'grind_setting': item.grindSetting,
        'water_temp_celsius': item.waterTempCelsius,
        'pre_infusion_seconds': item.preInfusionTimeSeconds,
        'total_extraction_seconds': item.totalExtractionTimeSeconds,
        'rating': item.rating,
        'flavor_notes': jsonEncode(item.flavorNotes),
        'notes': item.notes
      });
  Future<void> update(BrewLog item) => database.db.update(
      'brew_logs',
      {
        'created_at': item.createdAt.millisecondsSinceEpoch,
        'coffee_id': item.coffeeId,
        'grinder_id': item.grinderId,
        'method_id': item.methodId,
        'basket_id': item.basketId,
        'dose_grams': item.doseGrams,
        'yield_grams': item.yieldGrams,
        'grind_setting': item.grindSetting,
        'water_temp_celsius': item.waterTempCelsius,
        'pre_infusion_seconds': item.preInfusionTimeSeconds,
        'total_extraction_seconds': item.totalExtractionTimeSeconds,
        'rating': item.rating,
        'flavor_notes': jsonEncode(item.flavorNotes),
        'notes': item.notes
      },
      where: 'id = ?',
      whereArgs: [item.id]);
  Future<void> delete(String id) =>
      database.db.delete('brew_logs', where: 'id = ?', whereArgs: [id]);
}

String newId() => const Uuid().v4();
