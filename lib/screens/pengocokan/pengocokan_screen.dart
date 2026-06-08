import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';

class PengocokanScreen extends StatefulWidget {
  final String arisanId;
  const PengocokanScreen({super.key, required this.arisanId});

  @override
  State<PengocokanScreen> createState() => _PengocokanScreenState();
}

class _PengocokanScreenState extends State<PengocokanScreen>
    with TickerProviderStateMixin {
  final _service = ArisanService();
  final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<Anggota> _semuaAnggota = [];
  Anggota? _pemenang;
  bool _loading = false;
  bool _sudahKocok = false;
  int _periodeKe = 1;

  late AnimationController _spinController;
  late AnimationController _revealController;
  late Animation<double> _spinAnimation;
  late Animation<double> _scaleAnimation;

  String _namaDisplay = '???';
  List<String> _anggotaNames = [];

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    _revealController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _spinAnimation = CurvedAnimation(
        parent: _spinController, curve: Curves.easeOut);
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
            parent: _revealController, curve: Curves.elasticOut));

    _loadData();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final anggota = await _service.getAllAnggota();
    final riwayat =
        await _service.getRiwayatPengocokan(widget.arisanId);
    setState(() {
      _semuaAnggota = anggota;
      _anggotaNames = anggota.map((a) => a.nama).toList();
      _periodeKe = riwayat.length + 1;
    });
  }

  Future<void> _mulaiKocok() async {
    if (_semuaAnggota.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada anggota tersedia')));
      return;
    }

    setState(() {
      _loading = true;
      _sudahKocok = false;
      _pemenang = null;
    });

    _spinController.reset();
    _spinController.forward();

    final stopwatch = Stopwatch()..start();
    int delay = 80;

    while (stopwatch.elapsedMilliseconds < 2800) {
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) return;
      setState(() {
        _namaDisplay =
            _anggotaNames[Random().nextInt(_anggotaNames.length)];
      });
      if (stopwatch.elapsedMilliseconds > 1500) delay = 150;
      if (stopwatch.elapsedMilliseconds > 2200) delay = 250;
    }

    final pemenang = await _service.lakukanPengocokan(
      arisanId: widget.arisanId,
      periodeKe: _periodeKe,
    );

    if (!mounted) return;

    if (pemenang == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Semua anggota sudah pernah menang!')));
      return;
    }

    setState(() {
      _namaDisplay = pemenang.nama;
      _pemenang = pemenang;
      _loading = false;
      _sudahKocok = true;
    });

    _revealController.reset();
    _revealController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Spin Pengocokan Arisan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                    'Periode ke-$_periodeKe • ${_semuaAnggota.length} Anggota',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _spinAnimation,
                        builder: (_, __) {
                          return Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(
                                  color: Colors.white30, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.green.withOpacity(0.3),
                                    blurRadius: 40,
                                    spreadRadius: 10)
                              ],
                            ),
                            child: _sudahKocok && _pemenang != null
                                ? ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                            Icons.emoji_events_rounded,
                                            color: Colors.amber,
                                            size: 48),
                                        const SizedBox(height: 8),
                                        const Text('Pemenang!',
                                            style: TextStyle(
                                                color: Colors.amber,
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16),
                                          child: Text(
                                            _pemenang!.nama,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight:
                                                    FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _currency.format(
                                              _pemenang!.nominal),
                                          style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 16),
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
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3),
                                        ),
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: Text(
                                          _namaDisplay,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                _loading ? 18 : 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: 48),
                      if (!_sudahKocok)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _mulaiKocok,
                            icon: const Icon(Icons.casino_rounded,
                                size: 28),
                            label: Text(
                              _loading ? 'Mengocok...' : 'MULAI KOCOK',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      if (_sudahKocok)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _sudahKocok = false;
                                _pemenang = null;
                                _namaDisplay = '???';
                                _periodeKe++;
                              });
                              _loadData();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Kocok Lagi',
                                style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1B5E20),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.white54, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Menggunakan Algoritma Fisher-Yates Shuffle\n— setiap anggota memiliki peluang yang sama',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 11),
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