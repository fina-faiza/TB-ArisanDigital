class User {
  final String id;
  final String nama;
  final String email;
  final String password;
  final String role;

  User({
    required this.id,
    required this.nama,
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'email': email,
        'password': password,
        'role': role,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'],
        nama: map['nama'],
        email: map['email'],
        password: map['password'],
        role: map['role'],
      );
}

class Periode {
  final String id;
  final String namaPeriode;
  final String tahun;
  final String bulanMulai;
  final String bulanSelesai;
  final String status;

  Periode({
    required this.id,
    required this.namaPeriode,
    required this.tahun,
    required this.bulanMulai,
    required this.bulanSelesai,
    this.status = 'aktif',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama_periode': namaPeriode,
        'tahun': tahun,
        'bulan_mulai': bulanMulai,
        'bulan_selesai': bulanSelesai,
        'status': status,
      };

  factory Periode.fromMap(Map<String, dynamic> map) => Periode(
        id: map['id'],
        namaPeriode: map['nama_periode'],
        tahun: map['tahun'],
        bulanMulai: map['bulan_mulai'],
        bulanSelesai: map['bulan_selesai'],
        status: map['status'],
      );
}

class GrupArisan {
  final String id;
  final String periodeId;
  final String namaGrup;
  final int nominal;
  final int jumlahPeserta;
  final int jumlahPemenangPerPutaran;
  final int totalPutaran;

  GrupArisan({
    required this.id,
    required this.periodeId,
    required this.namaGrup,
    required this.nominal,
    required this.jumlahPeserta,
    required this.jumlahPemenangPerPutaran,
    required this.totalPutaran,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'periode_id': periodeId,
        'nama_grup': namaGrup,
        'nominal': nominal,
        'jumlah_peserta': jumlahPeserta,
        'jumlah_pemenang_per_putaran': jumlahPemenangPerPutaran,
        'total_putaran': totalPutaran,
      };

  factory GrupArisan.fromMap(Map<String, dynamic> map) => GrupArisan(
        id: map['id'],
        periodeId: map['periode_id'],
        namaGrup: map['nama_grup'],
        nominal: map['nominal'],
        jumlahPeserta: map['jumlah_peserta'],
        jumlahPemenangPerPutaran: map['jumlah_pemenang_per_putaran'],
        totalPutaran: map['total_putaran'],
      );
}

class Anggota {
  final String id;
  final String grupId;
  final String nama;
  final String noHp;
  final String? alamat;
  final bool statusAktif;
  final String createdAt;
  final int nominal;

  Anggota({
    required this.id,
    required this.grupId,
    required this.nama,
    required this.noHp,
    this.alamat,
    this.statusAktif = true,
    required this.createdAt,
    this.nominal = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'grup_id': grupId,
        'nama': nama,
        'no_hp': noHp,
        'alamat': alamat,
        'status_aktif': statusAktif ? 1 : 0,
        'created_at': createdAt,
      };

  factory Anggota.fromMap(Map<String, dynamic> map) => Anggota(
        id: map['id'],
        grupId: map['grup_id'],
        nama: map['nama'],
        noHp: map['no_hp'],
        alamat: map['alamat'],
        statusAktif: map['status_aktif'] == 1,
        createdAt: map['created_at'],
        nominal: map['nominal'] ?? 0,
      );
}

class Pembayaran {
  final String id;
  final String anggotaId;
  final String grupId;
  final int jumlah;
  final String metode;
  final String tanggal;
  final String bulan;
  final String status;
  final String? namaAnggota;

  Pembayaran({
    required this.id,
    required this.anggotaId,
    required this.grupId,
    required this.jumlah,
    required this.metode,
    required this.tanggal,
    required this.bulan,
    this.status = 'lunas',
    this.namaAnggota,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'anggota_id': anggotaId,
        'grup_id': grupId,
        'jumlah': jumlah,
        'metode': metode,
        'tanggal': tanggal,
        'bulan': bulan,
        'status': status,
      };

  factory Pembayaran.fromMap(Map<String, dynamic> map) => Pembayaran(
        id: map['id'],
        anggotaId: map['anggota_id'],
        grupId: map['grup_id'],
        jumlah: map['jumlah'],
        metode: map['metode'],
        tanggal: map['tanggal'],
        bulan: map['bulan'],
        status: map['status'],
        namaAnggota: map['nama'],
      );
}

class Pengocokan {
  final String id;
  final String grupId;
  final String anggotaId;
  final String tanggalKocok;
  final int putaranKe;
  final int potonganKas;
  final String? catatanKas;
  final String? namaAnggota;
  final String? namaGrup;
  final int? nominalGrup;
  final int? totalPutaran;

  Pengocokan({
    required this.id,
    required this.grupId,
    required this.anggotaId,
    required this.tanggalKocok,
    required this.putaranKe,
    this.potonganKas = 0,
    this.catatanKas,
    this.namaAnggota,
    this.namaGrup,
    this.nominalGrup,
    this.totalPutaran,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'grup_id': grupId,
        'anggota_id': anggotaId,
        'tanggal_kocok': tanggalKocok,
        'putaran_ke': putaranKe,
        'potongan_kas': potonganKas,
        'catatan_kas': catatanKas,
      };

  factory Pengocokan.fromMap(Map<String, dynamic> map) => Pengocokan(
        id: map['id'],
        grupId: map['grup_id'],
        anggotaId: map['anggota_id'],
        tanggalKocok: map['tanggal_kocok'],
        putaranKe: map['putaran_ke'],
        potonganKas: map['potongan_kas'] ?? 0,
        catatanKas: map['catatan_kas'],
        namaAnggota: map['nama_anggota'],
        namaGrup: map['nama_grup'],
        nominalGrup: map['nominal'],
        totalPutaran: map['total_putaran'],
      );
}