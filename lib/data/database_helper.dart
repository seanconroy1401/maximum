import 'package:maximum/data/models/note.dart';
import 'package:maximum/data/models/task.dart';
import 'package:maximum/data/models/place.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'models/task_status.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE Place (
      placeId INTEGER PRIMARY KEY AUTOINCREMENT,
      lat REAL NOT NULL,
      lng REAL NOT NULL,
      name TEXT NOT NULL,
      maxDistance INTEGER DEFAULT 50
    );
    ''');

    await db.execute('''
    CREATE TABLE Task (
      taskId INTEGER PRIMARY KEY AUTOINCREMENT,
      text TEXT NOT NULL,
      date TEXT,
      time TEXT,
      isAsap INTEGER DEFAULT 0,
      targetValue INTEGER DEFAULT 1,
      exclusions TEXT,
      repeatType TEXT,
      repeatData TEXT,
      placeId INTEGER,
      active INTEGER DEFAULT 1,
      FOREIGN KEY(placeId) REFERENCES Place(placeId)
    );
    ''');

    await db.execute('''
    CREATE TABLE Note (
      noteId INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      text TEXT NOT NULL,
      datetime INTEGER,
      lat REAL,
      lng REAL,
      placeId INTEGER,
      FOREIGN KEY(placeId) REFERENCES Place(placeId)
    );
    ''');

    await db.execute('''
    CREATE TABLE TaskStatus (
      taskId INTEGER,
      datetime INTEGER,
      value INTEGER,
      FOREIGN KEY(taskId) REFERENCES Task(taskId),
      PRIMARY KEY(taskId, datetime)
    );
    ''');

    await db.execute('''
    CREATE TABLE TaskAttachment (
      attachmentId INTEGER PRIMARY KEY AUTOINCREMENT,
      taskId INTEGER,
      data TEXT,
      FOREIGN KEY(taskId) REFERENCES Task(taskId)
    );
    ''');

    await db.execute('''
    CREATE TABLE NoteAttachment (
      attachmentId INTEGER PRIMARY KEY AUTOINCREMENT,
      noteId INTEGER,
      data TEXT,
      FOREIGN KEY(noteId) REFERENCES Note(noteId)
    );
    ''');

    await db.execute('''
    CREATE TABLE TaskTag (
      tagId INTEGER PRIMARY KEY AUTOINCREMENT,
      color TEXT NOT NULL,
      name TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE TaskTag_Task (
      taskId INTEGER,
      tagId INTEGER,
      FOREIGN KEY(taskId) REFERENCES Task(taskId),
      FOREIGN KEY(tagId) REFERENCES TaskTag(tagId),
      PRIMARY KEY(taskId, tagId)
    )
    ''');

    await db.execute('''
    CREATE TABLE NoteTag (
      tagId INTEGER PRIMARY KEY AUTOINCREMENT,
      color TEXT NOT NULL,
      name TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE NoteTag_Note (
      noteId INTEGER,
      tagId INTEGER,
      FOREIGN KEY(noteId) REFERENCES Note(noteId),
      FOREIGN KEY(tagId) REFERENCES NoteTag(tagId),
      PRIMARY KEY(noteId, tagId)
    )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<Task?> getTask(int taskId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'Task',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    return Task.fromMap(maps.first);
  }

  Future<Place?> getPlace(int placeId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'Place',
      where: 'placeId = ?',
      whereArgs: [placeId],
    );
    return maps.isNotEmpty ? Place.fromMap(maps.first) : null;
  }

  Future<List<Place>> getPlaces() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'Place',
    );
    return maps.map((e) => Place.fromMap(e)).toList();
  }

  Future<List<Note>> get notes async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'Note',
    );
    return maps.map((e) => Note.fromMap(e)).toList();
  }

  Future<List<Task>> get tasks async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'Task',
    );
    return maps.map((e) => Task.fromMap(e)).toList();
  }

  Future<int> getMostRecentTaskStatus(int taskId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'TaskStatus',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'datetime DESC',
      limit: 1,
    );
    if (maps.isEmpty) return 0;
    return maps.first['value'];
  }

  Future<List<TaskStatus>> getTaskStatuses(int taskId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'TaskStatus',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'datetime DESC',
    );
    return maps.map((e) => TaskStatus.fromMap(e)).toList();
  }

  Future<int> insertTask(Task task) async {
    Database db = await database;
    return await db.insert('Task', task.toMap());
  }

  Future<int> insertNote(Note note) async {
    Database db = await database;
    return await db.insert('Note', note.toMap());
  }

  Future<int> insertPlace(Place place) async {
    Database db = await database;
    return await db.insert('Place', place.toMap());
  }

  Future<int> insertTaskStatus(TaskStatus taskStatus) async {
    Database db = await database;
    return await db.insert('TaskStatus', taskStatus.toMap());
  }

  Future<int> updateTask(Task task) async {
    Database db = await database;
    return await db.update(
      'Task',
      task.toMap(),
      where: 'taskId = ?',
      whereArgs: [task.taskId],
    );
  }
}
