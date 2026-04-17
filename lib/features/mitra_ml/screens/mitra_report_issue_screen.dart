import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/issue_provider.dart';

class MitraReportIssueScreen extends StatefulWidget {
  const MitraReportIssueScreen({super.key});

  @override
  State<MitraReportIssueScreen> createState() => _MitraReportIssueScreenState();
}

class _MitraReportIssueScreenState extends State<MitraReportIssueScreen> {
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
      final success = await context.read<IssueProvider>().reportIssue(
        _issueType,
        _descriptionController.text,
        _priority,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${context.read<IssueProvider>().error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporkan Kendala', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Tipe Kendala', LucideIcons.alertTriangle),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(4, 4)),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _issueType,
                    isExpanded: true,
                    onChanged: (val) => setState(() => _issueType = val!),
                    items: _issueTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              _buildSectionTitle('Prioritas', LucideIcons.flag),
              const SizedBox(height: 10),
              Row(
                children: _priorities.map((p) {
                  final isSelected = _priority == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber : (isDark ? Colors.grey[850] : Colors.grey[100]),
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected ? null : const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                        ),
                        child: Text(
                          p,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
              _buildSectionTitle('Deskripsi Kejadian', LucideIcons.fileText),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Jelaskan detail kendala Anda di sini...',
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Keterangan tidak boleh kosong' : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: context.watch<IssueProvider>().isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                    elevation: 0,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.all(Colors.black.withOpacity(0.1)),
                  ),
                  child: context.watch<IssueProvider>().isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('KIRIM LAPORAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.amber),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
