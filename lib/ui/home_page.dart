import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories.dart';
import '../providers.dart';
import 'log_brew_page.dart';
import 'manage_data_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(recentLogsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Brew Coffee'), actions: [
        IconButton(
            tooltip: 'Manage coffees, grinders and machines',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageDataPage())),
            icon: const Icon(Icons.inventory_2_outlined))
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const LogBrewPage())),
          icon: const Icon(Icons.add),
          label: const Text('Log brew')),
      body: logs.when(
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final log = items[i];
                  final dose = (log['dose_grams'] as num).toDouble();
                  final yield = (log['yield_grams'] as num).toDouble();
                  final rating = (log['rating'] as num).toDouble();
                  return Card(
                      child: ListTile(
                          leading:
                              const CircleAvatar(child: Icon(Icons.coffee)),
                          title:
                              Text('${log['roaster']} · ${log['coffee_name']}'),
                          subtitle: Text(
                              '${log['method_name']}  •  ${log['grinder_brand']} ${log['grinder_model']}  •  ${dose.toStringAsFixed(1)}g -> ${yield.toStringAsFixed(1)}g  •  1:${(yield / dose).toStringAsFixed(1)}'),
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('★ ${rating.toStringAsFixed(1)}'),
                            PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                LogBrewPage(initialLog: log)));
                                    return;
                                  }
                                  if (await _confirmDelete(context)) {
                                    await BrewLogRepository(await ref
                                            .read(databaseProvider.future))
                                        .delete(log['id'] as String);
                                    ref.invalidate(recentLogsProvider);
                                  }
                                },
                                itemBuilder: (_) => const [
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
                                    ])
                          ])));
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load brews: $e')),
      ),
    );
  }
}

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

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.local_cafe_outlined,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Your brew journal is empty',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
                'Log your first brew to start tracking recipes and dialing in your coffee.',
                textAlign: TextAlign.center)
          ])));
}
