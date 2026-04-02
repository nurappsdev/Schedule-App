import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/apps_notifier.dart';
import '../widgets/custom_text.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appsNotifierProvider);
    final notifier = ref.read(appsNotifierProvider.notifier);

    if (state.history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            CustomText(
              text: "No execution history yet.",
              fontsize: 18,
              color: Colors.grey,
            ),
          ],
        ),
      );
    }

    // Sort history by execution time (most recent first)
    final sortedHistory = [...state.history]
      ..sort((a, b) => b.executionTime.compareTo(a.executionTime));

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(text: "Execution History", fontsize: 18, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Clear History"),
                  content: const Text("Are you sure you want to clear all execution history?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        notifier.clearHistory();
                        Navigator.pop(context);
                      },
                      child: const Text("Clear", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: sortedHistory.length,
        itemBuilder: (context, index) {
          final history = sortedHistory[index];
          
          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: CustomText(
                text: history.app.name,
                fontsize: 16,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.start,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (history.label.isNotEmpty)
                    CustomText(
                      text: "Label: ${history.label}",
                      fontsize: 14,
                      fontStyle: FontStyle.italic,
                      textAlign: TextAlign.start,
                    ),
                  const SizedBox(height: 4),
                  CustomText(
                    text: "Executed at: ${history.executionTime.day}/${history.executionTime.month}/${history.executionTime.year} ${TimeOfDay.fromDateTime(history.executionTime).format(context)}",
                    fontsize: 13,
                    color: Colors.grey[700],
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
              trailing: const Icon(Icons.launch, size: 16, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
