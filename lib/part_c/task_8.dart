import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes CRUD App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => NotesPage(),
        '/detail': (context) => NoteDetailPage(),
      },
    );
  }
}

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() async {
    final notes = await DatabaseHelper.instance.getNotes();
    setState(() {
      _notes = notes;
    });
  }

  void _addNoteDialog() async {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: contentController, decoration: InputDecoration(labelText: 'Content')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await DatabaseHelper.instance.insertNote({
                  'title': titleController.text,
                  'content': contentController.text
                });
                _loadNotes();
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openDetailScreen(Map<String, dynamic> note) async {
    await Navigator.pushNamed(context, '/detail', arguments: note);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Notes')),
      body: _notes.isEmpty
          ? Center(child: Text('No notes yet. Add one!'))
          : ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(note['title']),
              subtitle: Text(note['content']),
              onTap: () => _openDetailScreen(note),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNoteDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}

class NoteDetailPage extends StatefulWidget {
  @override
  _NoteDetailPageState createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late Map<String, dynamic> note;
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    note = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    titleController = TextEditingController(text: note['title']);
    contentController = TextEditingController(text: note['content']);
  }

  void _updateNote() async {
    await DatabaseHelper.instance.updateNote({
      'id': note['id'],
      'title': titleController.text,
      'content': contentController.text,
    });
    Navigator.pop(context);
  }

  void _deleteNote() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteNote(note['id']);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Note Details'),
        actions: [
          IconButton(icon: Icon(Icons.delete), onPressed: _deleteNote),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
            SizedBox(height: 10),
            TextField(controller: contentController, decoration: InputDecoration(labelText: 'Content')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _updateNote, child: Text('Save Changes')),
          ],
        ),
      ),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT
      )
    ''');
  }

  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await instance.database;
    return await db.insert('notes', note);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await instance.database;
    return await db.query('notes', orderBy: 'id DESC');
  }

  Future<int> updateNote(Map<String, dynamic> note) async {
    final db = await instance.database;
    return await db.update('notes', note, where: 'id = ?', whereArgs: [note['id']]);
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
