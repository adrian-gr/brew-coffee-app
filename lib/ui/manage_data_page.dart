import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/enums.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../providers.dart';

class ManageDataPage extends ConsumerStatefulWidget {
  const ManageDataPage({super.key});

  @override
  ConsumerState<ManageDataPage> createState() => _ManageDataPageState();
}

class _ManageDataPageState extends ConsumerState<ManageDataPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (_tabIndex != _tabController.index) {
          setState(() => _tabIndex = _tabController.index);
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('Manage setup'),
          bottom: TabBar(controller: _tabController, tabs: const [
            Tab(icon: Icon(Icons.coffee_outlined), text: 'Coffees'),
            Tab(icon: Icon(Icons.settings_outlined), text: 'Grinders'),
            Tab(icon: Icon(Icons.local_cafe_outlined), text: 'Machines')
          ])),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _addCurrent,
          icon: const Icon(Icons.add),
          label: Text(switch (_tabIndex) {
            0 => 'Add coffee',
            1 => 'Add grinder',
            _ => 'Add machine'
          })),
      body: TabBarView(controller: _tabController, children: [
        _CoffeeList(onEdit: _editCoffee, onDelete: _deleteCoffee),
        _GrinderList(onEdit: _editGrinder, onDelete: _deleteGrinder),
        _MethodList(
            onEdit: _editMethod,
            onDelete: _deleteMethod,
            onManageBaskets: _manageBaskets)
      ]));

  Future<void> _addCurrent() async {
    switch (_tabIndex) {
      case 0:
        await _editCoffee();
        return;
      case 1:
        await _editGrinder();
        return;
      default:
        await _editMethod();
    }
  }

  Future<void> _editCoffee([CoffeeBean? item]) async {
    final result = await showDialog<CoffeeBean>(
        context: context, builder: (_) => CoffeeDialog(initial: item));
    if (result == null) return;
    final repo = CoffeeRepository(await ref.read(databaseProvider.future));
    item == null ? await repo.insert(result) : await repo.update(result);
    ref.invalidate(coffeesProvider);
  }

  Future<void> _editGrinder([Grinder? item]) async {
    final result = await showDialog<Grinder>(
        context: context, builder: (_) => GrinderDialog(initial: item));
    if (result == null) return;
    final repo = GrinderRepository(await ref.read(databaseProvider.future));
    item == null ? await repo.insert(result) : await repo.update(result);
    ref.invalidate(grindersProvider);
  }

  Future<void> _editMethod([BrewMethod? item]) async {
    final result = await showDialog<BrewMethod>(
        context: context, builder: (_) => BrewMethodDialog(initial: item));
    if (result == null) return;
    final repo = BrewMethodRepository(await ref.read(databaseProvider.future));
    item == null ? await repo.insert(result) : await repo.update(result);
    ref.invalidate(methodsProvider);
    ref.invalidate(recentLogsProvider);
  }

  Future<void> _manageBaskets(BrewMethod machine) => showDialog(
      context: context, builder: (_) => BasketDialog(machine: machine));

  Future<void> _deleteCoffee(CoffeeBean item) async {
    if (!await _confirmDelete(context)) return;
    try {
      await CoffeeRepository(await ref.read(databaseProvider.future))
          .delete(item.id);
      ref.invalidate(coffeesProvider);
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deleteGrinder(Grinder item) async {
    if (!await _confirmDelete(context)) return;
    try {
      await GrinderRepository(await ref.read(databaseProvider.future))
          .delete(item.id);
      ref.invalidate(grindersProvider);
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deleteMethod(BrewMethod item) async {
    if (!await _confirmDelete(context)) return;
    try {
      await BrewMethodRepository(await ref.read(databaseProvider.future))
          .delete(item.id);
      ref.invalidate(methodsProvider);
      ref.invalidate(recentLogsProvider);
    } on StateError catch (error) {
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class _CoffeeList extends ConsumerWidget {
  const _CoffeeList({required this.onEdit, required this.onDelete});
  final ValueChanged<CoffeeBean> onEdit;
  final ValueChanged<CoffeeBean> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(coffeesProvider).when(
          data: (items) => items.isEmpty
              ? const _EmptyList(message: 'No coffees yet.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Card(
                        child: ListTile(
                            title: Text('${item.roaster} · ${item.name}'),
                            subtitle: Text(
                                '${item.roastLevel.label}${item.bagWeightGrams == null ? '' : ' • ${item.bagWeightGrams!.toStringAsFixed(0)}g'}'),
                            trailing: _RecordMenu(
                                onEdit: () => onEdit(item),
                                onDelete: () => onDelete(item))));
                  }),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load coffees: $e')));
}

class _GrinderList extends ConsumerWidget {
  const _GrinderList({required this.onEdit, required this.onDelete});
  final ValueChanged<Grinder> onEdit;
  final ValueChanged<Grinder> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(grindersProvider).when(
          data: (items) => items.isEmpty
              ? const _EmptyList(message: 'No grinders yet.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Card(
                        child: ListTile(
                            title: Text('${item.brand} ${item.model}'),
                            subtitle: Text(
                                '${item.stepType.label}${item.burrType == null ? '' : ' • ${item.burrType}'}'),
                            trailing: _RecordMenu(
                                onEdit: () => onEdit(item),
                                onDelete: () => onDelete(item))));
                  }),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load grinders: $e')));
}

class _MethodList extends ConsumerWidget {
  const _MethodList(
      {required this.onEdit,
      required this.onDelete,
      required this.onManageBaskets});
  final ValueChanged<BrewMethod> onEdit;
  final ValueChanged<BrewMethod> onDelete;
  final ValueChanged<BrewMethod> onManageBaskets;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(methodsProvider).when(
          data: (items) => items.isEmpty
              ? const _EmptyList(message: 'No machines or methods yet.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Card(
                        child: ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                                '${item.methodType.label}${item.portafilterSizeMm == null ? '' : ' • ${item.portafilterSizeMm!.toStringAsFixed(0)}mm'}'),
                            trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'baskets') {
                                    onManageBaskets(item);
                                  } else if (value == 'edit') {
                                    onEdit(item);
                                  } else {
                                    onDelete(item);
                                  }
                                },
                                itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'baskets',
                                          child: ListTile(
                                              leading: Icon(Icons.filter_alt),
                                              title: Text('Manage baskets'))),
                                      PopupMenuItem(
                                          value: 'edit',
                                          child: ListTile(
                                              leading: Icon(Icons.edit),
                                              title: Text('Edit'))),
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                              leading:
                                                  Icon(Icons.delete_outline),
                                              title: Text('Delete')))
                                    ])));
                  }),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load methods: $e')));
}

