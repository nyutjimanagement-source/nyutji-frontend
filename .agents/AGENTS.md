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

### 16. Penggunaan Local Font GoogleFonts (Offline-First)
* **Aturan**: Aplikasi memblokir unduhan font dari internet saat runtime (`GoogleFonts.config.allowRuntimeFetching = false`). Oleh karena itu, semua penggunaan font (seperti `GoogleFonts.montserrat(...)`) harus menggunakan kombinasi `fontWeight` dan `fontStyle` yang secara spesifik memiliki file `.ttf` pendukung di dalam folder `assets/google_fonts/`.
* **Solusi**: Hanya gunakan varian font yang fisiknya tersedia secara lokal. Misalnya, untuk membuat teks miring, pastikan menggunakan `fontWeight: FontWeight.w400` dengan `fontStyle: FontStyle.italic` (merujuk ke file `Montserrat-Italic.ttf`). Hindari kombinasi tidak standar seperti `FontWeight.w600` + `FontStyle.italic` jika file `Montserrat-SemiBoldItalic.ttf` tidak ada di folder assets, karena hal tersebut akan memicu *runtime exception* dan membuat aplikasi *freeze*.

### 17. Desain Model Counter Hybrid (Slider + Tombol Presisi)
* **Aturan**: Setiap fitur input kuantitas/angka dinamis (seperti volume bahan kimia, jumlah item, dll.) yang memerlukan penyetelan cepat sekaligus presisi wajib mengadopsi **Model Counter Hybrid**.
* **Implementasi**:
  1. **Komponen Pendukung**: Sediakan tombol Minus (`IconButton` dengan ikon minus) di kiri, `Slider` di tengah, dan tombol Plus (`IconButton` dengan ikon plus) di kanan.
  2. **Presisi & Interval**: Interval kenaikan/penurunan tombol (misalnya `0.1` atau `1.0`) dan tingkat presisi desimal deselerasi harus dapat dikonfigurasi sesuai kebutuhan bisnis.
  3. **Visual Badge**: Letakkan badge penampil kuantitas (rounded card atau capsule badge) di lokasi yang strategis (misal kanan atas atau di tengah) sesuai kebutuhan layout.
  4. **Estetika & Animasi Slider**:
     - **Warna**: Slider wajib menggunakan warna utama brand (`primaryTeal` untuk aktif, `Color(0xFFF3F4F6)` atau abu-abu ultra-light untuk tidak aktif).
     - **Garis Track**: Gunakan ketebalan track yang tipis dan elegan (misal: `trackHeight: 4.0` menggunakan custom `SliderTheme`).
     - **Animasi & Efek Sentuh**: Pasang efek lingkar transparan (*overlay overlayRadius: 16.0*) dengan opasitas tipis (`primaryTeal.withValues(alpha: 0.12)`) saat slider ditekan dan digeser untuk memberikan feedback taktil yang halus.

### 18. Desain Efek Garis Atas (Top Indicator Line) untuk Menu & Tab
* **Aturan**: Setiap indikator penanda tab aktif (baik pada Bottom Navigation Bar, custom sub-menu selector, atau custom TabBar) wajib mengadopsi desain **Top Indicator Line** yang konsisten dengan estetika brand.
* **Implementasi**:
  1. **Warna**: Wajib menggunakan warna branding utama yang sesuai dengan tema peran layar (misal: `primaryTeal` untuk Mitra/Kurir, `plPrimary` untuk Customer, `accentGold` untuk Admin). Dilarang keras menggunakan warna abu-abu statis atau warna luar yang tidak relevan.
  2. **Bentuk & Efek**: Harus memiliki ketebalan `3.0` (height) dengan lebar `60.0` (width) terpusat pada tab aktif. Sudut bagian bawah wajib melengkung (`borderRadius` dengan `bottomLeft` & `bottomRight` ber-radius `3.0`). Dilengkapi dengan bayangan berpendar tipis (`BoxShadow` dengan blurRadius `4.0`, offset `Offset(0, 1)`, dan warna yang sesuai dengan brand ber-opasitas `0.5` / `withValues(alpha: 0.5)`).
  3. **Transisi**: Perpindahan posisi garis indikator saat menu/tab ditekan atau digeser wajib menggunakan animasi perpindahan dinamis (`AnimatedPositioned`) with durasi transisi `300ms` sampai `400ms` dan kurva transisi `Curves.easeInOut` atau `Curves.easeOutQuint` untuk gerakan yang sangat halus.

### 19. Desain Layout Anti-Pecah & Responsif Skala Teks (Responsive Text Scale & FittedBox)
* **Aturan**: Setiap elemen UI dengan tata letak padat, ringkas, atau berkolom banyak (seperti kalender harian, tombol keyboard custom, panel indikator kecil, atau badge status mikro) wajib diproteksi agar tidak pecah/meluber akibat resolusi layar ponsel yang sempit maupun karena pengaturan ukuran font sistem yang besar.
* **Implementasi**:
  1. **Penguncian Skala Teks (TextScaler Lock)**: Bungkus kontainer atau area tata letak padat tersebut dengan widget `MediaQuery` kustom yang menyetel `textScaler: const TextScaler.linear(1.0)`. Ini memastikan proporsi layout tetap konsisten dan tidak rusak oleh pengaturan aksesibilitas font global pengguna.
  2. **Pengecilan Teks Otomatis (BoxFit ScaleDown)**: Bungkus teks status atau teks dinamis di dalam badge/tombol berukuran mikro dengan widget `FittedBox` dengan properti `fit: BoxFit.scaleDown`. Ini memaksa teks menyusut secara otomatis dan tetap berada dalam satu baris (single line) daripada patah menjadi dua baris atau terpotong jika ruang horizontal terlalu sempit.

