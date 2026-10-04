import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'chat_models.dart';

abstract class ChatStore {
  Future<List<RegisterDoc>> loadDocs(String midwifeId);
  Future<List<ChatMessage>> loadMessages(String midwifeId);
  Future<void> saveDoc(String midwifeId, RegisterDoc doc);
  Future<void> deleteDoc(String midwifeId, String docId);
  Future<void> saveMessage(String midwifeId, ChatMessage message);
}

class MemoryChatStore implements ChatStore {
  final Map<String, RegisterDoc> _docs = {};
  final Map<String, ChatMessage> _messages = {};

  String _docKey(String midwifeId, String id) => '$midwifeId::$id';

  @override
  Future<void> deleteDoc(String midwifeId, String docId) async {
    _docs.remove(_docKey(midwifeId, docId));
  }

  @override
  Future<List<RegisterDoc>> loadDocs(String midwifeId) async {
    return [
      for (final entry in _docs.entries)
        if (entry.key.startsWith('$midwifeId::')) entry.value,
    ];
  }

  @override
  Future<List<ChatMessage>> loadMessages(String midwifeId) async {
    final items = [
      for (final entry in _messages.entries)
        if (entry.key.startsWith('$midwifeId::')) entry.value,
    ]..sort((a, b) => a.at.compareTo(b.at));
    return items;
  }

  @override
  Future<void> saveDoc(String midwifeId, RegisterDoc doc) async {
    _docs[_docKey(midwifeId, doc.id)] = doc;
  }

  @override
  Future<void> saveMessage(String midwifeId, ChatMessage message) async {
    _messages[_docKey(midwifeId, message.id)] = message;
  }
}

class SqliteChatStore implements ChatStore {
  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      p.join(dir.path, 'dayone_chat.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE documents (id TEXT NOT NULL, midwife_id TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY (midwife_id, id))',
        );
        await db.execute(
          'CREATE TABLE messages (id TEXT NOT NULL, midwife_id TEXT NOT NULL, created_at INTEGER NOT NULL, payload TEXT NOT NULL, PRIMARY KEY (midwife_id, id))',
        );
      },
    );
    return _db!;
  }

  @override
  Future<void> deleteDoc(String midwifeId, String docId) async {
    final db = await _open();
    await db.delete('documents', where: 'midwife_id = ? AND id = ?', whereArgs: [midwifeId, docId]);
  }

  @override
  Future<List<RegisterDoc>> loadDocs(String midwifeId) async {
    final db = await _open();
    final rows = await db.query('documents', where: 'midwife_id = ?', whereArgs: [midwifeId]);
    return [
      for (final row in rows) RegisterDoc.fromJson(jsonDecode(row['payload'] as String) as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<ChatMessage>> loadMessages(String midwifeId) async {
    final db = await _open();
    final rows = await db.query(
      'messages',
      where: 'midwife_id = ?',
      whereArgs: [midwifeId],
      orderBy: 'created_at ASC',
    );
    return [
      for (final row in rows) ChatMessage.fromJson(jsonDecode(row['payload'] as String) as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> saveDoc(String midwifeId, RegisterDoc doc) async {
    final db = await _open();
    await db.insert(
      'documents',
      {'id': doc.id, 'midwife_id': midwifeId, 'payload': jsonEncode(doc.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveMessage(String midwifeId, ChatMessage message) async {
    final db = await _open();
    await db.insert(
      'messages',
      {
        'id': message.id,
        'midwife_id': midwifeId,
        'created_at': message.at.millisecondsSinceEpoch,
        'payload': jsonEncode(message.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
