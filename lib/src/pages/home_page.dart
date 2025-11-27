import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import 'dart:math';
import '../models/user.dart';
import '../models/app_step.dart';
import '../models/energy_level.dart';
import '../models/goal_option.dart';
import '../models/challenge.dart';
import '../services/challenge_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/circular_timer.dart';

class HomePage extends StatefulWidget {
  final User user;
  
  const HomePage({super.key, required this.user});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _storage = StorageService();
  final _challengeService = ChallengeService();
  
  // State
  AppStep _currentStep = AppStep.welcome;
  GoalOption? _selectedGoal;

  int _streak = 0;
  String? _lastCompletedDate;
  
  // Water tracking
  int _waterIntake = 0;
  
  // Mood tracking
  String? _selectedMood;
  
  // Challenge
  GeneratedChallenge? _currentChallenge;

  
  // Timer
  int _timeLeft = 0;
  int _totalTime = 0;
  bool _isTimerActive = false;
  bool _timerFinished = false;
  Timer? _timer;
  
  // Animations
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  
  // Daily quote
  late ({String text, String author}) _dailyQuote;
  late String _timeOfDay;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAnimations();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _floatController.dispose();
    super.dispose();
  }
  
  void _setupAnimations() {
    _floatController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }
  
  Future<void> _initializeData() async {
    // Set time of day
    final hour = DateTime.now().hour;
    _timeOfDay = hour < 12 ? 'Good Morning' : (hour < 18 ? 'Good Afternoon' : 'Good Evening');
    
    // Random quote
    _dailyQuote = AppConstants.quotes[Random().nextInt(AppConstants.quotes.length)];
    
    // Load water intake
    final water = await _storage.getWaterIntake();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (water.date == today) {
      setState(() => _waterIntake = water.count);
    } else {
      await _storage.saveWaterIntake(0, today);
    }
    
    // Load state
    final state = await _storage.getState();
    if (state != null) {
      setState(() {
        _streak = state['streak'] ?? 0;
        _lastCompletedDate = state['lastCompletedDate'];
      });
    }
  }
  
  int _parseDuration(String duration) {
    final num = int.tryParse(duration.split(' ')[0]) ?? 60;
    if (duration.toLowerCase().contains('sec')) return num;
    return num * 60;
  }
  

  
  void _selectGoal(GoalOption goal) {
    setState(() {
      _selectedGoal = goal;
      _currentStep = AppStep.energySelection;
    });
  }
  
  Future<void> _selectEnergy(EnergyLevel energy) async {
    setState(() {

      _currentStep = AppStep.generating;

    });
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final challenge = _challengeService.getChallengeFromDb(_selectedGoal!.id, energy);
    _initializeChallenge(challenge);
  }
  
  void _initializeChallenge(GeneratedChallenge challenge) {
    final seconds = _parseDuration(challenge.duration);
    setState(() {
      _currentChallenge = challenge;
      _totalTime = seconds;
      _timeLeft = seconds;
      _isTimerActive = false;
      _timerFinished = false;
      _currentStep = AppStep.challengeView;

    });
  }
  
  void _toggleTimer() {
    setState(() => _isTimerActive = !_isTimerActive);
    
    if (_isTimerActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          _timer?.cancel();
          setState(() {
            _isTimerActive = false;
            _timerFinished = true;
          });
        }
      });
    } else {
      _timer?.cancel();
    }
  }
  
  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerActive = false;
      _timerFinished = false;
      _timeLeft = _totalTime;
    });
  }
  
  Future<void> _addWater() async {
    if (_waterIntake < 8) {
      final newCount = _waterIntake + 1;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await _storage.saveWaterIntake(newCount, today);
      setState(() => _waterIntake = newCount);
    }
  }
  
  Future<void> _completeChallenge() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final isNewDay = _lastCompletedDate != today;
    
    // Save to history
    if (_currentChallenge != null) {
      final historyItem = ChallengeHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        completedAt: DateTime.now().toIso8601String(),
        title: _currentChallenge!.title,
        description: _currentChallenge!.description,
        duration: _currentChallenge!.duration,
        emoji: _currentChallenge!.emoji,
        funFact: _currentChallenge!.funFact,
      );
      
      final history = await _storage.getHistory();
      history.insert(0, historyItem);
      await _storage.saveHistory(history);
    }
    
    // Update streak
    final newStreak = isNewDay ? _streak + 1 : _streak;
    await _storage.saveState({
      'streak': newStreak,
      'lastCompletedDate': today,
    });
    
    setState(() {
      _streak = newStreak;
      _lastCompletedDate = today;
      _currentStep = AppStep.completed;
    });
  }
  
  void _resetFlow() {
    setState(() {
      _currentStep = AppStep.welcome;
      _selectedGoal = null;

      _currentChallenge = null;
      _selectedMood = null;
      _isTimerActive = false;
      _timerFinished = false;
    });
    _timer?.cancel();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: _buildCurrentStep(),
    );
  }
  
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case AppStep.welcome:
        return _buildDashboard();
      case AppStep.goalSelection:
        return _buildGoalSelection();
      case AppStep.energySelection:
        return _buildEnergySelection();
      case AppStep.generating:
        return _buildGenerating();
      case AppStep.challengeView:
        return _buildChallengeView();
      case AppStep.completed:
        return _buildCompleted();
    }
  }
  
  // Due to character limit, I'll create this in a second file or continue below
  // The following methods will build each screen
  
  Widget _buildDashboard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(AppTheme.spacing6).copyWith(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timeOfDay,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.name.split(' ')[0],
                    style: AppTextStyles.h2.copyWith(color: AppColors.gray900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.trophy, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '$_streak Day Streak',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing6),
          
          // Hero Card - Start Flow
          _HeroCard(
            floatAnimation: _floatAnimation,
            onTap: () => setState(() => _currentStep = AppStep.goalSelection),
            child: Container(
                height: 192,
                padding: const EdgeInsets.all(AppTheme.spacing6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF7E7BF7), AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radius2Xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Start Your Flow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personalized CorpFinity challenges',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: ['⚡', '🧠', '🧘'].map((emoji) {
                            return Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.transparent, width: 2),
                              ),
                              child: Center(child: Text(emoji)),
                            );
                          }).toList(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Go',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: AppTheme.spacing6),
          
          // Mood Tracker
          _buildMoodTracker(),
          const SizedBox(height: AppTheme.spacing6),
          
          _buildHydrationTracker(),
          const SizedBox(height: AppTheme.spacing6),
          
          _buildQuickChallenges(),
          const SizedBox(height: AppTheme.spacing6),
          
          _buildDailyWisdom(),
        ],
      ),
    );
  }
  
  Widget _buildMoodTracker() {
    final activeMood = AppConstants.moods.firstWhere(
      (m) => m.label == _selectedMood,
      orElse: () => AppConstants.moods[0],
    );
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling?',
            style: AppTextStyles.h4.copyWith(color: AppColors.gray800),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: AppConstants.moods.map((mood) {
              final isSelected = _selectedMood == mood.label;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood.label),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? mood.bg : AppColors.gray50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? mood.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getMoodIcon(mood.icon), 
                        color: isSelected ? mood.color : AppColors.gray400, 
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AppTextStyles.tiny.copyWith(
                        color: isSelected ? mood.color : AppColors.gray400,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      child: Text(mood.label),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (_selectedMood != null) ...[
            const SizedBox(height: 24),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: activeMood.bg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: activeMood.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.lightbulb, size: 16, color: activeMood.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.moodTips[_selectedMood]!.title,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppConstants.moodTips[_selectedMood]!.desc,
                            style: AppTextStyles.caption.copyWith(color: AppColors.gray600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  IconData _getMoodIcon(String iconName) {
    final iconMap = {
      'Sun': LucideIcons.sun,
      'Smile': LucideIcons.smile,
      'Meh': LucideIcons.meh,
      'Cloud': LucideIcons.cloud,
      'Frown': LucideIcons.frown,
    };
    return iconMap[iconName] ?? LucideIcons.circle;
  }
  
  // Continue with other builder methods in next message
  Widget _buildHydrationTracker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.droplets, size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text(
                      'Hydration',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$_waterIntake / 8 glasses today',
                  style: AppTextStyles.caption.copyWith(color: AppColors.info.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _waterIntake / 8,
                    minHeight: 8,
                    backgroundColor: AppColors.info.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _addWater,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.plus,
                size: 24,
                color: _waterIntake >= 8 ? AppColors.gray400 : AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickChallenges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Relief', style: AppTextStyles.h3.copyWith(color: AppColors.gray800)),
            Text('Fast Track', style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 144,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: ChallengeService.quickChallenges.length,
            itemBuilder: (context, index) {
              final challenge = ChallengeService.quickChallenges[index];
              return _TappableCard(
                onTap: () => _initializeChallenge(challenge),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: AppColors.gray100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(challenge.emoji, style: const TextStyle(fontSize: 24)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.clock, size: 10, color: AppColors.gray500),
                                const SizedBox(width: 4),
                                Text(
                                  challenge.duration,
                                  style: AppTextStyles.tiny.copyWith(color: AppColors.gray500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gray800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            challenge.description,
                            style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildDailyWisdom() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      decoration: BoxDecoration(
        color: AppColors.gray900,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        children: [
          Text(
            'DAILY WISDOM',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.gray400,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '"${_dailyQuote.text}"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '— ${_dailyQuote.author}',
            style: AppTextStyles.caption.copyWith(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
  
  // Continue with other build methods...
  Widget _buildGoalSelection() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => setState(() => _currentStep = AppStep.welcome),
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
            label: const Text('Back to Dashboard'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gray500),
          ),
          const SizedBox(height: 8),
          Text('Wellness Goal?', style: AppTextStyles.display.copyWith(color: AppColors.gray900)),
          const SizedBox(height: 8),
          Text('Select a category to improve.', style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppTheme.spacing6),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              itemCount: AppConstants.goalOptions.length,
              itemBuilder: (context, index) {
                final goal = AppConstants.goalOptions[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 80)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(30 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnimatedGoalCard(
                      goal: goal,
                      icon: _getGoalIcon(goal.icon),
                      onTap: () => _selectGoal(goal),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getGoalIcon(String iconName) {
    final iconMap = {
      'Brain': LucideIcons.brain,
      'Zap': LucideIcons.zap,
      'Moon': LucideIcons.moon,
      'Activity': LucideIcons.activity,
      'Utensils': LucideIcons.utensils,
      'Heart': LucideIcons.heart,
    };
    return iconMap[iconName] ?? LucideIcons.circle;
  }
  
  Widget _buildEnergySelection() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => setState(() => _currentStep = AppStep.goalSelection),
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
            label: const Text('Back'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gray500),
          ),
          const SizedBox(height: 8),
          Text('Energy Level?', style: AppTextStyles.display.copyWith(color: AppColors.gray900)),
          const SizedBox(height: 8),
          Text('We\'ll adjust intensity accordingly.', style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          const Spacer(),
          ...AppConstants.energyOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 350 + (index * 100)),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _AnimatedEnergyCard(
                  option: option,
                  icon: _getEnergyIcon(option.icon),
                  onTap: () => _selectEnergy(option.value),
                ),
              ),
            );
          }),
          const Spacer(),
        ],
      ),
    );
  }
  
  IconData _getEnergyIcon(String iconName) {
    final iconMap = {
      'Battery': LucideIcons.battery,
      'BatteryMedium': LucideIcons.batteryMedium,
      'BatteryCharging': LucideIcons.batteryCharging,
    };
    return iconMap[iconName] ?? LucideIcons.battery;
  }
  
  Widget _buildGenerating() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Consulting Database...',
            style: AppTextStyles.h2.copyWith(color: AppColors.gray800),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the best ${_selectedGoal?.label} challenge for you.',
            style: AppTextStyles.body.copyWith(color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  
  Widget _buildChallengeView() {
    if (_currentChallenge == null) {
      return const Center(child: Text('No challenge loaded'));
    }
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(AppTheme.spacing6),
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _currentStep = AppStep.energySelection;
                  _timer?.cancel();
                  _isTimerActive = false;
                }),
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                label: const Text('Back'),
                style: TextButton.styleFrom(foregroundColor: AppColors.gray500),
              ),
              Text(
                _currentChallenge!.duration,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Challenge emoji with scale animation
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Text(
              _currentChallenge!.emoji,
              style: const TextStyle(fontSize: 80),
            ),
          ),
          const SizedBox(height: 24),
          
          // Challenge title
          Text(
            _currentChallenge!.title,
            style: AppTextStyles.display.copyWith(color: AppColors.gray900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Circular timer
          CircularTimer(
            timeLeft: _timeLeft,
            totalTime: _totalTime,
            isActive: _isTimerActive,
          ),
          const SizedBox(height: 48),
          
          // Timer controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _toggleTimer,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isTimerActive ? LucideIcons.pause : LucideIcons.play,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!_isTimerActive && _timeLeft != _totalTime) ...[
                const SizedBox(width: 24),
                // Reset button
                GestureDetector(
                  onTap: _resetTimer,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gray200, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.rotateCcw,
                      size: 24,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 48),
          
          // Instructions card
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: AppColors.gray100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.info,
                        size: 16,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Instructions',
                      style: AppTextStyles.h4.copyWith(color: AppColors.gray800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _currentChallenge!.description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.gray600,
                    height: 1.6,
                  ),
                ),
                if (_currentChallenge!.funFact != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Did you know?',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentChallenge!.funFact!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Mark complete button
          if (_timerFinished || _timeLeft == 0) ...[
            CustomButton(
              text: 'Mark as Complete',
              onPressed: _completeChallenge,
              fullWidth: true,
              icon: const Icon(LucideIcons.circleCheck, size: 18, color: Colors.white),
            ),
          ] else ...[
            TextButton(
              onPressed: _completeChallenge,
              child: Text(
                'Skip timer & mark complete',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCompleted() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.circleCheck, size: 64, color: AppColors.success),
            ),
            const SizedBox(height: 32),
            Text('Well Done!', style: AppTextStyles.display.copyWith(color: AppColors.gray900)),
            const SizedBox(height: 8),
            Text(
              'You\'ve taken a moment for yourself.',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.warning.withValues(alpha: 0.1), AppColors.warning.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'CURRENT STREAK',
                    style: AppTextStyles.tiny.copyWith(color: AppColors.warning),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_streak',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.warning),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'days in a row',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Back to Dashboard',
              onPressed: _resetFlow,
              variant: ButtonVariant.secondary,
              fullWidth: true,
              icon: const Icon(LucideIcons.refreshCcw, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}


// Smooth touch feedback hero card
class _HeroCard extends StatefulWidget {
  final Animation<double> floatAnimation;
  final VoidCallback onTap;
  final Widget child;
  
  const _HeroCard({
    required this.floatAnimation,
    required this.onTap,
    required this.child,
  });
  
  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;
  
  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.floatAnimation, _pressAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, widget.floatAnimation.value),
            child: Transform.scale(
              scale: _pressAnimation.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}


// Reusable tappable card with smooth feedback
class _TappableCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  
  const _TappableCard({
    required this.onTap,
    required this.child,
  });
  
  @override
  State<_TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<_TappableCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// Animated goal card with press feedback
class _AnimatedGoalCard extends StatefulWidget {
  final GoalOption goal;
  final IconData icon;
  final VoidCallback onTap;
  
  const _AnimatedGoalCard({
    required this.goal,
    required this.icon,
    required this.onTap,
  });
  
  @override
  State<_AnimatedGoalCard> createState() => _AnimatedGoalCardState();
}

class _AnimatedGoalCardState extends State<_AnimatedGoalCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isPressed ? widget.goal.color.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: _isPressed ? widget.goal.color.withValues(alpha: 0.3) : AppColors.gray100, 
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed 
                    ? widget.goal.color.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: _isPressed ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.goal.color,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: _isPressed
                      ? [
                          BoxShadow(
                            color: widget.goal.color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.goal.label,
                      style: AppTextStyles.h4.copyWith(color: AppColors.gray800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.goal.description,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray400),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _isPressed ? 0.05 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  LucideIcons.chevronRight,
                  color: _isPressed ? widget.goal.color : AppColors.gray300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated energy card with press feedback
class _AnimatedEnergyCard extends StatefulWidget {
  final dynamic option;
  final IconData icon;
  final VoidCallback onTap;
  
  const _AnimatedEnergyCard({
    required this.option,
    required this.icon,
    required this.onTap,
  });
  
  @override
  State<_AnimatedEnergyCard> createState() => _AnimatedEnergyCardState();
}

class _AnimatedEnergyCardState extends State<_AnimatedEnergyCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppTheme.spacing6),
          decoration: BoxDecoration(
            color: _isPressed 
                ? widget.option.color.withValues(alpha: 0.15)
                : widget.option.bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: _isPressed ? widget.option.color : Colors.transparent, 
              width: 2,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.option.color.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedScale(
                scale: _isPressed ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(widget.icon, size: 32, color: widget.option.color),
              ),
              const SizedBox(width: 16),
              Text(
                widget.option.value.displayName,
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.w700, 
                  color: widget.option.color,
                ),
              ),
              const Spacer(),
              AnimatedSlide(
                offset: Offset(_isPressed ? 0.2 : 0, 0),
                duration: const Duration(milliseconds: 150),
                child: Icon(LucideIcons.chevronRight, color: widget.option.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
