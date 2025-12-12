import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;

class FonderieCard extends StatefulWidget {
  final Map<String, dynamic> fondry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  const FonderieCard({
    super.key,
    required this.fondry,
    required this.onEdit,
    required this.onDelete,
    this.isDeleting = false,
  });

  @override
  State<FonderieCard> createState() => _FonderieCardState();
}

class _FonderieCardState extends State<FonderieCard>
    with TickerProviderStateMixin {
  late AnimationController _meltController;
  late AnimationController _dripController;
  late AnimationController _glowController;
  late AnimationController _hoverController;

  late Animation<double> _meltAnimation;
  late Animation<double> _dripAnimation;
  late Animation<double> _colorAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _hoverAnimation;

  Offset _mousePosition = Offset.zero;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _meltController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _dripController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _meltAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _meltController, curve: Curves.easeInOutCubic),
    );

    _dripAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dripController, curve: Curves.easeOutQuad),
    );

    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _meltController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInQuad),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(FonderieCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDeleting && !oldWidget.isDeleting) {
      _startMelting();
    }
  }

  void _startMelting() {
    _meltController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _dripController.forward();
    });
  }

  void _onHoverEnter(PointerEnterEvent event) {
    if (!widget.isDeleting) {
      setState(() => _isHovered = true);
      _hoverController.forward();
      HapticFeedback.selectionClick();
    }
  }

  void _onHoverExit(PointerExitEvent event) {
    if (!widget.isDeleting) {
      setState(() => _isHovered = false);
      _hoverController.reverse();
    }
  }

  void _onHoverMove(PointerHoverEvent event, Size cardSize) {
    if (!widget.isDeleting && _isHovered) {
      setState(() {
        _mousePosition = Offset(
          (event.localPosition.dx - cardSize.width / 2) / (cardSize.width / 2),
          (event.localPosition.dy - cardSize.height / 2) /
              (cardSize.height / 2),
        );
      });
    }
  }

  @override
  void dispose() {
    _meltController.dispose();
    _dripController.dispose();
    _glowController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _meltAnimation,
        _dripAnimation,
        _glowAnimation,
        _hoverAnimation,
      ]),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final cardSize = Size(constraints.maxWidth, 150);

            return MouseRegion(
              onEnter: _onHoverEnter,
              onExit: _onHoverExit,
              onHover: (event) => _onHoverMove(event, cardSize),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (_dripAnimation.value > 0) _buildDrips(),
                  if (widget.isDeleting && _meltAnimation.value > 0.3)
                    _buildLavaParticles(),
                  _buildMainCard(cardSize),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMainCard(Size cardSize) {
    final tiltX = _mousePosition.dy * 0.12 * _hoverAnimation.value;
    final tiltY = _mousePosition.dx * -0.12 * _hoverAnimation.value;
    final scale =
        1.0 + (0.04 * _hoverAnimation.value) - (0.15 * _meltAnimation.value);

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(tiltX)
        ..rotateY(tiltY)
        // ignore: deprecated_member_use
        ..translate(0.0, 40 * _meltAnimation.value)
        // ignore: deprecated_member_use
        ..scale(scale, 1.0 - (0.4 * _meltAnimation.value), 1.0),
      alignment: Alignment.center,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(-0.15 * _meltAnimation.value),
        alignment: Alignment.bottomCenter,
        child: _buildCardContent(),
      ),
    );
  }

  Widget _buildCardContent() {
    final items =
        (widget.fondry['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final totalQuantity = widget.fondry['total_quantity'] ?? 0;
    final totalCout =
        (widget.fondry['total_cout'] as num?)?.toStringAsFixed(2) ??
        widget.fondry['total_cout']?.toString() ??
        '0.00';
    final operationsCount = widget.fondry['operations_count'] ?? items.length;

    final meltProgress = _colorAnimation.value;
    final glowColor = Color.lerp(
      Colors.orange.shade700,
      Colors.red.shade900,
      _glowAnimation.value,
    )!;

    final borderRadius = BorderRadius.circular(
      16 - (12 * _meltAnimation.value),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isDeleting
            ? Color.lerp(Colors.white, Colors.orange.shade100, meltProgress)
            : Colors.white,
        borderRadius: borderRadius,
        border: Border.all(
          color: widget.isDeleting
              ? Colors.orange.withValues(alpha: 0.6 * meltProgress)
              : Colors.blue.shade200.withValues(
                  alpha: 0.45 + (0.15 * _hoverAnimation.value),
                ),
          width: 1 + (0.5 * _hoverAnimation.value),
        ),
        boxShadow: [
          if (widget.isDeleting)
            BoxShadow(
              color: glowColor.withValues(
                alpha: 0.4 + (0.4 * _glowAnimation.value),
              ),
              blurRadius: 30 + (25 * meltProgress),
              spreadRadius: 2 + (3 * meltProgress),
              offset: Offset(0, 8 + (12 * meltProgress)),
            ),
          BoxShadow(
            color: widget.isDeleting
                ? Colors.orange.withValues(alpha: 0.3 + (0.5 * meltProgress))
                : Colors.black.withValues(
                    alpha: 0.04 + (0.06 * _hoverAnimation.value),
                  ),
            blurRadius: widget.isDeleting
                ? 20 + (30 * meltProgress)
                : 10 + (15 * _hoverAnimation.value),
            offset: widget.isDeleting
                ? Offset(0, 5 + (15 * meltProgress))
                : Offset(0, 2 + (6 * _hoverAnimation.value)),
          ),
          if (_isHovered && !widget.isDeleting)
            BoxShadow(
              color: Colors.blue.shade300.withValues(
                alpha: 0.3 * _hoverAnimation.value,
              ),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5 * meltProgress,
            sigmaY: 5 * meltProgress,
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 5,
                  children: [
                    _buildStatCard(
                      icon: Icons.qr_code_2,
                      color: const Color(0xFF4338CA),
                      label: 'Réf. Fonderie',
                      value: widget.fondry['ref_fondrie'] ?? 'N/A',
                      parallaxOffset: Offset(
                        _mousePosition.dx * 6 * _hoverAnimation.value,
                        _mousePosition.dy * 6 * _hoverAnimation.value,
                      ),
                    ),
                    _buildStatCard(
                      icon: Icons.production_quantity_limits,
                      color: const Color(0xFF2563EB),
                      label: 'Quantité totale',
                      value: '$totalQuantity',
                      parallaxOffset: Offset(
                        _mousePosition.dx * 4 * _hoverAnimation.value,
                        _mousePosition.dy * 4 * _hoverAnimation.value,
                      ),
                    ),
                    _buildStatCard(
                      icon: Icons.attach_money,
                      color: const Color(0xFF16A34A),
                      label: 'Coût total (DH)',
                      value: totalCout,
                      parallaxOffset: Offset(
                        _mousePosition.dx * 5 * _hoverAnimation.value,
                        _mousePosition.dy * 5 * _hoverAnimation.value,
                      ),
                    ),
                    _buildStatCard(
                      icon: Icons.list_alt,
                      color: const Color(0xFF9333EA),
                      label: 'Opérations',
                      value: '$operationsCount',
                      parallaxOffset: Offset(
                        _mousePosition.dx * 3 * _hoverAnimation.value,
                        _mousePosition.dy * 3 * _hoverAnimation.value,
                      ),
                    ),
                    _buildGridAction(
                      Icons.delete,
                      Colors.red.shade600,
                      widget.onDelete,
                      parallaxOffset: Offset(
                        _mousePosition.dx * 7 * _hoverAnimation.value,
                        _mousePosition.dy * 7 * _hoverAnimation.value,
                      ),
                    ),
                    _buildGridAction(
                      Icons.edit,
                      Colors.orange.shade600,
                      widget.onEdit,
                      parallaxOffset: Offset(
                        _mousePosition.dx * 8 * _hoverAnimation.value,
                        _mousePosition.dy * 8 * _hoverAnimation.value,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    Offset parallaxOffset = Offset.zero,
  }) {
    return Expanded(
      child: Transform.translate(
        offset: parallaxOffset,
        child: Container(
          width: 170,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.08 + (0.04 * _hoverAnimation.value),
            ),
            borderRadius: BorderRadius.circular(
              14 - (7 * _meltAnimation.value),
            ),
            border: Border.all(
              color: color.withValues(
                alpha: 0.15 + (0.1 * _hoverAnimation.value),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.12 + (0.08 * _hoverAnimation.value),
                  ),
                  borderRadius: BorderRadius.circular(
                    10 - (5 * _meltAnimation.value),
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridAction(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    Offset parallaxOffset = Offset.zero,
  }) {
    return Transform.translate(
      offset: parallaxOffset,
      child: GestureDetector(
        onTap: widget.isDeleting
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onTap();
              },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.10 + (0.05 * _hoverAnimation.value),
            ),
            borderRadius: BorderRadius.circular(
              15 - (8 * _meltAnimation.value),
            ),
            border: Border.all(
              color: color,
              width: 1 + (0.5 * _hoverAnimation.value),
            ),
            boxShadow: _isHovered && !widget.isDeleting
                ? [
                    BoxShadow(
                      color: color.withValues(
                        alpha: 0.3 * _hoverAnimation.value,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  Widget _buildDrips() {
    return Positioned(
      bottom: -80,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 120,
        child: CustomPaint(
          painter: DripPainter(
            progress: _dripAnimation.value,
            meltProgress: _meltAnimation.value,
            glowProgress: _glowAnimation.value,
          ),
        ),
      ),
    );
  }

  Widget _buildLavaParticles() {
    return Positioned.fill(
      child: CustomPaint(
        painter: LavaParticlesPainter(
          progress: _meltAnimation.value,
          glowProgress: _glowAnimation.value,
        ),
      ),
    );
  }
}

class DripPainter extends CustomPainter {
  final double progress;
  final double meltProgress;
  final double glowProgress;

  DripPainter({
    required this.progress,
    required this.meltProgress,
    required this.glowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    for (int i = 0; i < 8; i++) {
      final x = (i * size.width / 7) + (random.nextDouble() * 20 - 10);
      final dripHeight = (40 + random.nextDouble() * 60) * progress;
      final dripWidth = 6 + random.nextDouble() * 8;
      final delay = i * 0.08;
      final adjustedProgress = (progress - delay).clamp(0.0, 1.0);

      if (adjustedProgress > 0) {
        final glowColor = Color.lerp(
          Colors.orange.shade600,
          Colors.red.shade800,
          glowProgress,
        )!;

        // رسم التوهج
        final glowPaint = Paint()
          ..color = glowColor.withValues(alpha: 0.3 * adjustedProgress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

        canvas.drawCircle(
          Offset(x, dripHeight * 0.5),
          dripWidth * 2,
          glowPaint,
        );

        // رسم القطرة الرئيسية
        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.orange.shade800.withValues(alpha: 0.9),
            Colors.red.shade900.withValues(alpha: 0.95),
            Colors.red.shade900.withValues(alpha: 1.0),
          ],
        );

        final paint = Paint()
          ..shader = gradient.createShader(
            Rect.fromLTWH(x - dripWidth, 0, dripWidth * 2, dripHeight),
          )
          ..style = PaintingStyle.fill;

        final path = Path();
        path.moveTo(x, 0);

        // منحنى أكثر واقعية
        path.cubicTo(
          x - dripWidth * 0.7,
          dripHeight * 0.3,
          x - dripWidth * 0.9,
          dripHeight * 0.6,
          x,
          dripHeight,
        );

        path.cubicTo(
          x + dripWidth * 0.9,
          dripHeight * 0.6,
          x + dripWidth * 0.7,
          dripHeight * 0.3,
          x,
          0,
        );

        canvas.drawPath(path, paint);

        // قطرة دائرية في النهاية مع تدرج
        final dropPaint = Paint()
          ..shader =
              RadialGradient(
                colors: [
                  Colors.yellow.shade700.withValues(alpha: 0.8),
                  Colors.orange.shade800,
                  Colors.red.shade900,
                ],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(x, dripHeight),
                  radius: dripWidth,
                ),
              );

        canvas.drawCircle(Offset(x, dripHeight), dripWidth * 0.8, dropPaint);

        // نقطة ضوء صغيرة
        final highlightPaint = Paint()
          ..color = Colors.yellow.shade300.withValues(alpha: 0.6);

        canvas.drawCircle(
          Offset(x - dripWidth * 0.3, dripHeight - dripWidth * 0.3),
          dripWidth * 0.2,
          highlightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DripPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        meltProgress != oldDelegate.meltProgress ||
        glowProgress != oldDelegate.glowProgress;
  }
}

class LavaParticlesPainter extends CustomPainter {
  final double progress;
  final double glowProgress;

  LavaParticlesPainter({required this.progress, required this.glowProgress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.3) return;

    final random = math.Random(123);
    final adjustedProgress = (progress - 0.3) / 0.7;

    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final startY = size.height * 0.7;
      final y = startY + (random.nextDouble() * 50 * adjustedProgress);
      final particleSize = 2 + random.nextDouble() * 4;
      final opacity =
          (1.0 - adjustedProgress) * (0.6 + random.nextDouble() * 0.4);

      final glowColor = Color.lerp(
        Colors.orange.shade400,
        Colors.red.shade600,
        glowProgress,
      )!;

      // توهج الجزيء
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(x, y), particleSize * 2, glowPaint);

      // الجزيء نفسه
      final particlePaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.yellow.shade300.withValues(alpha: opacity),
                glowColor.withValues(alpha: opacity),
              ],
            ).createShader(
              Rect.fromCircle(center: Offset(x, y), radius: particleSize),
            );

      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(LavaParticlesPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        glowProgress != oldDelegate.glowProgress;
  }
}

// مثال على الاستخدام مع القائمة
class FonderieListExample extends StatefulWidget {
  const FonderieListExample({super.key});

  @override
  State<FonderieListExample> createState() => _FonderieListExampleState();
}

class _FonderieListExampleState extends State<FonderieListExample> {
  final Set<String> _deletingItems = {};

  final List<Map<String, dynamic>> _fonderies = [
    {
      'id': '1',
      'ref_fondrie': 'FND-001',
      'total_quantity': 150,
      'total_cout': 25000.50,
      'operations_count': 5,
      'items': [],
    },
    {
      'id': '2',
      'ref_fondrie': 'FND-002',
      'total_quantity': 200,
      'total_cout': 35000.75,
      'operations_count': 8,
      'items': [],
    },
  ];

  void _handleDelete(Map<String, dynamic> fonderie) {
    HapticFeedback.mediumImpact();

    setState(() {
      _deletingItems.add(fonderie['id']);
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _fonderies.removeWhere((f) => f['id'] == fonderie['id']);
          _deletingItems.remove(fonderie['id']);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Fonderie List'),
        backgroundColor: const Color(0xFF4338CA),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _fonderies.length,
        itemBuilder: (context, index) {
          final fonderie = _fonderies[index];
          final isDeleting = _deletingItems.contains(fonderie['id']);

          return FonderieCard(
            fondry: fonderie,
            isDeleting: isDeleting,
            onEdit: () {
              HapticFeedback.lightImpact();
              // Handle edit
            },
            onDelete: () => _handleDelete(fonderie),
          );
        },
      ),
    );
  }
}
