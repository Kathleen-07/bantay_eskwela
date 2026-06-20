import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bantay_eskwela/core/services/photo_picker.dart' as web_picker;
import 'package:bantay_eskwela/features/principal/presentation/providers/principal_providers.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  String? _selectedEventId;
  String? _selectedEventTitle;
  DateTime? _deadline;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      Uint8List? bytes;
      String? name;

      if (kIsWeb) {
        final result = await web_picker.pickPhotoFromGallery(
          accept: '.pdf,image/png,image/jpeg',
        );
        if (result != null) {
          bytes = result.bytes;
          name = result.name;
        }
      }

      if (bytes != null && name != null) {
        final ext = name.split('.').last.toLowerCase();
        if (!['pdf', 'png', 'jpg', 'jpeg'].contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a PDF, PNG, or JPG file'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        if (bytes.length > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File too large. Maximum 10MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        setState(() {
          _selectedFileBytes = bytes;
          _selectedFileName = name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _deadline = date);
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event')),
      );
      return;
    }
    if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deadline')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await ref.read(principalRepositoryProvider).uploadConsent(
        eventId: _selectedEventId!,
        eventTitle: _selectedEventTitle ?? '',
        fileBytes: _selectedFileBytes!,
        fileName: _selectedFileName ?? 'consent_form',
        deadline: _deadline!,
      );

      setState(() {
        _selectedEventId = null;
        _selectedEventTitle = null;
        _selectedFileBytes = null;
        _selectedFileName = null;
        _deadline = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consent form uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final consentsAsync = ref.watch(consentsStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consent Forms',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Upload Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Upload Consent Form',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Event Dropdown
                    eventsAsync.when(
                      data: (events) {
                        final consentEvents =
                        events.where((e) => e.requiresConsent).toList();
                        if (consentEvents.isEmpty) {
                          return const Text(
                            'No events requiring consent. Create an event first with "Requires Parent Consent" checked.',
                            style: TextStyle(color: Colors.grey),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedEventId,
                          decoration: const InputDecoration(
                            labelText: 'Select Event',
                            prefixIcon: Icon(Icons.event),
                            border: OutlineInputBorder(),
                          ),
                          items: consentEvents.map((e) {
                            return DropdownMenuItem(
                              value: e.id,
                              child: Text(e.title),
                            );
                          }).toList(),
                          onChanged: (value) {
                            final event = consentEvents
                                .firstWhere((e) => e.id == value);
                            setState(() {
                              _selectedEventId = value;
                              _selectedEventTitle = event.title;
                            });
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 16),

                    // File Picker
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _selectedFileBytes == null
                            ? 'Select File (PDF, PNG, JPG — max 10MB)'
                            : '📄 $_selectedFileName',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deadline Picker
                    OutlinedButton.icon(
                      onPressed: _pickDeadline,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _deadline == null
                            ? 'Select Signing Deadline'
                            : 'Deadline: ${DateFormat.yMMMd().format(_deadline!)}',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Upload Button
                    FilledButton.icon(
                      onPressed: _isUploading ? null : _handleUpload,
                      icon: _isUploading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.cloud_upload),
                      label: Text(
                          _isUploading ? 'Uploading...' : 'Upload Consent Form'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Consents List
          Text(
            'Uploaded Consent Forms',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          consentsAsync.when(
            data: (consents) {
              if (consents.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child:
                    Center(child: Text('No consent forms uploaded yet.')),
                  ),
                );
              }
              return Column(
                children: consents.map((c) {
                  final isExpired = c.deadline.isBefore(DateTime.now());
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isExpired
                            ? Colors.red.shade100
                            : Colors.blue.shade100,
                        child: Icon(
                          Icons.description,
                          color: isExpired ? Colors.red : Colors.blue,
                        ),
                      ),
                      title: Text(
                        c.eventTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📄 ${c.fileName}'),
                          Text(
                            'Deadline: ${DateFormat.yMMMd().format(c.deadline)}${isExpired ? ' (EXPIRED)' : ''}',
                            style: TextStyle(
                              color: isExpired ? Colors.red : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }
}