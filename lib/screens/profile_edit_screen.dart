import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? profileImagePath;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser;
    _username.text = user?.username ?? '';
    _email.text = user?.email ?? '';
    profileImagePath = user?.profileImagePath;
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (result == null) return;
    setState(() => profileImagePath = result.path);
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final ok = await state.updateMyProfile(
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _password.text.trim().isEmpty ? null : _password.text.trim(),
      profileImagePath: profileImagePath,
    );
    if (!mounted) return;
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 45,
                backgroundImage: profileImagePath == null ? null : FileImage(File(profileImagePath!)),
                child: profileImagePath == null ? const Icon(Icons.camera_alt_rounded) : null,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
          const SizedBox(height: 10),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Mail')),
          const SizedBox(height: 10),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'New Password (optional)')),
          const SizedBox(height: 12),
          if (user != null) ...[
            Text('Saved anime: ${state.watchlistIds.length}'),
            const SizedBox(height: 4),
            Text('Account created: ${user.createdAt.toLocal()}'),
          ],
          const SizedBox(height: 18),
          FilledButton(onPressed: _save, child: const Text('Save Changes')),
        ],
      ),
    );
  }
}
