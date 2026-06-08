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
  final _currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static const _arisanAktifId = 'arisan-001';

  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _initArisanDefault();
  }

  Future<void> _initArisanDefault() async {
    final list = await _service.getAllArisan();
    if (list.isEmpty) {
      await _service.tambahArisan(
        Arisan(
          id: _arisanAktifId,
          namaArisan: 'Arisan Keluarga Besar',
          periode: 'Bulanan',
          nominal: 50000,
          tanggalMulai: DateTime.now().toIso8601String(),
        ),
      );
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final stats = await _service.getDashboardStats(_arisanAktifId);
    setState(() {
      _stats = stats;
      _loading = false;
    });
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
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.savings_rounded),
            SizedBox(width: 8),
            Text('ArisanKu',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(onPressed: _loadStats, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selamat Datang, Pengurus!',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                          .format(DateTime.now()),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Total Terkumpul
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Iuran Terkumpul',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            _currency.format(_stats['total_terkumpul'] ?? 0),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('Periode: Arisan Keluarga Besar',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Statistik
                    Row(
                      children: [
                        _statCard('Total Anggota',
                            '${_stats['total_anggota'] ?? 0}',
                            Icons.group, Colors.blue),
                        const SizedBox(width: 12),
                        _statCard('Sudah Bayar',
                            '${_stats['sudah_bayar'] ?? 0}',
                            Icons.check_circle, Colors.green),
                        const SizedBox(width: 12),
                        _statCard('Belum Bayar',
                            '${_stats['belum_bayar'] ?? 0}',
                            Icons.warning_rounded, Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text('Menu Utama',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
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
                            const Color(0xFF1565C0),
                            () => _navigate(
                                AnggotaScreen(arisanId: _arisanAktifId))),
                        _menuCard(
                            'Pembayaran',
                            Icons.payment,
                            const Color(0xFF6A1B9A),
                            () => _navigate(
                                PembayaranScreen(arisanId: _arisanAktifId))),
                        _menuCard(
                            'Spin Arisan',
                            Icons.casino_rounded,
                            const Color(0xFFC62828),
                            () => _navigate(
                                PengocokanScreen(arisanId: _arisanAktifId))),
                        _menuCard(
                            'Riwayat',
                            Icons.history,
                            const Color(0xFF00695C),
                            () => _navigate(
                                RiwayatScreen(arisanId: _arisanAktifId))),
                      ],
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
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCard(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
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
      ),
    );
  }
}