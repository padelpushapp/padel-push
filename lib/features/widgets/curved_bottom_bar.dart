import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurvedBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreateTap;

  const CurvedBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreateTap,
  });

  // 📐 Dimensiones
  static const double _barHeight = 75.0;
  static const double _fabSize = 56.0;
  static const double _bubbleSize = 45.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double itemWidth = size.width / 5; 

    return SizedBox(
      height: _barHeight + bottomPadding + 10,
      width: size.width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. EL FONDO CURVO
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: _barHeight + bottomPadding,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _LiquidCurvePainter(),
                size: Size(size.width, _barHeight + bottomPadding),
              ),
            ),
          ),

          // 2. LA ESFERA
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            bottom: bottomPadding + 15,
            left: _calculateBubbleLeft(currentIndex, itemWidth),
            child: Container(
              width: _bubbleSize,
              height: _bubbleSize,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                   BoxShadow(
                     color: Colors.white.withOpacity(0.2),
                     blurRadius: 5,
                     spreadRadius: 1,
                     offset: const Offset(-2, -2),
                   ),
                ]
              ),
            ),
          ),

          // 3. LOS ICONOS
          Positioned(
            bottom: bottomPadding,
            left: 0,
            right: 0,
            height: _barHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavBarItem(Icons.dashboard_rounded, 0, currentIndex, onTabSelected, itemWidth),
                _NavBarItem(Icons.calendar_month_rounded, 1, currentIndex, onTabSelected, itemWidth),
                SizedBox(width: itemWidth), 
                _NavBarItem(Icons.emoji_events_rounded, 2, currentIndex, onTabSelected, itemWidth),
                _NavBarItem(Icons.person_rounded, 3, currentIndex, onTabSelected, itemWidth),
              ],
            ),
          ),

          // 4. EL FAB (REACTIVO CON RETRASO VISUAL)
          Positioned(
            bottom: bottomPadding + _barHeight - (_fabSize * 0.7),
            left: (size.width / 2) - (_fabSize / 2),
            child: _ReactiveFab(
              size: _fabSize, 
              onTap: onCreateTap,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBubbleLeft(int index, double itemWidth) {
    int physicalIndex = 0;
    if (index == 0) physicalIndex = 0;
    else if (index == 1) physicalIndex = 1;
    else if (index == 2) physicalIndex = 3;
    else if (index == 3) physicalIndex = 4;
    return (physicalIndex * itemWidth) + (itemWidth / 2) - (_bubbleSize / 2);
  }
}

/// ==========================================================
/// ✨ FAB REACTIVO (Con retraso para disfrutar la animación)
/// ==========================================================
class _ReactiveFab extends StatefulWidget {
  final double size;
  final VoidCallback onTap;

  const _ReactiveFab({required this.size, required this.onTap});

  @override
  State<_ReactiveFab> createState() => _ReactiveFabState();
}

class _ReactiveFabState extends State<_ReactiveFab> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Escala muy rápida para sentir el "click"
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Onda un poco más lenta para que se vea bien
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  // 🚀 AQUÍ ESTÁ LA MAGIA DEL RETRASO
  void _handleTap() async {
    // 1. Feedback inmediato (Vibración + Visuales)
    HapticFeedback.mediumImpact();
    
    // Disparamos la Ola
    _rippleController.forward(from: 0.0);
    
    // Encogemos el botón (presionado)
    _scaleController.forward();

    // 2. ⏳ ESPERA (El truco para ver la animación)
    // Esperamos 400ms. Es suficiente para ver la ola salir,
    // pero no tan lento como para que la app parezca lenta.
    await Future.delayed(const Duration(milliseconds: 400));

    // 3. Recuperamos el tamaño del botón (Soltamos el click)
    await _scaleController.reverse();

    // 4. FINALMENTE, ejecutamos la navegación
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // --- CAPA 1: LA OLA (Ripple) ---
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, child) {
              if (!_rippleController.isAnimating) return const SizedBox();

              final value = _rippleController.value;
              final opacity = (1.0 - value) * 0.6;
              // La ola crece hasta 2.2 veces el tamaño
              final scale = 1.0 + (value * 1.2);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(opacity),
                      width: 2.5, // Un poco más gruesa para que se vea mejor
                    ),
                  ),
                ),
              );
            },
          ),

          // --- CAPA 2: EL BOTÓN ---
          GestureDetector(
            onTap: _handleTap,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.25),
                          blurRadius: 1,
                          offset: const Offset(-1, -1),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 🧱 ÍTEM DE NAVEGACIÓN
// --------------------------------------------------------------------------
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double width;

  const _NavBarItem(this.icon, this.index, this.currentIndex, this.onTap, this.width);

  @override
  Widget build(BuildContext context) {
    final bool isSelected = index == currentIndex;
    const activeColor = Color(0xFF4F46E5);
    const inactiveColor = Color(0xFF94A3B8);

    return SizedBox(
      width: width, 
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0, 
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 26,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              width: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 🎨 PAINTER
// --------------------------------------------------------------------------
class _LiquidCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const double notchWidth = 80.0;
    const double notchDepth = 40.0;
    
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, 0);

    path.lineTo((w / 2) - (notchWidth / 2) - 10, 0);
    path.cubicTo((w / 2) - (notchWidth / 2), 0, (w / 2) - (notchWidth / 3), notchDepth, w / 2, notchDepth);
    path.cubicTo((w / 2) + (notchWidth / 3), notchDepth, (w / 2) + (notchWidth / 2), 0, (w / 2) + (notchWidth / 2) + 10, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.05), 5.0, true);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}