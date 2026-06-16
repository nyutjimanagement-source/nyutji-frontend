import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../providers/connectivity_provider.dart';

class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dengarkan perubahan koneksi untuk sinkronisasi antrean offline
    ref.listen<AsyncValue<List<ConnectivityResult>>>(connectivityProvider, (previous, next) {
      if (next is AsyncData) {
        final results = next.value!;
        final isOnline = !results.contains(ConnectivityResult.none) && results.isNotEmpty;
        
        final prevResults = previous?.value ?? [ConnectivityResult.none];
        final wasOffline = prevResults.contains(ConnectivityResult.none) || prevResults.isEmpty;

        if (wasOffline && isOnline) {
          // BackgroundSyncService sudah otomatis menangani sync secara global.
          // Tidak perlu trigger manual di sini lagi.
        }
      }
    });

    final connectivityState = ref.watch(connectivityProvider);

    return Column(
      children: [
        connectivityState.when(
          data: (results) {
            final hasNoConnection = results.contains(ConnectivityResult.none) || results.isEmpty;
            if (hasNoConnection) {
              return _buildOfflineBanner();
            }
            return const SizedBox.shrink(); // Sembunyikan banner jika online
          },
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const SizedBox.shrink(),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red[600],
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: const SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              "Tidak Ada Koneksi Internet",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
