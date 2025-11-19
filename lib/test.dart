import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _items = [
    {
      'id': 'item_1',
      'title': 'العنصر الأول',
      'description': 'وصف تفصيلي للعنصر الأول مع معلومات إضافية',
      'icon': Icons.rocket_launch_outlined,
      'color': Colors.purple,
    },
    {
      'id': 'item_2',
      'title': 'العنصر الثاني',
      'description': 'وصف تفصيلي للعنصر الثاني مع معلومات إضافية',
      'icon': Icons.diamond_outlined,
      'color': Colors.blue,
    },
    {
      'id': 'item_3',
      'title': 'العنصر الثالث',
      'description': 'وصف تفصيلي للعنصر الثالث مع معلومات إضافية',
      'icon': Icons.star_border_purple500_outlined,
      'color': Colors.orange,
    },
  ];

  final Set<String> _deletingItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildListView()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF0A0E27)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.3),
                    Colors.purple.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.3),
                    Colors.blue.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'قائمة العناصر',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اسحب لليسار لحذف العناصر',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _items.length,
      itemBuilder: (ctx, index) {
        final item = _items[index];
        final isDeleting = _deletingItems.contains(item['id']);

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 150)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: _buildCard(item, index, isDeleting),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> item, int index, bool isDeleting) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MeltingCard(
        key: ValueKey(item['id']),
        item: item,
        isDeleting: isDeleting,
        onDelete: () => _handleDelete(item, index),
      ),
    );
  }

  void _handleDelete(Map<String, dynamic> item, int index) {
    HapticFeedback.mediumImpact();

    setState(() {
      _deletingItems.add(item['id']);
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          final currentIndex = _items.indexWhere((i) => i['id'] == item['id']);
          if (currentIndex != -1) {
            _items.removeAt(currentIndex);
          }
          _deletingItems.remove(item['id']);
        });
      }
    });
  }
}

class MeltingCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isDeleting;
  final VoidCallback onDelete;

  const MeltingCard({
    super.key,
    required this.item,
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  MeltingCardState createState() => MeltingCardState();
}

class MeltingCardState extends State<MeltingCard>
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
  void didUpdateWidget(MeltingCard oldWidget) {
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
            final cardSize = Size(constraints.maxWidth, 120);

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
    final tiltX = _mousePosition.dy * 0.15 * _hoverAnimation.value;
    final tiltY = _mousePosition.dx * -0.15 * _hoverAnimation.value;
    final scale =
        1.0 + (0.05 * _hoverAnimation.value) - (0.15 * _meltAnimation.value);

    return Dismissible(
      key: ValueKey(widget.item['id']),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        widget.onDelete();
        return false;
      },
      background: _buildDismissBackground(),
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(tiltX)
          ..rotateY(tiltY)
          ..translate(0.0, 40 * _meltAnimation.value, 0.0)
          ..scale(scale, 1.0 - (0.4 * _meltAnimation.value)),
        alignment: Alignment.center,
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-0.15 * _meltAnimation.value),
          alignment: Alignment.bottomCenter,
          child: _buildGlassCard(cardSize),
        ),
      ),
    );
  }

  Widget _buildGlassCard(Size cardSize) {
    final Color baseColor = widget.item['color'] as Color;
    final meltProgress = _colorAnimation.value;

    final meltingColor = Color.lerp(
      baseColor,
      Colors.orange.shade900,
      meltProgress * 0.7,
    )!;

    final glowColor = Color.lerp(
      Colors.orange.shade700,
      Colors.red.shade900,
      _glowAnimation.value,
    )!;

    final borderRadius = BorderRadius.circular(
      20 - (15 * _meltAnimation.value),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20 * (1 - meltProgress * 0.5),
          sigmaY: 20 * (1 - meltProgress * 0.5),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1 + (0.3 * meltProgress)),
                meltingColor.withValues(alpha: 0.05 + (0.4 * meltProgress)),
              ],
            ),
            borderRadius: borderRadius,
            border: Border.all(
              width: 1.5,
              color: widget.isDeleting
                  ? Colors.orange.withValues(alpha: 0.6 * meltProgress)
                  : Colors.white.withValues(
                      alpha: 0.2 + (0.1 * _hoverAnimation.value),
                    ),
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
                color: meltingColor.withValues(
                  alpha: 0.3 + (0.5 * meltProgress),
                ),
                blurRadius: 20 + (30 * meltProgress),
                offset: Offset(0, 5 + (15 * meltProgress)),
              ),
              if (_isHovered && !widget.isDeleting)
                BoxShadow(
                  color: baseColor.withValues(
                    alpha: 0.4 * _hoverAnimation.value,
                  ),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isDeleting
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                    },
              borderRadius: borderRadius,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildIcon(meltingColor),
                    const SizedBox(width: 16),
                    Expanded(child: _buildContent()),
                    _buildArrow(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    final iconTranslateX = _mousePosition.dx * 8 * _hoverAnimation.value;
    final iconTranslateY = _mousePosition.dy * 8 * _hoverAnimation.value;

    return Transform.translate(
      offset: Offset(iconTranslateX, iconTranslateY),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.8),
              color.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(16 - (8 * _meltAnimation.value)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(
                alpha: 0.3 + (0.3 * _colorAnimation.value),
              ),
              blurRadius: 12 + (8 * _meltAnimation.value),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(widget.item['icon'], color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildContent() {
    final contentTranslateX = _mousePosition.dx * 4 * _hoverAnimation.value;
    final contentTranslateY = _mousePosition.dy * 4 * _hoverAnimation.value;

    return Transform.translate(
      offset: Offset(contentTranslateX, contentTranslateY),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item['title'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.item['description'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    return Icon(
      Icons.arrow_forward_ios_rounded,
      size: 20,
      color: Colors.white.withValues(alpha: 0.5),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade900.withValues(alpha: 0.8),
            Colors.orange.shade900.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.local_fire_department_rounded,
        color: Colors.white,
        size: 32,
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
