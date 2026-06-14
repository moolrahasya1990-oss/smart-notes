import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/note.dart';
import '../providers/notes_provider.dart';
import 'add_edit_note_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Synchronize default search state query if loaded
    _searchController.addListener(() {
      ref.read(notesProvider.notifier).setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search notes by title or body...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.clear();
                ref.read(notesProvider.notifier).setSearchQuery('');
              },
            ),
        ],
      ),
      body: notesState.searchQuery.isEmpty
          ? _buildInitialPrompt(context)
          : notesState.filteredNotes.isEmpty
              ? _buildNoResults(context, notesState.searchQuery)
              : _buildSearchResults(context, notesState.filteredNotes),
    );
  }

  Widget _buildInitialPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainJointCheck: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'Type to search your notes...',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.55)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied_rounded, size: 60, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'No Matches Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any match for "$query". Refined spelling or terms.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, List<Note> results) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(
              note.title.trim().isEmpty ? 'Untitled Note' : note.title,
              fontWeight: FontWeight.bold,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              note.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Chip(
              label: Text(note.categoryName, style: const TextStyle(fontSize: 10)),
              padding: EdgeInsets.zero,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note)),
              );
            },
          ),
        );
      },
    );
  }
}
