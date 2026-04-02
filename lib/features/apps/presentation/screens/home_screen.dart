import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/apps_notifier.dart';
import '../widgets/custom_text.dart';
import 'new_schedule_screen.dart';
import 'schedule_management_screen.dart';

import 'history_screen.dart';

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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const CustomText(text: "App Scheduler", fontsize: 18, fontWeight: FontWeight.bold),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.apps), text: "Apps"),
              Tab(icon: Icon(Icons.list_alt), text: "Schedules"),
              Tab(icon: Icon(Icons.history), text: "History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAllAppsTab(context, ref, state, notifier),
            const ScheduleManagementScreen(),
            const HistoryScreen(),
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
                title: CustomText(text: app.name, fontsize: 16, fontWeight: FontWeight.w500, textAlign: TextAlign.start),
                subtitle: CustomText(text: app.packageName, fontsize: 12, textAlign: TextAlign.start, color: Colors.grey),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.blue),
                  onPressed: () => notifier.openApp(app.packageName),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewScheduleScreen(initialApp: app),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