---

## III. Standar Database & Relasi Tabel

### 1. Penggunaan orderNumber sebagai Primary Key Tabel Orders
* **Aturan**: Tabel "orders" secara mutlak menggunakan "orderNumber" (dengan format *string* kustom, contoh: "SRP-20260529-1782") sebagai *Primary Key*. Dilarang keras menggunakan, mencari, atau menambahkan kolom "id" pada tabel "orders" maupun referensi *foreign key*-nya di tabel lain.
* **Implementasi**:
  1. Saat mencari data (*query*) menggunakan Sequelize (misal: "Order.findOne"), hanya gunakan parameter "where: { orderNumber: ... }".
  2. Hapus dan hindari logika *fallback* pencarian yang melibatkan kolom "id" (misal: "{ id: isNaN(orderNumber) ? null : parseInt(orderNumber) }").
  3. Seluruh tabel relasi (seperti "order_items", "order_attachment") yang terhubung ke pesanan wajib menggunakan kolom bertipe *string* yang merujuk langsung ke "orderNumber".

### 2. Sinkronisasi & Migrasi Database Mandiri (Shared Hosting / cPanel)
* **Aturan**: Mengingat Nyutji di-deploy pada lingkungan shared hosting cPanel yang membatasi eksekusi migrasi otomatis atau CLI global (seperti `sequelize-cli db:migrate` atau auto-sync pada runtime server `index.js` karena masalah hak akses/resource limit), maka pembuatan atau perubahan tabel database wajib menggunakan berkas script sinkronisasi mandiri yang dapat dijalankan secara manual.
* **Implementasi**:
  1. Buat script sinkronisasi khusus di root backend (misalnya `sync_nama_tabel.js`).
  2. Muat konfigurasi `.env` secara manual di dalam script.
  3. Hubungkan ke Sequelize dan panggil sinkronisasi model spesifik menggunakan `await Model.sync({ alter: true })`.
  4. Jalankan script ini secara manual melalui terminal cPanel dengan perintah: `node sync_nama_tabel.js`.

### 3. Penanganan Rentang Tanggal Bulan Dinamis (Pencegahan SQL Incorrect DATE Value)
* **Aturan**: Saat melakukan penarikan data (query database) berdasarkan rentang bulan (misalnya mengambil data dari tanggal 1 sampai akhir bulan), dilarang keras melakukan hardcoding tanggal akhir dengan `-31` (seperti `yyyy-MM-31`).
* **Alasan**: Bulan-bulan tertentu (seperti Februari, April, Juni, September, November) tidak memiliki 31 hari. Query basis data MySQL/MariaDB dengan nilai tanggal tidak valid seperti `2026-06-31` akan memicu error `Incorrect DATE value` (Internal Server Error 500) pada mode SQL ketat.
* **Implementasi (Backend Node.js/Sequelize)**:
  Selalu hitung hari terakhir dari bulan secara dinamis sebelum melakukan query:
  ```javascript
  const parts = month.split('-'); // Format 'yyyy-MM'
  const year = parseInt(parts[0], 10);
  const monthNum = parseInt(parts[1], 10);
  const lastDay = new Date(year, monthNum, 0).getDate(); // Menghasilkan jumlah hari asli (28, 29, 30, atau 31)
  const startDate = `${month}-01`;
  const endDate = `${month}-${String(lastDay).padStart(2, '0')}`;
  ```

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

### 4. Metode Type-Safe Cache & API Parsing (Penanganan TypeError Bersarang)
* **Aturan**: Setiap kali membaca atau mengurai data JSON bersarang (seperti list dari map) yang dimuat dari `CacheService` atau respons `ApiService` (Dio), dilarang keras melakukan casting tipe langsung menggunakan `List<Map<String, dynamic>>.from(...)` atau `as List<Map<String, dynamic>>`.
* **Alasan**: Pustaka parser JSON internal pada Dart/Dio/Hive menginstansiasi objek bersarang sebagai tipe `Map<dynamic, dynamic>` (atau `_InternalLinkedHashMap<dynamic, dynamic>`). Melakukan cast langsung ke `Map<String, dynamic>` akan memicu crash `TypeError` saat runtime.
* **Implementasi**:
  1. Gunakan pemetaan eksplisit untuk mengubah setiap objek di dalam list secara aman menggunakan `Map<String, dynamic>.from(item as Map)`:
     ```dart
     // Contoh konversi list of maps yang aman:
     final List<dynamic> rawList = response.data['data'] ?? [];
     final List<Map<String, dynamic>> typedList = rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
     ```
  2. Bungkus proses parsing cache dan API di dalam blok `try-catch` untuk menghindari crash silent yang dapat memblokir pembaruan state antarmuka.

---

## V. Standar Version Control (Git)

### 1. Penulisan Pesan Commit Wajib Bahasa Indonesia
* **Aturan**: Setiap kali melakukan komit kode (*git commit*), pesan komit wajib ditulis dalam **Bahasa Indonesia** yang ringkas, jelas, dan menggambarkan perubahan yang dilakukan secara presisi.
* **Format**: Gunakan tipe prefiks standar (seperti `feat:`, `fix:`, `style:`, `refactor:`, `docs:`) diikuti dengan penjelasan dalam bahasa Indonesia.
  * *Contoh*: `feat: tambah bubble merah draft pesanan pada keranjang di home screen PL`
  * *Contoh*: `fix: perbaikan type-safety parsing data cache`
