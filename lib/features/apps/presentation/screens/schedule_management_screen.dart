import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/apps_notifier.dart';
import 'new_schedule_screen.dart';

class ScheduleManagementScreen extends ConsumerWidget {
  const ScheduleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appsNotifierProvider);
    final notifier = ref.read(appsNotifierProvider.notifier);

    if (state.schedules.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No schedules created yet.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.schedules.length,
      itemBuilder: (context, index) {
        final schedule = state.schedules[index];
        Widget iconWidget = const Icon(Icons.android);

        if (schedule.app.icon != null) {
          iconWidget = Image.memory(schedule.app.icon!, width: 40, height: 40);
        }

        final now = DateTime.now();
        final isPast = schedule.scheduledTime.isBefore(now);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: iconWidget,
            title: Text(
              schedule.app.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (schedule.label.isNotEmpty)
                  Text(
                    "Label: ${schedule.label}",
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isPast ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${schedule.scheduledTime.day}/${schedule.scheduledTime.month}/${schedule.scheduledTime.year} at ${TimeOfDay.fromDateTime(schedule.scheduledTime).format(context)}",
                      style: TextStyle(
                        color: isPast ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isPast) ...[
                      const SizedBox(width: 8),
                      const Text(
                        "(Expired)",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewScheduleScreen(existingSchedule: schedule),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, notifier, schedule.id),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewScheduleScreen(existingSchedule: schedule),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppsNotifier notifier, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Schedule"),
        content: const Text("Are you sure you want to delete this schedule?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      notifier.deleteSchedule(id);
    }
  }
}
