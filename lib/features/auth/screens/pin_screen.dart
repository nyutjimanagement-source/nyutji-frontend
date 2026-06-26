import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../../providers/wallet_provider.dart';
import '../../../../core/widgets/nyutji_notif.dart';
import '../../mitra_ml/screens/mitra_keamanan_pin.dart';

enum PinMode { verify, create, confirm }

class PinScreen extends ConsumerStatefulWidget {
  final PinMode mode;
  final String? initialPin;
  final double? amountToWithdraw;

  const PinScreen({
    super.key,
    this.mode = PinMode.verify,
    this.initialPin,
    this.amountToWithdraw,
  });

  @override ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = "";
  final int _pinLength = 6;
  bool _isLoading = false;

  void _onKeyPress(String key) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += key;
      });
      if (_pin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    if (widget.mode == PinMode.create) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => PinScreen(mode: PinMode.confirm, initialPin: _pin)
      ));
      return;
    }

    if (widget.mode == PinMode.confirm) {
      if (_pin != widget.initialPin) {
        NyutjiNotif.showError(context, "PIN tidak cocok. Silakan ulangi.");
        setState(() {
          _pin = "";
        });
        return;
      }

      setState(() => _isLoading = true);
      final walletProv = ref.read(walletProvider);
      final success = await walletProv.updatePin(_pin);
      setState(() => _isLoading = false);

      if (!mounted) return;
      if (success) {
        NyutjiNotif.showSuccess(context, "PIN Baru Dibuat");
        _showSuccessDialog("PIN Berhasil Dibuat", "PIN baru Anda berhasil disimpan dan sudah aktif.");
      }
      return;
    }

    // Default: PinMode.verify
    setState(() => _isLoading = true);
    
    if (widget.amountToWithdraw != null) {
      final walletProv = ref.read(walletProvider);
      final success = await walletProv.requestWithdraw(widget.amountToWithdraw!, _pin);
      
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      if (success) {
        _showSuccessDialog("Tarik Dana Berhasil!", "Dana Anda sedang diproses dan akan diteruskan ke rekening tujuan.");
      } else {
        NyutjiNotif.showError(context, walletProv.errorMessage ?? "Gagal memproses penarikan.");
        setState(() {
          _pin = "";
        });
      }
    } else {
      // Dummy / Simulated Verify
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showSuccessDialog("Verifikasi Berhasil!", "PIN Anda benar.");
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.checkCircle, size: 60, color: Color(0xFF1E5655)),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // close dialog
                    Navigator.pop(context); // back to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5655),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    "Selesai",
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              widget.mode == PinMode.create 
                  ? "Buat PIN Baru" 
                  : (widget.mode == PinMode.confirm ? "Konfirmasi PIN Anda" : "Masukkan PIN Nyutji"),
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "PIN digunakan untuk mengamankan transaksi Anda.",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 60),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (index) {
                bool isFilled = index < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: isFilled ? 20 : 16,
                  height: isFilled ? 20 : 16,
                  decoration: BoxDecoration(
                    color: isFilled ? const Color(0xFF1E5655) : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: isFilled ? [
                      BoxShadow(color: const Color(0xFF1E5655).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
                    ] : [],
                  ),
                );
              }),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: SizedBox(
                  width: 30, height: 30,
                  child: CircularProgressIndicator(color: Color(0xFF1E5655), strokeWidth: 3),
                ),
              )
            else
              const Spacer(),
            
            // Numpad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNumpadRow(["1", "2", "3"]),
                  const SizedBox(height: 24),
                  _buildNumpadRow(["4", "5", "6"]),
                  const SizedBox(height: 24),
                  _buildNumpadRow(["7", "8", "9"]),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      widget.mode == PinMode.verify ? _buildForgotPinButton() : const SizedBox(width: 80, height: 80),
                      _buildNumpadButton("0"),
                      _buildDeleteButton(),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _buildNumpadButton(k)).toList(),
    );
  }

  Widget _buildNumpadButton(String label) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _onKeyPress(label),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onDelete,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: const Icon(
          LucideIcons.delete,
          size: 32,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _buildForgotPinButton() {
    return GestureDetector(
      onTap: _isLoading ? null : () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MitraKeamananPinScreen()));
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Text(
          "Lupa\nPIN ?",
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E5655),
          ),
        ),
      ),
    );
  }
}
