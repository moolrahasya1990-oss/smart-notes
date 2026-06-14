import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/storage/backup_service.dart';
import '../providers/notes_provider.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  final _manualRestoreController = TextEditingController();
  bool _exporting = false;
  bool _importing = false;

  Future<void> _exportBackupZip() async {
    setState(() => _exporting = true);
    try {
      final exportMap = ref.read(notesProvider.notifier).getExportData();
      final zipFile = await BackupService.createBackupZip(exportMap);
      
      // Share ZIP using native dialog
      final xFile = XFile(zipFile.path, mimeType: 'application/zip');
      await Share.shareXFiles([xFile], subject: 'Smart Notes Backup ZIP');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup ZIP generated and shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _restorePastedJson() async {
    final rawText = _manualRestoreController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or paste backup JSON block.')),
      );
      return;
    }

    setState(() => _importing = true);
    try {
      final Map<String, dynamic> parsedData = jsonDecode(rawText) as Map<String, dynamic>;
      await ref.read(notesProvider.notifier).restoreBackup(parsedData);
      
      _manualRestoreController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All records restored successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed. Invalid format: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _restoreDemoSeeds() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Sample Data?'),
          content: const Text(
            'This fills your notepad with sample categories, notes, and records for demo purposes. Overwrites current records.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final sampleData = {
                  'app': 'SmartNotes',
                  'version': 1,
                  'categories': ['Personal', 'Work', 'Study', 'Shopping', 'Travel'],
                  'notes': [
                    {
                      'id': 'sample-1',
                      'title': '💡 App Development Ideas',
                      'content': '- Design layout in Flutter using M3 components\n- Add Hive database for fast local disk access\n- Complete Riverpod state management implementation\n- Add a bio passcode face ID lock screen',
                      'createdAt': DateTime.now().toIso8601String(),
                      'updatedAt': DateTime.now().toIso8601String(),
                      'colorValue': 0xffbfdbfe,
                      'categoryName': 'Ideas',
                      'isPinned': 1,
                      'isFavorite': 1,
                    },
                    {
                      'id': 'sample-2',
                      'title': '🛒 Weekly grocery lists',
                      'content': '- Apple cider vinegar\n- Greek yogurt (plain)\n- Fresh strawberries and avocados\n- Dark unsweetened chocolates',
                      'createdAt': DateTime.now().toIso8601String(),
                      'updatedAt': DateTime.now().toIso8601String(),
                      'colorValue': 0xfffef08a,
                      'categoryName': 'Shopping',
                      'isPinned': 0,
                      'isFavorite': 0,
                    }
                  ]
                };
                await ref.read(notesProvider.notifier).restoreBackup(sampleData);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sample notepad seed loaded successfully')),
                  );
                }
              },
              child: const Text('Load Seeds'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _manualRestoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Migration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DB Overview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.dns_rounded, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Local Notepad Statistics',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol('Notes', '${state.allNotes.length}'),
                        Container(color: Colors.grey.withOpacity(0.3), width: 1, height: 32),
                        _buildStatCol('Pinned', '${state.allNotes.where((n) => n.isPinned).length}'),
                        Container(color: Colors.grey.withOpacity(0.3), width: 1, height: 32),
                        _buildStatCol('Categories', '${state.categories.length}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action: Export
            const Text(
              'EXPORT DATA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _exporting ? null : _exportBackupZip,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              icon: _exporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.archive_rounded),
              label: Text(_exporting ? 'Compressing zip...' : 'Compress & Share Backup ZIP'),
            ),
            const SizedBox(height: 8),
            Text(
              'Creates a compressed .zip containing JSON definitions and allows sharing securely to cloud drives or files folders.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),

            const SizedBox(height: 32),

            // Action: Import / Restore
            const Text(
              'RESTORE DATA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualRestoreController,
              maxLines: 4,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Paste backup JSON code block here...',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _importing ? null : _restorePastedJson,
                    icon: const Icon(Icons.unarchive_rounded),
                    label: const Text('Restore JSON'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _restoreDemoSeeds,
                  child: const Text('Load Demo Seeds'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Pasting database block values is highly portable and avoids storage capability issues on older Android versions.',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String name, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
