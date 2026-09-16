import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/app_database.dart';
import 'data/repositories.dart';
import 'data/models.dart';

final databaseProvider =
    FutureProvider<AppDatabase>((ref) => AppDatabase.open());
final coffeesProvider = FutureProvider<List<CoffeeBean>>((ref) async =>
    CoffeeRepository(await ref.watch(databaseProvider.future)).all());
final grindersProvider = FutureProvider<List<Grinder>>((ref) async =>
    GrinderRepository(await ref.watch(databaseProvider.future)).all());
final methodsProvider = FutureProvider<List<BrewMethod>>((ref) async =>
    BrewMethodRepository(await ref.watch(databaseProvider.future)).all());
final basketsProvider = FutureProvider.family<List<Basket>, String>(
    (ref, machineId) async =>
        BasketRepository(await ref.watch(databaseProvider.future))
            .forMachine(machineId));
final recentLogsProvider = FutureProvider<List<Map<String, Object?>>>(
    (ref) async =>
        BrewLogRepository(await ref.watch(databaseProvider.future)).recent());
