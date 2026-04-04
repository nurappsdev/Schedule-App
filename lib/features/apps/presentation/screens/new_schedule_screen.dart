import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../domain/entities/app_entity.dart';
import '../../domain/entities/schedule_entity.dart';
import '../providers/apps_notifier.dart';
import '../widgets/custom_text.dart';

class NewScheduleScreen extends ConsumerStatefulWidget {
  final ScheduleEntity? existingSchedule;
  final AppEntity? initialApp;
  const NewScheduleScreen({super.key, this.existingSchedule, this.initialApp});

  @override
  ConsumerState<NewScheduleScreen> createState() => _NewScheduleScreenState();
}

class _NewScheduleScreenState extends ConsumerState<NewScheduleScreen> {
  final _labelController = TextEditingController();
  AppEntity? _selectedApp;
  DateTime _selectedDate = DateTime.now().add(const Duration(minutes: 5));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 5)));
  String? _conflictMessage;
  bool _hasConflict = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedule != null) {
      _labelController.text = widget.existingSchedule!.label;
      _selectedApp = widget.existingSchedule!.app;
      _selectedDate = widget.existingSchedule!.scheduledTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.existingSchedule!.scheduledTime);
    } else if (widget.initialApp != null) {
      _selectedApp = widget.initialApp;
    }
    _checkConflict();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _checkConflict() {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      setState(() {
        _conflictMessage = "Time must be in the future";
        _hasConflict = false;
      });
      return;
    }

    final state = ref.read(appsNotifierProvider);
    final conflict = state.schedules.any((s) =>
        s.id != (widget.existingSchedule?.id ?? "") &&
        s.scheduledTime.year == scheduledDateTime.year &&
        s.scheduledTime.month == scheduledDateTime.month &&
        s.scheduledTime.day == scheduledDateTime.day &&
        s.scheduledTime.hour == scheduledDateTime.hour &&
        s.scheduledTime.minute == scheduledDateTime.minute);

    if (conflict) {
      final existing = state.schedules.firstWhere((s) =>
          s.scheduledTime.year == scheduledDateTime.year &&
          s.scheduledTime.month == scheduledDateTime.month &&
          s.scheduledTime.day == scheduledDateTime.day &&
          s.scheduledTime.hour == scheduledDateTime.hour &&
          s.scheduledTime.minute == scheduledDateTime.minute);
      setState(() {
        _conflictMessage = "⚠️ Conflict Warning!\nAnother schedule exists at this time\n(${existing.app.name})";
        _hasConflict = true;
      });
    } else {
      setState(() {
        _conflictMessage = null;
        _hasConflict = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _checkConflict();
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      _checkConflict();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: CustomText(text: widget.existingSchedule == null ? "New Schedule" : "Edit Schedule", fontsize: 18, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(text: "Select App", fontsize: 16, fontWeight: FontWeight.bold),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final AppEntity? selected = await showSearch<AppEntity?>(
                  context: context,
                  delegate: AppSearchDelegate(state.installedApps),
                );
                if (selected != null) {
                  setState(() => _selectedApp = selected);
                  _checkConflict();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    if (_selectedApp != null) ...[
                      if (_selectedApp!.icon != null)
                        Image.memory(_selectedApp!.icon!, width: 24, height: 24)
                      else
                        const Icon(Icons.android, size: 24),
                      const SizedBox(width: 8),
                      CustomText(text: _selectedApp!.name, fontsize: 14, textAlign: TextAlign.start),
                    ] else
                      const CustomText(text: "Choose an app", fontsize: 14, color: Colors.grey, textAlign: TextAlign.start),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            if (_selectedApp != null) ...[
              const SizedBox(height: 4),
              CustomText(text: _selectedApp!.packageName, fontsize: 12, color: Colors.grey, textAlign: TextAlign.start),
            ],
            const SizedBox(height: 24),
            const CustomText(text: "Label (Optional)", fontsize: 16, fontWeight: FontWeight.bold),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Daily Standup",
              ),
            ),
            const SizedBox(height: 24),
            const CustomText(text: "Date & Time", fontsize: 16, fontWeight: FontWeight.bold),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: CustomText(text: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", fontsize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: CustomText(text: _selectedTime.format(context), fontsize: 14),
                  ),
                ),
              ],
            ),
            if (_conflictMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _hasConflict ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _hasConflict ? Colors.orange : Colors.red),
                ),
                child: CustomText(
                  text: _conflictMessage!,
                  fontsize: 14,
                  color: _hasConflict ? Colors.orange.shade900 : Colors.red.shade900,
                  textAlign: TextAlign.start,
                ),
              ),
            ],
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const CustomText(text: "CANCEL", fontsize: 14),
                ),
                ElevatedButton(
                  onPressed: _selectedApp == null || (_conflictMessage != null && !_hasConflict)
                      ? null
                      : () async {
                          final scheduledDateTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            _selectedTime.hour,
                            _selectedTime.minute,
                          );

                          final schedule = ScheduleEntity(
                            id: widget.existingSchedule?.id ?? const Uuid().v4(),
                            alarmId: widget.existingSchedule?.alarmId ??
                                (DateTime.now().microsecondsSinceEpoch % 2147483647),
                            app: _selectedApp!,
                            label: _labelController.text,
                            scheduledTime: scheduledDateTime,
                          );

                          try {
                            await ref.read(appsNotifierProvider.notifier).saveSchedule(schedule);
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: CustomText(text: e.toString(), color: Colors.white), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: const CustomText(text: "SAVE", fontsize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AppSearchDelegate extends SearchDelegate<AppEntity?> {
  final List<AppEntity> apps;

  AppSearchDelegate(this.apps);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = "",
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final filtered = apps
        .where((app) =>
            app.name.toLowerCase().contains(query.toLowerCase()) ||
            app.packageName.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final app = filtered[index];
        return ListTile(
          leading: app.icon != null
              ? Image.memory(app.icon!, width: 32, height: 32)
              : const Icon(Icons.android),
          title: CustomText(text: app.name, fontsize: 16, textAlign: TextAlign.start),
          subtitle: CustomText(text: app.packageName, fontsize: 12, textAlign: TextAlign.start, color: Colors.grey),
          onTap: () => close(context, app),
        );
      },
    );
  }
}
