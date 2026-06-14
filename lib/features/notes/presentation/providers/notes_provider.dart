import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../data/repositories/notes_repository_impl.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepositoryImpl();
});

class NotesState {
  final List<Note> allNotes;
  final List<Note> filteredNotes;
  final List<String> categories;
  final String searchQuery;
  final String? selectedCategoryName;
  final bool isGridView;

  NotesState({
    required this.allNotes,
    required this.filteredNotes,
    required this.categories,
    required this.searchQuery,
    this.selectedCategoryName,
    this.isGridView = true,
  });

  NotesState copyWith({
    List<Note>? allNotes,
    List<Note>? filteredNotes,
    List<String>? categories,
    String? searchQuery,
    String? Function()? selectedCategoryName,
    bool? isGridView,
  }) {
    return NotesState(
      allNotes: allNotes ?? this.allNotes,
      filteredNotes: filteredNotes ?? this.filteredNotes,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryName: selectedCategoryName != null ? selectedCategoryName() : this.selectedCategoryName,
      isGridView: isGridView ?? this.isGridView,
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final NotesRepository _repository;
  final _uuid = const Uuid();

  NotesNotifier(this._repository) : super(NotesState(allNotes: [], filteredNotes: [], categories: [], searchQuery: '')) {
    _init();
  }

  Future<void> _init() async {
    await _repository.init();
    _refresh();
  }

  void _refresh() {
    final notes = _repository.getNotes();
    final categories = _repository.getCategories();
    state = state.copyWith(
      allNotes: notes,
      categories: categories,
    );
    _applyFiltersAndSearch();
  }

  void _applyFiltersAndSearch() {
    var filtered = List<Note>.from(state.allNotes);

    // Filter by category
    if (state.selectedCategoryName != null) {
      filtered = filtered.where((n) => n.categoryName.toLowerCase() == state.selectedCategoryName!.toLowerCase()).toList();
    }

    // Search query
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      filtered = filtered.where((n) {
        return n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q);
      }).toList();
    }

    state = state.copyWith(filteredNotes: filtered);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFiltersAndSearch();
  }

  void selectCategory(String? categoryName) {
    state = state.copyWith(selectedCategoryName: () => categoryName);
    _applyFiltersAndSearch();
  }

  void toggleViewLayout() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  Future<void> addNote({
    required String title,
    required String content,
    required int colorValue,
    required String categoryName,
  }) async {
    final now = DateTime.now();
    final newNote = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      colorValue: colorValue,
      categoryName: categoryName,
    );
    await _repository.saveNote(newNote);
    _refresh();
  }

  Future<void> updateNote(Note updatedNote) async {
    final savedNote = updatedNote.copyWith(updatedAt: DateTime.now());
    await _repository.saveNote(savedNote);
    _refresh();
  }

  Future<void> togglePin(String id) async {
    final index = state.allNotes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final note = state.allNotes[index];
      final updated = note.copyWith(isPinned: !note.isPinned);
      await _repository.saveNote(updated);
      _refresh();
    }
  }

  Future<void> toggleFavorite(String id) async {
    final index = state.allNotes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final note = state.allNotes[index];
      final updated = note.copyWith(isFavorite: !note.isFavorite);
      await _repository.saveNote(updated);
      _refresh();
    }
  }

  Future<void> duplicateNote(Note note) async {
    final now = DateTime.now();
    final duplicated = note.copyWith(
      id: _uuid.v4(),
      title: '${note.title} (Copy)',
      createdAt: now,
      updatedAt: now,
      isPinned: false, // Don't carry pinned over to duplicate by default
    );
    await _repository.saveNote(duplicated);
    _refresh();
  }

  Future<void> deleteNote(String id) async {
    await _repository.deleteNote(id);
    _refresh();
  }

  Future<void> createCategory(String category) async {
    await _repository.addCategory(category);
    _refresh();
  }

  Future<void> removeCategory(String category) async {
    await _repository.deleteCategory(category);
    // If deleted category is currently selected, reset filtering
    if (state.selectedCategoryName == category) {
      state = state.copyWith(selectedCategoryName: () => null);
    }
    // Set notes that had this category back to 'Personal' default
    for (var note in state.allNotes) {
      if (note.categoryName == category) {
        await _repository.saveNote(note.copyWith(categoryName: 'Personal'));
      }
    }
    _refresh();
  }

  Map<String, dynamic> getExportData() {
    return _repository.exportNotesData();
  }

  Future<void> restoreBackup(Map<String, dynamic> data) async {
    await _repository.importNotesData(data);
    _refresh();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  return NotesNotifier(repo);
});
