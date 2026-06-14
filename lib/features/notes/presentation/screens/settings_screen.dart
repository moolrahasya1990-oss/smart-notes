import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'lock_screen.dart';
import 'backup_restore_screen.dart';
import 'categories_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Section: Workspace
          _buildSectionHeader('Workspace'),
          ListTile(
            leading: const Icon(Icons.category_rounded),
            title: const Text('Manage Categories'),
            subtitle: const Text('Add, rename or delete notes filters'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          
          const Divider(),

          // Section: Appearance
          _buildSectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text('App Theme'),
            subtitle: Text(_themeModeName(themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeProvider.notifier).setThemeMode(mode);
                }
              },
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light Mode')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark Mode')),
              ],
            ),
          ),

          const Divider(),

          // Section: Security
          _buildSectionHeader('Security & Privacy'),
          if (!authState.hasPin) ...[
            ListTile(
              leading: const Icon(Icons.lock_rounded),
              title: const Text('Enable Security PIN'),
              subtitle: const Text('Secure notes using a 4-digit passcode'),
              trailing: const Icon(Icons.add_rounded),
              onTap: () => _setupPasscode(context, authNotifier),
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.phonelink_lock_rounded),
              title: const Text('Remove Security PIN'),
              subtitle: const Text('Remove application passcode'),
              trailing: const Icon(Icons.no_encryption_rounded, color: Colors.grey),
              onTap: () {
                authNotifier.removePin();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Security PIN removed')),
                );
              },
            ),
            if (authState.isBiometricsSupported)
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded),
                title: const Text('Biometric Unlock'),
                subtitle: const Text('Unlock using fingerprint or Face ID'),
                value: authState.isBiometricsEnabled,
                onChanged: (enabled) {
                  authNotifier.toggleBiometrics(enabled);
                },
              ),
          ],

          const Divider(),

          // Section: Migration
          _buildSectionHeader('Backup & Migration'),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore_rounded),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Export notepad ZIP or restore files'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
              );
            },
          ),

          const Divider(),

          // Section: About
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Smart Notes'),
            subtitle: Text('v1.0.0 (Release)  |  Offline First Notepad'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '© 2026 Smart Notes. Your notes are stored entirely on this device and are fully private.',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String heading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        heading.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Theme Active';
      case ThemeMode.dark:
        return 'Dark Theme Active';
    }
  }

  void _setupPasscode(BuildContext context, AuthNotifier notifier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LockScreen(
          isSettingPin: true,
          onPinConfigured: (newPin) {
            notifier.setPin(newPin);
            Navigator.pop(context); // Pop LockScreen setup
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passcode enabled successfully!')),
            );
          },
        ),
      ),
    );
  }
}
