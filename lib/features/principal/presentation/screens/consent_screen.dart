import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/core/widgets/section_scaffold.dart';
import 'package:bantay_eskwela/core/services/photo_picker.dart' as web_picker;
import 'package:bantay_eskwela/core/widgets/signature_records_view.dart';
import 'package:bantay_eskwela/features/principal/presentation/providers/principal_providers.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});
  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  String? _selectedEventId;
  String? _selectedEventTitle;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  DateTime? _deadline;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      Uint8List? bytes;
      String? name;
      if (kIsWeb) {
        final result = await web_picker.pickPhotoFromGallery(
            accept: '.pdf,image/png,image/jpeg');
        if (result != null) {
          bytes = result.bytes;
          name = result.name;
        }
      }
      if (bytes == null || name == null) return;

      final ext = name.split('.').last.toLowerCase();
      if (!['pdf', 'png', 'jpg', 'jpeg'].contains(ext)) {
        _toast('Please select a PDF, PNG, or JPG file', error: true);
        return;
      }
      if (bytes.length > 10 * 1024 * 1024) {
        _toast('File too large. Maximum 10MB.', error: true);
        return;
      }
      setState(() {
        _selectedFileBytes = bytes;
        _selectedFileName = name;
      });
    } catch (e) {
      _toast('Error selecting file: $e', error: true);
    }
  }

  Future<void> _pickDeadline() async {
    // Start the picker on today, and block all past dates.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _deadline = date);
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedEventId == null) {
      _toast('Please select an event');
      return;
    }
    if (_selectedFileBytes == null || _selectedFileName == null) {
      _toast('Please select a file');
      return;
    }
    if (_deadline == null) {
      _toast('Please select a signing deadline');
      return;
    }
    setState(() => _isUploading = true);
    try {
      await ref.read(principalRepositoryProvider).uploadConsent(
            eventId: _selectedEventId!,
            eventTitle: _selectedEventTitle ?? '',
            fileBytes: _selectedFileBytes!,
            fileName: _selectedFileName!,
            deadline: _deadline!,
          );
      setState(() {
        _selectedEventId = null;
        _selectedEventTitle = null;
        _selectedFileBytes = null;
        _selectedFileName = null;
        _deadline = null;
      });
      _toast('Consent form uploaded!');
    } catch (e) {
      _toast(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Consent Form'),
        content: const Text(
            'Are you sure you want to permanently delete this consent form? This cannot be undone.'),
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
      await ref.read(principalRepositoryProvider).deleteConsent(id);
      _toast('Consent form deleted.');
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
    final consentsAsync = ref.watch(consentsStreamProvider);

    return CenteredColumn(
      children: [
        FormCard(
          icon: Icons.upload_file,
          title: 'Upload Consent Form',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              eventsAsync.when(
                data: (events) {
                  final consentEvents =
                      events.where((e) => e.requiresConsent).toList();
                  if (consentEvents.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.parchment,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        'No events requiring consent. Create an event first with "Requires Parent Consent" checked.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedEventId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Select Event',
                        prefixIcon: Icon(Icons.event),
                        border: OutlineInputBorder()),
                    items: consentEvents
                        .map((e) => DropdownMenuItem(
                            value: e.id, child: Text(e.title)))
                        .toList(),
                    onChanged: (v) {
                      final ev = consentEvents.firstWhere((e) => e.id == v);
                      setState(() {
                        _selectedEventId = v;
                        _selectedEventTitle = ev.title;
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading events: $e'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_selectedFileName ??
                    'Select File (PDF, PNG, JPG — max 10MB)'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDeadline,
                icon: const Icon(Icons.calendar_today),
                label: Text(_deadline == null
                    ? 'Select Signing Deadline'
                    : 'Deadline: ${DateFormat.yMMMd().format(_deadline!)}'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isUploading ? null : _handleUpload,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Consent Form'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionTitle('Uploaded Consent Forms'),
        consentsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const Card(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child:
                          Center(child: Text('No consent forms uploaded yet.'))));
            }
            return Column(
              children: list.map((c) {
                final sigsAsync = ref.watch(consentSignaturesProvider(c.id));
                final sigs = sigsAsync.valueOrNull ?? [];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: AppTheme.forest.withOpacity(0.12),
                        child:
                            const Icon(Icons.description, color: AppTheme.forest)),
                    title: Text(c.eventTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${c.fileName}\nDeadline: ${DateFormat.yMMMd().format(c.deadline)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Signed-count badge — tap to view signatures
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => showSignatureRecords(
                            context,
                            title: '${c.eventTitle} — Signatures',
                            signatures: sigs,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.forest.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified,
                                    size: 15, color: AppTheme.forest),
                                const SizedBox(width: 4),
                                Text('${sigs.length} signed',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.forest)),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () => _handleDelete(c.id)),
                      ],
                    ),
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
