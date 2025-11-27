import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/challenge.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});
  
  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final _storage = StorageService();
  List<ChallengeHistoryItem> _history = [];
  int _streak = 0;
  DateTime _currentDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final history = await _storage.getHistory();
    final state = await _storage.getState();
    
    setState(() {
      _history = history;
      _streak = state?['streak'] ?? 0;
    });
  }
  
  void _changeMonth(int delta) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + delta, 1);
    });
  }
  
  List<DateTime?> _getCalendarDays() {
    final firstDay = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDay = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final startDayOfWeek = firstDay.weekday % 7; // Convert to 0=Sunday
    
    final days = <DateTime?>[];
    for (int i = 0; i < startDayOfWeek; i++) {
      days.add(null);
    }
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentDate.year, _currentDate.month, i));
    }
    return days;
  }
  
  bool _hasActivity(DateTime date) {
    return _history.any((h) {
      final hDate = DateTime.parse(h.completedAt);
      return hDate.year == date.year &&
          hDate.month == date.month &&
          hDate.day == date.day;
    });
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
  
  @override
  Widget build(BuildContext context) {
    final calendarDays = _getCalendarDays();
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(AppTheme.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Wellness Insights', style: AppTextStyles.h2.copyWith(color: AppColors.gray900)),
          const SizedBox(height: 4),
          Text('Your progress at a glance', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppTheme.spacing6),
          
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.flame, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'STREAK',
                            style: AppTextStyles.tiny.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_streak',
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Days in a row',
                        style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                          const Icon(LucideIcons.award, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'TOTAL',
                            style: AppTextStyles.tiny.copyWith(color: AppColors.gray400),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_history.length}',
                        style: AppTextStyles.display.copyWith(color: AppColors.gray900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sessions completed',
                        style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing6),
          
          // Calendar Card
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radius2Xl),
              border: Border.all(color: AppColors.gray100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                // Month header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${months[_currentDate.month - 1]} ${_currentDate.year}',
                      style: AppTextStyles.h4.copyWith(color: AppColors.gray800),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, size: 20),
                          onPressed: () => _changeMonth(-1),
                          color: AppColors.gray400,
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.chevronRight, size: 20),
                          onPressed: () => _changeMonth(1),
                          color: AppColors.gray400,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing6),
                
                // Week days header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                    return SizedBox(
                      width: 32,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.gray300),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Calendar grid
                Wrap(
                  spacing: 8,
                  runSpacing: 16,
                  children: calendarDays.map((date) {
                    if (date == null) {
                      return const SizedBox(width: 32, height: 32);
                    }
                    
                    final hasActivity = _hasActivity(date);
                    final isToday = _isToday(date);
                    
                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: hasActivity ? AppColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !hasActivity
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                        boxShadow: hasActivity
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: hasActivity
                                ? Colors.white
                                : (isToday ? AppColors.primary : AppColors.gray600),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spacing6),
                
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Completed', style: AppTextStyles.tiny.copyWith(color: AppColors.gray400)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Today', style: AppTextStyles.tiny.copyWith(color: AppColors.gray400)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing6),
          
          // Weekly Activity Graph
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing6),
            decoration: BoxDecoration(
              color: AppColors.gray900,
              borderRadius: BorderRadius.circular(AppTheme.radius2Xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WEEKLY RHYTHM',
                          style: AppTextStyles.tiny.copyWith(color: AppColors.gray400),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Activity Level',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.activity, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing6),
                
                // Bar chart
                SizedBox(
                  height: 96,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [65, 40, 100, 30, 80, 20, 50].asMap().entries.map((entry) {
                      final index = entry.key;
                      final height = entry.value;
                      final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 32,
                            height: 72 * (height / 100),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [AppColors.primary, AppColors.secondary],
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            days[index],
                            style: AppTextStyles.tiny.copyWith(color: AppColors.gray500),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
