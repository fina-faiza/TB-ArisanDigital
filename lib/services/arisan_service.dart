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

  // Kocokan utama — anggota yang sudah "diambil" tidak masuk pool
  // Anggota yang pernah "tidak_diambil" (sudah dihapus) otomatis masuk pool lagi
  Future<List<Anggota>> lakukanPengocokan({
    required String grupId,
    required int putaranKe,
    required int jumlahPemenang,
    required int potonganKas,
    String? catatanKas,
    bool isSusulan = false,
    List<String> tambahPool = const [], // ID anggota yang kembali ke pool
  }) async {
    final db = await _db.database;

    // Anggota yang statusnya 'diambil' atau 'menunggu' dianggap sudah menang
    // Kecuali yang ada di tambahPool (yang tidak diambil dan kembali ke pool)
    final sudahMenang = await db.rawQuery(
      '''
      SELECT anggota_id FROM pengocokan 
      WHERE grup_id = ? AND status IN ('diambil', 'menunggu')
    ''',
      [grupId],
    );

    var idSudahMenang = sudahMenang
        .map((e) => e['anggota_id'] as String)
        .where((id) => !tambahPool.contains(id))
        .toList();

    List<Map<String, dynamic>> rows;
    if (idSudahMenang.isEmpty) {
      rows = await db.rawQuery(
        '''
        SELECT a.*, g.nominal FROM anggota a
        JOIN grup_arisan g ON g.id = a.grup_id
        WHERE a.grup_id = ? AND a.status_aktif = 1
      ''',
        [grupId],
      );
    } else {
      final placeholder = List.filled(idSudahMenang.length, '?').join(', ');
      rows = await db.rawQuery(
        '''
        SELECT a.*, g.nominal FROM anggota a
        JOIN grup_arisan g ON g.id = a.grup_id
        WHERE a.grup_id = ? AND a.status_aktif = 1
          AND a.id NOT IN ($placeholder)
      ''',
        [grupId, ...idSudahMenang],
      );
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

  /// Update pengocokan status by id.
  ///
  /// Uses existing methods for the two supported actions:
  /// - 'diambil' => mark as taken
  /// - 'tidak_diambil' => remove from history and return to pool
  Future<void> updateStatusPengocokan(
    String pengocokanId,
    String status,
  ) async {
    if (status == 'diambil') {
      return tandaiDiambil(pengocokanId);
    }
    if (status == 'tidak_diambil') {
      await tandaiTidakDiambil(pengocokanId);
      return;
    }
    throw ArgumentError.value(
      status,
      'status',
      'Supported values are "diambil" or "tidak_diambil".',
    );
  }

  // Tandai "Tidak Diambil" — hapus dari riwayat, nama kembali ke pool
  // Return anggota_id yang dihapus agar bisa dipakai untuk spin susulan
  Future<String?> tandaiTidakDiambil(String pengocokanId) async {
    final db = await _db.database;

    // Ambil anggota_id dulu sebelum dihapus
    final rows = await db.query(
      'pengocokan',
      where: 'id = ?',
      whereArgs: [pengocokanId],
    );
    if (rows.isEmpty) return null;

    final anggotaId = rows.first['anggota_id'] as String;

    // Hapus dari riwayat
    await db.delete('pengocokan', where: 'id = ?', whereArgs: [pengocokanId]);

    return anggotaId;
  }

  // Cek apakah ada yang menunggu konfirmasi di putaran tertentu
  Future<List<Pengocokan>> getPemenangMenunggu(
    String grupId,
    int putaranKe,
  ) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT p.*,
             a.nama AS nama_anggota,
             g.nama_grup,
             g.nominal,
             g.total_putaran
      FROM pengocokan p
      JOIN anggota a ON a.id = p.anggota_id
      JOIN grup_arisan g ON g.id = p.grup_id
      WHERE p.grup_id = ? AND p.putaran_ke = ? AND p.status = 'menunggu'
    ''',
      [grupId, putaranKe],
    );
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
    final rows = await db.query(
      'periode',
      where: 'status = ?',
      whereArgs: ['aktif'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Periode.fromMap(rows.first);
  }

  Future<void> tambahPeriode(Periode periode) async {
    final db = await _db.database;
    await db.insert('periode', periode.toMap());
  }

  Future<void> updatePeriode(Periode periode) async {
    final db = await _db.database;
    await db.update(
      'periode',
      periode.toMap(),
      where: 'id = ?',
      whereArgs: [periode.id],
    );
  }

  Future<void> hapusPeriode(String id) async {
    final db = await _db.database;
    await db.delete('periode', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setPeriodeAktif(String id) async {
    final db = await _db.database;
    await db.update('periode', {'status': 'nonaktif'});
    await db.update(
      'periode',
      {'status': 'aktif'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─────────────────────────────────────────
  // GRUP ARISAN (CRUD)
  // ─────────────────────────────────────────
  Future<List<GrupArisan>> getGrupByPeriode(String periodeId) async {
    final db = await _db.database;
    final rows = await db.query(
      'grup_arisan',
      where: 'periode_id = ?',
      whereArgs: [periodeId],
    );
    return rows.map((r) => GrupArisan.fromMap(r)).toList();
  }

  Future<void> tambahGrup(GrupArisan grup) async {
    final db = await _db.database;
    await db.insert('grup_arisan', grup.toMap());
  }

  Future<void> updateGrup(GrupArisan grup) async {
    final db = await _db.database;
    await db.update(
      'grup_arisan',
      grup.toMap(),
      where: 'id = ?',
      whereArgs: [grup.id],
    );
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
    final rows = await db.rawQuery(
      '''
      SELECT a.*, g.nominal FROM anggota a
      JOIN grup_arisan g ON g.id = a.grup_id
      WHERE a.grup_id = ? AND a.status_aktif = 1
      ORDER BY a.nama ASC
    ''',
      [grupId],
    );
    return rows.map((r) => Anggota.fromMap(r)).toList();
  }

  Future<void> tambahAnggota(Anggota anggota) async {
    final db = await _db.database;
    await db.insert('anggota', anggota.toMap());
  }

  Future<void> updateAnggota(Anggota anggota) async {
    final db = await _db.database;
    await db.update(
      'anggota',
      anggota.toMap(),
      where: 'id = ?',
      whereArgs: [anggota.id],
    );
  }

  Future<void> hapusAnggota(String id) async {
    final db = await _db.database;
    await db.delete('anggota', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────
  // PEMBAYARAN
  // ─────────────────────────────────────────
  Future<List<Pembayaran>> getPembayaranByGrup(
    String grupId,
    String bulan,
  ) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT p.*, a.nama 
      FROM pembayaran p
      JOIN anggota a ON a.id = p.anggota_id
      WHERE p.grup_id = ? AND p.bulan = ?
      ORDER BY p.tanggal DESC
    ''',
      [grupId, bulan],
    );
    return rows.map((r) => Pembayaran.fromMap(r)).toList();
  }

  Future<List<Anggota>> getAnggotaBelumBayar(
    String grupId,
    String bulan,
  ) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT a.*, g.nominal FROM anggota a
      JOIN grup_arisan g ON g.id = a.grup_id
      WHERE a.grup_id = ? AND a.status_aktif = 1
        AND a.id NOT IN (
          SELECT anggota_id FROM pembayaran
          WHERE grup_id = ? AND bulan = ?
        )
      ORDER BY a.nama ASC
    ''',
      [grupId, grupId, bulan],
    );
    return rows.map((r) => Anggota.fromMap(r)).toList();
  }

  Future<void> tambahPembayaran(Pembayaran pembayaran) async {
    final db = await _db.database;
    await db.insert('pembayaran', pembayaran.toMap());
  }

  // Tambah pembayaran banyak sekaligus (select all)
  Future<void> tambahPembayaranBulk(List<Pembayaran> pembayaranList) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final p in pembayaranList) {
      batch.insert(
        'pembayaran',
        p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  // ─────────────────────────────────────────
  // RIWAYAT PENGOCOKAN
  // ─────────────────────────────────────────
  Future<List<Pengocokan>> getRiwayatByGrup(String grupId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
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
    ''',
      [grupId],
    );
    return rows.map((r) => Pengocokan.fromMap(r)).toList();
  }

  Future<int> getPutaranTerakhir(String grupId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT MAX(putaran_ke) as max_putaran FROM pengocokan 
      WHERE grup_id = ? AND status = 'diambil'
    ''',
      [grupId],
    );
    return (rows.first['max_putaran'] as int?) ?? 0;
  }

  // Cek apakah putaran ini masih ada yang menunggu
  Future<bool> adaYangMenunggu(String grupId, int putaranKe) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) as total FROM pengocokan
      WHERE grup_id = ? AND putaran_ke = ? AND status = 'menunggu'
    ''',
      [grupId, putaranKe],
    );
    return ((rows.first['total'] as int?) ?? 0) > 0;
  }

  // ─────────────────────────────────────────
  // DASHBOARD STATS
  // ─────────────────────────────────────────
  Future<Map<String, int>> getDashboardStats(
    String grupId,
    String bulan,
  ) async {
    final db = await _db.database;

    final totalAnggota =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM anggota WHERE grup_id = ? AND status_aktif = 1',
            [grupId],
          ),
        ) ??
        0;

    final sudahBayar =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM pembayaran WHERE grup_id = ? AND bulan = ?',
            [grupId, bulan],
          ),
        ) ??
        0;

    final totalTerkumpul =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT SUM(jumlah) FROM pembayaran WHERE grup_id = ? AND bulan = ?',
            [grupId, bulan],
          ),
        ) ??
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
