import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/screens/pin_screen.dart' as pin_screen;
import 'courier_profile_screen.dart';

class CourierTarikDanaModal extends ConsumerStatefulWidget {
  final String courierName;
  final double maxBalance;

  const CourierTarikDanaModal({
    super.key,
    required this.courierName,
    required this.maxBalance,
  });

  @override ConsumerState<CourierTarikDanaModal> createState() => _CourierTarikDanaModalState();
}

class _CourierTarikDanaModalState extends ConsumerState<CourierTarikDanaModal> {
  double _amount = 0;
  static const Color primaryTeal = Color(0xFF286B6A);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final double withdrawableMax = (widget.maxBalance ~/ 100000) * 100000.0;
    
    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Consumer(
          builder: (context, ref, _) {
final auth = ref.watch(authProvider);
            final user = auth.user;
            final hasBank = user != null && 
                            user['bank_name'] != null && user['bank_name'].toString().isNotEmpty && 
                            user['bank_account'] != null && user['bank_account'].toString().isNotEmpty && 
                            user['account_name'] != null && user['account_name'].toString().isNotEmpty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                Text("Konfirmasi Tarik Dana Kurir", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildDetailRow("Nama Kurir", widget.courierName),
                      const Divider(height: 32),
                      _buildDetailRow("Sumber Dana", "Wallet Nyutji", value2: "Saldo: ${Formatters.currencyIdr(widget.maxBalance)}", highlight2: true),
                      const Divider(height: 32),
                      hasBank 
                          ? _buildDetailRow("Rekening Penerima", user['account_name'] ?? '-', value2: "${user['bank_name']} - ${user['bank_account']}")
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Rekening Penerima", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                                InkWell(
                                  onTap: () {
                                    final nav = Navigator.of(context);
                                    nav.pop();
                                    nav.push(MaterialPageRoute(builder: (_) => Scaffold(
                                      appBar: AppBar(
                                        title: Text("Pengaturan Akun", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        backgroundColor: primaryTeal,
                                        iconTheme: const IconThemeData(color: Colors.white),
                                      ),
                                      body: const CourierProfileScreen(),
                                    )));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.alertCircle, size: 12, color: Colors.red),
                                        const SizedBox(width: 4),
                                        Text("Setup Rekening", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                    ],
                  ),
                ),
            
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Nominal Tarik Dana", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      Text(Formatters.currencyIdr(_amount), style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: primaryTeal)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: primaryTeal,
                      inactiveTrackColor: primaryTeal.withValues(alpha: 0.1),
                      thumbColor: primaryTeal,
                      overlayColor: primaryTeal.withValues(alpha: 0.2),
                      trackHeight: 8,
                    ),
                    child: Slider(
                      value: _amount,
                      min: 0,
                      max: withdrawableMax > 0 ? withdrawableMax : 100,
                      divisions: withdrawableMax > 0 ? (withdrawableMax ~/ 100000) : null,
                      onChanged: withdrawableMax > 0 ? (val) {
                        setState(() {
                          _amount = val;
                        });
                      } : null,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Rp 0", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                      Text("Maks: ${Formatters.currencyIdr(withdrawableMax)}", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !hasBank 
                      ? () {
                          final nav = Navigator.of(context);
                          nav.pop();
                          nav.push(MaterialPageRoute(builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: Text("Pengaturan Akun", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              backgroundColor: primaryTeal,
                              iconTheme: const IconThemeData(color: Colors.white),
                            ),
                            body: const CourierProfileScreen(),
                          )));
                        }
                      : (_amount > 0 ? () {
                          final nav = Navigator.of(context);
                          nav.pop();
                          nav.push(MaterialPageRoute(
                            builder: (context) => pin_screen.PinScreen(amountToWithdraw: _amount)
                          ));
                        } : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !hasBank ? Colors.red : primaryTeal,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: (!hasBank || _amount > 0) ? 8 : 0,
                    shadowColor: (!hasBank ? Colors.red : primaryTeal).withValues(alpha: 0.4),
                  ),
                  child: Text(
                    !hasBank ? "Setup Rekening Dulu" : (_amount > 0 ? "Tarik Dana  >  ${Formatters.currencyIdr(_amount)}" : "Tentukan Nominal"),
                    style: GoogleFonts.montserrat(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      color: (!hasBank || _amount > 0) ? Colors.white : Colors.grey[600]
                    )
                  ),
                ),
              ),
            ),
            SizedBox(height: 32 + MediaQuery.of(context).padding.bottom),
          ],
        );
        },
      ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {String? value2, bool highlight2 = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label, 
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value, 
                style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF111827)),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (value2 != null) ...[
                const SizedBox(height: 4),
                Text(
                  value2, 
                  style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: highlight2 ? primaryTeal : Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        )
      ],
    );
  }
}
