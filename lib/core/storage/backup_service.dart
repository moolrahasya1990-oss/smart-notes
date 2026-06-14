import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/notes/domain/models/note.dart';

class BackupService {
  // Export a simple text summary of a single note
  static Future<void> shareNoteAsText(Note note) async {
    final text = 'Title: ${note.title}\n\nLast Modified: ${note.updatedAt}\nWord Count: ${note.wordCount}\n\n${note.content}';
    await Share.share(text, subject: 'Smart Notes: ${note.title}');
  }

  // Export a note as a .txt File
  static Future<File> exportNoteToTxt(Note note) async {
    final tempDir = await getTemporaryDirectory();
    // Sanitize filename
    final safeTitle = note.title.replaceAll(RegExp(r'[^\w\s\-]'), '_');
    final filename = safeTitle.trim().isEmpty ? 'Note_${note.id}' : safeTitle;
    final file = File('${tempDir.path}/$filename.txt');
    await file.writeAsString('Title: ${note.title}\nLast Modified: ${note.updatedAt}\n\n${note.content}');
    return file;
  }

  // Generate ZIP backup from data map
  static Future<File> createBackupZip(Map<String, dynamic> data) async {
    final tempDir = await getTemporaryDirectory();
    final jsonStr = jsonEncode(data);

    // Create the JSON file
    final jsonFile = File('${tempDir.path}/backup_data.json');
    await jsonFile.writeAsString(jsonStr);

    // Compress using archive
    final archive = Archive();
    final jsonBytes = await jsonFile.readAsBytes();
    archive.addFile(ArchiveFile('backup_data.json', jsonBytes.length, jsonBytes));

    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    final zipFile = File('${tempDir.path}/SmartNotes_Backup.zip');
    await zipFile.writeAsBytes(zipBytes!);
    
    return zipFile;
  }

  // Untar / Unzip backup ZIP and compile JSON data
  static Future<Map<String, dynamic>> readBackupZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      if (file.isFile && file.name == 'backup_data.json') {
        final contentStr = utf8.decode(file.content as List<int>);
        return jsonDecode(contentStr) as Map<String, dynamic>;
      }
    }
    throw Exception('backup_data.json not found inside the ZIP archive');
  }
}
