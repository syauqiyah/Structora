import 'package:flutter/material.dart';
import '../utils/app_translations.dart';

class SpotlightStep {
  final GlobalKey key;
  final String title;
  final String desc;
  final IconData icon;
  final Color accentColor;

  SpotlightStep({
    required this.key,
    required this.title,
    required this.desc,
    required this.icon,
    required this.accentColor,
  });
}

class InteractiveSpotlightOverlay extends StatefulWidget {
  final List<SpotlightStep> steps;
  final VoidCallback onFinish;
  final bool isDarkMode;

  const InteractiveSpotlightOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
    required this.isDarkMode,
  });

  @override
  State<InteractiveSpotlightOverlay> createState() => _InteractiveSpotlightOverlayState();
}

class _InteractiveSpotlightOverlayState extends State<InteractiveSpotlightOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Rect? _getTargetRect() {
    if (_currentStepIndex >= widget.steps.length) return null;
    final currentKey = widget.steps[_currentStepIndex].key;
    final renderBox = currentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    final offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      offset.dx - 6,
      offset.dy - 6,
      renderBox.size.width + 12,
      renderBox.size.height + 12,
    );
  }

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() => _currentStepIndex++);
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetRect = _getTargetRect();
    final screenSize = MediaQuery.of(context).size;
    final currentStep = widget.steps[_currentStepIndex];

    final bool isNearBottom = targetRect != null && targetRect.bottom > (screenSize.height * 0.65);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. Kanvas Layer Hitam Transparan dengan Lubang Sorot Presisi
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: targetRect,
                    pulsePadding: _pulseAnim.value,
                    colorGlow: currentStep.accentColor,
                  ),
                );
              },
            ),
          ),

          // 2. Kartu Petunjuk Mengapung (Tooltip Card)
          if (targetRect != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: 20,
              right: 20,
              top: isNearBottom
                  ? (targetRect.top - 200).clamp(40.0, screenSize.height - 240)
                  : (targetRect.bottom + 18).clamp(40.0, screenSize.height - 240),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: currentStep.accentColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentStep.accentColor.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: currentStep.accentColor.withValues(alpha: 0.15),
                          child: Icon(currentStep.icon, size: 18, color: currentStep.accentColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentStep.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          '${_currentStepIndex + 1}/${widget.steps.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: currentStep.accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentStep.desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: widget.onFinish,
                          child: Text(
                            LanguageController.instance.isEnglish ? 'Skip' : 'Lewati',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDarkMode ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentStep.accentColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: Icon(
                            _currentStepIndex == widget.steps.length - 1
                                ? Icons.check
                                : Icons.arrow_forward,
                            size: 15,
                          ),
                          label: Text(
                            _currentStepIndex == widget.steps.length - 1
                                ? (LanguageController.instance.isEnglish ? 'Got it, Let\'s Learn!' : 'Paham, Mulai Belajar!')
                                : (LanguageController.instance.isEnglish ? 'Next' : 'Lanjut'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double pulsePadding;
  final Color colorGlow;

  _SpotlightPainter({
    required this.targetRect,
    required this.pulsePadding,
    required this.colorGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xDC030712);

    if (targetRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
      return;
    }

    final adjustedRect = Rect.fromLTRB(
      targetRect!.left - pulsePadding,
      targetRect!.top - pulsePadding,
      targetRect!.right + pulsePadding,
      targetRect!.bottom + pulsePadding,
    );

    final rrect = RRect.fromRectAndRadius(adjustedRect, const Radius.circular(16));

    // Menggambar latar gelap dengan lubang di koordinat target
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(rrect),
      ),
      backgroundPaint,
    );

    // Efek garis neon menyala mengelilingi lubang target
    final glowPaint = Paint()
      ..color = colorGlow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    canvas.drawRRect(rrect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) => true;
}