import '../models/note.dart';

abstract class NotesRepository {
  Future<void> init();
  List<Note> getNotes();
  Future<void> saveNote(Note note);
  Future<void> deleteNote(String id);
  
  List<String> getCategories();
  Future<void> addCategory(String category);
  Future<void> deleteCategory(String category);

  // Security Lock
  String? getPin();
  Future<void> savePin(String? pin);
  bool isBiometricsEnabled();
  Future<void> setBiometricsEnabled(bool enabled);

  // Backup & Export JSON
  Map<String, dynamic> exportNotesData();
  Future<void> importNotesData(Map<String, dynamic> data);
}
