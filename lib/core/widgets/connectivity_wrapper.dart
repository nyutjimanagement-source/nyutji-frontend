import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../providers/connectivity_provider.dart';
import 'nyutji_notif.dart';

class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dengarkan perubahan koneksi untuk menampilkan notifikasi cantik
    ref.listen<AsyncValue<List<ConnectivityResult>>>(connectivityProvider, (previous, next) {
      if (previous == null) {
        // Abaikan emisi pertama saat inisialisasi aplikasi agar tidak memicu Overlay saat bootstrapping
        return;
      }
      if (next is AsyncData) {
        final results = next.value!;
        final isOnline = !results.contains(ConnectivityResult.none) && results.isNotEmpty;
        
        final prevResults = previous.value ?? [ConnectivityResult.none];
        final wasOffline = prevResults.contains(ConnectivityResult.none) || prevResults.isEmpty;

        if (wasOffline && isOnline) {
          // Koneksi pulih -> Tampilkan toast sukses hijau
          NyutjiNotif.showSuccess(context, "Koneksi internet terhubung kembali.");
        } else if (!wasOffline && !isOnline) {
          // Koneksi terputus -> Tampilkan toast error merah
          NyutjiNotif.showError(context, "Koneksi terkendala. Cek internet Anda.");
        }
      }
    });

    return child;
  }
}
