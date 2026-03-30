import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/apps_notifier.dart';
import 'new_schedule_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appsNotifierProvider);
    final notifier = ref.read(appsNotifierProvider.notifier);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("App Cloner & Scheduler"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.apps), text: "All Apps"),
              Tab(icon: Icon(Icons.calendar_month), text: "Schedule Creation"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAllAppsTab(context, ref, state, notifier),
            _buildScheduleTab(context, state, notifier),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return ListenableBuilder(
              listenable: tabController,
              builder: (context, child) {
                if (tabController.index == 1) {
                  return FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NewScheduleScreen()),
                      );
                    },
                    child: const Icon(Icons.add_alarm),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAllAppsTab(
    BuildContext context,
    WidgetRef ref,
    AppsState state,
    AppsNotifier notifier,
  ) {
    if (state.isLoading && state.installedApps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredApps = state.filteredApps;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            onChanged: notifier.setSearchQuery,
            decoration: InputDecoration(
              hintText: "Search apps...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        notifier.setSearchQuery("");
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredApps.length,
            itemBuilder: (context, index) {
              final app = filteredApps[index];
              Widget icon = const Icon(Icons.android);
              if (app.icon != null) {
                icon = Image.memory(app.icon!, width: 40, height: 40);
              }

              return ListTile(
                leading: icon,
                title: Text(app.name),
                subtitle: Text(app.packageName, style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.blue),
                  onPressed: () => notifier.openApp(app.packageName),
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Clone ${app.name}?"),
                      content: const Text("Do you want to clone this app?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("No"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      await notifier.cloneApp(app);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${app.name} cloned successfully!"),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error cloning ${app.name}: $e"),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTab(
    BuildContext context,
    AppsState state,
    AppsNotifier notifier,
  ) {
    if (state.schedules.isEmpty) {
      return const Center(child: Text("No schedules created yet."));
    }

    return ListView.builder(
      itemCount: state.schedules.length,
      itemBuilder: (context, index) {
        final schedule = state.schedules[index];
        Widget iconWidget = const Icon(Icons.android);

        if (schedule.app.icon != null) {
          iconWidget = Image.memory(schedule.app.icon!, width: 40, height: 40);
        }

        final isPast = schedule.scheduledTime.isBefore(DateTime.now());

        return ListTile(
          leading: iconWidget,
          title: Text(schedule.app.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (schedule.label.isNotEmpty)
                Text("Label: ${schedule.label}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                "📅 ${schedule.scheduledTime.day}/${schedule.scheduledTime.month}/${schedule.scheduledTime.year} 🕐 ${TimeOfDay.fromDateTime(schedule.scheduledTime).format(context)}",
                style: TextStyle(color: isPast ? Colors.red : Colors.green),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => notifier.deleteSchedule(schedule.id),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewScheduleScreen(existingSchedule: schedule),
              ),
            );
          },
        );
      },
    );
  }
}
