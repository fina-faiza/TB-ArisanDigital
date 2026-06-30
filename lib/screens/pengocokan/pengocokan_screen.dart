import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';

class PengocokanScreen extends StatefulWidget {
  final List<GrupArisan> grupList;
  const PengocokanScreen({super.key, required this.grupList});

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
  List<Anggota> _pemenangList = [];
  bool _loading = false;
  bool _sudahKocok = false;
  int _putaranKe = 1;

  late AnimationController _spinController;
  late AnimationController _revealController;
  late Animation<double> _scaleAnimation;

  String _namaDisplay = '???';
  List<String> _anggotaNames = [];

  // Potongan kas
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
        vsync: this,
        duration: const Duration(milliseconds: 800));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
            parent: _revealController,
            curve: Curves.elasticOut));
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
    final anggota =
        await _service.getAnggotaByGrup(_grupSelected!.id);
    final putaran =
        await _service.getPutaranTerakhir(_grupSelected!.id);
    setState(() {
      _semuaAnggota = anggota;
      _anggotaNames = anggota.map((a) => a.nama).toList();
      _putaranKe = putaran + 1;
    });
  }

  void _showKasDialog() {
    _kasCtrl.clear();
    _catatanKas = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Potongan Kas Khadijiyyah',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan nominal potongan kas\n(kosongkan jika tidak ada)',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _kasCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nominal Kas (Rp)',
                labelStyle:
                    const TextStyle(color: Colors.white54),
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
                    borderSide: const BorderSide(
                        color: Color(0xFFB8960C))),
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
                backgroundColor: const Color(0xFFB8960C)),
            onPressed: () {
              final kas = int.tryParse(_kasCtrl.text) ?? 0;
              _catatanKas = kas > 0
                  ? '(kas khadijiyyah: seikhlasnya, hubungi admin)'
                  : '';
              Navigator.pop(context);
              _mulaiKocok(kas);
            },
            child: const Text('Mulai Kocok',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _mulaiKocok(int potonganKas) async {
    if (_semuaAnggota.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tidak ada anggota tersedia')));
      return;
    }

    setState(() {
      _loading = true;
      _sudahKocok = false;
      _pemenangList = [];
    });

    _spinController.reset();
    _spinController.forward();

    // Animasi nama berputar
    final stopwatch = Stopwatch()..start();
    int delay = 60;
    while (stopwatch.elapsedMilliseconds < 3000) {
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) return;
      if (_anggotaNames.isNotEmpty) {
        setState(() {
          _namaDisplay =
              _anggotaNames[Random().nextInt(_anggotaNames.length)];
        });
      }
      if (stopwatch.elapsedMilliseconds > 1500) delay = 120;
      if (stopwatch.elapsedMilliseconds > 2200) delay = 220;
      if (stopwatch.elapsedMilliseconds > 2700) delay = 350;
    }

    // Jalankan Fisher-Yates Shuffle
    final pemenangList = await _service.lakukanPengocokan(
      grupId: _grupSelected!.id,
      putaranKe: _putaranKe,
      jumlahPemenang: _grupSelected!.jumlahPemenangPerPutaran,
      potonganKas: potonganKas,
      catatanKas: _catatanKas.isNotEmpty ? _catatanKas : null,
    );

    if (!mounted) return;

    if (pemenangList.isEmpty) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Semua anggota sudah pernah menang!')));
      return;
    }

    setState(() {
      _pemenangList = pemenangList;
      _namaDisplay = pemenangList.first.nama;
      _loading = false;
      _sudahKocok = true;
    });

    _revealController.reset();
    _revealController.forward();
  }

  String _buatLaporanWA() {
    final now = DateTime.now();
    final tgl =
        DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(now);
    final grup = _grupSelected!;
    final totalKotak =
        grup.nominal * grup.jumlahPeserta;
    final potongan = int.tryParse(_kasCtrl.text) ?? 0;
    final totalDiterima =
        (grup.nominal * grup.jumlahPeserta ~/ grup.jumlahPemenangPerPutaran) -
            potongan;

    String pemenangStr = '';
    for (int i = 0; i < _pemenangList.length; i++) {
      pemenangStr +=
          '✨ ${_pemenangList[i].nama} ✨\n';
    }

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
$kasStr Total Diterima per Anggota: ${_currency.format(totalDiterima)}
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  laporan,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Copy teks di atas lalu paste ke grup WhatsApp',
                style:
                    TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
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
            onPressed: () {
              // Copy ke clipboard
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Salin teks laporan untuk dikirim ke WA')),
              );
            },
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text('Share WA',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Pilih Grup
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<GrupArisan>(
                  value: _grupSelected,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
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
                    });
                    _loadData();
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Info putaran
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'Putaran ke-$_putaranKe dari ${_grupSelected?.totalPutaran ?? 10} • ${_semuaAnggota.length} Anggota',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // Area utama
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lingkaran spin
                      AnimatedBuilder(
                        animation: _spinController,
                        builder: (_, __) => Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                                color: const Color(0xFFB8960C)
                                    .withOpacity(0.5),
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFFB8960C)
                                      .withOpacity(0.2),
                                  blurRadius: 40,
                                  spreadRadius: 10)
                            ],
                          ),
                          child: _sudahKocok &&
                                  _pemenangList.isNotEmpty
                              ? ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                          Icons.emoji_events_rounded,
                                          color: Color(0xFFB8960C),
                                          size: 36),
                                      const SizedBox(height: 4),
                                      const Text('Pemenang!',
                                          style: TextStyle(
                                              color:
                                                  Color(0xFFB8960C),
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          _pemenangList
                                              .map((p) => p.nama)
                                              .join('\n'),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.bold),
                                          textAlign:
                                              TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    if (_loading)
                                      const SizedBox(
                                        width: 36,
                                        height: 36,
                                        child:
                                            CircularProgressIndicator(
                                                color:
                                                    Color(0xFFB8960C),
                                                strokeWidth: 3),
                                      ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16),
                                      child: Text(
                                        _namaDisplay,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: _loading ? 16 : 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Tombol
                      if (!_sudahKocok)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed:
                                _loading ? null : _showKasDialog,
                            icon: const Icon(Icons.casino_rounded,
                                size: 24),
                            label: Text(
                              _loading
                                  ? 'Mengocok...'
                                  : 'MULAI KOCOK',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFB8960C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                            ),
                          ),
                        ),

                      if (_sudahKocok)
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _shareWA,
                                icon: const Icon(Icons.share,
                                    color: Colors.white),
                                label: const Text(
                                    'Lihat Laporan & Share WA',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF25D366),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _sudahKocok = false;
                                    _pemenangList = [];
                                    _namaDisplay = '???';
                                  });
                                  _loadData();
                                },
                                icon: const Icon(Icons.refresh,
                                    color: Colors.white70),
                                label: const Text('Kocok Putaran Baru',
                                    style: TextStyle(
                                        color: Colors.white70)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Colors.white24),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Info algoritma
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.white38, size: 14),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fisher-Yates Shuffle — setiap anggota memiliki peluang yang sama',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}