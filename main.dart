import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'note_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Simple Note',
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
              primaryColor: Colors.orange,
              scaffoldBackgroundColor: Colors.black,
            )
          : ThemeData.light().copyWith(
              primaryColor: Colors.orange,
              scaffoldBackgroundColor: Colors.white,
            ),
      home: NoteListScreen(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

class NoteListScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const NoteListScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  // ignore: library_private_types_in_public_api
  _NoteListScreenState createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNotes();
    _searchController.addListener(_onSearchChanged);
  }

  void _fetchNotes() async {
    List<Note> notes = await _dbHelper.getAllNotes();
    setState(() {
      _notes = notes;
      _filteredNotes = notes; // Default to showing all notes
    });
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredNotes = _notes; // Reset to all notes if search is empty
      } else {
        _filteredNotes = _notes.where((note) =>
            note.title.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
      }
    });
  }

  void _navigateToEditNoteScreen({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(note: note),
      ),
    );
    if (result == true) {
      _fetchNotes(); // Refresh notes when returning from edit screen
    }
  }

  void _navigateToViewNoteScreen(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewNoteScreen(note: note),
      ),
    );
  }

  void _sortNotesAlphabetically() {
    setState(() {
      _filteredNotes.sort((a, b) => a.title.compareTo(b.title));
    });
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sort Notes"),
          content: const Text("Choose an order for your notes:"),
          actions: [
            TextButton(
              child: const Text("Alphabetical"),
              onPressed: () {
                _sortNotesAlphabetically();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Default Order"),
              onPressed: () {
                setState(() {
                  _filteredNotes = _notes; // Reset to default order
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Note note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this note?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Return false
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Return true
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _dbHelper.deleteNoteById(note.id!);
      _fetchNotes(); // Refresh notes after deletion
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Simple Note',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear(); // Clear the search input
                  _filteredNotes = _notes; // Reset to all notes
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.black,
            ),
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: _showSortOptions,
          ),
        ],
        backgroundColor: Colors.orange,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _isSearching
                ? TextField(
                    controller: _searchController,
                    style: TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(),
                      hintStyle: TextStyle(color: Color.fromARGB(137, 57, 76, 247)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  )
                : Container(),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 194, 192, 192),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _filteredNotes = _notes; // Show all notes when button pressed
                });
              },
              child: const Text(
                "All Notes",
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 84, 150),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                final note = _filteredNotes[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 41, 40, 40), // Light ash background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(
                      note.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    subtitle: Text(
                      note.content.split('\n').first,
                      style: const TextStyle(fontSize: 18, color: Color.fromARGB(255, 146, 144, 144)),
                    ),
                    onTap: () => _navigateToViewNoteScreen(note),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToEditNoteScreen(note: note),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.blue),
                          onPressed: () => _confirmDelete(note), // Updated to use confirmation dialog
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditNoteScreen(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class EditNoteScreen extends StatefulWidget {
  final Note? note;
  const EditNoteScreen({super.key, this.note});

  @override
  // ignore: library_private_types_in_public_api
  _EditNoteScreenState createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final content = _contentController.text;

    if (title.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Please enter a title for the note."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    if (widget.note == null) {
      await _dbHelper.insertNote(Note(
        title: title,
        content: content,
      ));
    } else {
      await _dbHelper.updateNote(Note(
        id: widget.note!.id,
        title: title,
        content: content,
      ));
    }

    Navigator.pop(context, true); // Return true to indicate a successful save
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note',
        style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: null, // Allow multi-line input
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveNote,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewNoteScreen extends StatelessWidget {
  final Note note;

  const ViewNoteScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(note.title,style: const TextStyle(color: Colors.black),),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.black),
        
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(note.content, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
