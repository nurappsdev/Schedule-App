import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/apps_notifier.dart';
import '../widgets/custom_text.dart';
import 'new_schedule_screen.dart';

class ScheduleManagementScreen extends ConsumerWidget {
  const ScheduleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appsNotifierProvider);
    final notifier = ref.read(appsNotifierProvider.notifier);

    final now = DateTime.now();
    final activeSchedules = state.schedules.where((s) => s.scheduledTime.isAfter(now)).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    if (activeSchedules.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            CustomText(
              text: "No active schedules.",
              fontsize: 18,
              color: Colors.grey,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: activeSchedules.length,
      itemBuilder: (context, index) {
        final schedule = activeSchedules[index];
        Widget iconWidget = const Icon(Icons.android);

        if (schedule.app.icon != null) {
          iconWidget = Image.memory(schedule.app.icon!, width: 40, height: 40);
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: iconWidget,
            title: CustomText(
              text: schedule.app.name,
              fontsize: 16,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.start,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (schedule.label.isNotEmpty)
                  CustomText(
                    text: "Label: ${schedule.label}",
                    fontsize: 14,
                    fontStyle: FontStyle.italic,
                    textAlign: TextAlign.start,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: CustomText(
                        text: "${schedule.scheduledTime.day}/${schedule.scheduledTime.month}/${schedule.scheduledTime.year} at ${TimeOfDay.fromDateTime(schedule.scheduledTime).format(context)}",
                        fontsize: 14,
                        fontWeight: FontWeight.w500,
                        maxline: 1,
                        color: Colors.green,
                        textAlign: TextAlign.start,
                      ),
                    ),
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
        title: const CustomText(text: "Delete Schedule", fontsize: 18, fontWeight: FontWeight.bold),
        content: const CustomText(text: "Are you sure you want to delete this schedule?", fontsize: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const CustomText(text: "CANCEL", fontsize: 14),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const CustomText(text: "DELETE", fontsize: 14),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      notifier.deleteSchedule(id);
    }
  }
}
