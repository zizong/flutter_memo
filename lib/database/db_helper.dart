import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/memo.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'memos.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE memos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // 插入新备忘录
  Future<int> insertMemo(Memo memo) async {
    final db = await database;
    return await db.insert('memos', memo.toMap());
  }

  // 更新备忘录
  Future<int> updateMemo(Memo memo) async {
    final db = await database;
    return await db.update(
      'memos',
      memo.toMap(),
      where: 'id = ?',
      whereArgs: [memo.id],
    );
  }

  // 删除备忘录
  Future<int> deleteMemo(int id) async {
    final db = await database;
    return await db.delete(
      'memos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 查询所有备忘录（按创建时间降序）
  Future<List<Memo>> getAllMemos() async {
    final db = await database;
    final result = await db.query('memos', orderBy: 'createdAt DESC');
    return result.map((map) => Memo.fromMap(map)).toList();
  }
}