# Aturan Permanen Projek: Arsitektur Offline-First & Standar Pengkodean Nyutji

Aturan ini harus dipatuhi secara otomatis oleh semua asisten AI saat membuat atau memodifikasi fitur/layanan/halaman di projek Nyutji Laundry. Tujuannya adalah meminimalkan beban koneksi shared hosting, menjaga performa UI tetap responsif, serta menjaga estetika premium aplikasi.

---

## I. Arsitektur Offline-First Ringan & Ramah Shared Hosting

### 1. Prinsip Caching GET (Cache-First / Stale-While-Revalidate)
* **Aturan**: Setiap request data utama (seperti riwayat pesanan, saldo dompet, item mitra) harus dimuat dari cache lokal terlebih dahulu via `CacheService` (berbasis Hive box `nyutji_cache`).
* **Implementasi**:
  1. Tampilkan data dari cache secara instan jika ada. Hilangkan/minimalkan screen loading/shimmer.
  2. Kirim request API ke server secara asinkron di latar belakang.
  3. Jika berhasil, simpan respons terbaru ke cache lokal dan perbarui UI.
  4. Jika gagal (misal karena offline atau timeout), tetap gunakan data cache tanpa memunculkan dialog/layar error yang mengganggu (cukup tampilkan indikator offline pasif).

### 2. Throttling Request (Membatasi Request Duplikat)
* **Aturan**: Batasi frekuensi pemanggilan API GET ke server untuk sumber daya yang sama maksimal 1 kali setiap 15 detik.
* **Implementasi**:
  * Simpan *timestamp* fetch terakhir di provider (`order_provider.dart`, `wallet_provider.dart`, dll.).
  * Tolak request baru jika selisih waktu dari fetch terakhir masih di bawah 15 detik, **kecuali jika dipanggil dengan parameter `force: true`**.
  * Hal ini sangat penting untuk mencegah "badai request" konkuren yang dipicu oleh pre-loading tab pada widget `PageView` (seperti saat masuk dashboard pertama kali).

### 3. Pull-to-Refresh untuk Pembaruan Manual
* **Aturan**: Setiap halaman utama yang menampilkan daftar data dinamis wajib dibungkus dengan widget `RefreshIndicator`.
* **Implementasi**:
  * Ketika pengguna melakukan tarikan refresh (pull-to-refresh), jalankan fetch data dengan melewatkan parameter `force: true` agar melompati throttling 15 detik dan mengambil data segar langsung dari server.

### 4. Pelarangan Polling Agresif
* **Aturan**: Dilarang menggunakan `Timer.periodic` dengan durasi pendek (misalnya polling setiap 5-10 detik) untuk memantau status atau data di dashboard utama.
* **Solusi**: Biarkan data diperbarui saat pengguna pertama kali membuka halaman (menggunakan alur cache-first), dan biarkan pengguna memperbarui data secara berkala secara manual menggunakan gesture pull-to-refresh.

### 5. Larangan Offline Queue untuk Nyutji
* **Aturan**: **Dilarang** mengimplementasikan sistem Offline Queue (antrian mutasi saat offline) di aplikasi Nyutji.
* **Alasan**:
  1. Masalah koneksi di Nyutji bersifat **server-side** (shared hosting overload), bukan device-side — sudah ditangani oleh Retry Interceptor.
  2. Operasi kritis Nyutji (buat pesanan, upload POW, update status) memerlukan validasi real-time dari server dan **tidak aman** untuk di-queue karena risiko konflik state.
  3. Retry Mechanism yang sudah ada (`connectionError` + `badResponse HTML`) sudah cukup untuk menangani gangguan sementara tanpa kompleksitas Offline Queue.
* **Alternatif yang benar**: Gunakan `cache-first` untuk READ, dan `retry otomatis` untuk WRITE yang gagal sementara.

---

## II. Standar Pengkodean UI & State Management

### 1. Caching Gambar (`CachedNetworkImage`)
* **Aturan**: Dilarang menggunakan `Image.network` standar untuk aset gambar eksternal dari server/database.
* **Solusi**: Wajib menggunakan `CachedNetworkImage` dari package `cached_network_image` untuk menyimpan cache gambar di HP pengguna secara lokal agar menghemat paket data dan mempercepat akses visual.

