import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../providers.dart';

class LogBrewPage extends ConsumerStatefulWidget {
  const LogBrewPage({super.key, this.initialLog});

  final Map<String, Object?>? initialLog;

  @override
  ConsumerState<LogBrewPage> createState() => _LogBrewPageState();
}

class _LogBrewPageState extends ConsumerState<LogBrewPage> {
  final _formKey = GlobalKey<FormState>();
  final _dose = TextEditingController(text: '18');
  final _yield = TextEditingController(text: '36');
  final _temp = TextEditingController();
  final _pre = TextEditingController();
  final _time = TextEditingController(text: '30');
  final _notes = TextEditingController();
  String? coffeeId;
  String? grinderId;
  String? methodId;
  String? basketId;
  double rating = 4;
  double grindSetting = 100;
  final Set<String> selectedFlavors = <String>{};
  double get ratio {
    final d = double.tryParse(_dose.text) ?? 0;
    final y = double.tryParse(_yield.text) ?? 0;
    return d == 0 ? 0 : y / d;
  }

  bool get _isEditing => widget.initialLog != null;

  @override
  void initState() {
    super.initState();
    final log = widget.initialLog;
    if (log == null) return;
    _dose.text = (log['dose_grams'] as num).toString();
    _yield.text = (log['yield_grams'] as num).toString();
    grindSetting =
        double.tryParse(log['grind_setting'] as String? ?? '') ?? 100;
    _temp.text = log['water_temp_celsius']?.toString() ?? '';
    _pre.text = log['pre_infusion_seconds']?.toString() ?? '';
    _time.text = (log['total_extraction_seconds'] as num).toString();
    _notes.text = log['notes'] as String? ?? '';
    coffeeId = log['coffee_id'] as String?;
    grinderId = log['grinder_id'] as String?;
    methodId = log['method_id'] as String?;
    basketId = log['basket_id'] as String?;
    rating = (log['rating'] as num).toDouble();
    final storedFlavors = log['flavor_notes'];
    if (storedFlavors is String) {
      try {
        selectedFlavors
            .addAll((jsonDecode(storedFlavors) as List).whereType<String>());
      } catch (_) {
        // Ignore legacy or malformed flavor data.
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_dose, _yield, _temp, _pre, _time, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? positive(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Required' : null;
    }
    final number = double.tryParse(value);
    return number == null || number < 0 ? 'Enter a non-negative number' : null;
  }

  @override
  Widget build(BuildContext context) {
    final coffees = ref.watch(coffeesProvider);
    final grinders = ref.watch(grindersProvider);
    final methods = ref.watch(methodsProvider);
    final baskets = methodId == null
        ? const AsyncValue<List<Basket>>.data([])
        : ref.watch(basketsProvider(methodId!));
    return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit brew' : 'Log a brew')),
        body: Form(
            key: _formKey,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Recipe',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _select<CoffeeBean>(
                  context: context,
                  label: 'Coffee bean',
                  value: coffeeId,
                  items: coffees.valueOrNull
                          ?.map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text('${e.roaster} · ${e.name}')))
                          .toList() ??
                      [],
                  onChanged: (v) => setState(() => coffeeId = v)),
              const SizedBox(height: 12),
              _select<Grinder>(
                  context: context,
                  label: 'Grinder',
                  value: grinderId,
                  items: grinders.valueOrNull
                          ?.map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text('${e.brand} ${e.model}')))
                          .toList() ??
                      [],
                  onChanged: (v) => setState(() => grinderId = v)),
              const SizedBox(height: 12),
              _select<BrewMethod>(
                  context: context,
                  label: 'Brew method',
                  value: methodId,
                  items: methods.valueOrNull
                          ?.map((e) => DropdownMenuItem(
                              value: e.id, child: Text(e.name)))
                          .toList() ??
                      [],
                  onChanged: (v) => setState(() {
                        methodId = v;
                        basketId = null;
                      })),
              if (methodId != null) ...[
                const SizedBox(height: 12),
                baskets.when(
                    data: (items) => items.isEmpty
                        ? const Text('No baskets configured for this machine.')
                        : _select<Basket>(
                            context: context,
                            label: 'Basket',
                            value: basketId,
                            items: items
                                .map((e) => DropdownMenuItem(
                                    value: e.id, child: Text(e.name)))
                                .toList(),
                            onChanged: (v) => setState(() => basketId = v)),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Could not load baskets: $e'))
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: _number(_dose, 'Dose (g)',
                        onChanged: (_) => setState(() {}))),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('→')),
                Expanded(
                    child: _number(_yield, 'Yield (g)',
                        onChanged: (_) => setState(() {})))
              ]),
              const SizedBox(height: 8),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Ratio  1:${ratio.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(height: 12),
              _grindSlider(context),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _number(_temp, 'Water temp (°C)', required: false)),
                const SizedBox(width: 12),
                Expanded(child: _number(_time, 'Total time (s)'))
              ]),
              const SizedBox(height: 12),
              _number(_pre, 'Pre-infusion (s)', required: false),
              const SizedBox(height: 20),
              Text('Rating  ${rating.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleMedium),
              Slider(
                  value: rating,
                  min: 1,
                  max: 5,
                  divisions: 8,
                  label: rating.toStringAsFixed(1),
                  onChanged: (v) => setState(() => rating = v)),
              _coffeeCompass(context),
              const SizedBox(height: 16),
              _text(_notes, 'Notes', required: false, maxLines: 3),
              const SizedBox(height: 24),
              FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_isEditing ? 'Update brew' : 'Save brew'))
            ])));
  }

  Widget _text(TextEditingController c, String label,
          {bool required = true, int maxLines = 1}) =>
      TextFormField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
              : null);

  Widget _grindSlider(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Grind setting',
                style: Theme.of(context).textTheme.labelLarge),
            Text(grindSetting.toStringAsFixed(0),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600))
          ]),
          Slider(
              value: grindSetting,
              min: 0,
              max: 500,
              divisions: 500,
              label: grindSetting.toStringAsFixed(0),
              onChanged: (value) => setState(() => grindSetting = value))
        ]));
  }

  Widget _coffeeCompass(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Taste profile', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text('Tap the notes you taste in the cup.',
          style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 10),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
              child: SizedBox(
                  width: 330,
                  height: 330,
                  child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(
                        size: const Size.square(330),
                        painter: _CompassPainter(
                            selected: selectedFlavors,
                            accent: colors.primary,
                            muted: colors.outlineVariant)),
                    const _CompassCenter(),
                    ..._tasteOptions.map((taste) {
                      final angle = taste.$2;
                      final x = math.cos(angle) * 123;
                      final y = math.sin(angle) * 123;
                      final selected = selectedFlavors.contains(taste.$1);
                      return Transform.translate(
                          offset: Offset(x, y),
                          child: GestureDetector(
                              onTap: () => setState(() => selected
                                  ? selectedFlavors.remove(taste.$1)
                                  : selectedFlavors.add(taste.$1)),
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                      color: selected
                                          ? colors.primary
                                          : colors.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Color(0x14000000),
                                            blurRadius: 8,
                                            offset: Offset(0, 3))
                                      ]),
                                  child: Text(taste.$1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                              color: selected
                                                  ? colors.onPrimary
                                                  : colors.onSurface,
                                              fontWeight: FontWeight.w600)))));
                    })
                  ])))),
      if (selectedFlavors.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedFlavors
                .map((flavor) => Chip(
                    label: Text(flavor),
                    onDeleted: () =>
                        setState(() => selectedFlavors.remove(flavor))))
                .toList())
      ]
    ]);
  }

  Widget _number(TextEditingController c, String label,
          {bool required = true, void Function(String)? onChanged}) =>
      TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
          onChanged: onChanged,
          validator: (v) => positive(v, required: required));
  Widget _select<T>(
          {required BuildContext context,
          required String label,
          required String? value,
          required List<DropdownMenuItem<String>> items,
          required ValueChanged<String?> onChanged}) =>
      SizedBox(
          width: math.min(360.0, MediaQuery.sizeOf(context).width - 32),
          child: DropdownButtonFormField<String>(
              isExpanded: false,
              initialValue:
                  items.any((item) => item.value == value) ? value : null,
              decoration: InputDecoration(labelText: label),
              items: items,
              onChanged: onChanged,
              validator: (selected) => selected == null ? 'Required' : null));
  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        coffeeId == null ||
        grinderId == null ||
        methodId == null) {
      return;
    }
    final existing = widget.initialLog;
    final log = BrewLog(
        id: existing?['id'] as String? ?? newId(),
        createdAt: existing == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(
                existing['created_at'] as int),
        coffeeId: coffeeId!,
        grinderId: grinderId!,
        methodId: methodId!,
        basketId: basketId,
        doseGrams: double.parse(_dose.text),
        yieldGrams: double.parse(_yield.text),
        grindSetting: grindSetting.toStringAsFixed(0),
        waterTempCelsius: double.tryParse(_temp.text),
        preInfusionTimeSeconds: int.tryParse(_pre.text),
        totalExtractionTimeSeconds: int.parse(_time.text),
        rating: rating,
        flavorNotes: selectedFlavors.toList(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim());
    final repo = BrewLogRepository(await ref.read(databaseProvider.future));
    _isEditing ? await repo.update(log) : await repo.insert(log);
    ref.invalidate(recentLogsProvider);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

const _tasteOptions = <(String, double)>[
  ('Fruity', -math.pi / 2),
  ('Floral', -math.pi / 3),
  ('Sweet', -math.pi / 6),
  ('Citrus', 0),
  ('Nutty', math.pi / 6),
  ('Chocolate', math.pi / 3),
  ('Spicy', math.pi / 2),
  ('Woody', 2 * math.pi / 3),
  ('Earthy', 5 * math.pi / 6),
  ('Herbal', math.pi),
  ('Tart', 7 * math.pi / 6),
  ('Caramel', 4 * math.pi / 3),
];

class _CompassCenter extends StatelessWidget {
  const _CompassCenter();

  @override
  Widget build(BuildContext context) => Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text('Taste\ncompass',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w700)));
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter(
      {required this.selected, required this.accent, required this.muted});

  final Set<String> selected;
  final Color accent;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rings = [
      (145.0, 1.0),
      (108.0, 1.0),
      (66.0, 1.0),
    ];
    for (final ring in rings) {
      canvas.drawCircle(
          center,
          ring.$1,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ring.$2
            ..color = muted.withValues(alpha: .65));
    }
    final slicePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < _tasteOptions.length; i++) {
      final angle = _tasteOptions[i].$2;
      slicePaint.color = selected.contains(_tasteOptions[i].$1)
          ? accent.withValues(alpha: .18)
          : muted.withValues(alpha: .08);
      canvas.drawArc(Rect.fromCircle(center: center, radius: 138), angle - .08,
          .16, true, slicePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.accent != accent ||
      oldDelegate.muted != muted;
}
