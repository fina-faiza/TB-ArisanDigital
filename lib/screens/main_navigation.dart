import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/arisan_service.dart';
import '../services/auth_service.dart';
import 'anggota/anggota_screen.dart';
import 'pembayaran/pembayaran_screen.dart';
import 'pengocokan/pengocokan_screen.dart';
import 'riwayat/riwayat_screen.dart';
import 'periode/periode_screen.dart';
import 'auth/login_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final _service = ArisanService();
  final _auth = AuthService();

  int _currentIndex = 0;
  Periode? _periodeAktif;
  List<GrupArisan> _grupList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPeriode();
  }

  Future<void> _loadPeriode() async {
    setState(() => _loading = true);
    final periode = await _service.getPeriodeAktif();
    List<GrupArisan> grupList = [];
    if (periode != null) {
      grupList = await _service.getGrupByPeriode(periode.id);
    }
    setState(() {
      _periodeAktif = periode;
      _grupList = grupList;
      _loading = false;
    });
  }

  void _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _openPeriode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PeriodeScreen()),
    ).then((_) => _loadPeriode());
  }

  static const List<String> _titles = [
    'Beranda',
    'Data Anggota',
    'Spin Arisan',
    'Pembayaran',
    'Riwayat',
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB8960C)),
        ),
      );
    }

    if (_periodeAktif == null || _grupList.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16213E),
          foregroundColor: Colors.white,
          title: Row(
            children: [
              Image.asset('assets/images/logo_khadijiyyah.png',
                  height: 28),
              const SizedBox(width: 8),
              const Text('Arisan Khadijiyyah',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB8960C))),
            ],
          ),
          actions: [
            IconButton(
                onPressed: _openPeriode,
                icon: const Icon(Icons.settings,
                    color: Colors.white70)),
            IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white70)),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month,
                    color: Colors.white38, size: 60),
                const SizedBox(height: 16),
                Text(
                  _periodeAktif == null
                      ? 'Belum ada periode aktif'
                      : 'Belum ada grup arisan di periode ini',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8960C)),
                  onPressed: _openPeriode,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Kelola Periode',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final screens = [
      BerandaTab(grupList: _grupList, periodeAktif: _periodeAktif!),
      AnggotaScreen(grupList: _grupList, embedded: true),
      PengocokanScreen(grupList: _grupList, embedded: true),
      PembayaranScreen(
          grupList: _grupList, bulanAwal: 'Mei', embedded: true),
      RiwayatScreen(grupList: _grupList, embedded: true),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/images/logo_khadijiyyah.png', height: 28),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titles[_currentIndex],
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB8960C))),
                const Text('Arisan Khadijiyyah',
                    style:
                        TextStyle(fontSize: 10, color: Color(0xFF00BCD4))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
              onPressed: _openPeriode,
              icon: const Icon(Icons.settings, color: Colors.white70)),
          IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white70)),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF16213E),
            selectedItemColor: const Color(0xFFB8960C),
            unselectedItemColor: Colors.white38,
            showUnselectedLabels: true,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded), label: 'Beranda'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people_rounded), label: 'Anggota'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.casino_rounded), label: 'Spin'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.payment_rounded), label: 'Bayar'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded), label: 'Riwayat'),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TAB BERANDA
// ─────────────────────────────────────────
class BerandaTab extends StatefulWidget {
  final List<GrupArisan> grupList;
  final Periode periodeAktif;
  const BerandaTab(
      {super.key, required this.grupList, required this.periodeAktif});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  final _service = ArisanService();
  final _currency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  GrupArisan? _grupSelected;
  Map<String, int> _stats = {};
  bool _loading = true;

  final List<String> _bulanList = [
    'Mei', 'Juni', 'Juli', 'Agustus', 'September',
    'Oktober', 'November', 'Desember', 'Januari', 'Februari'
  ];
  String _bulanSelected = 'Mei';

  @override
  void initState() {
    super.initState();
    _grupSelected =
        widget.grupList.isNotEmpty ? widget.grupList.first : null;
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (_grupSelected == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final stats = await _service.getDashboardStats(
        _grupSelected!.id, _bulanSelected);
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(
            child:
                CircularProgressIndicator(color: Color(0xFFB8960C)))
        : RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8960C).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              const Color(0xFFB8960C).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Periode ${widget.periodeAktif.namaPeriode} • ${widget.periodeAktif.bulanMulai} - ${widget.periodeAktif.bulanSelesai}',
                      style: const TextStyle(
                          color: Color(0xFFB8960C),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Grup:',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<GrupArisan>(
                          value: _grupSelected,
                          dropdownColor: const Color(0xFF16213E),
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          items: widget.grupList
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g.namaGrup),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _grupSelected = v);
                            _loadStats();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Bulan:',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _bulanSelected,
                          dropdownColor: const Color(0xFF16213E),
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          items: _bulanList
                              .map((b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _bulanSelected = v!);
                            _loadStats();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB8960C), Color(0xFFD4AF37)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Iuran Terkumpul',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(
                          _currency
                              .format(_stats['total_terkumpul'] ?? 0),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_grupSelected?.namaGrup ?? '-'} • Bulan $_bulanSelected',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statCard(
                          'Total Anggota',
                          '${_stats['total_anggota'] ?? 0}',
                          Icons.group,
                          const Color(0xFF00BCD4)),
                      const SizedBox(width: 10),
                      _statCard(
                          'Sudah Bayar',
                          '${_stats['sudah_bayar'] ?? 0}',
                          Icons.check_circle,
                          Colors.green),
                      const SizedBox(width: 10),
                      _statCard(
                          'Belum Bayar',
                          '${_stats['belum_bayar'] ?? 0}',
                          Icons.warning_rounded,
                          Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _statCardWide(
                    'Putaran Selesai',
                    '${_stats['putaran_terakhir'] ?? 0} dari ${_grupSelected?.totalPutaran ?? 10}',
                    Icons.rotate_right,
                    const Color(0xFFB8960C),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Arisan Khadijiyyah by Firsha',
                      style:
                          TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: Colors.white54),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _statCardWide(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}