class _RecordMenu extends StatelessWidget {
  const _RecordMenu({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
      onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => const [
            PopupMenuItem(
                value: 'edit',
                child:
                    ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
            PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete_outline), title: Text('Delete')))
          ]);
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
      child: Text(message, style: Theme.of(context).textTheme.titleMedium));
}

class CoffeeDialog extends StatefulWidget {
  const CoffeeDialog({super.key, this.initial});
  final CoffeeBean? initial;

  @override
  State<CoffeeDialog> createState() => _CoffeeDialogState();
}

class _CoffeeDialogState extends State<CoffeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roaster;
  late final TextEditingController _name;
  late final TextEditingController _bagWeight;
  late RoastLevel _roastLevel;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _roaster = TextEditingController(text: initial?.roaster);
    _name = TextEditingController(text: initial?.name);
    _bagWeight = TextEditingController(
        text: initial?.bagWeightGrams == null
            ? ''
            : initial!.bagWeightGrams!.toStringAsFixed(0));
    _roastLevel = initial?.roastLevel ?? RoastLevel.medium;
  }

  @override
  void dispose() {
    _roaster.dispose();
    _name.dispose();
    _bagWeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.initial == null ? 'Add coffee' : 'Edit coffee'),
          content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                _requiredText(_roaster, 'Roaster'),
                const SizedBox(height: 12),
                _requiredText(_name, 'Coffee name'),
                const SizedBox(height: 12),
                DropdownButtonFormField<RoastLevel>(
                    initialValue: _roastLevel,
                    decoration: const InputDecoration(labelText: 'Roast level'),
                    items: RoastLevel.values
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (value) => setState(() => _roastLevel = value!)),
                const SizedBox(height: 12),
                _number(_bagWeight, 'Bag weight (g)', required: false)
              ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(onPressed: _save, child: const Text('Save'))
          ]);

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
        context,
        CoffeeBean(
            id: widget.initial?.id ?? newId(),
            roaster: _roaster.text.trim(),
            name: _name.text.trim(),
            roastLevel: _roastLevel,
            bagWeightGrams: double.tryParse(_bagWeight.text),
            isArchived: widget.initial?.isArchived ?? false));
  }
}

class GrinderDialog extends StatefulWidget {
  const GrinderDialog({super.key, this.initial});
  final Grinder? initial;

  @override
  State<GrinderDialog> createState() => _GrinderDialogState();
}

