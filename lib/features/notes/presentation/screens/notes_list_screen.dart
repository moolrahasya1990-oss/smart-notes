import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ads/banner_ad_widget.dart';
import '../../domain/models/note.dart';
import '../providers/notes_provider.dart';
import 'add_edit_note_screen.dart';
import 'categories_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(notesProvider);
    final notesNotifier = ref.read(notesProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(notesState.isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => notesNotifier.toggleViewLayout(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal Custom Category List Selector
          _buildCategorySelector(context, notesState, notesNotifier),
          const SizedBox(height: 8),
          
          // Notes List Content
          Expanded(
            child: notesState.filteredNotes.isEmpty
                ? _buildEmptyState(context, notesState.selectedCategoryName)
                : notesState.isGridView
                    ? _buildGridView(context, notesState.filteredNotes, notesNotifier)
                    : _buildListView(context, notesState.filteredNotes, notesNotifier),
          ),

          // Bottom Banner Ad
          const BannerAdWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditNoteScreen(
                defaultCategory: notesState.selectedCategoryName ?? 'Personal',
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Note'),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, NotesState state, NotesNotifier notifier) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = state.selectedCategoryName == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: isSelected,
                onSelected: (_) => notifier.selectCategory(null),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            );
          }

          final category = state.categories[index - 1];
          final isSelected = state.selectedCategoryName == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => notifier.selectCategory(category),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String? selectedCategory) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            selectedCategory == null
                ? 'Your Notepad is Empty'
                : 'No notes in "$selectedCategory"',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            selectedCategory == null
                ? 'Create your first note using the button below!'
                : 'Click code or write notes in other sectors',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(BuildContext context, List<Note> notes, NotesNotifier notifier) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        return _NoteCard(
          note: notes[index],
          onTap: () => _openNoteEditor(context, notes[index]),
          onLongPress: () => _showNoteActions(context, notes[index], notifier),
        );
      },
    );
  }

  Widget _buildListView(BuildContext context, List<Note> notes, NotesNotifier notifier) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _NoteCard(
            note: notes[index],
            onTap: () => _openNoteEditor(context, notes[index]),
            onLongPress: () => _showNoteActions(context, notes[index], notifier),
          ),
        );
      },
    );
  }

  void _openNoteEditor(BuildContext context, Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note)),
    );
  }

  void _showNoteActions(BuildContext context, Note note, NotesNotifier notifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  note.title.trim().isEmpty ? 'Note Options' : note.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(note.isPinned ? Icons.pin_drop_rounded : Icons.pin_drop_outlined),
                title: Text(note.isPinned ? 'Unpin Note' : 'Pin Note'),
                onTap: () {
                  notifier.togglePin(note.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(note.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded),
                title: Text(note.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
                onTap: () {
                  notifier.toggleFavorite(note.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Duplicate Note'),
                onTap: () {
                  notifier.duplicateNote(note);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Delete Note', style: TextStyle(color: Colors.red)),
                onTap: () {
                  notifier.deleteNote(note.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note deleted successfully')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NoteCard({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = note.colorValue == 0xFFFFFFFF
        ? theme.colorScheme.surface
        : Color(note.colorValue);
    final defaultTextPrimary = theme.colorScheme.onSurface;
    final defaultTextSecondary = theme.colorScheme.onSurface.withOpacity(0.65);

    // If card has a highly saturated bright background, adapt text color readability
    final textColor = note.colorValue == 0xFFFFFFFF ? defaultTextPrimary : Colors.black87;
    final secondaryColor = note.colorValue == 0xFFFFFFFF ? defaultTextSecondary : Colors.black54;

    return Card(
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title.trim().isEmpty ? 'Untitled Note' : note.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontStyle: note.title.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(Icons.pin_drop_rounded, size: 16, color: note.colorValue == 0xFFFFFFFF ? theme.colorScheme.primary : Colors.black87),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.content,
                  style: TextStyle(fontSize: 13, color: secondaryColor, height: 1.3),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: note.colorValue == 0xFFFFFFFF
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note.categoryName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: note.colorValue == 0xFFFFFFFF
                            ? theme.colorScheme.primary
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(fontSize: 10, color: secondaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