### 2. Margin Bawah Dinamis (Dynamic Bottom Padding)
* **Aturan**: Hindari memberikan margin/padding statis (hardcoded seperti `SizedBox(height: 16)`) di bagian bawah layar, terutama pada Bottom Sheet atau Floating Action Button.
* **Solusi**: Deteksi margin secara pintar menggunakan `MediaQuery.of(context).padding.bottom` untuk menyesuaikan sisa ruang layar pada berbagai tipe HP (layar poni, HP jadul, notch layar penuh).

### 3. Anti-Tabrakan Layar (Responsive Ellipsis Text)
* **Aturan**: Teks panjang (seperti nama item, deskripsi, alamat) dilarang keras nabrak atau meluber melewati batas kanan layar.
* **Solusi**: Selalu bungkus teks dinamis dalam widget layout pembatas (`Expanded` atau `Flexible`) dan berikan parameter `overflow: TextOverflow.ellipsis` agar teks dipotong rapi dengan tanda titik tiga `...`.

### 4. Efek Geser Alami (`BouncingScrollPhysics`)
* **Aturan**: Berikan kenyamanan navigasi bergaya premium untuk pengguna iOS maupun Android.
* **Solusi**: Selalu gunakan `physics: const BouncingScrollPhysics()` pada semua scrollable widget (`ListView`, `SingleChildScrollView`, `PageView`, `GridView`) baik saat menggeser cards/kartu secara horizontal (kiri-kanan) maupun untuk gesture screen saat ditarik keatas/kebawah (vertikal).

### 5. Kliping Halus Kontainer (`Clip.antiAlias`)
* **Aturan**: Menghindari sudut tumpul yang terlihat patah-patah, abu-abu kotor, atau transparan gelap di ujung sudut kontainer bulat saat melakukan collapse/expand (transisi melebarkan/mengecilkan widget).
* **Solusi**: Wajib menambahkan properti `clipBehavior: Clip.antiAlias` pada grup kontainer yang menggunakan `BorderRadius` dan memiliki transisi ekspansi.

### 6. Pencegahan Kebocoran Data (Anti-State Leak)
* **Aturan**: Data sensitif atau state lama tidak boleh membekas atau bocor di memori saat pengguna keluar akun (logout) atau berpindah peran.
* **Solusi**: Gunakan "mantra penghancur" Riverpod `ref.invalidate(provider)` atau lakukan reset state eksplisit saat logout untuk membersihkan memori HP dari sisa-sisa data user sebelumnya.

### 7. Kecepatan Pencarian Lokal (`StatefulBuilder`)
* **Aturan**: Pencarian/filter cepat pada daftar data (seperti menu hapus pengguna) tidak boleh menyebabkan lag karena memicu render ulang seluruh halaman yang berat.
* **Solusi**: Gunakan teknik *Local State Filtering* menggunakan widget `StatefulBuilder` untuk mengisolasi proses pengetikan karakter pencarian dan penyaringan daftar secara lokal tanpa mengganggu halaman induk.

### 8. Tombol / Tautan Estetik
* **Aturan**: Tombol berwujud tautan teks (text link button) harus didesain minimalis dan bersih agar tidak mendominasi layar.
* **Solusi**: Desain tautan estetik dengan warna hitam solid, berukuran kecil tepat `12px` (`fontSize: 12`), dan gaya tulisan premium.

### 9. Pagination Model Kapsul (Pill Indicator)
* **Aturan**: Desain pagination slider atau indikator halaman harus modern dan mewah, bukan dots lingkaran standar.
* **Solusi**: Gunakan indikator pagination berbentuk "Kapsul" (pill/rounded rectangle horizontal) dengan warna aktif dan non-aktif yang harmonis.

