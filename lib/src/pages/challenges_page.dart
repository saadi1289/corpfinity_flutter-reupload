import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/challenge.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});
  
  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final _storage = StorageService();
  String _activeTab = 'active'; // 'active' or 'history'
  List<ChallengeHistoryItem> _history = [];
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    final history = await _storage.getHistory();
    setState(() => _history = history);
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Your Goals', style: AppTextStyles.h2.copyWith(color: AppColors.gray900)),
          const SizedBox(height: 4),
          Text('Track your wellness journey', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppTheme.spacing6),
          
          // Tab switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 'active'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 'active' ? AppColors.gray100 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ongoing',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _activeTab == 'active' ? AppColors.gray900 : AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 'history'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 'history' ? AppColors.gray100 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'History',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _activeTab == 'history' ? AppColors.gray900 : AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing6),
          
          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _activeTab == 'active' ? _buildActiveTab() : _buildHistoryTab(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveTab() {
    final goals = [
      ('Hydration Master', 'Drink 8 glasses of water daily', 65, AppColors.info),
      ('Step Champion', 'Walk 10,000 steps this week', 40, AppColors.success),
      ('Mindfulness', 'Complete 3 breathing sessions', 100, AppColors.secondary),
    ];
    
    return ListView(
      key: const ValueKey('active'),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      children: [
        ...goals.map((goal) {
          final (title, desc, progress, color) = goal;
          final isComplete = progress >= 100;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.h4.copyWith(color: AppColors.gray800)),
                          const SizedBox(height: 4),
                          Text(desc, style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
                        ],
                      ),
                    ),
                    Icon(
                      isComplete ? LucideIcons.circleCheck : LucideIcons.circle,
                      color: isComplete ? AppColors.success : AppColors.gray300,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.gray100,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PROGRESS', style: AppTextStyles.tiny.copyWith(color: AppColors.gray400)),
                    Text('$progress%', style: AppTextStyles.tiny.copyWith(color: AppColors.gray400)),
                  ],
                ),
              ],
            ),
          );
        }),
        
        // Weekly challenge card
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
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
            children: [
              const Text(
                'Weekly Challenge',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete 5 micro-breaks to unlock the Zen Master badge.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.award, size: 16, color: Color(0xFFFDE68A)),
                    SizedBox(width: 8),
                    Text(
                      'Reward: 500 pts',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return Center(
        key: const ValueKey('history-empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.target, size: 48, color: AppColors.gray200),
            const SizedBox(height: 16),
            Text('No challenges completed yet.', style: AppTextStyles.body.copyWith(color: AppColors.gray400)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      key: const ValueKey('history'),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final completedDate = DateTime.parse(item.completedAt);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.gray100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Center(
                  child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gray800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(LucideIcons.clock, size: 10, color: AppColors.gray400),
                            const SizedBox(width: 4),
                            Text(
                              '${completedDate.month}/${completedDate.day}',
                              style: AppTextStyles.tiny.copyWith(color: AppColors.gray400),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
