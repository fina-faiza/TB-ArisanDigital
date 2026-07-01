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

  // ─────────────────────────────────────────
  // KOCOKAN POOL
  // ─────────────────────────────────────────
  Future<void> simpanPool(
      String grupId, int putaranKe, List<String> anggotaIds) async {
    final db = await _db.database;
    await db.delete('kocokan_pool',
        where: 'grup_id = ? AND putaran_ke = ?',
        whereArgs: [grupId, putaranKe]);
    final batch = db.batch();
    for (final id in anggotaIds) {
      batch.insert('kocokan_pool', {
        'id': _uuid.v4(),
        'grup_id': grupId,
        'anggota_id': id,
        'putaran_ke': putaranKe,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Anggota>> getPoolPutaran(
      String grupId, int putaranKe) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT a.*, g.nominal FROM anggota a
      JOIN grup_arisan g ON g.id = a.grup_id
      JOIN kocokan_pool kp ON kp.anggota_id = a.id
      WHERE kp.grup_id = ? AND kp.putaran_ke = ?
        AND a.status_aktif = 1
      ORDER BY a.nama ASC
    ''', [grupId, putaranKe]);
    return rows.map((r) => Anggota.fromMap(r)).toList();
  }

  Future<bool> adaPool(String grupId, int putaranKe) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT COUNT(*) as total FROM kocokan_pool
      WHERE grup_id = ? AND putaran_ke = ?
    ''', [grupId, putaranKe]);
    return ((rows.first['total'] as int?) ?? 0) > 0;
  }

  // ─────────────────────────────────────────
  // PENGOCOKAN
  // ─────────────────────────────────────────

  // Spin utama & susulan
  // jumlahPemenang = jumlah yang harus keluar
  // Pool = anggota yang dipilih di putaran ini KECUALI yang sudah "Diambil"
  Future<List<Anggota>> lakukanPengocokan({
    required String grupId,
    required int putaranKe,
    required int jumlahPemenang,
    required int potonganKas,
    String? catatanKas,
    bool isSusulan = false,
  }) async {
    final db = await _db.database;

    // Ambil ID anggota yang sudah "Diambil" di putaran ini
    final sudahDiambil = await db.rawQuery('''
      SELECT anggota_id FROM pengocokan
      WHERE grup_id = ? AND putaran_ke = ? AND status = 'diambil'
    ''', [grupId, putaranKe]);
    final idSudahDiambil =
        sudahDiambil.map((e) => e['anggota_id'] as String).toList();

    // Pool = anggota yang dipilih di putaran ini
    // KECUALI yang sudah "Diambil"
    List<Map<String, dynamic>> rows;
    if (idSudahDiambil.isEmpty) {
      rows = await db.rawQuery('''
        SELECT a.*, g.nominal FROM anggota a
        JOIN grup_arisan g ON g.id = a.grup_id
        JOIN kocokan_pool kp ON kp.anggota_id = a.id
        WHERE kp.grup_id = ? AND kp.putaran_ke = ?
          AND a.status_aktif = 1
      ''', [grupId, putaranKe]);
    } else {
      final placeholder =
          List.filled(idSudahDiambil.length, '?').join(', ');
      rows = await db.rawQuery('''
        SELECT a.*, g.nominal FROM anggota a
        JOIN grup_arisan g ON g.id = a.grup_id
        JOIN kocokan_pool kp ON kp.anggota_id = a.id
        WHERE kp.grup_id = ? AND kp.putaran_ke = ?
          AND a.status_aktif = 1
          AND a.id NOT IN ($placeholder)
      ''', [grupId, putaranKe, ...idSudahDiambil]);
    }

    if (rows.isEmpty) return [];

    // Hapus record "menunggu" di putaran ini sebelum spin baru
    // (yang tidak diambil sudah dihapus, ini untuk bersihkan sisa)
    await db.delete('pengocokan',
        where: 'grup_id = ? AND putaran_ke = ? AND status = ?',
        whereArgs: [grupId, putaranKe, 'menunggu']);

    final anggotaList = rows.map((r) => Anggota.fromMap(r)).toList();
    final shuffled = fisherYatesShuffle(anggotaList);

    // Ambil sejumlah pemenang yang dibutuhkan
    // Tidak boleh melebihi jumlah yang tersedia
    final ambil =
        jumlahPemenang.clamp(0, shuffled.length);
    final pemenangList = shuffled.take(ambil).toList();

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
        'is_susulan': isSusulan ? 1 : 0,
      });
    }

    return pemenangList;
  }

  // Tandai "Diambil" — status berubah, tetap di riwayat
  Future<void> tandaiDiambil(String pengocokanId) async {
    final db = await _db.database;
    await db.update(
      'pengocokan',
      {'status': 'diambil'},
      where: 'id = ?',
      whereArgs: [pengocokanId],
    );
  }

  // Tandai "Tidak Diambil" — hapus dari riwayat, nama kembali ke pool
  Future<String?> tandaiTidakDiambil(String pengocokanId) async {
    final db = await _db.database;
    final rows = await db.query('pengocokan',
        where: 'id = ?', whereArgs: [pengocokanId]);
    if (rows.isEmpty) return null;
    final anggotaId = rows.first['anggota_id'] as String;
    await db.delete('pengocokan',
        where: 'id = ?', whereArgs: [pengocokanId]);
    return anggotaId;
  }

  // Hitung berapa yang masih perlu dikocok susulan
  // = jumlahPemenangPerPutaran - jumlah yang sudah "Diambil"
  Future<int> hitungKurangPemenang(
      String grupId, int putaranKe, int targetPemenang) async {
    final db = await _db.database;
    final sudahDiambil = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM pengocokan
      WHERE grup_id = ? AND putaran_ke = ? AND status = 'diambil'
    ''', [grupId, putaranKe])) ?? 0;
    return (targetPemenang - sudahDiambil).clamp(0, targetPemenang);
  }

  // Ambil pemenang yang menunggu konfirmasi di putaran ini
  Future<List<Pengocokan>> getPemenangMenunggu(
      String grupId, int putaranKe) async {
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
      WHERE p.grup_id = ? AND p.putaran_ke = ? AND p.status = 'menunggu'
    ''', [grupId, putaranKe]);
    return rows.map((r) => Pengocokan.fromMap(r)).toList();
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

  Future<void> tambahPembayaranBulk(
      List<Pembayaran> pembayaranList) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final p in pembayaranList) {
      batch.insert('pembayaran', p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
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
      ORDER BY p.putaran_ke ASC, p.is_susulan ASC, a.nama ASC
    ''', [grupId]);
    return rows.map((r) => Pengocokan.fromMap(r)).toList();
  }

  Future<int> getPutaranTerakhir(String grupId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT MAX(putaran_ke) as max_putaran FROM pengocokan
      WHERE grup_id = ? AND status = 'diambil'
    ''', [grupId]);
    return (rows.first['max_putaran'] as int?) ?? 0;
  }

  Future<void> updateStatusPengocokan(
    String pengocokanId,
    String status,
  ) async {
    final db = await _db.database;

    if (status == 'diambil') {
      await db.update(
        'pengocokan',
        {'status': 'diambil'},
        where: 'id = ?',
        whereArgs: [pengocokanId],
      );
    } else if (status == 'tidak_diambil') {
      await db.delete(
        'pengocokan',
        where: 'id = ?',
        whereArgs: [pengocokanId],
      );
    }
  }

  // ─────────────────────────────────────────
  // DASHBOARD STATS
  // ─────────────────────────────────────────
  Future<Map<String, int>> getDashboardStats(
      String grupId, String bulan) async {
    final db = await _db.database;

    final totalAnggota = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM anggota WHERE grup_id = ? AND status_aktif = 1',
            [grupId])) ?? 0;

    final sudahBayar = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM pembayaran WHERE grup_id = ? AND bulan = ?',
            [grupId, bulan])) ?? 0;

    final totalTerkumpul = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT SUM(jumlah) FROM pembayaran WHERE grup_id = ? AND bulan = ?',
            [grupId, bulan])) ?? 0;

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