import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/core/widgets/section_scaffold.dart';
import 'package:bantay_eskwela/features/auth/presentation/providers/auth_provider.dart';
import 'package:bantay_eskwela/features/principal/presentation/providers/principal_providers.dart';
import 'package:bantay_eskwela/features/principal/domain/announcement_model.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});
  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPosting = false;
  String? _editingId;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _startEdit(AnnouncementModel a) {
    setState(() {
      _editingId = a.id;
      _titleController.text = a.title;
      _contentController.text = a.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _titleController.clear();
      _contentController.clear();
    });
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required')),
      );
      return;
    }
    setState(() => _isPosting = true);
    try {
      if (_editingId != null) {
        await ref.read(principalRepositoryProvider).updateAnnouncement(
            announcementId: _editingId!,
            title: _titleController.text,
            content: _contentController.text);
        _toast('Announcement updated successfully!');
      } else {
        final user = ref.read(currentUserProvider).valueOrNull;
        await ref.read(principalRepositoryProvider).createAnnouncement(
            title: _titleController.text,
            content: _contentController.text,
            postedByName: user?.fullName ?? 'Principal');
        _toast('Announcement posted successfully!');
      }
      _cancelEdit();
    } catch (e) {
      _toast(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await _confirmDelete('announcement');
    if (confirm != true) return;
    try {
      await ref.read(principalRepositoryProvider).deleteAnnouncement(id);
      if (_editingId == id) _cancelEdit();
      _toast('Announcement deleted.');
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

  Future<bool?> _confirmDelete(String what) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Delete ${what[0].toUpperCase()}${what.substring(1)}'),
          content: Text(
              'Are you sure you want to permanently delete this $what? This cannot be undone.'),
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

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsStreamProvider);
    final isEditing = _editingId != null;

    return CenteredColumn(
      children: [
        FormCard(
          icon: isEditing ? Icons.edit : Icons.campaign,
          title: isEditing ? 'Edit Announcement' : 'Post New Announcement',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: 200,
                decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                maxLength: 5000,
                decoration: const InputDecoration(
                    labelText: 'Content',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.article_outlined),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isPosting ? null : _handleSubmit,
                      icon: _isPosting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(isEditing ? Icons.save : Icons.send),
                      label: Text(_isPosting
                          ? 'Saving...'
                          : (isEditing
                              ? 'Save Changes'
                              : 'Post Announcement')),
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
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionTitle('Posted Announcements'),
        announcementsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return const Card(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No announcements yet.'))));
            }
            return Column(
              children: list.map((a) {
                final beingEdited = _editingId == a.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: beingEdited
                      ? RoundedRectangleBorder(
                          side: const BorderSide(color: AppTheme.gold, width: 2),
                          borderRadius: BorderRadius.circular(14))
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: AppTheme.forest.withOpacity(0.12),
                        child: const Icon(Icons.campaign,
                            color: AppTheme.forest)),
                    title: Text(a.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(a.content,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                            'Posted by ${a.postedByName} • ${DateFormat.yMMMd().format(a.createdAt)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppTheme.gold),
                          tooltip: 'Edit',
                          onPressed: () => _startEdit(a)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _handleDelete(a.id)),
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