### 10. Expandable Card Animasi (`AnimatedSize`)
* **Aturan**: Kartu yang bisa dilebarkan untuk menampilkan info detail (expandable card) dilarang mekar secara kaku tanpa transisi.
* **Solusi**: Gunakan widget `AnimatedSize` dengan durasi transisi `300ms` (`duration: const Duration(milliseconds: 300)`) dan kurva animasi yang halus agar kartu melebar dan menciut secara estetik.

### 11. Transisi Halaman Geser Horizontal
* **Aturan**: Transisi perpindahan antar halaman/screen tidak boleh menggunakan efek bawaan android standar yang kaku.
* **Solusi**: Gunakan transisi geser horizontal dari kanan ke kiri secara konsisten (menggunakan custom `PageRouteBuilder` atau kelas `RetroRoute` yang sudah disiapkan projek).

### 12. Tampilan Bukti Pengerjaan (POW - Proof of Wash)
* **Aturan**: Gambar bukti pengerjaan laundry harus ditampilkan secara proporsional dan memiliki watermark keamanan.
* **Solusi**:
  1. Bungkus dengan `Positioned.fill` dan atur `fit: BoxFit.cover` agar foto otomatis memenuhi area grid.
  2. Tanamkan watermark bertuliskan "Nyutji Management" sebanyak 3 kalimat terpisah.
  3. Posisikan watermark secara acak (kombinasi atas, tengah, dan bawah gambar).
  4. Berikan efek kemiringan watermark sebesar 45 derajat (`Transform.rotate(angle: -pi / 4)` atau setara) agar sulit dimanipulasi.

### 13. Penggunaan Notifikasi Kustom (`NyutjiNotif`)
* **Aturan**: Dilarang menggunakan standar bawaan Flutter (`ScaffoldMessenger.of(context).showSnackBar`) atau *dialog popup* bawaan sistem untuk menampilkan pesan *success*, *error*, atau informasi kepada pengguna.
* **Solusi**: Wajib menggunakan pemanggilan statis dari widget kustom `NyutjiNotif` (misal: `NyutjiNotif.showSuccess`, `NyutjiNotif.showError`) secara langsung pada blok eksekusi agar notifikasi muncul dengan desain premium (*BeautyPopupWidget*) tanpa perlu melempar pesan melalui `Navigator.pop`.

### 14. Keamanan Context dalam GridView/ListView Builder
* **Aturan**: Di dalam `itemBuilder` pada `GridView` atau `ListView`, jangan gunakan `context` lokal builder untuk operasi asinkron (navigasi, notifikasi) setelah `await`.
* **Solusi**: Gunakan `mounted` (bukan `context.mounted`) dan `this.context` untuk mengakses context induk `State` yang dijamin tetap hidup meski layout builder sudah dihancurkan dan dibangun ulang. Contoh:
  ```dart
  itemBuilder: (ctx, index) { // ← pakai nama berbeda (ctx) agar tidak shadow
    onTap: () async {
      await someAsyncOperation();
      if (mounted) { // ← cek mounted milik State, bukan ctx
        NyutjiNotif.showSuccess(this.context, "Berhasil"); // ← this.context
        Navigator.pop(this.context);
      }
    }
  }
  ```

### 15. Skeleton Loading Menggunakan Shimmer Loading
* **Aturan**: Gunakan skeleton loading berbasis shimmer loading untuk indikasi visual saat memuat data, bukan menggunakan spinner bulat (CircularProgressIndicator) standar pada konten utama.
* **Solusi**: Bungkus layout skeleton menggunakan widget kustom `ShimmerLoading` dengan ukuran (lebar dan tinggi) yang menyerupai bentuk asli komponen data yang sedang dimuat untuk transisi visual yang halus dan estetik.

---

## III. Standar Database & Relasi Tabel

