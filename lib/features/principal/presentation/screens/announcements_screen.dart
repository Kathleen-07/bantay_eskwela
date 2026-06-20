import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  // Edit mode tracking
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
        // Update existing
        await ref.read(principalRepositoryProvider).updateAnnouncement(
              announcementId: _editingId!,
              title: _titleController.text,
              content: _contentController.text,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new
        final user = ref.read(currentUserProvider).valueOrNull;
        await ref.read(principalRepositoryProvider).createAnnouncement(
              title: _titleController.text,
              content: _contentController.text,
              postedByName: user?.fullName ?? 'Principal',
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      _cancelEdit();
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
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text(
            'Are you sure you want to permanently delete this announcement? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(principalRepositoryProvider).deleteAnnouncement(id);
        // If we were editing the deleted one, reset the form
        if (_editingId == id) _cancelEdit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement deleted.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsStreamProvider);
    final isEditing = _editingId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post / Edit Form
          Card(
            color: isEditing ? Colors.orange.shade50 : null,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isEditing ? Icons.edit : Icons.campaign,
                          color: isEditing ? Colors.orange : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditing
                              ? 'Edit Announcement'
                              : 'Post New Announcement',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 200,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        prefixIcon: Icon(Icons.article_outlined),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      maxLength: 5000,
                    ),
                    const SizedBox(height: 16),
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
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Icon(isEditing ? Icons.save : Icons.send),
                            label: Text(
                              _isPosting
                                  ? 'Saving...'
                                  : (isEditing
                                      ? 'Save Changes'
                                      : 'Post Announcement'),
                            ),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor:
                                  isEditing ? Colors.orange : null,
                            ),
                          ),
                        ),
                        if (isEditing) ...[
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _isPosting ? null : _cancelEdit,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Announcements List
          Text(
            'Posted Announcements',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          announcementsAsync.when(
            data: (announcements) {
              if (announcements.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No announcements yet.')),
                  ),
                );
              }
              return Column(
                children: announcements.map((a) {
                  final isBeingEdited = _editingId == a.id;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: isBeingEdited
                        ? RoundedRectangleBorder(
                            side: const BorderSide(
                                color: Colors.orange, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.campaign),
                      ),
                      title: Text(
                        a.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Colors.orange),
                            tooltip: 'Edit',
                            onPressed: () => _startEdit(a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () => _handleDelete(a.id),
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
