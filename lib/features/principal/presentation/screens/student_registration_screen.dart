import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:bantay_eskwela/core/services/photo_picker.dart' as web_picker;
import 'package:bantay_eskwela/core/services/download_helper.dart' as download_helper;
import 'package:bantay_eskwela/core/services/print_helper.dart' as print_helper;
import 'package:bantay_eskwela/core/validators/input_validators.dart';
import 'package:bantay_eskwela/core/services/cloudinary_service.dart';
import 'package:bantay_eskwela/features/principal/presentation/providers/principal_providers.dart';
import 'package:bantay_eskwela/features/principal/presentation/widgets/student_id_card.dart';
import 'package:bantay_eskwela/features/principal/presentation/widgets/printable_id_card.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';

class StudentRegistrationScreen extends ConsumerStatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  ConsumerState<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends ConsumerState<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _gradeLevelController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedParentId;
  bool _isLoading = false;

  // Photo state
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  bool _isUploadingPhoto = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _fullNameController.dispose();
    _sectionController.dispose();
    _gradeLevelController.dispose();
    _parentPhoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      Uint8List? bytes;
      String? name;

      if (kIsWeb) {
        final result = await web_picker.pickPhotoFromGallery();
        if (result != null) {
          bytes = result.bytes;
          name = result.name;
        }
      } else {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        if (image != null) {
          bytes = await image.readAsBytes();
          name = image.name;
        }
      }

      if (bytes != null && name != null) {
        final ext = name.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select an image (JPG, PNG, WEBP)'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        if (bytes.length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo too large. Maximum 5MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        setState(() {
          _selectedPhotoBytes = bytes;
          _selectedPhotoName = name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a parent')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String photoUrl = '';
      if (_selectedPhotoBytes != null && _selectedPhotoName != null) {
        setState(() => _isUploadingPhoto = true);
        photoUrl = await CloudinaryService.uploadImage(
          imageBytes: _selectedPhotoBytes!,
          fileName: _selectedPhotoName!,
        );
        setState(() => _isUploadingPhoto = false);
      }

      final student =
          await ref.read(principalRepositoryProvider).registerStudent(
                studentId: _studentIdController.text,
                fullName: _fullNameController.text,
                section: _sectionController.text,
                gradeLevel: _gradeLevelController.text,
                parentId: _selectedParentId!,
                parentPhone: _parentPhoneController.text,
                photoUrl: photoUrl,
              );

      if (mounted) {
        _showIdCardDialog(student);
        _clearForm();
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingPhoto = false;
        });
      }
    }
  }

  void _clearForm() {
    _studentIdController.clear();
    _fullNameController.clear();
    _sectionController.clear();
    _gradeLevelController.clear();
    _parentPhoneController.clear();
    setState(() {
      _selectedParentId = null;
      _selectedPhotoBytes = null;
      _selectedPhotoName = null;
    });
  }

  Future<Uint8List?> _captureCard(StudentModel student) async {
    final controller = ScreenshotController();
    return await controller.captureFromWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PrintableIdCard(student: student),
        ),
      ),
      pixelRatio: 3.0,
      delay: const Duration(milliseconds: 300),
    );
  }

  void _showIdCardDialog(StudentModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudentIdCard(student: student),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        try {
                          final image = await _captureCard(student);
                          if (image != null) {
                            final safeName = student.studentId
                                .replaceAll(RegExp(r'[^\w]'), '_');
                            await download_helper.downloadFileWeb(
                              bytes: image,
                              fileName: 'ID_${safeName}_frontback.png',
                            );
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'ID Card (front & back) downloaded!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Download failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () async {
                        try {
                          final image = await _captureCard(student);
                          if (image != null && kIsWeb) {
                            print_helper.printImageWeb(
                              image,
                              'Student ID - ${student.fullName}',
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Print failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentDetails(StudentModel student) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with school green
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E33), Color(0xFF0F3D20)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 116,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFC8A23A), width: 3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: student.photoUrl.isNotEmpty
                            ? Image.network(
                                student.photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.person,
                                      size: 48, color: Colors.grey),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.person,
                                    size: 48, color: Colors.grey),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      student.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8A23A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ID: ${student.studentId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _detailRow(Icons.school_outlined, 'Grade Level',
                        student.gradeLevel),
                    _detailRow(Icons.groups_outlined, 'Section',
                        student.section),
                    _detailRow(Icons.phone_outlined, 'Parent Phone',
                        student.parentPhone),
                    _detailRow(Icons.qr_code_2, 'QR Code', student.qrData),
                    _detailRow(
                      Icons.check_circle_outline,
                      'Status',
                      student.isActive ? 'Active' : 'Inactive',
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showIdCardDialog(student);
                        },
                        icon: const Icon(Icons.badge),
                        label: const Text('View ID Card'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1B5E33)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(parentsListProvider);
    final studentsAsync = ref.watch(studentsStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Register New Student',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 20),

                      // Photo Upload
                      Center(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: InkWell(
                            onTap: _pickPhoto,
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _selectedPhotoBytes != null
                                        ? Image.memory(
                                            _selectedPhotoBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_a_photo,
                                                  size: 32,
                                                  color:
                                                      Colors.blue.shade300),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Add Photo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue.shade300,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedPhotoName ??
                                      'Click to select student photo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Student ID
                      TextFormField(
                        controller: _studentIdController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(20),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Student ID / LRN',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Student ID is required';
                          }
                          if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                            return 'Student ID must contain numbers only';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r"[a-zA-Z .,'-]")),
                          LengthLimitingTextInputFormatter(100),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: InputValidators.validateName,
                      ),
                      const SizedBox(height: 16),

                      // Grade Level & Section Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gradeLevelController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Grade Level',
                                prefixIcon: Icon(Icons.school_outlined),
                                border: OutlineInputBorder(),
                                hintText: 'e.g., 7',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _sectionController,
                              decoration: const InputDecoration(
                                labelText: 'Section',
                                prefixIcon: Icon(Icons.groups_outlined),
                                border: OutlineInputBorder(),
                                hintText: 'e.g., St. Luke',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Parent Searchable Selector
                      parentsAsync.when(
                        data: (parents) =>
                            Autocomplete<Map<String, String>>(
                          displayStringForOption: (p) =>
                              '${p['name']} (${p['email']})',
                          optionsBuilder: (textValue) {
                            final query =
                                textValue.text.toLowerCase().trim();
                            if (query.isEmpty) {
                              return parents;
                            }
                            return parents.where((p) {
                              final name =
                                  (p['name'] ?? '').toLowerCase();
                              final email =
                                  (p['email'] ?? '').toLowerCase();
                              return name.contains(query) ||
                                  email.contains(query);
                            });
                          },
                          onSelected: (p) {
                            setState(() => _selectedParentId = p['id']);
                            FocusScope.of(context).unfocus();
                          },
                          fieldViewBuilder: (context, textController,
                              focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Parent Account',
                                prefixIcon: const Icon(
                                    Icons.family_restroom_outlined),
                                suffixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                                hintText: 'Search by name or email',
                                helperText: _selectedParentId != null
                                    ? '✓ Parent selected'
                                    : null,
                                helperStyle:
                                    const TextStyle(color: Colors.green),
                              ),
                              onChanged: (_) {
                                if (_selectedParentId != null) {
                                  setState(
                                      () => _selectedParentId = null);
                                }
                              },
                              validator: (value) {
                                if (_selectedParentId == null) {
                                  return 'Please search and select a parent';
                                }
                                return null;
                              },
                            );
                          },
                          optionsViewBuilder:
                              (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(8),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 250,
                                    maxWidth: 552,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final p =
                                          options.elementAt(index);
                                      return ListTile(
                                        leading: const CircleAvatar(
                                          child:
                                              Icon(Icons.person, size: 20),
                                        ),
                                        title: Text(p['name'] ?? ''),
                                        subtitle: Text(p['email'] ?? ''),
                                        onTap: () => onSelected(p),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) =>
                            Text('Error loading parents: $e'),
                      ),
                      const SizedBox(height: 16),

                      // Parent Phone
                      TextFormField(
                        controller: _parentPhoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                          LengthLimitingTextInputFormatter(13),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Parent Phone (SMS)',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                          hintText: '09XXXXXXXXX',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          if (!RegExp(r'^(\+63|0)[0-9]{10}$')
                              .hasMatch(value.trim())) {
                            return 'Use format: 09XXXXXXXXX';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Register Button
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _handleRegister,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.qr_code),
                        label: Text(
                          _isLoading
                              ? (_isUploadingPhoto
                                  ? 'Uploading Photo...'
                                  : 'Registering...')
                              : 'Register & Generate ID',
                        ),
                        style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Students List Header + Search
          Row(
            children: [
              Text(
                'Registered Students',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, ID, grade, or section',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase().trim()),
            ),
          ),
          const SizedBox(height: 16),
          studentsAsync.when(
            data: (students) {
              final activeStudents =
                  students.where((s) => s.isActive).toList();

              // Apply search filter
              final filtered = _searchQuery.isEmpty
                  ? activeStudents
                  : activeStudents.where((s) {
                      return s.fullName.toLowerCase().contains(_searchQuery) ||
                          s.studentId.toLowerCase().contains(_searchQuery) ||
                          s.gradeLevel.toLowerCase().contains(_searchQuery) ||
                          s.section.toLowerCase().contains(_searchQuery);
                    }).toList();

              if (activeStudents.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No students registered yet.')),
                  ),
                );
              }

              if (filtered.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No students match "$_searchQuery"',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${filtered.length} student${filtered.length == 1 ? '' : 's'}'
                      '${_searchQuery.isNotEmpty ? ' found' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  _buildStudentsTable(filtered),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteStudent(StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
            'Permanently delete ${student.fullName}? This removes their record and ID. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(principalRepositoryProvider).deleteStudent(student.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Student deleted.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditDialog(StudentModel student) {
    final idCtrl = TextEditingController(text: student.studentId);
    final nameCtrl = TextEditingController(text: student.fullName);
    final gradeCtrl = TextEditingController(text: student.gradeLevel);
    final sectionCtrl = TextEditingController(text: student.section);
    final phoneCtrl = TextEditingController(text: student.parentPhone);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Edit Student'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: idCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Student ID / LRN',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                        return 'Numbers only';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Z .,'-]")),
                      LengthLimitingTextInputFormatter(100),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: InputValidators.validateName,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: gradeCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Grade',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: sectionCtrl,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r"[a-zA-Z .'-]")),
                            LengthLimitingTextInputFormatter(50),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Section',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      LengthLimitingTextInputFormatter(13),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Parent Phone',
                      border: OutlineInputBorder(),
                      hintText: '09XXXXXXXXX',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!RegExp(r'^(\+63|0)[0-9]{10}$').hasMatch(v.trim())) {
                        return 'Use format: 09XXXXXXXXX';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => saving = true);
                      try {
                        await ref
                            .read(principalRepositoryProvider)
                            .updateStudent(
                              studentDocId: student.id,
                              studentId: idCtrl.text,
                              fullName: nameCtrl.text,
                              section: sectionCtrl.text,
                              gradeLevel: gradeCtrl.text,
                              parentId: student.parentId,
                              parentPhone: phoneCtrl.text,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Student updated!'),
                                backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        setLocal(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text(e
                                    .toString()
                                    .replaceAll('Exception: ', '')),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: Text(saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsTable(List<StudentModel> students) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Photo')),
            DataColumn(label: Text('Student LRN')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Grade')),
            DataColumn(label: Text('Section')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Actions')),
          ],
          rows: students.map((student) {
            return DataRow(
              onSelectChanged: (_) => _showStudentDetails(student),
              cells: [
                DataCell(
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: student.photoUrl.isNotEmpty
                        ? NetworkImage(student.photoUrl)
                        : null,
                    child: student.photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                ),
              DataCell(Text(student.studentId)),
              DataCell(Text(student.fullName)),
              DataCell(Text(student.gradeLevel)),
              DataCell(Text(student.section)),
              DataCell(Text(student.parentPhone)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.badge, color: Color(0xFF1B5E33)),
                      tooltip: 'View ID Card',
                      onPressed: () => _showIdCardDialog(student),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.orange),
                      tooltip: 'Edit',
                      onPressed: () => _showEditDialog(student),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _handleDeleteStudent(student),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
