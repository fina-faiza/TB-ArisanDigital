import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('arisan_digital.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        nama TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'anggota'
      )
    ''');

    await db.execute('''
      CREATE TABLE anggota (
        id TEXT PRIMARY KEY,
        nama TEXT NOT NULL,
        no_hp TEXT NOT NULL,
        alamat TEXT,
        nominal INTEGER NOT NULL,
        status_aktif INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE arisan (
        id TEXT PRIMARY KEY,
        nama_arisan TEXT NOT NULL,
        periode TEXT NOT NULL,
        nominal INTEGER NOT NULL,
        tanggal_mulai TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'aktif'
      )
    ''');

    await db.execute('''
      CREATE TABLE pembayaran (
        id TEXT PRIMARY KEY,
        anggota_id TEXT NOT NULL,
        arisan_id TEXT NOT NULL,
        jumlah INTEGER NOT NULL,
        metode TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'lunas',
        FOREIGN KEY (anggota_id) REFERENCES anggota(id),
        FOREIGN KEY (arisan_id) REFERENCES arisan(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pengocokan (
        id TEXT PRIMARY KEY,
        arisan_id TEXT NOT NULL,
        anggota_id TEXT NOT NULL,
        tanggal_kocok TEXT NOT NULL,
        periode_ke INTEGER NOT NULL,
        FOREIGN KEY (arisan_id) REFERENCES arisan(id),
        FOREIGN KEY (anggota_id) REFERENCES anggota(id)
      )
    ''');

    await db.insert('users', {
      'id': 'pengurus-001',
      'nama': 'Pengurus Arisan',
      'email': 'pengurus@arisan.com',
      'password': 'admin123',
      'role': 'pengurus',
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}