class Anggota {
  final String id;
  final String nama;
  final String noHp;
  final String? alamat;
  final int nominal;
  final bool statusAktif;
  final String createdAt;

  Anggota({
    required this.id,
    required this.nama,
    required this.noHp,
    this.alamat,
    required this.nominal,
    this.statusAktif = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'no_hp': noHp,
        'alamat': alamat,
        'nominal': nominal,
        'status_aktif': statusAktif ? 1 : 0,
        'created_at': createdAt,
      };

  factory Anggota.fromMap(Map<String, dynamic> map) => Anggota(
        id: map['id'],
        nama: map['nama'],
        noHp: map['no_hp'],
        alamat: map['alamat'],
        nominal: map['nominal'],
        statusAktif: map['status_aktif'] == 1,
        createdAt: map['created_at'],
      );
}

class Pembayaran {
  final String id;
  final String anggotaId;
  final String arisanId;
  final int jumlah;
  final String metode;
  final String tanggal;
  final String status;
  final String? namaAnggota;

  Pembayaran({
    required this.id,
    required this.anggotaId,
    required this.arisanId,
    required this.jumlah,
    required this.metode,
    required this.tanggal,
    this.status = 'lunas',
    this.namaAnggota,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'anggota_id': anggotaId,
        'arisan_id': arisanId,
        'jumlah': jumlah,
        'metode': metode,
        'tanggal': tanggal,
        'status': status,
      };

  factory Pembayaran.fromMap(Map<String, dynamic> map) => Pembayaran(
        id: map['id'],
        anggotaId: map['anggota_id'],
        arisanId: map['arisan_id'],
        jumlah: map['jumlah'],
        metode: map['metode'],
        tanggal: map['tanggal'],
        status: map['status'],
        namaAnggota: map['nama'],
      );
}

class Arisan {
  final String id;
  final String namaArisan;
  final String periode;
  final int nominal;
  final String tanggalMulai;
  final String status;

  Arisan({
    required this.id,
    required this.namaArisan,
    required this.periode,
    required this.nominal,
    required this.tanggalMulai,
    this.status = 'aktif',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama_arisan': namaArisan,
        'periode': periode,
        'nominal': nominal,
        'tanggal_mulai': tanggalMulai,
        'status': status,
      };

  factory Arisan.fromMap(Map<String, dynamic> map) => Arisan(
        id: map['id'],
        namaArisan: map['nama_arisan'],
        periode: map['periode'],
        nominal: map['nominal'],
        tanggalMulai: map['tanggal_mulai'],
        status: map['status'],
      );
}

class Pengocokan {
  final String id;
  final String arisanId;
  final String anggotaId;
  final String tanggalKocok;
  final int periodeKe;
  final String? namaAnggota;
  final String? namaArisan;

  Pengocokan({
    required this.id,
    required this.arisanId,
    required this.anggotaId,
    required this.tanggalKocok,
    required this.periodeKe,
    this.namaAnggota,
    this.namaArisan,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'arisan_id': arisanId,
        'anggota_id': anggotaId,
        'tanggal_kocok': tanggalKocok,
        'periode_ke': periodeKe,
      };

  factory Pengocokan.fromMap(Map<String, dynamic> map) => Pengocokan(
        id: map['id'],
        arisanId: map['arisan_id'],
        anggotaId: map['anggota_id'],
        tanggalKocok: map['tanggal_kocok'],
        periodeKe: map['periode_ke'],
        namaAnggota: map['nama_anggota'],
        namaArisan: map['nama_arisan'],
      );
}