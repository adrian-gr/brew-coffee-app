import '../core/enums.dart';

class CoffeeBean {
  const CoffeeBean(
      {required this.id,
      required this.roaster,
      required this.name,
      required this.roastLevel,
      this.roastDate,
      this.bagWeightGrams,
      this.isArchived = false});
  final String id;
  final String roaster;
  final String name;
  final RoastLevel roastLevel;
  final DateTime? roastDate;
  final double? bagWeightGrams;
  final bool isArchived;
}

class Grinder {
  const Grinder(
      {required this.id,
      required this.brand,
      required this.model,
      this.burrType,
      required this.stepType});
  final String id;
  final String brand;
  final String model;
  final String? burrType;
  final GrinderStepType stepType;
}

class BrewMethod {
  const BrewMethod(
      {required this.id,
      required this.methodType,
      required this.name,
      this.portafilterSizeMm});
  final String id;
  final BrewMethodType methodType;
  final String name;
  final double? portafilterSizeMm;
}

class Basket {
  const Basket({required this.id, required this.machineId, required this.name});
  final String id;
  final String machineId;
  final String name;
}

class BrewLog {
  const BrewLog(
      {required this.id,
      required this.createdAt,
      required this.coffeeId,
      required this.grinderId,
      required this.methodId,
      this.basketId,
      required this.doseGrams,
      required this.yieldGrams,
      required this.grindSetting,
      this.waterTempCelsius,
      this.preInfusionTimeSeconds,
      required this.totalExtractionTimeSeconds,
      required this.rating,
      this.flavorNotes = const [],
      this.notes});
  final String id;
  final DateTime createdAt;
  final String coffeeId;
  final String grinderId;
  final String methodId;
  final String? basketId;
  final double doseGrams;
  final double yieldGrams;
  final String grindSetting;
  final double? waterTempCelsius;
  final int? preInfusionTimeSeconds;
  final int totalExtractionTimeSeconds;
  final double rating;
  final List<String> flavorNotes;
  final String? notes;

  double get ratio => doseGrams == 0 ? 0 : yieldGrams / doseGrams;
}
