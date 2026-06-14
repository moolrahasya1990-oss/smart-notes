import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/note.dart';
import '../../domain/repositories/notes_repository.dart';

class NotesRepositoryImpl implements NotesRepository {
  late Box _notesBox;
  late Box _categoriesBox;
  late Box _settingsBox;

  @override
  Future<void> init() async {
    // Open Hive boxes for local storage
    _notesBox = await Hive.openBox('smart_notes_box');
    _categoriesBox = await Hive.openBox('smart_categories_box');
    _settingsBox = await Hive.openBox('smart_settings_box');

    // Seed default categories if empty
    if (_categoriesBox.isEmpty) {
      final defaultCategories = ['Personal', 'Work', 'Study', 'Ideas', 'Shopping'];
      for (var cat in defaultCategories) {
        await _categoriesBox.add(cat);
      }
    }
  }

  @override
  List<Note> getNotes() {
    final List<Note> notes = [];
    for (var key in _notesBox.keys) {
      final value = _notesBox.get(key);
      if (value is Map) {
        try {
          notes.add(Note.fromJson(Map<String, dynamic>.from(value)));
        } catch (e) {
          // Skip corrupted entry
        }
      }
    }
    // Default descending sort: Pinned first, then by Last Modified date
    notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  @override
  Future<void> saveNote(Note note) async {
    await _notesBox.put(note.id, note.toJson());
  }

  @override
  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  @override
  List<String> getCategories() {
    return _categoriesBox.values.cast<String>().toList();
  }

  @override
  Future<void> addCategory(String category) async {
    if (!getCategories().contains(category)) {
      await _categoriesBox.add(category);
    }
  }

  @override
  Future<void> deleteCategory(String category) async {
    final keys = _categoriesBox.keys;
    dynamic targetKey;
    for (var k in keys) {
      if (_categoriesBox.get(k) == category) {
        targetKey = k;
        break;
      }
    }
    if (targetKey != null) {
      await _categoriesBox.delete(targetKey);
    }
  }

  @override
  String? getPin() {
    return _settingsBox.get('security_pin') as String?;
  }

  @override
  Future<void> savePin(String? pin) async {
    if (pin == null) {
      await _settingsBox.delete('security_pin');
    } else {
      await _settingsBox.put('security_pin', pin);
    }
  }

  @override
  bool isBiometricsEnabled() {
    return _settingsBox.get('biometrics_enabled', defaultValue: false) as bool;
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _settingsBox.put('biometrics_enabled', enabled);
  }

  @override
  Map<String, dynamic> exportNotesData() {
    final notesList = getNotes().map((n) => n.toJson()).toList();
    final categoriesList = getCategories();
    return {
      'app': 'SmartNotes',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'notes': notesList,
      'categories': categoriesList,
    };
  }

  @override
  Future<void> importNotesData(Map<String, dynamic> data) async {
    if (data['app'] != 'SmartNotes') throw Exception('Invalid backup format');
    
    // Import categories
    final categories = data['categories'] as List?;
    if (categories != null) {
      await _categoriesBox.clear();
      for (var cat in categories) {
        await _categoriesBox.add(cat.toString());
      }
    }

    // Import notes
    final notes = data['notes'] as List?;
    if (notes != null) {
      await _notesBox.clear();
      for (var noteData in notes) {
        final parsedMap = Map<String, dynamic>.from(noteData as Map);
        final note = Note.fromJson(parsedMap);
        await _notesBox.put(note.id, note.toJson());
      }
    }
  }
}
