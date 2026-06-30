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

  // Hanya hitung anggota yang BELUM PERNAH MENANG (status diambil ATAU menunggu)
  // Anggota dengan status 'tidak_diambil' akan kembali masuk ke pool
  Future<List<Anggota>> lakukanPengocokan({
    required String grupId,
    required int putaranKe,
    required int jumlahPemenang,
    required int potonganKas,
    String? catatanKas,
  }) async {
    final db = await _db.database;

    // Anggota yang statusnya 'diambil' atau 'menunggu' dianggap sudah menang
    // Anggota dengan 'tidak_diambil' TIDAK dihitung sudah menang (masuk pool lagi)
    final sudahMenang = await db.rawQuery('''
      SELECT anggota_id FROM pengocokan 
      WHERE grup_id = ? AND status IN ('diambil', 'menunggu')
    ''', [grupId]);
    final idSudahMenang =
        sudahMenang.map((e) => e['anggota_id']).toList();

    List<Map<String, dynamic>> rows;
    if (idSudahMenang.isEmpty) {
      rows = await db.rawQuery('''
        SELECT a.*, g.nominal FROM anggota a
        JOIN grup_arisan g ON g.id = a.grup_id
        WHERE a.grup_id = ? AND a.status_aktif = 1
      ''', [grupId]);
    } else {
      final placeholder =
          List.filled(idSudahMenang.length, '?').join(', ');
      rows = await db.rawQuery('''
        SELECT a.*, g.nominal FROM anggota a
        JOIN grup_arisan g ON g.id = a.grup_id
        WHERE a.grup_id = ? AND a.status_aktif = 1
          AND a.id NOT IN ($placeholder)
      ''', [grupId, ...idSudahMenang]);
    }

    if (rows.isEmpty) return [];

    final anggotaList = rows.map((r) => Anggota.fromMap(r)).toList();
    final shuffled = fisherYatesShuffle(anggotaList);
    final pemenangList = shuffled.take(jumlahPemenang).toList();

    for (final pemenang in pemenangList) {
      await db.insert('pengocokan', {
        'id': _uuid.v4(),
        'grup_id': grupId,
        'anggota_id': pemenang.id,
        'tanggal_kocok': DateTime.now().toIso8601String(),
        'putaran_ke': putaranKe,
        'potongan_kas': potonganKas,
        'catatan_kas': catatanKas,
        'status': 'menunggu',
      });
    }

    return pemenangList;
  }

  // Update status pengocokan: 'diambil' atau 'tidak_diambil'
  // Jika 'tidak_diambil' -> hapus record agar otomatis masuk pool lagi
  Future<void> updateStatusPengocokan(
      String pengocokanId, String status) async {
    final db = await _db.database;

    if (status == 'tidak_diambil') {
      // Hapus record supaya nama kembali ke pool kocokan
      await db.delete('pengocokan',
          where: 'id = ?', whereArgs: [pengocokanId]);
    } else {
      await db.update(
        'pengocokan',
        {'status': status},
        where: 'id = ?',
        whereArgs: [pengocokanId],
      );
    }
  }

  // ─────────────────────────────────────────
  // PERIODE (CRUD)
  // ─────────────────────────────────────────
  Future<List<Periode>> getAllPeriode() async {
    final db = await _db.database;
    final rows = await db.query('periode', orderBy: 'tahun DESC');
    return rows.map((r) => Periode.fromMap(r)).toList();
  }

  Future<Periode?> getPeriodeAktif() async {
    final db = await _db.database;
    final rows = await db.query('periode',
        where: 'status = ?', whereArgs: ['aktif'], limit: 1);
    if (rows.isEmpty) return null;
    return Periode.fromMap(rows.first);
  }

  Future<void> tambahPeriode(Periode periode) async {
    final db = await _db.database;
    await db.insert('periode', periode.toMap());
  }

  Future<void> updatePeriode(Periode periode) async {
    final db = await _db.database;
    await db.update('periode', periode.toMap(),
        where: 'id = ?', whereArgs: [periode.id]);
  }

  Future<void> hapusPeriode(String id) async {
    final db = await _db.database;
    await db.delete('periode', where: 'id = ?', whereArgs: [id]);
  }

  // Set periode jadi aktif, nonaktifkan periode lain
  Future<void> setPeriodeAktif(String id) async {
    final db = await _db.database;
    await db.update('periode', {'status': 'nonaktif'});
    await db.update('periode', {'status': 'aktif'},
        where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────
  // GRUP ARISAN (CRUD)
  // ─────────────────────────────────────────
  Future<List<GrupArisan>> getGrupByPeriode(String periodeId) async {
    final db = await _db.database;
    final rows = await db.query('grup_arisan',
        where: 'periode_id = ?', whereArgs: [periodeId]);
    return rows.map((r) => GrupArisan.fromMap(r)).toList();
  }

  Future<void> tambahGrup(GrupArisan grup) async {
    final db = await _db.database;
    await db.insert('grup_arisan', grup.toMap());
  }

  Future<void> updateGrup(GrupArisan grup) async {
    final db = await _db.database;
    await db.update('grup_arisan', grup.toMap(),
        where: 'id = ?', whereArgs: [grup.id]);
  }

  Future<void> hapusGrup(String id) async {
    final db = await _db.database;
    await db.delete('grup_arisan', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────
  // ANGGOTA
  // ─────────────────────────────────────────
  Future<List<Anggota>> getAnggotaByGrup(String grupId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT a.*, g.nominal FROM anggota a
      JOIN grup_arisan g ON g.id = a.grup_id
      WHERE a.grup_id = ? AND a.status_aktif = 1
      ORDER BY a.nama ASC
    ''', [grupId]);
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
  // PEMBAYARAN
  // ─────────────────────────────────────────
  Future<List<Pembayaran>> getPembayaranByGrup(
      String grupId, String bulan) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT p.*, a.nama 
      FROM pembayaran p
      JOIN anggota a ON a.id = p.anggota_id
      WHERE p.grup_id = ? AND p.bulan = ?
      ORDER BY p.tanggal DESC
    ''', [grupId, bulan]);
    return rows.map((r) => Pembayaran.fromMap(r)).toList();
  }

  Future<List<Anggota>> getAnggotaBelumBayar(
      String grupId, String bulan) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT a.*, g.nominal FROM anggota a
      JOIN grup_arisan g ON g.id = a.grup_id
      WHERE a.grup_id = ? AND a.status_aktif = 1
        AND a.id NOT IN (
          SELECT anggota_id FROM pembayaran
          WHERE grup_id = ? AND bulan = ?
        )
      ORDER BY a.nama ASC
    ''', [grupId, grupId, bulan]);
    return rows.map((r) => Anggota.fromMap(r)).toList();
  }

  Future<void> tambahPembayaran(Pembayaran pembayaran) async {
    final db = await _db.database;
    await db.insert('pembayaran', pembayaran.toMap());
  }

  // ─────────────────────────────────────────
  // RIWAYAT PENGOCOKAN
  // ─────────────────────────────────────────
  Future<List<Pengocokan>> getRiwayatByGrup(String grupId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT p.*,
             a.nama AS nama_anggota,
             g.nama_grup,
             g.nominal,
             g.total_putaran
      FROM pengocokan p
      JOIN anggota a ON a.id = p.anggota_id
      JOIN grup_arisan g ON g.id = p.grup_id
      WHERE p.grup_id = ?
      ORDER BY p.putaran_ke ASC, a.nama ASC
    ''', [grupId]);
    return rows.map((r) => Pengocokan.fromMap(r)).toList();
  }

  Future<int> getPutaranTerakhir(String grupId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT MAX(putaran_ke) as max_putaran FROM pengocokan 
      WHERE grup_id = ? AND status IN ('diambil', 'menunggu')
    ''', [grupId]);
    return (rows.first['max_putaran'] as int?) ?? 0;
  }

  // ─────────────────────────────────────────
  // DASHBOARD STATS
  // ─────────────────────────────────────────
  Future<Map<String, int>> getDashboardStats(
      String grupId, String bulan) async {
    final db = await _db.database;

    final totalAnggota = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM anggota WHERE grup_id = ? AND status_aktif = 1',
            [grupId])) ??
        0;

    final sudahBayar = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM pembayaran WHERE grup_id = ? AND bulan = ?',
            [grupId, bulan])) ??
        0;

    final totalTerkumpul = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT SUM(jumlah) FROM pembayaran WHERE grup_id = ? AND bulan = ?',
            [grupId, bulan])) ??
        0;

    final putaranTerakhir = await getPutaranTerakhir(grupId);

    return {
      'total_anggota': totalAnggota,
      'sudah_bayar': sudahBayar,
      'belum_bayar': totalAnggota - sudahBayar,
      'total_terkumpul': totalTerkumpul,
      'putaran_terakhir': putaranTerakhir,
    };
  }
}