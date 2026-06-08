import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import '../models/models.dart';

class ArisanService {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  // ─────────────────────────────────────────
  // FISHER-YATES SHUFFLE
  // ─────────────────────────────────────────
  List<Anggota> fisherYatesShuffle(List<Anggota> anggotaList) {
    final random = Random.secure();
    final result = List<Anggota>.from(anggotaList);

    for (int i = result.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }

    return result;
  }

  Future<Anggota?> lakukanPengocokan({
    required String arisanId,
    required int periodeKe,
  }) async {
    final db = await _db.database;

    final sudahMenang = await db.rawQuery(
      'SELECT anggota_id FROM pengocokan WHERE arisan_id = ?',
      [arisanId],
    );
    final idSudahMenang = sudahMenang.map((e) => e['anggota_id']).toList();

    List<Map<String, dynamic>> rows;
    if (idSudahMenang.isEmpty) {
      rows = await db.query('anggota', where: 'status_aktif = 1');
    } else {
      final placeholder = List.filled(idSudahMenang.length, '?').join(', ');
      rows = await db.query(
        'anggota',
        where: 'status_aktif = 1 AND id NOT IN ($placeholder)',
        whereArgs: idSudahMenang,
      );
    }

    if (rows.isEmpty) return null;

    final anggotaList = rows.map((r) => Anggota.fromMap(r)).toList();
    final shuffled = fisherYatesShuffle(anggotaList);
    final pemenang = shuffled.first;

    await db.insert('pengocokan', {
      'id': _uuid.v4(),
      'arisan_id': arisanId,
      'anggota_id': pemenang.id,
      'tanggal_kocok': DateTime.now().toIso8601String(),
      'periode_ke': periodeKe,
    });

    return pemenang;
  }

  // ─────────────────────────────────────────
  // ANGGOTA
  // ─────────────────────────────────────────
  Future<List<Anggota>> getAllAnggota() async {
    final db = await _db.database;
    final rows = await db.query('anggota', orderBy: 'nama ASC');
    return rows.map((r) => Anggota.fromMap(r)).toList();
  }

  Future<void> tambahAnggota(Anggota anggota) async {
    final db = await _db.database;
    await db.insert('anggota', anggota.toMap());
  }

  Future<void> updateAnggota(Anggota anggota) async {
    final db = await _db.database;
    await db.update('anggota', anggota.toMap(),
        where: 'id = ?', whereArgs: [anggota.id]);
  }

  Future<void> hapusAnggota(String id) async {
    final db = await _db.database;
    await db.delete('anggota', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────
  // ARISAN
  // ─────────────────────────────────────────
  Future<List<Arisan>> getAllArisan() async {
    final db = await _db.database;
    final rows = await db.query('arisan', orderBy: 'tanggal_mulai DESC');
    return rows.map((r) => Arisan.fromMap(r)).toList();
  }

  Future<void> tambahArisan(Arisan arisan) async {
    final db = await _db.database;
    await db.insert('arisan', arisan.toMap());
  }

  // ─────────────────────────────────────────
  // PEMBAYARAN
  // ─────────────────────────────────────────
  Future<List<Pembayaran>> getPembayaranByArisan(String arisanId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT p.*, a.nama 
      FROM pembayaran p
      JOIN anggota a ON a.id = p.anggota_id
      WHERE p.arisan_id = ?
      ORDER BY p.tanggal DESC
    ''', [arisanId]);
    return rows.map((r) => Pembayaran.fromMap(r)).toList();
  }

  Future<List<Anggota>> getAnggotaBelumBayar(String arisanId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT a.* FROM anggota a
      WHERE a.status_aktif = 1
        AND a.id NOT IN (
          SELECT anggota_id FROM pembayaran WHERE arisan_id = ?
        )
    ''', [arisanId]);
    return rows.map((r) => Anggota.fromMap(r)).toList();
  }

  Future<void> tambahPembayaran(Pembayaran pembayaran) async {
    final db = await _db.database;
    await db.insert('pembayaran', pembayaran.toMap());
  }

  // ─────────────────────────────────────────
  // RIWAYAT PENGOCOKAN
  // ─────────────────────────────────────────
  Future<List<Pengocokan>> getRiwayatPengocokan(String arisanId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT p.*, 
             a.nama AS nama_anggota,
             ar.nama_arisan
      FROM pengocokan p
      JOIN anggota a ON a.id = p.anggota_id
      JOIN arisan ar ON ar.id = p.arisan_id
      WHERE p.arisan_id = ?
      ORDER BY p.periode_ke ASC
    ''', [arisanId]);
    return rows.map((r) => Pengocokan.fromMap(r)).toList();
  }

  // ─────────────────────────────────────────
  // DASHBOARD STATS
  // ─────────────────────────────────────────
  Future<Map<String, int>> getDashboardStats(String arisanId) async {
    final db = await _db.database;

    final totalAnggota = Sqflite.firstIntValue(
            await db.rawQuery(
                'SELECT COUNT(*) FROM anggota WHERE status_aktif = 1')) ??
        0;

    final sudahBayar = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM pembayaran WHERE arisan_id = ?',
            [arisanId])) ??
        0;

    final belumBayar = totalAnggota - sudahBayar;

    final totalTerkumpul = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT SUM(jumlah) FROM pembayaran WHERE arisan_id = ?',
            [arisanId])) ??
        0;

    return {
      'total_anggota': totalAnggota,
      'sudah_bayar': sudahBayar,
      'belum_bayar': belumBayar,
      'total_terkumpul': totalTerkumpul,
    };
  }
}