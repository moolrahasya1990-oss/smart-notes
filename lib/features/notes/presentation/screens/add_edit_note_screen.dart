import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ads/ad_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/backup_service.dart';
import '../../domain/models/note.dart';
import '../providers/notes_provider.dart';

class AddEditNoteScreen extends ConsumerStatefulWidget {
  final Note? note;
  final String? defaultCategory;

  const AddEditNoteScreen({
    Key? key,
    this.note,
    this.defaultCategory,
  }) : super(key: key);

  @override
  ConsumerState<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends ConsumerState<AddEditNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  late String _categoryName;
  late int _colorValue;
  late bool _isPinned;
  late bool _isFavorite;
  String? _noteId;
  
  int _wordCount = 0;
  int _charCount = 0;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    if (note != null) {
      _noteId = note.id;
      _titleController.text = note.title;
      _contentController.text = note.content;
      _categoryName = note.categoryName;
      _colorValue = note.colorValue;
      _isPinned = note.isPinned;
      _isFavorite = note.isFavorite;
      _wordCount = note.wordCount;
      _charCount = note.charCount;
    } else {
      _categoryName = widget.defaultCategory ?? 'Personal';
      _colorValue = AppTheme.noteColors.first;
      _isPinned = false;
      _isFavorite = false;
    }

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _contentController.text;
    final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    setState(() {
      _wordCount = words;
      _charCount = text.length;
    });

    // Debounced Auto-save: Triggers saving 1.5 seconds after user stops typing
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), () {
      _saveNote(isAutoSave: true);
    });
  }

  Future<void> _saveNote({bool isAutoSave = false}) async {
    final title = _titleController.text;
    final content = _contentController.text;

    // Don't auto-save an empty draft. But if the note exists already and is emptied, keep saving.
    if (isAutoSave && title.trim().isEmpty && content.trim().isEmpty && _noteId == null) {
      return;
    }

    if (_noteId == null) {
      // First save: Create Note and assign a fresh UUID so subsequent updates write back
      final generatedId = DateTime.now().millisecondsSinceEpoch.toString(); // Fallback temp ID
      _noteId = generatedId;
      await ref.read(notesProvider.notifier).addNote(
        title: title,
        content: content,
        colorValue: _colorValue,
        categoryName: _categoryName,
      );
      // Retrieve the newly created note to sync its actual ID
      final list = ref.read(notesProvider).allNotes;
      if (list.isNotEmpty) {
        _noteId = list.first.id; // Map key
      }
    } else {
      // Edit existing note
      final existingNote = widget.note ?? _findNoteInState(_noteId!);
      if (existingNote != null) {
        final updated = existingNote.copyWith(
          title: title,
          content: content,
          categoryName: _categoryName,
          colorValue: _colorValue,
          isPinned: _isPinned,
          isFavorite: _isFavorite,
        );
        await ref.read(notesProvider.notifier).updateNote(updated);
      }
    }
  }

  Note? _findNoteInState(String id) {
    try {
      return ref.read(notesProvider).allNotes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final theme = Theme.of(context);
    final isCustomColorActive = _colorValue != 0xFFFFFFFF;

    final scaffoldBg = isCustomColorActive ? Color(_colorValue) : theme.scaffoldBackgroundColor;
    final textColor = isCustomColorActive ? Colors.black87 : theme.colorScheme.onSurface;

    return WillPopScope(
      onWillPop: () async {
        _autoSaveTimer?.cancel();
        await _saveNote(); // Save immediately on back press

        // Show interstitial ad, then pop the screen
        AdService.showInterstitialAd(onComplete: () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
        return false; // Return false to manually handle popping via Navigator after ad is closed
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: Icon(_isPinned ? Icons.pin_drop_rounded : Icons.pin_drop_outlined, color: textColor),
              onPressed: () {
                setState(() => _isPinned = !_isPinned);
                _saveNote(isAutoSave: true);
              },
            ),
            IconButton(
              icon: Icon(_isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, color: textColor),
              onPressed: () {
                setState(() => _isFavorite = !_isFavorite);
                _saveNote(isAutoSave: true);
              },
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: textColor),
              onSelected: (action) async {
                await _saveNote();
                if (!mounted) return;
                
                final currentNote = _findNoteInState(_noteId ?? '');
                if (currentNote == null) return;

                if (action == 'duplicate') {
                  await ref.read(notesProvider.notifier).duplicateNote(currentNote);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note duplicated successfully')),
                    );
                  }
                } else if (action == 'share_text') {
                  await BackupService.shareNoteAsText(currentNote);
                } else if (action == 'share_file') {
                  final file = await BackupService.exportNoteToTxt(currentNote);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Note exported as TXT to local cache: ${file.path}')),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'duplicate', child: Text('Duplicate Note')),
                const PopupMenuItem(value: 'share_text', child: Text('Share as Text')),
                const PopupMenuItem(value: 'share_file', child: Text('Export to TXT')),
              ],
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Category Swiper Dropdown
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: isCustomColorActive ? Colors.black12 : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: isCustomColorActive ? null : Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: notesState.categories.contains(_categoryName) ? _categoryName : 'Personal',
                    dropdownColor: isCustomColorActive ? Color(_colorValue) : theme.colorScheme.surface,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _categoryName = val);
                        _saveNote(isAutoSave: true);
                      }
                    },
                    items: notesState.categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Title Field
              TextField(
                controller: _titleController,
                maxLength: 80,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Note Title',
                  hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),

              // Content Fields
              Expanded(
                child: CustomPaint(
                  painter: NotebookLinesPainter(
                    lineColor: textColor.withOpacity(0.12),
                    lineHeight: 28.0, // Matches fontSize 16 * height 1.75 = 28.0
                    offsetTop: 22.0,  // Offsets line alignment perfectly with first line of text
                  ),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      height: 1.75, // Matches lineHeight 28.0
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start writing your amazing notes here...',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(top: 0, bottom: 8),
                    ),
                  ),
                ),
              ),

              // Color swatch bar
              _buildColorSelectorBar(),

              // Word counter footer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: textColor.withOpacity(0.12))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Words: $_wordCount  |  Characters: $_charCount',
                      style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
                    ),
                    Text(
                      _noteId != null ? 'Synced' : 'Drafting',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSelectorBar() {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppTheme.noteColors.length,
        itemBuilder: (context, index) {
          final color = AppTheme.noteColors[index];
          final isSelected = _colorValue == color;
          final borderDecoration = isSelected
              ? Border.all(color: Colors.black87, width: 2)
              : Border.all(color: Colors.black12, width: 1);

          return GestureDetector(
            onTap: () {
              setState(() => _colorValue = color);
              _saveNote(isAutoSave: true);
            },
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color == 0xFFFFFFFF ? Colors.white : Color(color),
                shape: BoxShape.circle,
                border: borderDecoration,
              ),
              child: isSelected ? const Icon(Icons.done, size: 18, color: Colors.black87) : null,
            ),
          );
        },
      ),
    );
  }
}

class NotebookLinesPainter extends CustomPainter {
  final Color lineColor;
  final double lineHeight;
  final double offsetTop;

  NotebookLinesPainter({
    required this.lineColor,
    required this.lineHeight,
    required this.offsetTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    for (double y = offsetTop; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NotebookLinesPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || 
           oldDelegate.lineHeight != lineHeight || 
           oldDelegate.offsetTop != offsetTop;
  }
}
