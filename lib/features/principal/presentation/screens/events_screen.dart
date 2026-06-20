import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/core/widgets/section_scaffold.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/principal/presentation/providers/principal_providers.dart';
import 'package:bantay_eskwela/features/principal/domain/event_model.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});
  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _requiresConsent = false;
  bool _isPosting = false;
  String? _editingId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _startEdit(EventModel e) {
    setState(() {
      _editingId = e.id;
      _titleController.text = e.title;
      _descriptionController.text = e.description;
      _locationController.text = e.location;
      _selectedDate = e.eventDate;
      _selectedTime = TimeOfDay.fromDateTime(e.eventDate);
      _requiresConsent = e.requiresConsent;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _selectedDate = null;
      _selectedTime = null;
      _requiresConsent = false;
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: _selectedTime ?? TimeOfDay.now());
    if (t != null) setState(() => _selectedTime = t);
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty) {
      _toast('All fields are required');
      return;
    }
    if (_selectedDate == null) {
      _toast('Please select an event date');
      return;
    }
    setState(() => _isPosting = true);
    try {
      var dt = _selectedDate!;
      if (_selectedTime != null) {
        dt = DateTime(dt.year, dt.month, dt.day, _selectedTime!.hour,
            _selectedTime!.minute);
      }
      if (_editingId != null) {
        await ref.read(principalRepositoryProvider).updateEvent(
            eventId: _editingId!,
            title: _titleController.text,
            description: _descriptionController.text,
            location: _locationController.text,
            eventDate: dt,
            requiresConsent: _requiresConsent);
        _toast('Event updated successfully!');
      } else {
        final user = ref.read(currentUserProvider).valueOrNull;
        await ref.read(principalRepositoryProvider).createEvent(
            title: _titleController.text,
            description: _descriptionController.text,
            location: _locationController.text,
            eventDate: dt,
            postedByName: user?.fullName ?? 'Principal',
            requiresConsent: _requiresConsent);
        _toast('Event posted successfully!');
      }
      _cancelEdit();
    } catch (e) {
      _toast(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
            'Are you sure you want to permanently delete this event? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(principalRepositoryProvider).deleteEvent(id);
      if (_editingId == id) _cancelEdit();
      _toast('Event deleted.');
    } catch (e) {
      _toast('Delete failed: $e', error: true);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppTheme.forest));
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final isEditing = _editingId != null;

    return CenteredColumn(
      children: [
        FormCard(
          icon: isEditing ? Icons.edit : Icons.event,
          title: isEditing ? 'Edit Event' : 'Create New Event',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                  controller: _titleController,
                  maxLength: 200,
                  decoration: const InputDecoration(
                      labelText: 'Event Title',
                      prefixIcon: Icon(Icons.event_outlined),
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 5000,
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder())),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_selectedDate == null
                            ? 'Select Date'
                            : DateFormat.yMMMd().format(_selectedDate!)),
                        style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16)))),
                const SizedBox(width: 12),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(_selectedTime == null
                            ? 'Select Time'
                            : _selectedTime!.format(context)),
                        style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16)))),
              ]),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _requiresConsent,
                onChanged: (v) => setState(() => _requiresConsent = v ?? false),
                title: const Text('Requires Parent Consent'),
                subtitle:
                    const Text('Check if this event needs a signed consent form'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.forest,
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isPosting ? null : _handleSubmit,
                    icon: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(isEditing ? Icons.save : Icons.add),
                    label: Text(_isPosting
                        ? 'Saving...'
                        : (isEditing ? 'Save Changes' : 'Create Event')),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isEditing ? AppTheme.gold : null),
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                      onPressed: _isPosting ? null : _cancelEdit,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20)),
                      child: const Text('Cancel')),
                ],
              ]),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionTitle('Upcoming Events'),
        eventsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const Card(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No events yet.'))));
            }
            return Column(
              children: list.map((e) {
                final beingEdited = _editingId == e.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: beingEdited
                      ? RoundedRectangleBorder(
                          side: const BorderSide(color: AppTheme.gold, width: 2),
                          borderRadius: BorderRadius.circular(14))
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: e.requiresConsent
                            ? AppTheme.gold.withOpacity(0.18)
                            : AppTheme.forest.withOpacity(0.12),
                        child: Icon(e.requiresConsent ? Icons.warning : Icons.event,
                            color: e.requiresConsent
                                ? AppTheme.gold
                                : AppTheme.forest)),
                    title: Text(e.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(e.description,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                            '${e.location} • ${DateFormat.yMMMd().add_jm().format(e.eventDate)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.forest)),
                        if (e.requiresConsent)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Requires parent consent',
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.gold)),
                          ),
                      ],
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppTheme.gold),
                          tooltip: 'Edit',
                          onPressed: () => _startEdit(e)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _handleDelete(e.id)),
                    ]),
                    isThreeLine: true,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}
