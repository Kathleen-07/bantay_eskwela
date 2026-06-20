import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';

/// Student ID Card widget — Front and Back, school green/gold branding.
class StudentIdCard extends StatefulWidget {
  final StudentModel student;
  final String schoolName;

  const StudentIdCard({
    super.key,
    required this.student,
    this.schoolName = 'Santa Ana Academy of Barili, Inc.',
  });

  @override
  State<StudentIdCard> createState() => _StudentIdCardState();
}

class _StudentIdCardState extends State<StudentIdCard> {
  bool _showFront = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showFront = !_showFront),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showFront
                ? _FrontCard(
                    key: const ValueKey('front'),
                    student: widget.student,
                    schoolName: widget.schoolName,
                  )
                : _BackCard(
                    key: const ValueKey('back'),
                    student: widget.student,
                    schoolName: widget.schoolName,
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(_showFront),
            const SizedBox(width: 6),
            _dot(!_showFront),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _showFront ? 'Tap to see back' : 'Tap to see front',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _dot(bool active) {
    return Container(
      width: active ? 16 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white38,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// School colors
const Color _green = Color(0xFF1B5E33);
const Color _darkGreen = Color(0xFF0F3D20);
const Color _gold = Color(0xFFC8A23A);

/// Front of the ID Card
class _FrontCard extends StatelessWidget {
  final StudentModel student;
  final String schoolName;

  const _FrontCard({super.key, required this.student, required this.schoolName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 214,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_green, _darkGreen],
                ),
              ),
            ),
            // Gold top strip
            Container(height: 6, color: _gold),
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Header: logo + school name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        backgroundImage: const AssetImage(
                            'assets/images/santa_ana_logo.png'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          schoolName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 86,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _gold, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: student.photoUrl.isNotEmpty
                              ? Image.network(
                                  student.photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _photoPlaceholder(),
                                )
                              : _photoPlaceholder(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'STUDENT ID',
                              style: TextStyle(
                                color: _gold,
                                fontSize: 10,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(color: Colors.white30, height: 10),
                            Text(
                              student.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _InfoChip(
                                label:
                                    '${student.gradeLevel}  •  ${student.section}'),
                            const SizedBox(height: 4),
                            _InfoChip(
                                label: 'ID: ${student.studentId}', isId: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, size: 40, color: Colors.grey),
    );
  }
}

/// Back of the ID Card
class _BackCard extends StatelessWidget {
  final StudentModel student;
  final String schoolName;

  const _BackCard({super.key, required this.student, required this.schoolName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 214,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(color: Colors.white),
            // Top green strip with logo
            Container(
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_green, _darkGreen]),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      backgroundImage: const AssetImage(
                          'assets/images/santa_ana_logo.png'),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        schoolName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 44, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _green, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: QrImageView(
                          data: student.qrData,
                          version: QrVersions.auto,
                          size: 90,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'SCAN TO VERIFY',
                        style: TextStyle(
                          fontSize: 7,
                          letterSpacing: 1,
                          color: _green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BackInfoRow(label: 'Name', value: student.fullName),
                        const SizedBox(height: 6),
                        _BackInfoRow(
                            label: 'Student ID', value: student.studentId),
                        const SizedBox(height: 6),
                        _BackInfoRow(
                            label: 'Grade Level', value: student.gradeLevel),
                        const SizedBox(height: 6),
                        _BackInfoRow(label: 'Section', value: student.section),
                        const Divider(height: 10),
                        const Text(
                          'If found, please return to the school office.',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(height: 8, color: _gold),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final bool isId;

  const _InfoChip({required this.label, this.isId = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isId ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: isId ? 10 : 9,
          fontWeight: isId ? FontWeight.bold : FontWeight.normal,
          letterSpacing: isId ? 1 : 0,
        ),
      ),
    );
  }
}

class _BackInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _BackInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
