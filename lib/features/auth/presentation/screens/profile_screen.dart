import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/user.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../bloc/auth_bloc.dart';
import 'create_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> _emojis = [
    '🎉', '🏆', '🎬', '🦊', '🚀', '🎨',
    '🍕', '👑', '😎', '🔥', '🎭', '🎯',
    '🦄', '🐙', '🌮', '🎸', '⚡', '🍀',
  ];

  late final TextEditingController _nameController;
  String? _selectedEmoji;
  bool _saving = false;

  bool get _isGuest => widget.user.email == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _selectedEmoji = widget.user.avatarEmoji;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name')),
      );
      return;
    }
    setState(() => _saving = true);
    context.read<AuthBloc>().add(
          UpdateProfileRequested(
            displayName: name,
            // Empty string clears the emoji back to initials.
            avatarEmoji: _selectedEmoji ?? '',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr is AuthProfileUpdated || curr is AuthProfileUpdateFailure,
      listener: (context, state) {
        if (state is AuthProfileUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved')),
          );
          Navigator.of(context).pop();
        } else if (state is AuthProfileUpdateFailure) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: UserAvatar(
                    displayName: _nameController.text.isEmpty
                        ? widget.user.displayName
                        : _nameController.text,
                    avatarEmoji: _selectedEmoji,
                    radius: 52,
                  ),
                ),
                const SizedBox(height: 24),
                if (_isGuest) _buildGuestCta(context) else _buildEditForm(context),
                const SizedBox(height: 28),
                _buildAccountInfo(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestCta(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                size: 44, color: AppTheme.gold),
            const SizedBox(height: 12),
            Text(
              'You\'re playing as a guest',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create an account to save your progress and customise your '
              'profile across devices.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<AuthBloc>(),
                      child: const CreateAccountScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Display name',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Your name',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        Text('Choose an avatar',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        _buildEmojiGrid(context),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Widget _buildEmojiGrid(BuildContext context) {
    final options = <String?>[null, ..._emojis]; // null = use initials
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((emoji) {
        final selected = emoji == _selectedEmoji;
        return GestureDetector(
          onTap: () => setState(() => _selectedEmoji = emoji),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.violet.withOpacity(0.16)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppTheme.violet : Colors.black12,
                width: selected ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: emoji == null
                ? Icon(Icons.text_fields,
                    color: selected ? AppTheme.violet : AppTheme.inkSoft)
                : Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccountInfo(BuildContext context) {
    final created = DateFormat.yMMMM().format(widget.user.createdAt);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined, color: AppTheme.violet),
            title: const Text('Email'),
            subtitle: Text(widget.user.email ?? 'Guest (no email)'),
          ),
          const Divider(height: 1),
          ListTile(
            leading:
                const Icon(Icons.calendar_today_outlined, color: AppTheme.violet),
            title: const Text('Member since'),
            subtitle: Text(created),
          ),
        ],
      ),
    );
  }
}
