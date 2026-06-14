import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notes_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _categoryController = TextEditingController();

  void _onAddCategory() {
    final catName = _categoryController.text.trim();
    if (catName.isEmpty) return;

    ref.read(notesProvider.notifier).createCategory(catName);
    _categoryController.clear();
    Navigator.pop(context); // Close dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Category "$catName" created')),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: _categoryController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Group name (e.g. Finance, Goals)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _categoryController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _onAddCategory,
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.categories.length,
        itemBuilder: (context, index) {
          final category = state.categories[index];
          final noteCount = state.allNotes.where((n) => n.categoryName == category).length;
          final isProtected = ['personal', 'work', 'study', 'ideas', 'shopping']
              .contains(category.toLowerCase());

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.folder_open_rounded, color: theme.colorScheme.primary),
              ),
              title: Text(
                category,
                fontWeight: FontWeight.bold,
              ),
              subtitle: Text('$noteCount notes'),
              trailing: isProtected
                  ? const Tooltip(
                      message: 'System category',
                      child: Icon(Icons.lock_outline_rounded, size: 18),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteCategory(category),
                    ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _confirmDeleteCategory(String category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete "$category"?'),
          content: Text(
            'This will permanently delete this category. Selected notes in "$category" will revert to "Personal".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(notesProvider.notifier).removeCategory(category);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "$category" deleted')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
