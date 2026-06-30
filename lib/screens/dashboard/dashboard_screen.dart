import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/arisan_service.dart';
import '../../services/auth_service.dart';
import '../anggota/anggota_screen.dart';
import '../pembayaran/pembayaran_screen.dart';
import '../pengocokan/pengocokan_screen.dart';
import '../riwayat/riwayat_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = ArisanService();
  final _auth = AuthService();
  final _currency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Periode? _periodeAktif;
  List<GrupArisan> _grupList = [];
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final periode = await _service.getPeriodeAktif();
    if (periode != null) {
      final grupList = await _service.getGrupByPeriode(periode.id);
      setState(() {
        _periodeAktif = periode;
        _grupList = grupList;
        _grupSelected = grupList.isNotEmpty ? grupList.first : null;
      });
      if (_grupSelected != null) {
        await _loadStats();
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _loadStats() async {
    if (_grupSelected == null) return;
    final stats = await _service.getDashboardStats(
        _grupSelected!.id, _bulanSelected);
    setState(() => _stats = stats);
  }

  void _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('assets/images/logo_khadijiyyah.png',
                height: 32),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arisan Khadijiyyah',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB8960C))),
                Text('Idrisiyyah Indonesia',
                    style: TextStyle(
                        fontSize: 10, color: Color(0xFF00BCD4))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.white70)),
          IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white70)),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFB8960C)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Periode aktif
                    if (_periodeAktif != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8960C).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFB8960C).withOpacity(0.3)),
                        ),
                        child: Text(
                          'Periode ${_periodeAktif!.namaPeriode} • ${_periodeAktif!.bulanMulai} - ${_periodeAktif!.bulanSelesai}',
                          style: const TextStyle(
                              color: Color(0xFFB8960C),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Pilih Grup
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
                            items: _grupList
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

                    // Total Terkumpul
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

                    // Statistik
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

                    // Menu Utama
                    const Text('Menu Utama',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _menuCard(
                            'Data Anggota',
                            Icons.people,
                            const Color(0xFF0D47A1),
                            () => _navigate(AnggotaScreen(
                                grupList: _grupList))),
                        _menuCard(
                            'Pembayaran',
                            Icons.payment,
                            const Color(0xFF4A148C),
                            () => _navigate(PembayaranScreen(
                                grupList: _grupList,
                                bulanAwal: _bulanSelected))),
                        _menuCard(
                            'Spin Arisan',
                            Icons.casino_rounded,
                            const Color(0xFFB71C1C),
                            () => _navigate(PengocokanScreen(
                                grupList: _grupList))),
                        _menuCard(
                            'Riwayat',
                            Icons.history,
                            const Color(0xFF1B5E20),
                            () => _navigate(RiwayatScreen(
                                grupList: _grupList))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Arisan Khadijiyyah by Firsha',
                        style: TextStyle(
                            color: Colors.white24, fontSize: 11),
                      ),
                    ),
                  ],
                ),
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
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
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

  Widget _menuCard(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}