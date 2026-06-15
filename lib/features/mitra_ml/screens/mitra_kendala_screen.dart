import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/issue_provider.dart';

class MitraKendalaScreen extends ConsumerStatefulWidget {
  const MitraKendalaScreen({super.key});

  @override
  ConsumerState<MitraKendalaScreen> createState() => _MitraKendalaScreenState();
}

class _MitraKendalaScreenState extends ConsumerState<MitraKendalaScreen> {
  static const primaryTeal = Color(0xFF1E5655);
  static const bgColor = Color(0xFFF3F4F6);
  static const darkText = Color(0xFF111827);
  static const textGrey = Color(0xFF6B7280);

  final _formKey = GlobalKey<FormState>();
  String _issueType = 'MESIN_RUSAK';
  String _priority = 'MEDIUM';
  final _descriptionController = TextEditingController();

  final List<String> _issueTypes = [
    'MESIN_RUSAK',
    'KURIR_TELAT',
    'LISTRIK_MATI',
    'AIR_BERMASALAH',
    'LAINNYA'
  ];

  final List<String> _priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final issueProv = ref.read(issueProvider);

      final success = await issueProv.reportIssue(
        _issueType,
        _descriptionController.text,
        _priority,
      );

      if (!mounted) return;

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Laporan berhasil dikirim!', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            backgroundColor: primaryTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        navigator.pop();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal: ${issueProv.error}', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkText),
        title: Text(
          'Laporkan Kendala', 
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800, 
            color: darkText,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Tipe Kendala', LucideIcons.alertTriangle),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      _buildIssueTypeCapsule(_issueTypes[0]),
                      const SizedBox(width: 10),
                      _buildIssueTypeCapsule(_issueTypes[1]),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildIssueTypeCapsule(_issueTypes[2]),
                      const SizedBox(width: 10),
                      _buildIssueTypeCapsule(_issueTypes[3]),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildIssueTypeCapsule(_issueTypes[4]),
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Prioritas', LucideIcons.flag),
              const SizedBox(height: 16),
              Row(
                children: _priorities.map((p) {
                  final isSelected = _priority == p;
                  Color priorityColor;
                  switch(p) {
                    case 'LOW': priorityColor = Colors.green; break;
                    case 'MEDIUM': priorityColor = Colors.blue; break;
                    case 'HIGH': priorityColor = Colors.orange; break;
                    case 'CRITICAL': priorityColor = Colors.red; break;
                    default: priorityColor = primaryTeal;
                  }
                  
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? priorityColor : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? priorityColor : Colors.grey[300]!,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: priorityColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          p,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
                            fontSize: 11,
                            color: isSelected ? Colors.white : textGrey,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Deskripsi Kejadian', LucideIcons.fileText),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: GoogleFonts.montserrat(fontSize: 14, color: darkText, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Jelaskan detail kendala Anda di sini...',
                    hintStyle: GoogleFonts.montserrat(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Keterangan tidak boleh kosong' : null,
                ),
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: ref.watch(issueProvider).isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: primaryTeal.withValues(alpha: 0.5),
                  ),
                  child: ref.watch(issueProvider).isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        )
                      : Text('KIRIM LAPORAN', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryTeal.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: primaryTeal),
        ),
        const SizedBox(width: 12),
        Text(
          title, 
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800, 
            fontSize: 15,
            color: darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildIssueTypeCapsule(String type) {
    final isSelected = _issueType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _issueType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryTeal : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? primaryTeal : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryTeal.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Text(
            type.replaceAll('_', ' '),
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
              color: isSelected ? Colors.white : textGrey,
            ),
          ),
        ),
      ),
    );
  }
}
