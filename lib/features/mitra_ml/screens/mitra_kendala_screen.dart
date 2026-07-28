import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/api_constants.dart';
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

  final List<Map<String, dynamic>> _maintenanceVideos = [
    {
      'title': 'Panduan Maintenance Mesin Cuci Samsung',
      'duration': '03:30',
      'tag': 'MESIN RUSAK',
      'url': '${ApiConstants.rootUrl}/nyutji-storage/video/washer_samsung.mp4',
      'fallbackUrl': '${ApiConstants.rootUrl}/storage/video/washer_samsung.mp4',
      'icon': LucideIcons.wrench,
      'color': const Color(0xFF1E5655),
      'description': 'Panduan praktis maintenance unit mesin cuci Samsung, pembersihan saringan kotoran, katup buang, serta pemeliharaan putaran tabung.',
    },
    {
      'title': 'Penanganan Eror Air & Sensor Saluran Masuk',
      'duration': '03:12',
      'tag': 'AIR BERMASALAH',
      'url': '${ApiConstants.rootUrl}/nyutji-storage/video/water_sensor.mp4',
      'fallbackUrl': '${ApiConstants.rootUrl}/storage/video/water_sensor.mp4',
      'icon': LucideIcons.droplets,
      'color': const Color(0xFF0284C7),
      'description': 'Solusi cepat saat sensor debit air mengalami kendala atau kran inlet tersumbat kotoran halus.',
    },
    {
      'title': 'Perawatan Rutin Tabung & Sabuk Pemutar (Belt)',
      'duration': '04:05',
      'tag': 'MAINTENANCE',
      'url': '${ApiConstants.rootUrl}/nyutji-storage/video/belt_maintenance.mp4',
      'fallbackUrl': '${ApiConstants.rootUrl}/storage/video/belt_maintenance.mp4',
      'icon': LucideIcons.cog,
      'color': const Color(0xFFD97706),
      'description': 'Tips pengecekan berkala kekencangan belt motor dan desinfeksi tabung stainless agar bebas bau dan higienis.',
    },
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showVideoPlayer(Map<String, dynamic> videoData) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => _VideoPlayerModal(videoData: videoData),
    );
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
              // ── Preview & List Video Maintenance (Di atas Tipe Kendala) ──────
              _buildSectionTitle('Panduan & Maintenance Mesin', LucideIcons.film),
              const SizedBox(height: 14),
              SizedBox(
                height: 155,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: _maintenanceVideos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = _maintenanceVideos[index];
                    return _buildVideoCard(item);
                  },
                ),
              ),
              const SizedBox(height: 28),

              // ── Tipe Kendala ───────────────────────────────────────────────
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
              
              // ── Prioritas ──────────────────────────────────────────────────
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
              
              // ── Deskripsi Kejadian ──────────────────────────────────────────
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

  Widget _buildVideoCard(Map<String, dynamic> item) {
    final Color itemColor = item['color'] ?? primaryTeal;
    final IconData icon = item['icon'] ?? LucideIcons.playCircle;

    return GestureDetector(
      onTap: () => _showVideoPlayer(item),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: itemColor.withValues(alpha: 0.20), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['tag'] ?? 'TUTORIAL',
                    style: GoogleFonts.montserrat(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: itemColor,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 12, color: textGrey),
                    const SizedBox(width: 4),
                    Text(
                      item['duration'] ?? '',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: itemColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
              decoration: BoxDecoration(
                color: itemColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.play, size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Putar Panduan Video',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

// ── In-App Video Player Pop-Up Dialog ───────────────────────────────────────
class _VideoPlayerModal extends StatefulWidget {
  final Map<String, dynamic> videoData;
  const _VideoPlayerModal({required this.videoData});

  @override
  State<_VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<_VideoPlayerModal> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  VideoPlayerController _createController(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return VideoPlayerController.networkUrl(Uri.parse(path));
    }
    return VideoPlayerController.asset(path);
  }

  Future<void> _initPlayer() async {
    final String mainUrl = (widget.videoData['url'] ?? widget.videoData['assetPath'] ?? '').toString();
    final String fallbackUrl = (widget.videoData['fallbackUrl'] ?? widget.videoData['fallbackPath'] ?? '').toString();

    try {
      if (mainUrl.isNotEmpty) {
        _controller = _createController(mainUrl);
        await _controller!.initialize();
      } else {
        throw Exception('No primary video URL');
      }
    } catch (_) {
      try {
        _controller?.dispose();
        if (fallbackUrl.isNotEmpty) {
          _controller = _createController(fallbackUrl);
          await _controller!.initialize();
        } else {
          throw Exception('No fallback video URL');
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
        return;
      }
    }

    if (mounted && _controller != null && _controller!.value.isInitialized) {
      setState(() {
        _isInitialized = true;
      });
      _controller!.play();
      setState(() {
        _isPlaying = true;
      });
      _controller!.addListener(_onPlayerStateChanged);
    }
  }

  void _onPlayerStateChanged() {
    if (!mounted || _controller == null) return;
    final isPlaying = _controller!.value.isPlaying;
    if (isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerStateChanged);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double screenHeight = mediaQuery.size.height;
    final double bottomInset = mediaQuery.padding.bottom;
    final double dynamicBottomPadding = 16.0 + (bottomInset > 0 ? bottomInset * 0.4 : 4.0);

    // Ketinggian frame video portrait dinamis (memenuhi layar HP secara memanjang & tinggi)
    final double videoFrameHeight = screenHeight < 680 ? 380.0 : (screenHeight < 800 ? 460.0 : 520.0);
    final double maxDialogHeight = screenHeight * 0.90;

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: screenHeight < 680 ? 16.0 : 24.0,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxDialogHeight),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Modal
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 48, 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (widget.videoData['color'] as Color? ?? const Color(0xFF1E5655)).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.videoData['tag'] ?? 'TUTORIAL',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.videoData['title'] ?? 'Panduan Video',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Video Player Display Frame (Diperpanjang Memanjang Vertikal untuk Portrait Video)
                      Container(
                        width: double.infinity,
                        height: videoFrameHeight,
                        color: Colors.black,
                        child: _hasError
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.videoOff, size: 40, color: Colors.white54),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Gagal memuat streaming video dari server Nyutji.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : !_isInitialized
                                ? const Center(
                                    child: CircularProgressIndicator(color: Color(0xFF1E5655)),
                                  )
                                : GestureDetector(
                                    onTap: () {
                                      if (_controller != null) {
                                        if (_isPlaying) {
                                          _controller!.pause();
                                        } else {
                                          _controller!.play();
                                        }
                                      }
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Center(
                                          child: AspectRatio(
                                            aspectRatio: _controller!.value.aspectRatio > 0
                                                ? _controller!.value.aspectRatio
                                                : 9 / 16,
                                            child: VideoPlayer(_controller!),
                                          ),
                                        ),
                                        if (!_isPlaying)
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.55),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(LucideIcons.play, size: 40, color: Colors.white),
                                          ),
                                      ],
                                    ),
                                  ),
                      ),

                      // Controls Bar
                      if (_isInitialized && _controller != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Color(0xFF1E5655),
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white10,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isPlaying ? LucideIcons.pause : LucideIcons.play,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (_isPlaying) {
                                    _controller!.pause();
                                  } else {
                                    _controller!.play();
                                  }
                                },
                              ),
                              ValueListenableBuilder(
                                valueListenable: _controller!,
                                builder: (context, VideoPlayerValue value, _) {
                                  return Text(
                                    '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  _isMuted ? LucideIcons.volumeX : LucideIcons.volume2,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isMuted = !_isMuted;
                                    _controller!.setVolume(_isMuted ? 0.0 : 1.0);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Description
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Text(
                          widget.videoData['description'] ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.45,
                          ),
                        ),
                      ),
                      SizedBox(height: dynamicBottomPadding),
                    ],
                  ),
                ),
              ),
            ),
            // Floating Close Button
            Positioned(
              top: -12,
              right: -12,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.x, size: 18, color: Color(0xFF1E5655)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