class _GrinderDialogState extends State<GrinderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _burrType;
  late GrinderStepType _stepType;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _brand = TextEditingController(text: initial?.brand);
    _model = TextEditingController(text: initial?.model);
    _burrType = TextEditingController(text: initial?.burrType);
    _stepType = initial?.stepType ?? GrinderStepType.stepped;
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _burrType.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.initial == null ? 'Add grinder' : 'Edit grinder'),
          content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                _requiredText(_brand, 'Brand'),
                const SizedBox(height: 12),
                _requiredText(_model, 'Model'),
                const SizedBox(height: 12),
                _requiredText(_burrType, 'Burr type'),
                const SizedBox(height: 12),
                DropdownButtonFormField<GrinderStepType>(
                    initialValue: _stepType,
                    decoration:
                        const InputDecoration(labelText: 'Adjustment type'),
                    items: GrinderStepType.values
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (value) => setState(() => _stepType = value!))
              ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(onPressed: _save, child: const Text('Save'))
          ]);

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
        context,
        Grinder(
            id: widget.initial?.id ?? newId(),
            brand: _brand.text.trim(),
            model: _model.text.trim(),
            burrType: _burrType.text.trim(),
            stepType: _stepType));
  }
}

class BasketDialog extends ConsumerStatefulWidget {
  const BasketDialog({super.key, required this.machine});
  final BrewMethod machine;

  @override
  ConsumerState<BasketDialog> createState() => _BasketDialogState();
}

class _BasketDialogState extends ConsumerState<BasketDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baskets = ref.watch(basketsProvider(widget.machine.id));
    return AlertDialog(
        title: Text('Baskets · ${widget.machine.name}'),
        content: SizedBox(
            width: 360,
            child: baskets.when(
                data: (items) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (items.isEmpty)
                          const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('No baskets added yet.')),
                        ...items.map((basket) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(basket.name),
                            trailing: IconButton(
                                tooltip: 'Delete basket',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await BasketRepository(await ref
                                          .read(databaseProvider.future))
                                      .delete(basket.id);
                                  ref.invalidate(
                                      basketsProvider(widget.machine.id));
                                }))),
                        const SizedBox(height: 8),
                        TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                                labelText: 'New basket',
                                hintText: 'e.g. 18 g precision basket'),
                            onSubmitted: (_) => _add())
                      ],
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Could not load baskets: $error'))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done')),
          FilledButton(onPressed: _add, child: const Text('Add basket'))
        ]);
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await BasketRepository(await ref.read(databaseProvider.future))
        .insert(Basket(id: newId(), machineId: widget.machine.id, name: name));
    _name.clear();
    ref.invalidate(basketsProvider(widget.machine.id));
  }
}

class BrewMethodDialog extends StatefulWidget {
  const BrewMethodDialog({super.key, this.initial});
  final BrewMethod? initial;

  @override
  State<BrewMethodDialog> createState() => _BrewMethodDialogState();
}

class _BrewMethodDialogState extends State<BrewMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _portafilter;
  late BrewMethodType _methodType;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name);
    _portafilter = TextEditingController(
        text: initial?.portafilterSizeMm == null
            ? ''
            : initial!.portafilterSizeMm!.toStringAsFixed(0));
    _methodType = initial?.methodType ?? BrewMethodType.espressoMachine;
  }

  @override
  void dispose() {
    _name.dispose();
    _portafilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.initial == null
              ? 'Add machine or method'
              : 'Edit machine or method'),
          content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                _requiredText(_name, 'Name'),
                const SizedBox(height: 12),
                DropdownButtonFormField<BrewMethodType>(
                    initialValue: _methodType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: BrewMethodType.values
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (value) => setState(() => _methodType = value!)),
                const SizedBox(height: 12),
                _number(_portafilter, 'Portafilter size (mm)', required: false)
              ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(onPressed: _save, child: const Text('Save'))
          ]);

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
        context,
        BrewMethod(
            id: widget.initial?.id ?? newId(),
            methodType: _methodType,
            name: _name.text.trim(),
            portafilterSizeMm: double.tryParse(_portafilter.text)));
  }
}

Widget _requiredText(TextEditingController controller, String label) =>
    TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Required' : null);

Widget _number(TextEditingController controller, String label,
        {bool required = true}) =>
    TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return required ? 'Required' : null;
          }
          final number = double.tryParse(value);
          return number == null || number < 0
              ? 'Enter a non-negative number'
              : null;
        });

Future<bool> _confirmDelete(BuildContext context) async =>
    await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Delete record?'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'))
                ])) ??
    false;
