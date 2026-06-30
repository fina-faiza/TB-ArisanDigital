import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('arisan_khadijiyyah.db');
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
        role TEXT NOT NULL DEFAULT 'pengurus'
      )
    ''');

    await db.execute('''
      CREATE TABLE periode (
        id TEXT PRIMARY KEY,
        nama_periode TEXT NOT NULL,
        tahun TEXT NOT NULL,
        bulan_mulai TEXT NOT NULL,
        bulan_selesai TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'aktif'
      )
    ''');

    await db.execute('''
      CREATE TABLE grup_arisan (
        id TEXT PRIMARY KEY,
        periode_id TEXT NOT NULL,
        nama_grup TEXT NOT NULL,
        nominal INTEGER NOT NULL,
        jumlah_peserta INTEGER NOT NULL,
        jumlah_pemenang_per_putaran INTEGER NOT NULL,
        total_putaran INTEGER NOT NULL,
        FOREIGN KEY (periode_id) REFERENCES periode(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE anggota (
        id TEXT PRIMARY KEY,
        grup_id TEXT NOT NULL,
        nama TEXT NOT NULL,
        no_hp TEXT NOT NULL,
        alamat TEXT,
        status_aktif INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (grup_id) REFERENCES grup_arisan(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pembayaran (
        id TEXT PRIMARY KEY,
        anggota_id TEXT NOT NULL,
        grup_id TEXT NOT NULL,
        jumlah INTEGER NOT NULL,
        metode TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        bulan TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'lunas',
        FOREIGN KEY (anggota_id) REFERENCES anggota(id),
        FOREIGN KEY (grup_id) REFERENCES grup_arisan(id)
      )
    ''');

    // status: 'menunggu', 'diambil', 'tidak_diambil'
    await db.execute('''
      CREATE TABLE pengocokan (
        id TEXT PRIMARY KEY,
        grup_id TEXT NOT NULL,
        anggota_id TEXT NOT NULL,
        tanggal_kocok TEXT NOT NULL,
        putaran_ke INTEGER NOT NULL,
        potongan_kas INTEGER NOT NULL DEFAULT 0,
        catatan_kas TEXT,
        status TEXT NOT NULL DEFAULT 'menunggu',
        FOREIGN KEY (grup_id) REFERENCES grup_arisan(id),
        FOREIGN KEY (anggota_id) REFERENCES anggota(id)
      )
    ''');

    // Insert pengurus default
    await db.insert('users', {
      'id': 'pengurus-001',
      'nama': 'Pengurus Khadijiyyah',
      'email': 'pengurus@khadijiyyah.com',
      'password': 'admin123',
      'role': 'pengurus',
    });

    // Insert periode 2026/2027
    await db.insert('periode', {
      'id': 'periode-2026-2027',
      'nama_periode': '2026/2027',
      'tahun': '2026',
      'bulan_mulai': 'Mei',
      'bulan_selesai': 'Februari',
      'status': 'aktif',
    });

    // Insert grup arisan 50rb
    await db.insert('grup_arisan', {
      'id': 'grup-50rb',
      'periode_id': 'periode-2026-2027',
      'nama_grup': 'GRUP A (50K)',
      'nominal': 50000,
      'jumlah_peserta': 60,
      'jumlah_pemenang_per_putaran': 6,
      'total_putaran': 10,
    });

    // Insert grup arisan 200rb
    await db.insert('grup_arisan', {
      'id': 'grup-200rb',
      'periode_id': 'periode-2026-2027',
      'nama_grup': 'GRUP B (200K)',
      'nominal': 200000,
      'jumlah_peserta': 30,
      'jumlah_pemenang_per_putaran': 3,
      'total_putaran': 10,
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}