### 1. Penggunaan orderNumber sebagai Primary Key Tabel Orders
* **Aturan**: Tabel "orders" secara mutlak menggunakan "orderNumber" (dengan format *string* kustom, contoh: "SRP-20260529-1782") sebagai *Primary Key*. Dilarang keras menggunakan, mencari, atau menambahkan kolom "id" pada tabel "orders" maupun referensi *foreign key*-nya di tabel lain.
* **Implementasi**:
  1. Saat mencari data (*query*) menggunakan Sequelize (misal: "Order.findOne"), hanya gunakan parameter "where: { orderNumber: ... }".
  2. Hapus dan hindari logika *fallback* pencarian yang melibatkan kolom "id" (misal: "{ id: isNaN(orderNumber) ? null : parseInt(orderNumber) }").
  3. Seluruh tabel relasi (seperti "order_items", "order_attachment") yang terhubung ke pesanan wajib menggunakan kolom bertipe *string* yang merujuk langsung ke "orderNumber".

---

## IV. Standar Koneksi API & Error Handling

### 1. Pesan Log Throttle Adalah Normal (Bukan Error)
* **Aturan**: Pesan log `[fetchOrders] Throttled (kurang dari 15 detik)` atau `[fetchWallet] Throttled (kurang dari 15 detik)` adalah perilaku **yang diharapkan dan benar**, bukan sebuah bug atau error yang perlu diperbaiki.
* **Penjelasan**: Throttle ini adalah mekanisme perlindungan server shared hosting. Ketika beberapa widget atau tab memanggil `fetchOrders()` atau `fetchWallet()` secara bersamaan (misal: saat pre-loading dashboard), sistem secara cerdas memblokir request duplikat dan menjawab dengan data dari cache lokal. Ini mencegah "badai request" ke server.
* **Kapan perlu diperhatikan**: Hanya jika user mengeluh data yang tampil terasa *sangat basi* padahal sudah lebih dari 15 detik. Solusinya adalah memastikan `pull-to-refresh` menggunakan parameter `force: true`.

### 2. Arsitektur Interceptor Dio: Urutan LIFO untuk Response/Error
* **Aturan**: Saat menambahkan interceptor pada `Dio`, perhatikan bahwa **REQUEST diproses secara FIFO** (pertama masuk, pertama keluar), namun **RESPONSE dan ERROR diproses secara LIFO** (terakhir masuk, pertama keluar).
* **Implementasi wajib** pada `api_service.dart`:
  1. Interceptor **Auth** (penambah token Bearer) selalu ditambahkan **pertama** (`index 0`) agar token disisipkan sebelum request dikirim.
  2. Interceptor **HTML-Detect + Retry** ditambahkan **kedua** (`index 1`) sehingga ia memproses response/error **lebih dahulu** dari Auth (karena LIFO). Dengan posisi ini, deteksi halaman HTML dari shared hosting dan logika retry terjadi di satu tempat sebelum error sempat "naik" ke caller.
  3. **Dilarang** memisahkan logika deteksi HTML (di Auth `onResponse`) dari logika retry (di interceptor lain) karena error yang di-`reject` dari `onResponse` hanya diteruskan ke interceptor di bawahnya (index lebih rendah), bukan ke atas.
* **Jenis error yang wajib di-retry** (maksimal 3x dengan jeda bertambah):
  * `connectionError` — koneksi TCP gagal (connection reset, closed before header) → flush connection pool sebelum retry
  * `connectionTimeout` / `receiveTimeout` / `sendTimeout` — timeout jaringan
  * `badResponse` berisi HTML — respons HTML sementara dari cPanel/Apache (resource limit, 503 page)
* **Jenis error yang TIDAK boleh di-retry**:
  * `badResponse` berisi JSON dengan status 4xx (misal: 401 Unauthorized, 404 Not Found, 422 Validation Error) — ini adalah error permanen dari logika bisnis, bukan masalah jaringan.

### 3. `ApiService().reset()` Hanya Dipanggil saat Logout
* **Aturan**: Metode `ApiService().reset()` yang memutus dan membuat ulang seluruh koneksi HTTP **hanya boleh dipanggil di dalam fungsi `logout()`**. Dilarang memanggil `reset()` di fungsi `login()`, constructor, atau lifecycle widget manapun.
* **Alasan**: Memanggil `reset()` sebelum setiap `login()` akan memutus paksa semua koneksi TCP aktif (`force: true`), sehingga server membalas dengan "Connection reset by peer" dan "closed before full header" pada request yang langsung menyusul setelahnya.
