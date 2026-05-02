import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'note_editor_page.dart';
import 'note_model.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> allNotes = [];
  List<Note> filteredNotes = [];
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory; // 使用 String 筛选
  bool _onlyShowFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadNotesFromLocal();
    _searchController.addListener(_filterNotes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList('notes') ?? [];
    if (!mounted) return;
    setState(() {
      allNotes = notesJson
          .map((jsonStr) => Note.fromJson(json.decode(jsonStr)))
          .toList();
      _filterNotes();
    });
  }

  Future<void> _saveNotesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = allNotes
        .map((note) => json.encode(note.toJson()))
        .toList();
    await prefs.setStringList('notes', notesJson);
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredNotes = allNotes.where((note) {
        final plainText = _getPlainTextPreview(note.content).toLowerCase();
        final matchSearch =
            note.title.toLowerCase().contains(query) ||
            plainText.contains(query) ||
            note.tags.any((tag) => tag.toLowerCase().contains(query));

        final matchCategory =
            _selectedCategory == null || note.category == _selectedCategory;
        final matchFavorite = !_onlyShowFavorite || note.isFavorite;
        return matchSearch && matchCategory && matchFavorite;
      }).toList();
      filteredNotes.sort((a, b) => b.createTime.compareTo(a.createTime));
    });
  }

  String _getPlainTextPreview(String content) {
    if (content.isEmpty) return "无内容";
    try {
      final doc = quill.Document.fromJson(jsonDecode(content));
      final text = doc.toPlainText().trim();
      return text.isEmpty ? "无内容" : text;
    } catch (e) {
      return content;
    }
  }

  Future<void> _createNewNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditorPage()),
    );
    if (result != null && result is Note) {
      if (!mounted) return;
      setState(() {
        allNotes.insert(0, result);
        _searchController.clear();
      });
      await _saveNotesToLocal();
      _filterNotes();
    }
  }

  Future<void> _editNote(int index) async {
    final note = filteredNotes[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)),
    );

    if (result != null && result is Note) {
      if (!mounted) return;
      setState(() {
        final originalIndex = allNotes.indexOf(note);
        if (originalIndex != -1) {
          allNotes[originalIndex] = result;
        }
      });
      await _saveNotesToLocal();
      _filterNotes();
    }
  }

  Future<void> _deleteNoteWithConfirm(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确定删除？"),
        content: const Text("删除后笔记将无法找回。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("确定", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && index < filteredNotes.length) {
      final note = filteredNotes[index];
      if (!mounted) return;
      setState(() => allNotes.remove(note));
      await _saveNotesToLocal();
      _filterNotes();
    }
  }

  Future<void> _toggleFavorite(int index) async {
    final note = filteredNotes[index];
    setState(() {
      final originalIndex = allNotes.indexOf(note);
      if (originalIndex == -1) return;
      allNotes[originalIndex] = Note(
        title: note.title,
        content: note.content,
        createTime: note.createTime,
        updateTime: note.updateTime,
        textColor: note.textColor,
        imagePaths: note.imagePaths,
        isFavorite: !note.isFavorite,
        category: note.category,
        tags: note.tags,
        hasHistoryLink: note.hasHistoryLink,
      );
    });
    await _saveNotesToLocal();
    _filterNotes();
  }

  void _showCategoryFilter() {
    Set<String> dynamicCategories = {'代数', '几何', '微积分', '其他'};
    for (var n in allNotes) {
      dynamicCategories.add(n.category);
    }
    List<String> categoriesToShow = dynamicCategories.toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "按分类筛选",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...categoriesToShow.map((category) {
            final bool selected = _selectedCategory == category;
            return ListTile(
              title: Text(category),
              leading: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? Theme.of(context).primaryColor : Colors.grey,
              ),
              onTap: () {
                setState(() => _selectedCategory = category);
                _filterNotes();
                Navigator.pop(context);
              },
            );
          }).toList(),
          const Divider(),
          ListTile(
            title: const Text(
              '全部分类 (取消筛选)',
              style: TextStyle(color: Colors.blue),
            ),
            leading: Icon(
              _selectedCategory == null ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: _selectedCategory == null ? Colors.blue : Colors.grey,
            ),
            onTap: () {
              setState(() => _selectedCategory = null);
              _filterNotes();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("我的笔记"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "搜索笔记/标签...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.blue),
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('语音搜索功能待接入')));
                  },
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showCategoryFilter,
            icon: const Icon(Icons.category),
            tooltip: "分类筛选",
          ),
          IconButton(
            onPressed: () {
              setState(() => _onlyShowFavorite = !_onlyShowFavorite);
              _filterNotes();
            },
            icon: Icon(
              _onlyShowFavorite ? Icons.favorite : Icons.favorite_border,
              color: _onlyShowFavorite ? Colors.red : null,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        child: const Icon(Icons.add),
      ),
      body: filteredNotes.isEmpty
          ? const Center(child: Text("还没有笔记，点击+号创建"))
          : ListView.builder(
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final note = filteredNotes[index];
                final createTimeStr =
                    "${note.createTime.year}-${note.createTime.month.toString().padLeft(2, '0')}-${note.createTime.day.toString().padLeft(2, '0')} ${note.createTime.hour.toString().padLeft(2, '0')}:${note.createTime.minute.toString().padLeft(2, '0')}";

                return ListTile(
                  title: Text(note.title.isEmpty ? "无标题" : note.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPlainTextPreview(note.content),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (note.tags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: note.tags
                              .map(
                                (tag) => Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  backgroundColor: Colors.grey[200],
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        "${note.category} | $createTimeStr",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          note.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: note.isFavorite ? Colors.red : null,
                          size: 20,
                        ),
                        onPressed: () => _toggleFavorite(index),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteNoteWithConfirm(index),
                      ),
                    ],
                  ),
                  onTap: () => _editNote(index),
                );
              },
            ),
    );
  }
}
