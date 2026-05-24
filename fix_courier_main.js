const fs = require('fs');
const path = 'c:/0905NyutjiDev/frontend/lib/features/kurir_kl/screens/courier_main_screen.dart';
let content = fs.readFileSync(path, 'utf8');

const startString = 'onPressed: _isUploading ? null : () async {';
const startIndex = content.indexOf(startString);

if (startIndex !== -1) {
    const endString = 'style: ElevatedButton.styleFrom(';
    const endIndex = content.indexOf(endString, startIndex);
    
    if (endIndex !== -1) {
        const newBlock = `onPressed: _isUploading ? null : () async {
                                  if (_taskCapturedImages[orderId] == null) {
                                    _showBeautifulNotif("Wajib upload foto sebelum Selesai!", false);
                                    return;
                                  }
                                  
                                  setState(() => _isUploading = true);
                                  final provider = context.read<OrderProvider>();
                                  
                                  // Step 2: UPLOAD FOTO POW (Real via API)
                                  final step = isDelivery ? 'DELIVERING' : 'PICKING_UP';
                                  final uploadSuccess = await provider.uploadPOWImage(
                                    orderId, 
                                    XFile(_taskCapturedImages[orderId]!.path), 
                                    step
                                  );

                                  if (!uploadSuccess) {
                                    if (mounted) {
                                      setState(() => _isUploading = false);
                                      _showBeautifulNotif(provider.errorMessage ?? "Gagal mengunggah foto. Coba lagi.", false);
                                    }
                                    return;
                                  }

                                  // Step 3: Trigger NEXT STATUS (WEIGHING atau DONE)
                                  final String nextStatus = isDelivery ? 'DONE' : 'WEIGHING';
                                  final success = await provider.updateOrderStatus(orderId, nextStatus);
                                  
                                  if (mounted) {
                                    setState(() => _isUploading = false);
                                    if (success) {
                                      _taskCapturedImages.remove(orderId);
                                      if (isDelivery) {
                                          _showBeautifulNotif("Tugas Selesai! Cucian telah diterima pelanggan.", true);
                                      } else {
                                          _showBeautifulNotif("Tugas Selesai! Pesanan diteruskan ke Mitra (Timbangan).", true);
                                      }
                                      _refreshData();
                                    } else {
                                      _showBeautifulNotif(provider.errorMessage ?? "Gagal memperbarui status", false);
                                    }
                                  }
                                },
                              `;
                              
        content = content.substring(0, startIndex) + newBlock + content.substring(endIndex);
        fs.writeFileSync(path, content, 'utf8');
        console.log('Successfully fixed file.');
    } else {
        console.log('End string not found');
    }
} else {
    console.log('Start string not found');
}
