enum RoastLevel { light, lightMedium, medium, dark }

enum GrinderStepType { stepped, stepless }

enum BrewMethodType {
  espressoMachine,
  aeropress,
  v60,
  kalitaWave,
  frenchPress,
  other
}

extension RoastLevelLabel on RoastLevel {
  String get label => switch (this) {
        RoastLevel.light => 'Light',
        RoastLevel.lightMedium => 'Light-Medium',
        RoastLevel.medium => 'Medium',
        RoastLevel.dark => 'Dark',
      };
}

extension GrinderStepTypeLabel on GrinderStepType {
  String get label => this == GrinderStepType.stepped ? 'Stepped' : 'Stepless';
}

extension BrewMethodTypeLabel on BrewMethodType {
  String get label => switch (this) {
        BrewMethodType.espressoMachine => 'Espresso Machine',
        BrewMethodType.aeropress => 'AeroPress',
        BrewMethodType.v60 => 'V60',
        BrewMethodType.kalitaWave => 'Kalita Wave',
        BrewMethodType.frenchPress => 'French Press',
        BrewMethodType.other => 'Other',
      };
}
