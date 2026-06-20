import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bantay_eskwela/features/principal/domain/student_model.dart';

/// Printable ID card — front and back, school green/gold branding.
/// CR80 standard size: 85.6mm x 53.98mm at 96dpi ≈ 325x205px
class PrintableIdCard extends StatelessWidget {
  final StudentModel student;
  final String schoolName;

  const PrintableIdCard({
    super.key,
    required this.student,
    this.schoolName = 'Santa Ana Academy of Barili, Inc.',
  });

  // School colors
  static const Color green = Color(0xFF1B5E33);
  static const Color darkGreen = Color(0xFF0F3D20);
  static const Color gold = Color(0xFFC8A23A);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'STUDENT IDENTIFICATION CARD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: green,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Text('FRONT',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.grey)),
                  const SizedBox(height: 6),
                  _buildFront(),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  const Text('BACK',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.grey)),
                  const SizedBox(height: 6),
                  _buildBack(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '✂ Cut along the border — Standard CR80 ID size (85.6mm × 54mm)',
            style: TextStyle(
                fontSize: 9, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      width: 325,
      height: 205,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [green, darkGreen],
                ),
              ),
            ),
            // Gold top accent strip
            Container(
              height: 6,
              decoration: const BoxDecoration(color: gold),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Header with logo + school name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
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
                            fontSize: 7.5,
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
                        width: 68,
                        height: 82,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: gold, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: student.photoUrl.isNotEmpty
                              ? Image.network(student.photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.person,
                                          size: 34, color: Colors.grey)))
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.person,
                                      size: 34, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('STUDENT ID',
                                style: TextStyle(
                                    color: gold,
                                    fontSize: 9,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold)),
                            const Divider(color: Colors.white30, height: 8),
                            Text(student.fullName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            _chip('${student.gradeLevel}  •  ${student.section}'),
                            const SizedBox(height: 4),
                            _chip('ID: ${student.studentId}', bold: true),
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

  Widget _buildBack() {
    return Container(
      width: 325,
      height: 205,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Container(
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [green, darkGreen]),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
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
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 40, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          border: Border.all(color: green, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: QrImageView(
                          data: student.qrData,
                          version: QrVersions.auto,
                          size: 88,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('SCAN TO VERIFY',
                          style: TextStyle(
                              fontSize: 6,
                              letterSpacing: 1,
                              color: green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Name', student.fullName),
                        const SizedBox(height: 5),
                        _row('Student ID', student.studentId),
                        const SizedBox(height: 5),
                        _row('Grade', student.gradeLevel),
                        const SizedBox(height: 5),
                        _row('Section', student.section),
                        const Divider(height: 10, color: Colors.grey),
                        const Text(
                          'If found, please return to the school office.',
                          style: TextStyle(
                              fontSize: 7,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic),
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
              child: Container(height: 7, color: gold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(bold ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              letterSpacing: bold ? 1 : 0)),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 7,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
