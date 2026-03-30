import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/app_entity.dart';
import '../../domain/entities/schedule_entity.dart';
import '../providers/apps_notifier.dart';

class NewScheduleScreen extends ConsumerStatefulWidget {
  final ScheduleEntity? existingSchedule;
  const NewScheduleScreen({super.key, this.existingSchedule});

  @override
  ConsumerState<NewScheduleScreen> createState() => _NewScheduleScreenState();
}

class _NewScheduleScreenState extends ConsumerState<NewScheduleScreen> {
  final _labelController = TextEditingController();
  AppEntity? _selectedApp;
  DateTime _selectedDate = DateTime.now().add(const Duration(minutes: 5));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 5)));
  String? _conflictMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedule != null) {
      _labelController.text = widget.existingSchedule!.label;
      _selectedApp = widget.existingSchedule!.app;
      _selectedDate = widget.existingSchedule!.scheduledTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.existingSchedule!.scheduledTime);
    }
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
      setState(() => _conflictMessage = "Time must be in the future");
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
      setState(() => _conflictMessage = "⚠️ Conflict Warning!\nAnother schedule exists at this time\n(${existing.app.name})");
    } else {
      setState(() => _conflictMessage = null);
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
        title: Text(widget.existingSchedule == null ? "New Schedule" : "Edit Schedule"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select App", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppEntity>(
              value: _selectedApp,
              items: state.installedApps.map((app) {
                return DropdownMenuItem(
                  value: app,
                  child: Row(
                    children: [
                      if (app.icon != null)
                        Image.memory(app.icon!, width: 24, height: 24)
                      else
                        const Icon(Icons.android, size: 24),
                      const SizedBox(width: 8),
                      Text(app.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedApp = value);
                _checkConflict();
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: const Text("Choose an app"),
            ),
            if (_selectedApp != null) ...[
              const SizedBox(height: 4),
              Text(_selectedApp!.packageName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 24),
            const Text("Label (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Daily Standup",
              ),
            ),
            const SizedBox(height: 24),
            const Text("Date & Time", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
            if (_conflictMessage != null) ...[
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _conflictMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: _selectedApp == null || _conflictMessage != null
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
                                SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: const Text("SAVE"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
