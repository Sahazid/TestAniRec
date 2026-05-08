import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'admin_screen.dart';
import 'auth_screen.dart';
import 'behavior_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 16, 18, 110),
        children: [
          const Text('Profile', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -.7)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF6B00), Color(0xFF8B5CF6), Color(0xFF111827)]),
              boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(.24), blurRadius: 32, offset: const Offset(0, 16))],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: user == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
              child: Row(
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.18), border: Border.all(color: Colors.white.withOpacity(.25))),
                    child: user?.profileImagePath == null
                        ? const Icon(Icons.person_rounded, size: 38, color: Colors.white)
                        : ClipOval(child: Image.file(File(user!.profileImagePath!), fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user == null ? 'Guest User' : user.username, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        user == null
                            ? 'Login to sync watchlist and profile'
                            : '${state.watchlistIds.length} saved anime • Joined ${user.createdAt.toLocal().toString().split(".").first}',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          if (user == null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
              child: const Text('Login / Signup'),
            ),
          ] else ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => state.logout(),
              child: const Text('Logout'),
            ),
          ],
          const SizedBox(height: 22),
          _ModernTile(
            icon: state.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Theme Mode',
            subtitle: state.isDark ? 'Dark futuristic anime mode enabled' : 'Clean light mode enabled',
            trailing: Switch(value: state.isDark, onChanged: (_) => state.toggleTheme()),
          ),
          if (user != null)
            _ModernTile(
              icon: Icons.psychology_rounded,
              title: 'AI Behavior Learning',
              subtitle: state.behaviorKeywords.isEmpty ? 'Search and save anime to train recommendations.' : state.behaviorKeywords.join(', '),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BehaviorScreen())),
            ),
          if (user?.isAdmin == true)
            _ModernTile(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Admin Panel',
              subtitle: 'Manage users, anime and app stats',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
            ),
        ],
      ),
    );
  }
}

class _ModernTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _ModernTile({required this.icon, required this.title, required this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: 16,
        leading: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Theme.of(context).colorScheme.primary.withOpacity(.14)),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
