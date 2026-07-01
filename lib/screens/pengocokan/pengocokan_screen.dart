import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';

class PengocokanScreen extends StatefulWidget {
  final List<GrupArisan> grupList;
  final bool embedded;
  const PengocokanScreen(
      {super.key, required this.grupList, this.embedded = false});

  @override
  State<PengocokanScreen> createState() => _PengocokanScreenState();
}

class _PengocokanScreenState extends State<PengocokanScreen>
    with TickerProviderStateMixin {
  final _service = ArisanService();
  final _currency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  GrupArisan? _grupSelected;
  List<Anggota> _semuaAnggota = [];
  List<Anggota> _poolAnggota = []; // Anggota yang dipilih ikut kocokan
  List<Anggota> _pemenangList = [];
  List<Pengocokan> _menungguKonfirmasi = [];

  bool _loading = false;
  bool _sudahKocok = false;
  int _putaranKe = 1;
  int _kurangPemenang = 0;
  bool _adaSusulan = false;

  late AnimationController _spinController;
  late AnimationController _revealController;
  late Animation<double> _scaleAnimation;

  String _namaDisplay = '???';
  List<String> _anggotaNames = [];

  final _kasCtrl = TextEditingController();
  String _catatanKas = '';

  @override
  void initState() {
    super.initState();
    if (widget.grupList.isNotEmpty) {
      _grupSelected = widget.grupList.first;
      _loadData();
    }

    _spinController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    _revealController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
            parent: _revealController, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _spinController.dispose();
    _revealController.dispose();
    _kasCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_grupSelected == null) return;
    final anggota = await _service.getAnggotaByGrup(_grupSelected!.id);
    final putaranDiambil =
        await _service.getPutaranTerakhir(_grupSelected!.id);
    final putaranAktif = putaranDiambil + 1;
    final adaPool =
        await _service.adaPool(_grupSelected!.id, putaranAktif);
    final pool = adaPool
        ? await _service.getPoolPutaran(_grupSelected!.id, putaranAktif)
        : [];
    final menunggu = await _service.getPemenangMenunggu(
        _grupSelected!.id, putaranAktif);
    final kurang = await _service.hitungKurangPemenang(
        _grupSelected!.id,
        putaranAktif,
        _grupSelected!.jumlahPemenangPerPutaran);

    setState(() {
      _semuaAnggota = anggota;
      _anggotaNames = anggota.map((a) => a.nama).toList();
      _putaranKe = putaranAktif;
      _poolAnggota = pool as List<Anggota>;
      _menungguKonfirmasi = menunggu;
      _kurangPemenang = kurang;
      _adaSusulan = menunggu.isEmpty && kurang > 0 && adaPool;
    });
  }

  // Dialog pilih anggota yang ikut kocokan
  void _showPilihAnggotaDialog() {
    Set<String> selectedIds =
        _poolAnggota.map((a) => a.id).toSet();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pilih Anggota\nPutaran $_putaranKe',
                style: const TextStyle(
                    color: Color(0xFFB8960C), fontSize: 15),
              ),
              Text(
                '${selectedIds.length}/${_semuaAnggota.length}',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              children: [
                // Pilih semua / batal semua
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFB8960C)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 6),
                        ),
                        onPressed: () {
                          setS(() {
                            if (selectedIds.length ==
                                _semuaAnggota.length) {
                              selectedIds.clear();
                            } else {
                              selectedIds = _semuaAnggota
                                  .map((a) => a.id)
                                  .toSet();
                            }
                          });
                        },
                        child: Text(
                          selectedIds.length == _semuaAnggota.length
                              ? 'Batal Semua'
                              : 'Pilih Semua',
                          style: const TextStyle(
                              color: Color(0xFFB8960C),
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _semuaAnggota.length,
                    itemBuilder: (_, i) {
                      final a = _semuaAnggota[i];
                      final isSelected = selectedIds.contains(a.id);
                      return GestureDetector(
                        onTap: () {
                          setS(() {
                            if (isSelected) {
                              selectedIds.remove(a.id);
                            } else {
                              selectedIds.add(a.id);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFB8960C)
                                    .withOpacity(0.15)
                                : Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFB8960C)
                                  : Colors.white12,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: isSelected
                                    ? const Color(0xFFB8960C)
                                    : Colors.white38,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  a.nama,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8960C)),
              onPressed: () async {
                if (selectedIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Pilih minimal 1 anggota!')),
                  );
                  return;
                }
                await _service.simpanPool(
                    _grupSelected!.id,
                    _putaranKe,
                    selectedIds.toList());
                if (!mounted) return;
                Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Simpan',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showKasDialog({bool isSusulan = false}) {
    _kasCtrl.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          isSusulan
              ? 'Spin Susulan Putaran $_putaranKe'
              : 'Mulai Kocok Putaran $_putaranKe',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSusulan)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: Text(
                  'Mencari $_kurangPemenang pemenang pengganti.\nPool = semua anggota pilihan KECUALI yang sudah Diambil.',
                  style:
                      const TextStyle(color: Colors.orange, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const Text(
              'Potongan kas? (kosongkan jika tidak ada)',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kasCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nominal Kas (Rp)',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.account_balance_wallet,
                    color: Color(0xFFB8960C)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Colors.white24)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFB8960C))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: isSusulan
                    ? Colors.orange
                    : const Color(0xFFB8960C)),
            onPressed: () {
              final kas = int.tryParse(_kasCtrl.text) ?? 0;
              _catatanKas =
                  kas > 0 ? '(kas khadijiyyah: seikhlasnya, hubungi admin)' : '';
              Navigator.pop(context);
              _mulaiKocok(kas, isSusulan: isSusulan);
            },
            child: Text(
              isSusulan ? 'Mulai Spin Susulan' : 'Mulai Kocok',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mulaiKocok(int potonganKas,
      {bool isSusulan = false}) async {
    if (_poolAnggota.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pilih anggota yang ikut kocokan dulu!')));
      return;
    }

    final jumlahPemenang = isSusulan
        ? _kurangPemenang
        : _grupSelected!.jumlahPemenangPerPutaran;

    setState(() {
      _loading = true;
      _sudahKocok = false;
      _pemenangList = [];
    });

    _spinController.reset();
    _spinController.forward();

    // Animasi nama berputar
    final poolNames = _poolAnggota.map((a) => a.nama).toList();
    final stopwatch = Stopwatch()..start();
    int delay = 60;
    while (stopwatch.elapsedMilliseconds < 3000) {
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) return;
      if (poolNames.isNotEmpty) {
        setState(() {
          _namaDisplay =
              poolNames[Random().nextInt(poolNames.length)];
        });
      }
      if (stopwatch.elapsedMilliseconds > 1500) delay = 120;
      if (stopwatch.elapsedMilliseconds > 2200) delay = 220;
      if (stopwatch.elapsedMilliseconds > 2700) delay = 350;
    }

    final pemenangList = await _service.lakukanPengocokan(
      grupId: _grupSelected!.id,
      putaranKe: _putaranKe,
      jumlahPemenang: jumlahPemenang,
      potonganKas: potonganKas,
      catatanKas: _catatanKas.isNotEmpty ? _catatanKas : null,
      isSusulan: isSusulan,
    );

    if (!mounted) return;

    if (pemenangList.isEmpty) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tidak ada anggota tersedia!')));
      return;
    }

    setState(() {
      _pemenangList = pemenangList;
      _namaDisplay = pemenangList.first.nama;
      _loading = false;
      _sudahKocok = true;
      _adaSusulan = false;
    });

    _revealController.reset();
    _revealController.forward();
    await _loadData();
  }

  // Dialog konfirmasi pemenang
  void _showKonfirmasiDialog() {
    if (_menungguKonfirmasi.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            'Konfirmasi Putaran $_putaranKe\n(${_menungguKonfirmasi.length} menunggu)',
            style: const TextStyle(
                color: Color(0xFFB8960C), fontSize: 15),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _menungguKonfirmasi
                  .map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.namaAnggota ?? '-',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () async {
                                await _service.tandaiDiambil(p.id);
                                setS(() => _menungguKonfirmasi
                                    .removeWhere(
                                        (x) => x.id == p.id));
                                await _loadData();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.green.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.green),
                                ),
                                child: const Text('Diambil',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () async {
                                await _service
                                    .tandaiTidakDiambil(p.id);
                                setS(() => _menungguKonfirmasi
                                    .removeWhere(
                                        (x) => x.id == p.id));
                                await _loadData();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red
                                      .withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.red),
                                ),
                                child: const Text('Tidak',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8960C)),
              onPressed: () {
                Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Selesai',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _buatLaporanWA() {
    final now = DateTime.now();
    final tgl =
        DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(now);
    final grup = _grupSelected!;
    final potongan = int.tryParse(_kasCtrl.text) ?? 0;
    final totalDiterima =
        (grup.nominal * grup.jumlahPeserta ~/
                grup.jumlahPemenangPerPutaran) -
            potongan;

    String pemenangStr = _pemenangList
        .map((p) => '✨ ${p.nama} ✨')
        .join('\n');

    String kasStr = potongan > 0
        ? 'Kas Khadijiyyah : -${_currency.format(potongan)}\n'
        : '(kas khadijiyyah: seikhlasnya, hubungi admin)\n';

    return '''🎉 PEMENANG ARISAN 🎉
--------------------------------
Grup: ${grup.namaGrup} ARISAN KHADIJIYYAH
Tanggal: $tgl
Putaran: $_putaranKe dari ${grup.totalPutaran}
Sisa Putaran: ${grup.totalPutaran - _putaranKe}

Selamat kepada:
$pemenangStr

Terkumpul : ${_currency.format(grup.nominal * grup.jumlahPeserta)}
$kasStr Total Diterima : ${_currency.format(totalDiterima)}
--------------------------------
Laporan iuran terbaru sudah tersedia di aplikasi.
"Arisan Khadijiyyah by Firsha"''';
  }

  void _shareWA() {
    final laporan = _buatLaporanWA();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Laporan Pemenang',
            style: TextStyle(color: Color(0xFFB8960C))),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(laporan,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366)),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text('Share WA',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final screenH = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          // Pilih Grup
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<GrupArisan>(
              value: _grupSelected,
              dropdownColor: const Color(0xFF16213E),
              style: const TextStyle(
                  color: Colors.white, fontSize: 13),
              isExpanded: true,
              underline: const SizedBox(),
              items: widget.grupList
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(
                            '${g.namaGrup} • ${g.jumlahPemenangPerPutaran} pemenang/putaran'),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _grupSelected = v;
                  _sudahKocok = false;
                  _pemenangList = [];
                  _namaDisplay = '???';
                  _poolAnggota = [];
                  _adaSusulan = false;
                });
                _loadData();
              },
            ),
          ),
          const SizedBox(height: 8),

          // Info putaran & pool
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'Putaran $_putaranKe dari ${_grupSelected?.totalPutaran ?? 10}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol pilih anggota
              GestureDetector(
                onTap: _showPilihAnggotaDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _poolAnggota.isEmpty
                        ? Colors.red.withOpacity(0.15)
                        : const Color(0xFFB8960C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _poolAnggota.isEmpty
                          ? Colors.red.withOpacity(0.5)
                          : const Color(0xFFB8960C).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people,
                          size: 14,
                          color: _poolAnggota.isEmpty
                              ? Colors.red
                              : const Color(0xFFB8960C)),
                      const SizedBox(width: 4),
                      Text(
                        _poolAnggota.isEmpty
                            ? 'Pilih Anggota'
                            : '${_poolAnggota.length} dipilih',
                        style: TextStyle(
                          color: _poolAnggota.isEmpty
                              ? Colors.red
                              : const Color(0xFFB8960C),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Banner menunggu konfirmasi
          if (_menungguKonfirmasi.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showKonfirmasiDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_menungguKonfirmasi.length} pemenang menunggu konfirmasi — Tap di sini',
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: Colors.orange, size: 16),
                  ],
                ),
              ),
            ),
          ],

          // Banner susulan
          if (_adaSusulan && _kurangPemenang > 0) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.blue.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.refresh_rounded,
                      color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Butuh $_kurangPemenang pemenang susulan putaran $_putaranKe',
                      style: const TextStyle(
                          color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Lingkaran spin
          AnimatedBuilder(
            animation: _spinController,
            builder: (_, __) => Container(
              width: screenH * 0.27,
              height: screenH * 0.27,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(
                    color:
                        const Color(0xFFB8960C).withOpacity(0.5),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                      color:
                          const Color(0xFFB8960C).withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5)
                ],
              ),
              child: _sudahKocok && _pemenangList.isNotEmpty
                  ? ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: Color(0xFFB8960C), size: 28),
                          const SizedBox(height: 2),
                          const Text('Pemenang!',
                              style: TextStyle(
                                  color: Color(0xFFB8960C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10),
                            child: Text(
                              _pemenangList
                                  .map((p) => p.nama)
                                  .join('\n'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_loading)
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                                color: Color(0xFFB8960C),
                                strokeWidth: 3),
                          ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          child: Text(
                            _namaDisplay,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _loading ? 13 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 14),

          // Tombol-tombol
          if (!_sudahKocok && _menungguKonfirmasi.isEmpty) ...[
            if (!_adaSusulan)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _loading || _poolAnggota.isEmpty
                      ? null
                      : () => _showKasDialog(),
                  icon: const Icon(Icons.casino_rounded, size: 20),
                  label: Text(
                    _loading
                        ? 'Mengocok...'
                        : _poolAnggota.isEmpty
                            ? 'Pilih anggota dulu!'
                            : 'MULAI KOCOK',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _poolAnggota.isEmpty
                        ? Colors.grey
                        : const Color(0xFFB8960C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (_adaSusulan && _kurangPemenang > 0)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _showKasDialog(isSusulan: true),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    _loading
                        ? 'Mengocok...'
                        : 'SPIN SUSULAN ($_kurangPemenang pemenang)',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],

          if (_sudahKocok) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _shareWA,
                icon: const Icon(Icons.share,
                    color: Colors.white, size: 18),
                label: const Text('Lihat Laporan & Share WA',
                    style:
                        TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _showKonfirmasiDialog,
                icon: const Icon(Icons.check_circle_outline,
                    color: Color(0xFFB8960C), size: 16),
                label: const Text('Konfirmasi Pemenang',
                    style: TextStyle(
                        color: Color(0xFFB8960C), fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB8960C)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _sudahKocok = false;
                    _pemenangList = [];
                    _namaDisplay = '???';
                  });
                  _loadData();
                },
                icon: const Icon(Icons.arrow_forward,
                    color: Colors.white54, size: 16),
                label: const Text('Lanjut Putaran Berikutnya',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Info algoritma
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.white30, size: 12),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Fisher-Yates Shuffle — setiap anggota memiliki peluang yang sama',
                    style: TextStyle(
                        color: Colors.white30, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Container(
          color: const Color(0xFF1A1A2E), child: _buildBody());
    }
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Spin Pengocokan',
            style: TextStyle(
                color: Color(0xFFB8960C),
                fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }
}