import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../utils/app_translations.dart';

class CustomCameraArScreen extends StatefulWidget {
  final String title;
  final String initialTab;

  const CustomCameraArScreen({
    super.key,
    required this.title,
    this.initialTab = 'stack',
  });

  @override
  State<CustomCameraArScreen> createState() => _CustomCameraArScreenState();
}

class _CustomCameraArScreenState extends State<CustomCameraArScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  ObjectDetector? _objectDetector;

  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  String _cameraError = '';

  int _targetItemCount = 3; // Default 3 barang (bisa diatur 2 - 8)
  late TextEditingController _itemCountController;

  final List<Rect> _visibleObjectRects = <Rect>[];
  final List<Offset> _manualTapPoints = <Offset>[];
  final Set<int> _taggedRectIndices = <int>{};

  bool _isManualSelection = false;
  String _classifiedStructure = 'STACK'; // 'STACK', 'LINKED_LIST', 'QUEUE', 'BUBBLE_SORT', 'SELECTION_SORT', 'LINEAR_SEARCH', 'BINARY_SEARCH'
  Size _imageSize = Size.zero;
  CameraDescription? _cameraDescription;
  DateTime? _lastProcessTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _itemCountController = TextEditingController(text: '3');
    _initializeMlKitDetector();
    _initializeCamera();
  }

  void _initializeMlKitDetector() {
    final ObjectDetectorOptions options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: false,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = 'Kamera tidak ditemukan pada perangkat ini.';
          });
        }
        return;
      }

      final CameraDescription cameraDesc = cameras.firstWhere(
            (CameraDescription cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraDescription = cameraDesc;

      final CameraController controller = CameraController(
        cameraDesc,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      _cameraController = controller;
      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      _startImageStream();
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Gagal memuat kamera AR: $e';
        });
      }
    }
  }

  void _startImageStream() {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isStreamingImages) return;

    controller.startImageStream((CameraImage image) {
      if (_isProcessingFrame) return;

      final DateTime now = DateTime.now();
      if (_lastProcessTime != null &&
          now.difference(_lastProcessTime!) < const Duration(milliseconds: 350)) {
        return;
      }
      _lastProcessTime = now;

      _isProcessingFrame = true;
      _processCameraFramePassively(image);
    });
  }

  Future<void> _processCameraFramePassively(CameraImage image) async {
    final ObjectDetector? detector = _objectDetector;
    final CameraDescription? desc = _cameraDescription;
    if (detector == null || desc == null) {
      _isProcessingFrame = false;
      return;
    }

    final InputImage? inputImage = _inputImageFromCameraImage(image, desc);
    if (inputImage == null) {
      _isProcessingFrame = false;
      return;
    }

    try {
      final List<DetectedObject> objects = await detector.processImage(inputImage);

      if (mounted) {
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        final Size screenSize = renderBox?.size ??
            Size(MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height);

        final double scaleX = screenSize.width / image.height.toDouble();
        final double scaleY = screenSize.height / image.width.toDouble();

        final List<Rect> rects = <Rect>[];
        for (final DetectedObject obj in objects) {
          final Rect rawBox = obj.boundingBox;
          final Rect scaledBox = Rect.fromLTRB(
            rawBox.left * scaleX,
            rawBox.top * scaleY,
            rawBox.right * scaleX,
            rawBox.bottom * scaleY,
          );
          rects.add(scaledBox);
        }

        setState(() {
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          _visibleObjectRects.clear();
          _visibleObjectRects.addAll(rects);
        });
      }
    } catch (e) {
      debugPrint('Error ML Kit Passive Object Detection: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription description) {
    final int sensorOrientation = description.sensorOrientation;
    InputImageRotation? rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    rotation ??= InputImageRotation.rotation0deg;

    final InputImageFormat? format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;
    final Plane plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _handleManualTap(TapDownDetails details, BoxConstraints constraints) {
    final bool isEn = LanguageController.instance.isEnglish;
    final Offset localPos = details.localPosition;

    // 1. Kunci Batas Maksimal Jumlah Barang yang Dimasukkan
    if (_manualTapPoints.length >= _targetItemCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'Reached limit of $_targetItemCount items! Tap Reset to start over.'
                : 'Sudah mencapai batas $_targetItemCount barang! Tekan Reset untuk mengulang.',
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 2. Anti-Double Tap: Jika jarak ketukan baru dengan titik terpasang < 35.0 piksel
    for (final Offset pt in _manualTapPoints) {
      if ((localPos - pt).distance < 35.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn ? 'This item is already tagged!' : 'Barang ini sudah ditandai!',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
        return;
      }
    }

    setState(() {
      _manualTapPoints.add(localPos);
      _analyzeTapPattern();
    });
  }

  void _analyzeTapPattern() {
    if (_isManualSelection) return;
    if (_manualTapPoints.length < 2) return;

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    double totalDist = 0.0;
    for (int i = 0; i < _manualTapPoints.length; i++) {
      final Offset pt = _manualTapPoints[i];
      if (pt.dx < minX) minX = pt.dx;
      if (pt.dx > maxX) maxX = pt.dx;
      if (pt.dy < minY) minY = pt.dy;
      if (pt.dy > maxY) maxY = pt.dy;

      if (i > 0) {
        totalDist += (pt - _manualTapPoints[i - 1]).distance;
      }
    }

    final double deltaX = maxX - minX;
    final double deltaY = maxY - minY;
    final double avgDistance = totalDist / (_manualTapPoints.length - 1);

    // 1. Pola Vertikal (Delta Y > Delta X * 1.2) -> STACK
    if (deltaY > deltaX * 1.2) {
      _classifiedStructure = 'STACK';
      return;
    }

    // 2. Pola Horizontal (Delta X >= Delta Y)
    if (_targetItemCount <= 3) {
      if (avgDistance < 95.0) {
        _classifiedStructure = 'QUEUE';
      } else {
        _classifiedStructure = 'LINKED_LIST';
      }
    } else {
      // 4+ Barang: Default BUBBLE_SORT
      _classifiedStructure = 'BUBBLE_SORT';
    }
  }

  void _updateTargetItemCount(int newCount) {
    int clamped = newCount;
    if (clamped < 2) clamped = 2;
    if (clamped > 8) clamped = 8;

    setState(() {
      _targetItemCount = clamped;
      _itemCountController.text = clamped.toString();
      _manualTapPoints.clear();
      _taggedRectIndices.clear();
      _isManualSelection = false;
    });
  }

  Future<void> _refreshScanner() async {
    final bool isEn = LanguageController.instance.isEnglish;

    setState(() {
      _manualTapPoints.clear();
      _taggedRectIndices.clear();
      _visibleObjectRects.clear();
      _classifiedStructure = 'STACK';
      _isManualSelection = false;
    });

    try {
      await _objectDetector?.close();
      _initializeMlKitDetector();
    } catch (e) {
      debugPrint('Error reset ML Kit detector: $e');
    }

    final CameraController? controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('Error reset camera focus: $e');
      }

      if (controller.value.isStreamingImages) {
        try {
          await controller.stopImageStream();
        } catch (_) {}
      }
      _startImageStream();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'AR tap points reset. Ready for new arrangement.'
                : 'Titik AR direset. Siap memindai susunan baru.',
          ),
          backgroundColor: const Color(0xFF00F0FF),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showObjectArrangementGuideSheet(bool isEn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.82,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            color: Color(0xFF00F0FF), size: 22),
                        const SizedBox(width: 10),
                        Text(
                          isEn
                              ? 'AR Object Arrangement Guide'
                              : 'Panduan Benda & Cara Menyusun AR',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn
                              ? 'Tap physical items on your desk. AR automatically classifies data structures based on tap positions and item sizes:'
                              : 'Ketuk titik benda fisik di meja belajarmu. AR otomatis mengklasifikasikan struktur data berdasarkan pola posisi dan ukuran benda:',
                          style: const TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.4),
                        ),
                        const SizedBox(height: 14),

                        _buildGuideCard(
                          icon: Icons.layers_rounded,
                          title: '1. Stack (LIFO)',
                          itemExample: isEn
                              ? 'Everyday Items: 3–4 books, plates, or boxes.'
                              : 'Contoh Benda: 3–4 buku, piring, atau kotak.',
                          arrangement: isEn
                              ? 'How to Arrange: Stack vertically straight upward (TOP at peak, BASE at bottom).'
                              : 'Cara Menyusun: Tumpuk vertikal lurus ke atas (TOP di atas, BASE di bawah).',
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 10),

                        _buildGuideCard(
                          icon: Icons.link_rounded,
                          title: '2. Linked List',
                          itemExample: isEn
                              ? 'Everyday Items: 3–4 erasers, pens, or small boxes.'
                              : 'Contoh Benda: 3–4 penghapus, pulpen, atau kotak kecil.',
                          arrangement: isEn
                              ? 'How to Arrange: Align horizontally with spacing (~3–5 cm) to reveal Next ➔ pointer arrows, HEAD, and NULL.'
                              : 'Cara Menyusun: Jejerkan mendatar berjarak renggang (~3–5 cm) untuk memunculkan panah Next ➔, HEAD, dan NULL.',
                          color: const Color(0xFF00F0FF),
                        ),
                        const SizedBox(height: 10),

                        _buildGuideCard(
                          icon: Icons.people_alt_rounded,
                          title: '3. Queue (FIFO)',
                          itemExample: isEn
                              ? 'Everyday Items: 3–4 water bottles, cups, or shoes.'
                              : 'Contoh Benda: 3–4 botol minum, gelas, atau sandal.',
                          arrangement: isEn
                              ? 'How to Arrange: Align tightly in a straight horizontal queue (FRONT at left, REAR at right).'
                              : 'Cara Menyusun: Jejerkan mendatar rapat satu baris seperti antrean (FRONT di kiri, REAR di kanan).',
                          color: const Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 10),

                        _buildGuideCard(
                          icon: Icons.swap_horiz_rounded,
                          title: '4. Bubble Sort',
                          itemExample: isEn
                              ? 'Everyday Items: 4 standing bottles or books of different heights.'
                              : 'Contoh Benda: 4 botol atau buku berdiri dengan tinggi berbeda.',
                          arrangement: isEn
                              ? 'How to Arrange: Place 4 items left-to-right randomly to observe pairwise adjacent comparisons [i] ↔ [i+1].'
                              : 'Cara Menyusun: Jejerkan 4 benda acak dari kiri ke kanan untuk melihat perbandingan bersebelahan [i] ↔ [i+1].',
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 10),

                        _buildGuideCard(
                          icon: Icons.low_priority_rounded,
                          title: '5. Selection Sort',
                          itemExample: isEn
                              ? 'Everyday Items: 4 items of varied sizes or heights.'
                              : 'Contoh Benda: 4 benda berbeda ukuran atau tinggi.',
                          arrangement: isEn
                              ? 'How to Arrange: Place 4 items to observe minimum element (MIN) highlighting and swapping to index [0].'
                              : 'Cara Menyusun: Jejerkan 4 benda untuk melihat penandaan elemen terkecil (MIN) yang ditukar ke indeks [0].',
                          color: const Color(0xFFEC4899),
                        ),
                        const SizedBox(height: 10),

                        _buildGuideCard(
                          icon: Icons.find_in_page_rounded,
                          title: '6. Linear Search',
                          itemExample: isEn
                              ? 'Everyday Items: 4–5 different items randomly placed.'
                              : 'Contoh Benda: 4–5 benda berbeda secara acak (tidak perlu urut).',
                          arrangement: isEn
                              ? 'How to Arrange: Align items horizontally for sequential inspection starting from index [0].'
                              : 'Cara Menyusun: Jejerkan mendatar untuk simulasi pencarian berurutan dari indeks [0].',
                          color: const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(height: 10),

                        _buildGuideCard(
                          icon: Icons.center_focus_strong_rounded,
                          title: '7. Binary Search',
                          itemExample: isEn
                              ? 'Everyday Items: 5 bottles or books pre-sorted from shortest to tallest.'
                              : 'Contoh Benda: 5 botol atau buku yang sudah diurutkan dari terpendek ke tertinggi.',
                          arrangement: isEn
                              ? 'How to Arrange: Align in strict ascending order so AR highlights the Midpoint (MID) directly.'
                              : 'Cara Menyusun: Jejerkan terurut dari terpendek ke tertinggi agar AR langsung menyorot titik tengah (MID).',
                          color: const Color(0xFF06B6D4),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required String title,
    required String itemExample,
    required String arrangement,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF060913),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            itemExample,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 3),
          Text(
            arrangement,
            style: const TextStyle(fontSize: 10.5, color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }

  String _getStructureExplanationText(bool isEn) {
    switch (_classifiedStructure) {
      case 'STACK':
        return isEn
            ? 'STACK (LIFO): Highest point is TOP (Push/Pop), lowest point is BASE.'
            : 'STACK (LIFO): Titik tertinggi adalah TOP (Push/Pop), titik terendah adalah BASE.';
      case 'LINKED_LIST':
        return isEn
            ? 'LINKED LIST: First point is HEAD, connected by Next ➔ pointer towards NULL.'
            : 'LINKED LIST: Titik pertama adalah HEAD, dihubungkan oleh pointer Next ➔ menuju NULL.';
      case 'QUEUE':
        return isEn
            ? 'QUEUE (FIFO): Leftmost point is FRONT (Dequeue), rightmost point is REAR (Enqueue).'
            : 'QUEUE (FIFO): Titik paling kiri adalah FRONT (Dequeue), titik paling kanan adalah REAR (Enqueue).';
      case 'BUBBLE_SORT':
        return isEn
            ? 'BUBBLE SORT: Compares and swaps adjacent elements [i] ↔ [i+1].'
            : 'BUBBLE SORT: Membandingkan & menukar elemen bersebelahan [i] ↔ [i+1].';
      case 'SELECTION_SORT':
        return isEn
            ? 'SELECTION SORT: Finds minimum element (MIN) and swaps it to index [0].'
            : 'SELECTION SORT: Mencari elemen terkecil (MIN) dan menukarnya ke indeks [0].';
      case 'LINEAR_SEARCH':
        return isEn
            ? 'LINEAR SEARCH: Sequentially inspects elements from index [0] to [n].'
            : 'LINEAR SEARCH: Memeriksa elemen berurutan satu per satu dari indeks [0].';
      case 'BINARY_SEARCH':
        return isEn
            ? 'BINARY SEARCH: Divides search space in half and highlights midpoint MID.'
            : 'BINARY SEARCH: Membagi dua ruang pencarian dan menyorot titik tengah MID.';
      default:
        return isEn
            ? 'Tap physical items on screen to detect Data Structure pattern.'
            : 'Ketuk titik benda fisik di layar untuk memindai pola Struktur Data.';
    }
  }

  Widget _buildStructureChip(String typeKey, String label, Color color) {
    final bool isSelected = _classifiedStructure == typeKey;

    return InkWell(
      onTap: () {
        setState(() {
          _classifiedStructure = typeKey;
          _isManualSelection = true;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Colors.white70,
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream().catchError((_) {});
      }
      controller.dispose();
      _isCameraInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _itemCountController.dispose();

    final CameraController? controller = _cameraController;
    if (controller != null && controller.value.isStreamingImages) {
      controller.stopImageStream().catchError((_) {});
    }
    controller?.dispose();
    _cameraController = null;

    _objectDetector?.close();
    _objectDetector = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = LanguageController.instance.isEnglish;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Kamera Native Preview Feed & Tap Gesture Detector
          if (_isCameraInitialized && _cameraController != null)
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return GestureDetector(
                  onTapDown: (TapDownDetails details) =>
                      _handleManualTap(details, constraints),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_cameraController!),
                      // 2. CustomPainter Canvas Overlay untuk Rendering Bounding Box & Pointer Badges
                      CustomPaint(
                        painter: ArTapOverlayPainter(
                          manualTapPoints: _manualTapPoints,
                          classifiedStructure: _classifiedStructure,
                          imageSize: _imageSize,
                          isEnglish: isEn,
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else if (_cameraError.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _cameraError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
            ),

          // 3. Top Header Bar (Navigasi Back, Judul, Panduan, & Rescan)
          Positioned(
            top: 45,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      isEn ? 'AR Data Structure Scanner' : 'Pemindai AR Struktur Data',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  child: IconButton(
                    icon: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF00F0FF)),
                    tooltip: isEn ? 'AR Setup Guide' : 'Panduan Benda AR',
                    onPressed: () => _showObjectArrangementGuideSheet(isEn),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00F0FF)),
                    tooltip: isEn ? 'Rescan' : 'Scan Ulang',
                    onPressed: _refreshScanner,
                  ),
                ),
              ],
            ),
          ),

          // 4. Sub-Header Control Bar: Input Jumlah Barang & Indikator Progres
          Positioned(
            top: 95,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Text(
                    isEn ? 'Item Count:' : 'Jumlah Barang:',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _updateTargetItemCount(_targetItemCount - 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.remove_rounded, color: Color(0xFF00F0FF), size: 14),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: TextField(
                      controller: _itemCountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00F0FF),
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (String val) {
                        final int? parsed = int.tryParse(val.trim());
                        if (parsed != null) {
                          _updateTargetItemCount(parsed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: () => _updateTargetItemCount(_targetItemCount + 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Color(0xFF00F0FF), size: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 14,
                    width: 1,
                    color: Colors.white24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isEn
                            ? 'Tagged: ${_manualTapPoints.length} / $_targetItemCount (${_classifiedStructure.replaceAll("_", " ")})'
                            : 'Ditandai: ${_manualTapPoints.length} / $_targetItemCount (${_classifiedStructure.replaceAll("_", " ")})',
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Bottom Control Panel & Kartu Keterangan Struktur Data
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kartu Penjelasan Keterangan Struktur Data Aktif
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF00F0FF), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getStructureExplanationText(isEn),
                          style: const TextStyle(fontSize: 11, color: Colors.white, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Switch Selector Chips untuk Deret Titik
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStructureChip('STACK', 'STACK (LIFO)', const Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        _buildStructureChip('LINKED_LIST', 'LINKED LIST', const Color(0xFF00F0FF)),
                        const SizedBox(width: 6),
                        _buildStructureChip('QUEUE', 'QUEUE (FIFO)', const Color(0xFF3B82F6)),
                        const SizedBox(width: 6),
                        _buildStructureChip('BUBBLE_SORT', 'BUBBLE SORT', const Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        _buildStructureChip('SELECTION_SORT', 'SELECTION SORT', const Color(0xFFEC4899)),
                        const SizedBox(width: 6),
                        _buildStructureChip('LINEAR_SEARCH', 'LINEAR SEARCH', const Color(0xFF8B5CF6)),
                        const SizedBox(width: 6),
                        _buildStructureChip('BINARY_SEARCH', 'BINARY SEARCH', const Color(0xFF06B6D4)),
                      ],
                    ),
                  ),
                ),

                if (_manualTapPoints.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _manualTapPoints.clear();
                          _taggedRectIndices.clear();
                          _isManualSelection = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                      label: Text(
                        isEn ? 'Reset Tap Points' : 'Reset Titik Benda',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ArTapOverlayPainter extends CustomPainter {
  final List<Offset> manualTapPoints;
  final String classifiedStructure;
  final Size imageSize;
  final bool isEnglish;

  ArTapOverlayPainter({
    required this.manualTapPoints,
    required this.classifiedStructure,
    required this.imageSize,
    required this.isEnglish,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (manualTapPoints.isEmpty) {
      _paintCenterReticle(
        canvas,
        size,
        promptText: isEnglish
            ? 'Tap physical items on desk to tag'
            : 'Ketuk permukaan benda fisik di meja',
      );
      return;
    }

    final Paint pointPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    final Paint linePaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final List<Offset> points = List<Offset>.from(manualTapPoints);

    if (classifiedStructure == 'STACK') {
      points.sort((Offset a, Offset b) => a.dy.compareTo(b.dy));
    } else {
      points.sort((Offset a, Offset b) => a.dx.compareTo(b.dx));
    }

    for (int i = 0; i < points.length; i++) {
      final Offset pt = points[i];

      canvas.drawCircle(pt, 16, pointPaint);
      canvas.drawCircle(
        pt,
        22,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      String label = '';
      Color labelColor = const Color(0xFF10B981);

      if (classifiedStructure == 'STACK') {
        if (i == 0) {
          label = isEnglish ? 'TOP (LIFO Peak)' : 'TOP (Atas)';
          labelColor = const Color(0xFF10B981);
        } else if (i == points.length - 1) {
          label = isEnglish ? 'BASE' : 'BASE (Dasar)';
          labelColor = const Color(0xFFF59E0B);
        } else {
          label = 'NODE [$i]';
        }
      } else if (classifiedStructure == 'QUEUE') {
        if (i == 0) {
          label = isEnglish ? 'FRONT (FIFO)' : 'FRONT (Depan)';
          labelColor = const Color(0xFF10B981);
        } else if (i == points.length - 1) {
          label = isEnglish ? 'REAR (IN)' : 'REAR (Belakang)';
          labelColor = const Color(0xFF00F0FF);
        } else {
          label = 'ITEM [$i]';
        }
      } else if (classifiedStructure == 'LINKED_LIST') {
        if (i == 0) {
          label = 'HEAD 🚀';
          labelColor = const Color(0xFF00F0FF);
        } else if (i == points.length - 1) {
          label = 'NEXT -> NULL 🛑';
          labelColor = const Color(0xFFEF4444);
        } else {
          label = 'NODE [$i]';
        }
      } else if (classifiedStructure == 'BUBBLE_SORT') {
        label = 'VAL [$i]';
        labelColor = const Color(0xFFF59E0B);
      } else if (classifiedStructure == 'SELECTION_SORT') {
        int minIdx = 0;
        double maxDy = -double.infinity;
        for (int k = 0; k < points.length; k++) {
          if (points[k].dy > maxDy) {
            maxDy = points[k].dy;
            minIdx = k;
          }
        }
        if (minIdx == 0 && points.length > 1) minIdx = 1;

        if (i == minIdx) {
          label = 'MIN 🎯 [$i]';
          labelColor = const Color(0xFFEC4899);
        } else if (i == 0) {
          label = 'SWAP [0]';
          labelColor = const Color(0xFF10B981);
        } else {
          label = 'VAL [$i]';
          labelColor = const Color(0xFF8B5CF6);
        }
      } else if (classifiedStructure == 'BINARY_SEARCH') {
        final int midIdx = points.length ~/ 2;
        if (i == 0) {
          label = 'LOW [$i]';
          labelColor = const Color(0xFF10B981);
        } else if (i == points.length - 1) {
          label = 'HIGH [$i]';
          labelColor = const Color(0xFFEF4444);
        } else if (i == midIdx) {
          label = 'MID 🎯 [$i]';
          labelColor = const Color(0xFF06B6D4);
        } else {
          label = 'INDEX [$i]';
          labelColor = const Color(0xFF8B5CF6);
        }
      } else if (classifiedStructure == 'LINEAR_SEARCH') {
        label = 'SCAN [$i] ➔';
        labelColor = const Color(0xFF8B5CF6);
      } else {
        label = 'INDEX [$i]';
        labelColor = const Color(0xFF8B5CF6);
      }

      _drawTextBadge(canvas, Offset(pt.dx, pt.dy - 30), label, labelColor);
    }

    // Connect tap points with lines/arrows
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
      if (classifiedStructure == 'LINKED_LIST' || classifiedStructure == 'QUEUE' || classifiedStructure == 'LINEAR_SEARCH') {
        _drawArrowHead(canvas, points[i], points[i + 1], const Color(0xFF00F0FF));
      } else if (classifiedStructure == 'BUBBLE_SORT') {
        _drawBiArrowHead(canvas, points[i], points[i + 1], const Color(0xFFF59E0B));
      }
    }
  }

  void _paintCenterReticle(Canvas canvas, Size size, {String? promptText}) {
    final Offset center = Offset(size.width / 2, size.height / 2 - 30);
    final Paint reticlePaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 40, reticlePaint);
    canvas.drawCircle(
      center,
      6,
      Paint()..color = const Color(0xFF00F0FF),
    );

    final String text = promptText ??
        (isEnglish
            ? 'Tap physical items on desk'
            : 'Ketuk permukaan benda fisik di meja');

    _drawTextBadge(canvas, Offset(center.dx, center.dy + 55), text, const Color(0xFF00F0FF));
  }

  void _drawTextBadge(Canvas canvas, Offset centerPos, String text, Color color) {
    final TextSpan span = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );

    final TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final Rect bgRect = Rect.fromCenter(
      center: centerPos,
      width: tp.width + 16,
      height: tp.height + 10,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.88),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    tp.paint(canvas, Offset(centerPos.dx - tp.width / 2, centerPos.dy - tp.height / 2));
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Color color) {
    final double angle = atan2(to.dy - from.dy, to.dx - from.dx);
    const double arrowSize = 12.0;

    final Path path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowSize * cos(angle - pi / 6),
        to.dy - arrowSize * sin(angle - pi / 6),
      )
      ..lineTo(
        to.dx - arrowSize * cos(angle + pi / 6),
        to.dy - arrowSize * sin(angle + pi / 6),
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawBiArrowHead(Canvas canvas, Offset from, Offset to, Color color) {
    _drawArrowHead(canvas, from, to, color);
    _drawArrowHead(canvas, to, from, color);
  }

  @override
  bool shouldRepaint(covariant ArTapOverlayPainter oldDelegate) => true;
}