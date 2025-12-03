import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Homepage-focused tutorial that highlights key sections
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final Widget child;

  const TutorialOverlay({
    super.key,
    required this.onComplete,
    required this.child,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  // Steps will be built dynamically based on screen size
  List<_TutorialStepData> _getSteps(Size screenSize, double topPadding) {
    final baseTop = topPadding + 120; // After header

    return [
      const _TutorialStepData(
        id: 'welcome',
        icon: LucideIcons.sparkles,
        title: 'Welcome to CorpFinity! 👋',
        description:
            'Let\'s take a quick tour of your wellness dashboard. This is where you\'ll manage your daily wellness journey.',
        highlightType: HighlightType.none,
      ),
      _TutorialStepData(
        id: 'startFlow',
        icon: LucideIcons.play,
        title: 'Start Your Flow ✨',
        description:
            'This is your main action! Tap here to begin a personalized wellness challenge.\n\n• Choose a goal (stress relief, energy boost, focus)\n• Select your energy level\n• Get a guided exercise tailored for you',
        highlightType: HighlightType.section,
        highlightTop: baseTop,
        highlightHeight: 192,
      ),
      _TutorialStepData(
        id: 'mood',
        icon: LucideIcons.smile,
        title: 'Track Your Mood 😊',
        description:
            'How are you feeling today?\n\n• Tap any emoji to log your mood\n• Get personalized tips based on how you feel\n• Track patterns over time',
        highlightType: HighlightType.section,
        highlightTop: baseTop + 216,
        highlightHeight: 160,
      ),
      _TutorialStepData(
        id: 'hydration',
        icon: LucideIcons.droplets,
        title: 'Stay Hydrated 💧',
        description:
            'Track your daily water intake!\n\n• Tap the + button each time you drink\n• Aim for 8 glasses a day\n• Stay healthy and energized',
        highlightType: HighlightType.section,
        highlightTop: baseTop + 400,
        highlightHeight: 95,
      ),
      const _TutorialStepData(
        id: 'navigation',
        icon: LucideIcons.layoutGrid,
        title: 'Explore the App 🧭',
        description:
            'Use the bottom tabs to navigate:\n\n• Flow - Your wellness dashboard (you\'re here!)\n• Goals - Daily goals & challenge history\n• Insights - Stats, streaks & calendar\n• Profile - Settings & achievements',
        highlightType: HighlightType.bottomNav,
      ),
      const _TutorialStepData(
        id: 'ready',
        icon: LucideIcons.rocket,
        title: 'You\'re All Set! 🎉',
        description:
            'That\'s everything! Start your wellness journey by tapping "Start Your Flow" and completing your first challenge.\n\nSmall steps lead to big changes!',
        highlightType: HighlightType.none,
        isLast: true,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep(int totalSteps) {
    if (_currentStep < totalSteps - 1) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep++);
        _fadeController.forward();
      });
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep--);
        _fadeController.forward();
      });
    }
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    final steps = _getSteps(screenSize, topPadding);
    final step = steps[_currentStep];

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // The actual app content
          widget.child,

          // Dark overlay with cutout for highlighted area
          AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return IgnorePointer(
                child: CustomPaint(
                  size: screenSize,
                  painter: _HighlightPainter(
                    opacity: 0.88 * _fadeController.value,
                    highlightType: step.highlightType,
                    highlightTop: step.highlightTop,
                    highlightHeight: step.highlightHeight,
                    bottomPadding: bottomPadding,
                  ),
                ),
              );
            },
          ),

          // Pulsing border around highlighted area
          if (step.highlightType != HighlightType.none)
            _buildHighlightBorder(step, screenSize, bottomPadding),

          // Tutorial card - always in a safe position
          _buildTutorialCard(step, steps.length, screenSize, bottomPadding, topPadding),

          // Progress indicator and skip button at top
          _buildTopBar(topPadding, steps.length),
        ],
      ),
    );
  }

  Widget _buildTopBar(double topPadding, int totalSteps) {
    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeController,
        child: Row(
          children: [
            // Progress dots
            Expanded(
              child: Row(
                children: List.generate(totalSteps, (index) {
                  final isActive = index == _currentStep;
                  final isPast = index < _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    width: isActive ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : isPast
                              ? Colors.white70
                              : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Skip button
            TextButton(
              onPressed: _skip,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightBorder(
      _TutorialStepData step, Size screenSize, double bottomPadding) {
    double top;
    double left = 16;
    double right = 16;
    double height;
    BorderRadius borderRadius = BorderRadius.circular(24);

    if (step.highlightType == HighlightType.bottomNav) {
      top = screenSize.height - 70 - bottomPadding;
      height = 70 + bottomPadding;
      left = 0;
      right = 0;
      borderRadius = BorderRadius.zero;
    } else {
      top = step.highlightTop ?? 0;
      height = step.highlightHeight ?? 100;
    }

    return Positioned(
      top: top,
      left: left,
      right: right,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final glowOpacity = 0.6 + (_pulseController.value * 0.4);

            return Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: glowOpacity),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: glowOpacity * 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: glowOpacity * 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTutorialCard(
    _TutorialStepData step,
    int totalSteps,
    Size screenSize,
    double bottomPadding,
    double topPadding,
  ) {
    // Calculate card position based on highlight
    double cardTop;
    
    if (step.highlightType == HighlightType.none) {
      // Center the card for welcome/final screens
      cardTop = screenSize.height * 0.25;
    } else if (step.highlightType == HighlightType.bottomNav) {
      // Place card above bottom nav
      cardTop = screenSize.height - 70 - bottomPadding - 320;
    } else {
      // Place card below the highlighted section
      final highlightBottom = (step.highlightTop ?? 0) + (step.highlightHeight ?? 0);
      cardTop = highlightBottom + 16;
      
      // If card would go too low, place it above the highlight instead
      if (cardTop + 280 > screenSize.height - bottomPadding - 20) {
        cardTop = (step.highlightTop ?? 0) - 290;
        // If still too high, just center it
        if (cardTop < topPadding + 50) {
          cardTop = topPadding + 50;
        }
      }
    }

    return Positioned(
      left: 16,
      right: 16,
      top: cardTop,
      child: FadeTransition(
        opacity: _fadeController,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _fadeController,
            curve: Curves.easeOutCubic,
          )),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 340),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  _buildAnimatedIcon(step),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    step.title,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.gray900,
                      fontSize: 19,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    step.description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.gray600,
                      height: 1.5,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Navigation buttons
                  Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.gray200),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.chevronLeft,
                                    size: 18, color: AppColors.gray600),
                                SizedBox(width: 4),
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    color: AppColors.gray600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: _buildNextButton(step, totalSteps),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(_TutorialStepData step) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.08);
        final rotation = step.isLast ? _pulseController.value * 0.1 : 0.0;

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: step.isLast
                      ? [AppColors.secondary, AppColors.accent]
                      : [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (step.isLast ? AppColors.secondary : AppColors.primary)
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(step.icon, size: 28, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextButton(_TutorialStepData step, int totalSteps) {
    final isLast = step.isLast;
    final colors = isLast
        ? [AppColors.secondary, AppColors.accent]
        : [AppColors.primary, AppColors.primaryLight];

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isLast ? 1.0 + (_pulseController.value * 0.02) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: colors),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _nextStep(totalSteps),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isLast
                            ? LucideIcons.arrowRight
                            : LucideIcons.chevronRight,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TutorialStepData {
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final HighlightType highlightType;
  final double? highlightTop;
  final double? highlightHeight;
  final bool isLast;

  const _TutorialStepData({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.highlightType,
    this.highlightTop,
    this.highlightHeight,
    this.isLast = false,
  });
}

enum HighlightType { none, section, bottomNav }

/// Custom painter that draws dark overlay with a cutout for the highlighted area
class _HighlightPainter extends CustomPainter {
  final double opacity;
  final HighlightType highlightType;
  final double? highlightTop;
  final double? highlightHeight;
  final double bottomPadding;

  _HighlightPainter({
    required this.opacity,
    required this.highlightType,
    this.highlightTop,
    this.highlightHeight,
    required this.bottomPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (highlightType == HighlightType.none) {
      // Just draw full overlay
      final paint = Paint()..color = Colors.black.withValues(alpha: opacity);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    // Draw overlay with cutout
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);
    final cutoutPaint = Paint()..blendMode = BlendMode.clear;

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Draw full overlay
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Cut out the highlighted area
    if (highlightType == HighlightType.bottomNav) {
      final rect = Rect.fromLTWH(
        0,
        size.height - 70 - bottomPadding,
        size.width,
        70 + bottomPadding,
      );
      canvas.drawRect(rect, cutoutPaint);
    } else {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          12,
          highlightTop ?? 0,
          size.width - 24,
          highlightHeight ?? 100,
        ),
        const Radius.circular(24),
      );
      canvas.drawRRect(rect, cutoutPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_HighlightPainter oldDelegate) =>
      oldDelegate.opacity != opacity ||
      oldDelegate.highlightType != highlightType ||
      oldDelegate.highlightTop != highlightTop ||
      oldDelegate.highlightHeight != highlightHeight;
}
