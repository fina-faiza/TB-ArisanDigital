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
  List<Anggota> _pemenangList = [];
  bool _loading = false;
  bool _sudahKocok = false;
  int _putaranKe = 1;

  // Status menunggu konfirmasi di putaran ini
  List<Pengocokan> _menungguKonfirmasi = [];
  bool _adaSusulan = false;
  List<String> _poolSusulan = []; // ID anggota yang kembali ke pool

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
    final putaran = await _service.getPutaranTerakhir(_grupSelected!.id);
    final putaranAktif = putaran + 1;
    final menunggu = await _service.getPemenangMenunggu(
        _grupSelected!.id, putaranAktif);

    setState(() {
      _semuaAnggota = anggota;
      _anggotaNames = anggota.map((a) => a.nama).toList();
      _putaranKe = putaranAktif;
      _menungguKonfirmasi = menunggu;
      _adaSusulan = _poolSusulan.isNotEmpty;
    });
  }

  void _showKasDialog({bool isSusulan = false}) {
    _kasCtrl.clear();
    _catatanKas = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          isSusulan ? 'Spin Susulan' : 'Potongan Kas Khadijiyyah',
          style: const TextStyle(color: Colors.white, fontSize: 16),
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
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: Text(
                  'Spin susulan untuk ${_poolSusulan.length} pemenang yang tidak diambil.\nMasih termasuk Putaran $_putaranKe.',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
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
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.account_balance_wallet,
                    color: Color(0xFFB8960C)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24)),
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
    if (_semuaAnggota.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada anggota tersedia')));
      return;
    }

    final jumlahPemenang = isSusulan
        ? _poolSusulan.length
        : _grupSelected!.jumlahPemenangPerPutaran;

    setState(() {
      _loading = true;
      _sudahKocok = false;
      _pemenangList = [];
    });

    _spinController.reset();
    _spinController.forward();

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

    final pemenangList = await _service.lakukanPengocokan(
      grupId: _grupSelected!.id,
      putaranKe: _putaranKe,
      jumlahPemenang: jumlahPemenang,
      potonganKas: potonganKas,
      catatanKas: _catatanKas.isNotEmpty ? _catatanKas : null,
      isSusulan: isSusulan,
      tambahPool: isSusulan ? _poolSusulan : [],
    );

    if (!mounted) return;

    if (pemenangList.isEmpty) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tidak ada anggota tersedia untuk dikocok!')));
      return;
    }

    // Reset pool susulan setelah spin susulan
    if (isSusulan) {
      setState(() => _poolSusulan = []);
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
    _loadData();
  }

  // Konfirmasi pemenang yang menunggu
  void _showKonfirmasiDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            'Konfirmasi Pemenang Putaran $_putaranKe',
            style: const TextStyle(
                color: Color(0xFFB8960C), fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih status pengambilan untuk setiap pemenang:',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ..._menungguKonfirmasi.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
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
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              await _service.tandaiDiambil(p.id);
                              setS(() => _menungguKonfirmasi
                                  .removeWhere((x) => x.id == p.id));
                              _loadData();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text('Diambil',
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () async {
                              final anggotaId = await _service
                                  .tandaiTidakDiambil(p.id);
                              if (anggotaId != null) {
                                setS(() {
                                  _menungguKonfirmasi
                                      .removeWhere((x) => x.id == p.id);
                                  _poolSusulan.add(anggotaId);
                                });
                                setState(
                                    () => _poolSusulan.add(anggotaId));
                                _loadData();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: const Text('Tidak',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8960C)),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _adaSusulan = _poolSusulan.isNotEmpty;
                });
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
    final tgl = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(now);
    final grup = _grupSelected!;
    final potongan = int.tryParse(_kasCtrl.text) ?? 0;
    final totalDiterima = (grup.nominal *
                grup.jumlahPeserta ~/
                grup.jumlahPemenangPerPutaran) -
            potongan;

    String pemenangStr = '';
    for (int i = 0; i < _pemenangList.length; i++) {
      pemenangStr += '✨ ${_pemenangList[i].nama} ✨\n';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(laporan,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Copy teks di atas lalu paste ke grup WhatsApp',
                style: TextStyle(color: Colors.white54, fontSize: 11),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pilih Grup
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  _poolSusulan = [];
                  _adaSusulan = false;
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
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),

          // Banner menunggu konfirmasi
          if (_menungguKonfirmasi.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showKonfirmasiDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_menungguKonfirmasi.length} pemenang menunggu konfirmasi — Tap untuk konfirmasi',
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: Colors.orange, size: 18),
                  ],
                ),
              ),
            ),
          ],

          // Banner susulan
          if (_adaSusulan && _poolSusulan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.blue.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.refresh_rounded,
                      color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_poolSusulan.length} anggota siap untuk spin susulan putaran $_putaranKe',
                      style:
                          const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Area spin utama
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _spinController,
                    builder: (_, __) => Container(
                      width: 220,
                      height: 220,
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
                      child: _sudahKocok && _pemenangList.isNotEmpty
                          ? ScaleTransition(
                              scale: _scaleAnimation,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons.emoji_events_rounded,
                                      color: Color(0xFFB8960C),
                                      size: 32),
                                  const SizedBox(height: 4),
                                  const Text('Pemenang!',
                                      style: TextStyle(
                                          color: Color(0xFFB8960C),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      _pemenangList
                                          .map((p) => p.nama)
                                          .join('\n'),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
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
                                    child: CircularProgressIndicator(
                                        color: Color(0xFFB8960C),
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
                                      fontSize: _loading ? 14 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol-tombol
                  if (!_sudahKocok && _menungguKonfirmasi.isEmpty) ...[
                    // Spin utama
                    if (!_adaSusulan)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _showKasDialog(),
                          icon: const Icon(Icons.casino_rounded,
                              size: 24),
                          label: Text(
                            _loading ? 'Mengocok...' : 'MULAI KOCOK',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB8960C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                          ),
                        ),
                      ),

                    // Spin susulan
                    if (_adaSusulan && _poolSusulan.isNotEmpty) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _showKasDialog(isSusulan: true),
                          icon: const Icon(Icons.refresh_rounded,
                              size: 24),
                          label: Text(
                            _loading
                                ? 'Mengocok...'
                                : 'SPIN SUSULAN (${_poolSusulan.length} pemenang)',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ],

                  if (_sudahKocok) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _shareWA,
                        icon: const Icon(Icons.share,
                            color: Colors.white),
                        label: const Text('Lihat Laporan & Share WA',
                            style: TextStyle(
                                color: Colors.white, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _showKonfirmasiDialog,
                        icon: const Icon(Icons.check_circle_outline,
                            color: Color(0xFFB8960C), size: 18),
                        label: const Text('Konfirmasi Pemenang',
                            style: TextStyle(
                                color: Color(0xFFB8960C))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFB8960C)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                        icon: const Icon(Icons.arrow_forward,
                            color: Colors.white70, size: 18),
                        label: const Text('Lanjut Putaran Berikutnya',
                            style: TextStyle(color: Colors.white70)),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
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