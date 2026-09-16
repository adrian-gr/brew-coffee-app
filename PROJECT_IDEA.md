Act as a Principal Software Engineer and Mobile Developer. You are task-driven to build an offline-first mobile application (targeting iOS and Android) for coffee brewing and espresso logging using Flutter and Dart.

### project Overview & Requirements
Build a structured coffee logging application using Flutter. The app allows home baristas to manage their coffee beans, equipment (grinders and brewing methods), and log precise extraction parameters for every brew.

### Tech Stack Specifications
- Framework: Flutter (Dart)
- State Management: Riverpod (or Provider)
- Local Database: Drift (or SQLite via sqflite) with fully relational schemas
- UI Framework: Material 3 / Custom Responsive Widgets

### Data Models & Relationships

1. Coffee Bean Entity
   - id: String (UUID)
   - roaster: String (e.g., "Dabov", "Monte Cristo")
   - name: String (e.g., "Signature Blend", "Ethiopia Bombe")
   - roastLevel: Enum (Light, Light-Medium, Medium, Dark)
   - roastDate: DateTime?
   - bagWeightGrams: double?
   - isArchived: bool (default: false)

2. Grinder Entity
   - id: String (UUID)
   - brand: String
   - model: String
   - burrType: String? (e.g., "64mm Flat", "Conical")
   - stepType: Enum (Stepped, Stepless)

3. Brew Method / Equipment Entity
   - id: String (UUID)
   - methodType: Enum (EspressoMachine, Aeropress, V60, KalitaWave, FrenchPress, Other)
   - name: String (e.g., "Lelit Bianca", "Aeropress Clear")
   - portafilterSizeMm: double? (e.g., 58.0, 54.0)

4. Brew Log Entity (Main Record)
   - id: String (UUID)
   - createdAt: DateTime
   - coffeeId: Foreign Key -> Coffee Bean
   - grinderId: Foreign Key -> Grinder
   - methodId: Foreign Key -> Brew Method
   - doseGrams: double (In weight, e.g., 18.0)
   - yieldGrams: double (Out weight, e.g., 36.0)
   - ratio: Derived/Calculated Property (yieldGrams / doseGrams, e.g., 1:2.0)
   - grindSetting: String (e.g., "14.5" or "2.5 steps")
   - waterTempCelsius: double?
   - preInfusionTimeSeconds: int?
   - totalExtractionTimeSeconds: int
   - rating: double (1.0 to 5.0)
   - flavorNotes: List<String> (e.g., ["Floral", "Citrus", "Chocolate"])
   - notes: String?

### Implementation Requirements
1. Database Layer: Set up the relational database tables with proper foreign keys and CRUD operations for Coffee, Grinder, Method, and BrewLog.
2. Auto-Calculations: Ensure the ratio ($1:X$) is automatically derived whenever dose or yield changes in the UI.
3. Form UI & Validation:
   - Provide clean dropdowns/pickers to select existing Coffee, Grinder, and Method when logging a brew.
   - Enforce non-negative numeric validation for weights and extraction times.
4. Clean Architecture: Separate code into Data Models, Repositories/Database Access, State Management, and UI Views.

Please output the foundational folder structure, data models, and the local database implementation code to begin this project.