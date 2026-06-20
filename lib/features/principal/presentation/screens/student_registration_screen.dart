import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:bantay_eskwela/app/theme.dart';
import 'package:bantay_eskwela/core/widgets/section_scaffold.dart';
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
  final _parentPhoneController = TextEditingController();
  final _searchController = TextEditingController();

  static const List<String> _gradeLevels = [
    'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12',
  ];
  static const List<String> _sections = [
    'St. Luke', 'St. Rita', 'St. Mark', 'St. John', 'St. Paul',
    'St. Peter', 'St. Matthew', 'St. Joseph', 'St. Therese', 'St. Francis',
  ];

  String? _selectedGrade;
  String? _selectedSection;
  String? _selectedParentId;
  String _searchQuery = '';
  bool _isLoading = false;

  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  bool _isUploadingPhoto = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _fullNameController.dispose();
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
        final picker = ImagePicker();
        final img = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 800,
            maxHeight: 800,
            imageQuality: 85);
        if (img != null) {
          bytes = await img.readAsBytes();
          name = img.name;
        }
      }
      if (bytes == null || name == null) return;
      final ext = name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        _toast('Please select an image (JPG, PNG, WEBP)', error: true);
        return;
      }
      if (bytes.length > 5 * 1024 * 1024) {
        _toast('Photo too large. Maximum 5MB.', error: true);
        return;
      }
      setState(() {
        _selectedPhotoBytes = bytes;
        _selectedPhotoName = name;
      });
    } catch (e) {
      _toast('Error selecting photo: $e', error: true);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParentId == null) {
      _toast('Please select a parent');
      return;
    }
    setState(() => _isLoading = true);
    try {
      String photoUrl = '';
      if (_selectedPhotoBytes != null && _selectedPhotoName != null) {
        setState(() => _isUploadingPhoto = true);
        photoUrl = await CloudinaryService.uploadImage(
            imageBytes: _selectedPhotoBytes!, fileName: _selectedPhotoName!);
        setState(() => _isUploadingPhoto = false);
      }
      final student = await ref.read(principalRepositoryProvider).registerStudent(
            studentId: _studentIdController.text,
            fullName: _fullNameController.text,
            section: _selectedSection ?? '',
            gradeLevel: _selectedGrade ?? '',
            parentId: _selectedParentId!,
            parentPhone: _parentPhoneController.text,
            photoUrl: photoUrl,
          );
      if (mounted) {
        _showIdCardDialog(student);
        _clearForm();
      }
    } catch (e) {
      _toast(e.toString().replaceAll('Exception: ', ''), error: true);
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
    _parentPhoneController.clear();
    setState(() {
      _selectedParentId = null;
      _selectedGrade = null;
      _selectedSection = null;
      _selectedPhotoBytes = null;
      _selectedPhotoName = null;
    });
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppTheme.forest));
  }

  Widget _formLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.forest)),
      );

  Future<Uint8List?> _captureCard(StudentModel student) async {
    final controller = ScreenshotController();
    return controller.captureFromWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
            textDirection: TextDirection.ltr,
            child: PrintableIdCard(student: student)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        try {
                          final img = await _captureCard(student);
                          if (img != null) {
                            final safe = student.studentId
                                .replaceAll(RegExp(r'[^\w]'), '_');
                            await download_helper.downloadFileWeb(
                                bytes: img,
                                fileName: 'ID_${safe}_frontback.png');
                            _toast('ID Card downloaded!');
                          }
                        } catch (e) {
                          _toast('Download failed: $e', error: true);
                        }
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () async {
                        try {
                          final img = await _captureCard(student);
                          if (img != null && kIsWeb) {
                            print_helper.printImageWeb(
                                img, 'Student ID - ${student.fullName}');
                          }
                        } catch (e) {
                          _toast('Print failed: $e', error: true);
                        }
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.gold),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done')),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppTheme.forest, AppTheme.pine]),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 116,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: AppTheme.gold, width: 3)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: student.photoUrl.isNotEmpty
                            ? Image.network(student.photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.person,
                                        size: 48, color: Colors.grey)))
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.person,
                                    size: 48, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(student.fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppTheme.gold,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('ID: ${student.studentId}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _detailRow(Icons.school_outlined, 'Grade Level',
                        student.gradeLevel),
                    _detailRow(
                        Icons.groups_outlined, 'Section', student.section),
                    _detailRow(Icons.phone_outlined, 'Parent Phone',
                        student.parentPhone),
                    _detailRow(Icons.qr_code_2, 'QR Code', student.qrData),
                  ],
                ),
              ),
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 20)),
                        child: const Text('Close')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppTheme.forest),
            const SizedBox(width: 12),
            SizedBox(
                width: 100,
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500))),
            Expanded(
                child: Text(value.isEmpty ? '—' : value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold))),
          ],
        ),
      );

  Future<void> _handleDeleteStudent(StudentModel s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
            'Permanently delete ${s.fullName}? This removes their record and ID. This cannot be undone.'),
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
      await ref.read(principalRepositoryProvider).deleteStudent(s.id);
      _toast('Student deleted.');
    } catch (e) {
      _toast('Delete failed: $e', error: true);
    }
  }

  void _showEditDialog(StudentModel student) {
    final idCtrl = TextEditingController(text: student.studentId);
    final nameCtrl = TextEditingController(text: student.fullName);
    final phoneCtrl = TextEditingController(text: student.parentPhone);
    String? grade =
        _gradeLevels.contains(student.gradeLevel) ? student.gradeLevel : null;
    String? section =
        _sections.contains(student.section) ? student.section : null;
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
                        border: OutlineInputBorder()),
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
                        labelText: 'Full Name', border: OutlineInputBorder()),
                    validator: InputValidators.validateName,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: grade,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Grade', border: OutlineInputBorder()),
                        items: _gradeLevels
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setLocal(() => grade = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: section,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Section',
                            border: OutlineInputBorder()),
                        items: _sections
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setLocal(() => section = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                  ]),
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
                        hintText: '09XXXXXXXXX',
                        border: OutlineInputBorder()),
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
                child: const Text('Cancel')),
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
                              section: section!,
                              gradeLevel: grade!,
                              parentId: student.parentId,
                              parentPhone: phoneCtrl.text,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _toast('Student updated!');
                      } catch (e) {
                        setLocal(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(
                                  e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red));
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

  @override
  Widget build(BuildContext context) {
    final parentsAsync = ref.watch(parentsListProvider);
    final studentsAsync = ref.watch(studentsStreamProvider);

    return CenteredColumn(
      maxWidth: 900,
      children: [
        // Registration form
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: FormCard(
              icon: Icons.person_add_alt_1,
              title: 'Register New Student',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              width: 116,
                              height: 138,
                              decoration: BoxDecoration(
                                  color: AppTheme.parchment,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.forest.withOpacity(0.35),
                                      width: 1.5)),
                              child: _selectedPhotoBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(_selectedPhotoBytes!,
                                          fit: BoxFit.cover))
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.add_a_photo_outlined,
                                            color: AppTheme.forest, size: 30),
                                        SizedBox(height: 6),
                                        Text('Add Photo',
                                            style: TextStyle(
                                                color: AppTheme.forest,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              _selectedPhotoName ??
                                  'Click to select student photo',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _formLabel('STUDENT INFORMATION'),
                    const SizedBox(height: 14),
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
                          border: OutlineInputBorder()),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Student ID is required';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                          return 'Student ID must contain numbers only';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                          border: OutlineInputBorder()),
                      validator: InputValidators.validateName,
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGrade,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Grade Level',
                              prefixIcon: Icon(Icons.school_outlined),
                              border: OutlineInputBorder()),
                          items: _gradeLevels
                              .map((g) =>
                                  DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedGrade = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSection,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Section',
                              prefixIcon: Icon(Icons.groups_outlined),
                              border: OutlineInputBorder()),
                          items: _sections
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedSection = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _formLabel('PARENT / GUARDIAN'),
                    const SizedBox(height: 14),
                    parentsAsync.when(
                      data: (parents) => Autocomplete<Map<String, String>>(
                        displayStringForOption: (p) =>
                            '${p['name']} (${p['email']})',
                        optionsBuilder: (t) {
                          final q = t.text.toLowerCase().trim();
                          if (q.isEmpty) return parents;
                          return parents.where((p) =>
                              (p['name'] ?? '').toLowerCase().contains(q) ||
                              (p['email'] ?? '').toLowerCase().contains(q));
                        },
                        onSelected: (p) {
                          setState(() => _selectedParentId = p['id']);
                          FocusScope.of(context).unfocus();
                        },
                        fieldViewBuilder: (context, tc, fn, _) => TextFormField(
                          controller: tc,
                          focusNode: fn,
                          decoration: InputDecoration(
                            labelText: 'Parent Account',
                            prefixIcon:
                                const Icon(Icons.family_restroom_outlined),
                            suffixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            hintText: 'Search by name or email',
                            helperText: _selectedParentId != null
                                ? '✓ Parent selected'
                                : null,
                            helperStyle:
                                const TextStyle(color: AppTheme.forest),
                          ),
                          onChanged: (_) {
                            if (_selectedParentId != null) {
                              setState(() => _selectedParentId = null);
                            }
                          },
                          validator: (_) => _selectedParentId == null
                              ? 'Please search and select a parent'
                              : null,
                        ),
                        optionsViewBuilder: (context, onSelected, options) =>
                            Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxHeight: 250, maxWidth: 560),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, i) {
                                  final p = options.elementAt(i);
                                  return ListTile(
                                    leading: const CircleAvatar(
                                        child: Icon(Icons.person, size: 20)),
                                    title: Text(p['name'] ?? ''),
                                    subtitle: Text(p['email'] ?? ''),
                                    onTap: () => onSelected(p),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading parents: $e'),
                    ),
                    const SizedBox(height: 16),
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
                          hintText: '09XXXXXXXXX'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (!RegExp(r'^(\+63|0)[0-9]{10}$').hasMatch(v.trim())) {
                          return 'Use format: 09XXXXXXXXX';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _handleRegister,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.qr_code),
                      label: Text(_isLoading
                          ? (_isUploadingPhoto
                              ? 'Uploading Photo...'
                              : 'Registering...')
                          : 'Register & Generate ID'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const SectionTitle('Registered Students'),
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
                      })
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) =>
                setState(() => _searchQuery = v.toLowerCase().trim()),
          ),
        ),
        const SizedBox(height: 16),
        studentsAsync.when(
          data: (students) {
            final active = students.where((s) => s.isActive).toList();
            final filtered = _searchQuery.isEmpty
                ? active
                : active
                    .where((s) =>
                        s.fullName.toLowerCase().contains(_searchQuery) ||
                        s.studentId.toLowerCase().contains(_searchQuery) ||
                        s.gradeLevel.toLowerCase().contains(_searchQuery) ||
                        s.section.toLowerCase().contains(_searchQuery))
                    .toList();
            if (active.isEmpty) {
              return const Card(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child:
                          Center(child: Text('No students registered yet.'))));
            }
            if (filtered.isEmpty) {
              return Card(
                  child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                          child: Text('No students match "$_searchQuery"',
                              style:
                                  TextStyle(color: Colors.grey.shade600)))));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                      '${filtered.length} student${filtered.length == 1 ? '' : 's'}${_searchQuery.isNotEmpty ? ' found' : ''}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ),
                _buildStudentsTable(filtered),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildStudentsTable(List<StudentModel> students) {
    return Card(
      child: Column(
        children: students.map((student) {
          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                onTap: () => _showStudentDetails(student),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundImage: student.photoUrl.isNotEmpty
                      ? NetworkImage(student.photoUrl)
                      : null,
                  child: student.photoUrl.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(student.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'LRN ${student.studentId}  •  ${student.gradeLevel} - ${student.section}\n${student.parentPhone}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.badge, color: AppTheme.forest),
                      tooltip: 'View ID Card',
                      onPressed: () => _showIdCardDialog(student),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.edit_outlined, color: AppTheme.gold),
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
              if (student != students.last)
                Divider(height: 1, color: Colors.black.withOpacity(0.06)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
