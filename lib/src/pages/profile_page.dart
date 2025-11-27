import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_button.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;
  final Function(User) onUpdateUser;
  
  const ProfilePage({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onUpdateUser,
  });
  
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  bool _isEditing = false;
  bool _loading = false;
  bool _notifications = true;
  bool _darkMode = false;
  
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  String _editAvatarSeed = '';
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _passwordController = TextEditingController();
    _editAvatarSeed = widget.user.email;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSave() async {
    setState(() => _loading = true);
    
    try {
      final updatedUser = widget.user.copyWith(
        name: _nameController.text,
        avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=$_editAvatarSeed',
      );
      
      await _authService.updateUser(updatedUser);
      widget.onUpdateUser(updatedUser);
      
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
  
  void _handleCancel() {
    setState(() {
      _isEditing = false;
      _nameController.text = widget.user.name;
      _editAvatarSeed = widget.user.email;
      _passwordController.clear();
    });
  }
  
  void _shuffleAvatar() {
    setState(() {
      _editAvatarSeed = Random().nextInt(1000000).toString();
    });
  }
  
  String get _currentAvatarUrl {
    if (_isEditing) {
      return 'https://api.dicebear.com/7.x/avataaars/svg?seed=$_editAvatarSeed';
    }
    final seed = widget.user.avatar?.split('seed=').last ?? widget.user.email;
    return 'https://api.dicebear.com/7.x/avataaars/svg?seed=$seed';
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 256,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary.withValues(alpha: 0.05), Colors.transparent],
              ),
            ),
          ),
        ),
        
        // Content
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacing6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Profile' : 'My Profile',
                    style: AppTextStyles.h2.copyWith(color: AppColors.gray900),
                  ),
                  if (!_isEditing)
                    IconButton(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.pencil, size: 18, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing6),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isEditing ? _buildEditMode() : _buildViewMode(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildEditMode() {
    return Column(
      key: const ValueKey('edit'),
      children: [
        // Avatar editor
        Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      _currentAvatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.gray100),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _shuffleAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.refreshCcw, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Tap to shuffle your look', style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
          ],
        ),
        const SizedBox(height: 32),
        
        // Name field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FULL NAME', style: AppTextStyles.tiny.copyWith(color: AppColors.gray500)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.user),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Email field (disabled)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EMAIL ADDRESS', style: AppTextStyles.tiny.copyWith(color: AppColors.gray500)),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              controller: TextEditingController(text: widget.user.email),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.mail),
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Password field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHANGE PASSWORD', style: AppTextStyles.tiny.copyWith(color: AppColors.gray500)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.lock),
                hintText: 'New Password',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Cancel',
                onPressed: _handleCancel,
                variant: ButtonVariant.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: _loading ? 'Saving...' : 'Save Changes',
                onPressed: _loading ? null : _handleSave,
                isLoading: _loading,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildViewMode() {
    return Column(
      key: const ValueKey('view'),
      children: [
        // Profile card
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
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    _currentAvatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.gray100),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user.name, style: AppTextStyles.h3.copyWith(color: AppColors.gray900)),
                    const SizedBox(height: 4),
                    Text(widget.user.email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.secondary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.1)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.shield, size: 10, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'PRO MEMBER',
                            style: AppTextStyles.tiny.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing6),
        
        // Settings section
        Text(
          'PREFERENCES',
          style: AppTextStyles.tiny.copyWith(color: AppColors.gray400, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        
        // Notifications toggle
        _buildSettingToggle(
          icon: LucideIcons.bell,
          iconColor: AppColors.info,
          iconBg: AppColors.info.withValues(alpha: 0.1),
          label: 'Notifications',
          value: _notifications,
          onChanged: (value) => setState(() => _notifications = value),
        ),
        const SizedBox(height: 12),
        
        // Dark mode toggle
        _buildSettingToggle(
          icon: LucideIcons.moon,
          iconColor: AppColors.secondary,
          iconBg: AppColors.secondary.withValues(alpha: 0.1),
          label: 'Dark Mode',
          value: _darkMode,
          onChanged: (value) => setState(() => _darkMode = value),
        ),
        const SizedBox(height: 12),
        
        // Privacy & Security
        _buildSettingTile(
          icon: LucideIcons.shield,
          iconColor: AppColors.success,
          iconBg: AppColors.success.withValues(alpha: 0.1),
          label: 'Privacy & Security',
          onTap: () {},
        ),
        const SizedBox(height: 32),
        
        // Logout button
        CustomButton(
          text: 'Log Out',
          onPressed: widget.onLogout,
          variant: ButtonVariant.outline,
          fullWidth: true,
          icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.error),
        ),
        const SizedBox(height: 24),
        
        Text(
          'CORPFINITY V1.3.0',
          style: AppTextStyles.tiny.copyWith(color: AppColors.gray300, letterSpacing: 1.5),
        ),
      ],
    );
  }
  
  Widget _buildSettingToggle({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray700)),
              ],
            ),
            // Custom toggle switch
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : AppColors.gray200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray700)),
              ],
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }
}
