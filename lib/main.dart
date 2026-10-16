// EcoRecolecta · Prototipo de aplicación para el seguimiento de recolección de residuos.
// Copyright © 2026 Alejandro Guillermo Enríquez Rodríguez. Todos los derechos reservados.
// Prohibida su reproducción, distribución o modificación sin autorización escrita del autor.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

void main() => runApp(const EcoRecolectaApp());

const kGreen = Color(0xFF0F7A47);
const kDark = Color(0xFF0A4D33);
const kLime = Color(0xFF8CC63F);
const kBg = Color(0xFFF4F8F5);

// ───────── Estado global simple (demo) ─────────
final tab = ValueNotifier<int>(0); // pestaña activa
final sel = ValueNotifier<int>(0); // ruta seleccionada
final user = ValueNotifier<String?>(null); // null = invitado

// ───────── Datos de rutas (simulados) ─────────
class Ruta {
  final String code, nombre, colonias, dias, hora;
  final Color color;
  final List<LatLng> base;
  const Ruta(this.code, this.nombre, this.colonias, this.dias, this.hora, this.color, this.base);
}

LatLng _o(double a, double b) => LatLng(17.0565 + a, -96.7075 + b);
List<LatLng> _sh(List<LatLng> b, double a, double c) =>
    b.map((p) => LatLng(p.latitude + a, p.longitude + c)).toList();
final _b0 = [_o(.0075, .0045), _o(.0045, .0015), _o(.001, -.001), _o(-.002, .0005), _o(-.0045, -.0025), _o(-.0075, -.0045)];

final rutas = <Ruta>[
  Ruta('R-01', 'Ruta Norte', 'Centro · Las Flores · Niño Perdido', 'Lun · Mié · Vie', '7:30', kGreen, _b0),
  Ruta('R-02', 'Ruta Centro', 'Zócalo · Reforma · La Noria', 'Mar · Jue · Sáb', '8:00', const Color(0xFF3B82C4), _sh(_b0, .004, .012)),
  Ruta('R-03', 'Ruta Sur', 'San Felipe · Los Pinos · El Rosario', 'Lun · Mié · Vie', '9:00', const Color(0xFFE08A1E), _sh(_b0, -.006, -.010)),
  Ruta('R-04', 'Ruta Oriente', 'Jardines · Primavera · Cinco Señores', 'Mar · Jue · Sáb', '7:00', const Color(0xFF8E4FB0), _sh(_b0, .001, .022)),
];

void _toShell(BuildContext c) {
  tab.value = 0;
  Navigator.of(c).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const Shell()), (_) => false);
}

void _toWelcome(BuildContext c) {
  user.value = null;
  Navigator.of(c).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomePage()), (_) => false);
}

class EcoRecolectaApp extends StatelessWidget {
  const EcoRecolectaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'EcoRecolecta',
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ColoredBox(
          color: const Color(0xFFDCE8E0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, minHeight: double.infinity),
              child: child,
            ),
          ),
        ),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: kGreen),
          scaffoldBackgroundColor: kBg,
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        home: const WelcomePage(),
      );
}

// ───────── MARCA: camión dentro de las flechas de reciclaje ─────────
class ArrowsPainter extends CustomPainter {
  final List<Color> colors;
  final double k;
  ArrowsPainter(this.colors, this.k);
  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    final r = s.width / 2 - 18 * k;
    for (var i = 0; i < 3; i++) {
      final start = (-90 + i * 120 + 10) * pi / 180;
      final sweep = 92 * pi / 180;
      final stroke = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16 * k
        ..strokeCap = StrokeCap.round;
      c.drawArc(Rect.fromCircle(center: center, radius: r), start, sweep, false, stroke);
      final a = start + sweep;
      final tip = center + Offset(cos(a), sin(a)) * r;
      final t = Offset(-sin(a), cos(a));
      final n = Offset(cos(a), sin(a));
      final head = Path()
        ..moveTo(tip.dx + t.dx * 30 * k, tip.dy + t.dy * 30 * k)
        ..lineTo(tip.dx + n.dx * 22 * k, tip.dy + n.dy * 22 * k)
        ..lineTo(tip.dx - n.dx * 22 * k, tip.dy - n.dy * 22 * k)
        ..close();
      c.drawPath(head, Paint()..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class HeroMark extends StatelessWidget {
  final double size;
  final bool dark; // true = sobre fondo verde oscuro
  const HeroMark({super.key, required this.size, this.dark = true});
  @override
  Widget build(BuildContext context) {
    final colors = dark
        ? const [Color(0xFFB6E36B), Color(0xFF8CC63F), Color(0xFF4FB05A)]
        : const [Color(0xFF8CC63F), Color(0xFF3E9E45), Color(0xFF0A4D33)];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          Transform.rotate(
            angle: (1 - v) * -1.3,
            child: CustomPaint(size: Size(size, size), painter: ArrowsPainter(colors, size / 300)),
          ),
          Container(
            width: size * .70,
            height: size * .70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 18, color: Colors.black.withValues(alpha: .18))],
            ),
          ),
          Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset((1 - v) * -size * .3, size * .02),
              child: Image.asset('assets/camion.png', width: size * .60),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..lineTo(0, s.height - 40)
    ..quadraticBezierTo(s.width / 2, s.height + 20, s.width, s.height - 40)
    ..lineTo(s.width, 0)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ───────── BIENVENIDA ─────────
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(children: [
            ClipPath(
              clipper: _CurveClipper(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 24, bottom: 64),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kDark, kGreen]),
                ),
                child: SafeArea(bottom: false, child: Center(child: HeroMark(size: 250))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
              child: Column(children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -.5),
                    children: [
                      TextSpan(text: 'Eco', style: TextStyle(color: kGreen)),
                      TextSpan(text: 'Recolecta', style: TextStyle(color: kDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Recolectamos hoy, cuidamos el mañana.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: kDark)),
                const SizedBox(height: 14),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _Pill(Icons.eco, 'Reduce'),
                  SizedBox(width: 8),
                  _Pill(Icons.delete_outline, 'Separa'),
                  SizedBox(width: 8),
                  _Pill(Icons.recycling, 'Recicla'),
                ]),
                const SizedBox(height: 16),
                const Text('Bienvenido. Sigue a tu camión en tiempo real y cuida tu colonia.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: kGreen, padding: const EdgeInsets.all(16)),
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const AuthPage(register: false))),
                    child: const Text('Iniciar sesión', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: kGreen,
                        side: const BorderSide(color: kGreen, width: 1.5),
                        padding: const EdgeInsets.all(16)),
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const AuthPage(register: true))),
                    child: const Text('Crear cuenta', style: TextStyle(fontSize: 17)),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => _toShell(context),
                  child: const Text('Omitir por ahora', style: TextStyle(color: Colors.black54, fontSize: 15)),
                ),
                const SizedBox(height: 10),
                const Text('© 2026 Alejandro Guillermo Enríquez Rodríguez\nTodos los derechos reservados.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.black38, fontSize: 11)),
              ]),
            ),
          ]),
        ),
      );
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFE8F5EC), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: kGreen),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: kDark, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );
}

// ───────── LOGIN / REGISTRO ─────────
class AuthPage extends StatefulWidget {
  final bool register;
  const AuthPage({super.key, required this.register});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late bool _reg = widget.register;
  bool _hide = true;
  final _name = TextEditingController();
  final _mail = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _mail.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    if (_mail.text.trim().isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe tu correo y contraseña')));
      return;
    }
    final n = _name.text.trim();
    user.value = n.isNotEmpty ? n : _mail.text.trim().split('@').first;
    _toShell(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: kDark),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(padding: const EdgeInsets.all(24), children: [
              const Center(child: HeroMark(size: 130, dark: false)),
              const SizedBox(height: 12),
              Text(_reg ? 'Crea tu cuenta' : 'Iniciar sesión',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kDark)),
              const SizedBox(height: 4),
              Text(_reg ? 'Solo te tomará un minuto.' : 'Qué gusto verte de nuevo.',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),
              if (_reg) ...[
                _field(_name, 'Nombre', Icons.person_outline),
                const SizedBox(height: 14),
              ],
              _field(_mail, 'Correo electrónico', Icons.mail_outline, type: TextInputType.emailAddress),
              const SizedBox(height: 14),
              TextField(
                controller: _pass,
                obscureText: _hide,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              if (!_reg)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () {}, child: const Text('¿Olvidaste tu contraseña?')),
                ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kGreen, padding: const EdgeInsets.all(16)),
                onPressed: _submit,
                child: Text(_reg ? 'Registrarme' : 'Ingresar', style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _reg = !_reg),
                child: Text(_reg ? 'Ya tengo cuenta · Inicia sesión' : 'No tengo cuenta · ¡Regístrate!'),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => _toShell(context),
                  child: const Text('Omitir por ahora', style: TextStyle(color: Colors.black54)),
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _field(TextEditingController c, String label, IconData i, {TextInputType? type}) => TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(i),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}

// ───────── SHELL (navegación principal) ─────────
class Shell extends StatelessWidget {
  const Shell({super.key});
  static const _titles = ['ECORECOLECTA', 'Buscar ruta', 'Horarios', 'Reportar', 'Ajustes'];
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: tab,
        builder: (_, i, __) => Scaffold(
          appBar: AppBar(
            backgroundColor: kDark,
            foregroundColor: Colors.white,
            title: Row(children: [
              if (i == 0) const Icon(Icons.recycling, color: kLime),
              if (i == 0) const SizedBox(width: 8),
              Text(_titles[i]),
            ]),
          ),
          body: IndexedStack(index: i, children: const [
            LivePage(),
            RutasPage(),
            SchedulePage(),
            ReportPage(),
            SettingsPage(),
          ]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: i,
            onDestinationSelected: (v) => tab.value = v,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
              NavigationDestination(icon: Icon(Icons.alt_route), label: 'Rutas'),
              NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Horarios'),
              NavigationDestination(icon: Icon(Icons.add_a_photo_outlined), selectedIcon: Icon(Icons.add_a_photo), label: 'Reportar'),
              NavigationDestination(icon: Icon(Icons.tune), label: 'Ajustes'),
            ],
          ),
        ),
      );
}

// ───────── MAPA EN VIVO ─────────
class LivePage extends StatefulWidget {
  const LivePage({super.key});
  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final _mc = MapController();
  final _k = ValueNotifier<int>(0); // solo el camión y la tarjeta se redibujan
  late List<LatLng> _path;
  Timer? _t;

  static List<LatLng> _densify(List<LatLng> p, int n) {
    final out = <LatLng>[];
    for (var i = 0; i < p.length - 1; i++) {
      for (var s = 0; s < n; s++) {
        final f = s / n;
        out.add(LatLng(p[i].latitude + (p[i + 1].latitude - p[i].latitude) * f,
            p[i].longitude + (p[i + 1].longitude - p[i].longitude) * f));
      }
    }
    out.add(p.last);
    return out;
  }

  void _onSel() {
    _k.value = 0;
    setState(() => _path = _densify(rutas[sel.value].base, 8));
    try {
      _mc.move(rutas[sel.value].base[2], 15);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _path = _densify(rutas[sel.value].base, 8);
    sel.addListener(_onSel);
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _k.value = (_k.value + 1) % _path.length;
    });
  }

  @override
  void dispose() {
    sel.removeListener(_onSel);
    _t?.cancel();
    _k.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = rutas[sel.value];
    return Stack(children: [
      FlutterMap(
        mapController: _mc,
        options: MapOptions(initialCenter: r.base[2], initialZoom: 15),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'mx.edu.itoaxaca.ecorecolecta',
          ),
          const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
          PolylineLayer(polylines: [Polyline(points: _path, strokeWidth: 5, color: r.color.withValues(alpha: .75))]),
          MarkerLayer(markers: [
            Marker(point: r.base[4], width: 44, height: 44, child: const Icon(Icons.home_rounded, color: kDark, size: 38)),
          ]),
          ValueListenableBuilder<int>(
            valueListenable: _k,
            builder: (_, k, __) => MarkerLayer(markers: [
              Marker(
                point: _path[k],
                width: 52,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(color: r.color, shape: BoxShape.circle, boxShadow: const [
                    BoxShadow(blurRadius: 8, color: Colors.black38),
                  ]),
                  child: const Icon(Icons.local_shipping, color: Colors.white),
                ),
              ),
            ]),
          ),
        ],
      ),
      Positioned(
        top: 12,
        left: 12,
        right: 12,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => tab.value = 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(children: [
                const Icon(Icons.search, color: kGreen),
                const SizedBox(width: 10),
                const Expanded(child: Text('Busca tu ruta o colonia', style: TextStyle(color: Colors.black54))),
                _badge(r.code, r.color),
              ]),
            ),
          ),
        ),
      ),
      Positioned(
        left: 12,
        right: 12,
        bottom: 34,
        child: ValueListenableBuilder<int>(
          valueListenable: _k,
          builder: (_, k, __) {
            final left = 4 * 8 - k;
            final eta = left <= 0 ? 0 : (left / 4).ceil();
            return Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const CircleAvatar(backgroundColor: kLime, child: Icon(Icons.timer, color: kDark)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(eta == 0 ? '¡El camión está en tu calle!' : 'Llega a tu calle en ~$eta min',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${r.nombre} · ${r.dias}', style: const TextStyle(color: Colors.black54)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(r.colonias),
                  const SizedBox(height: 8),
                  const Chip(label: Text('Datos simulados · demo')),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

Widget _badge(String code, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
      child: Text(code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );

// ───────── BUSCAR RUTA ─────────
class RutasPage extends StatefulWidget {
  const RutasPage({super.key});
  @override
  State<RutasPage> createState() => _RutasPageState();
}

class _RutasPageState extends State<RutasPage> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final list = rutas
        .where((r) => '${r.code} ${r.nombre} ${r.colonias}'.toLowerCase().contains(q))
        .toList();
    return ValueListenableBuilder<int>(
      valueListenable: sel,
      builder: (_, s, __) => ListView(padding: const EdgeInsets.all(14), children: [
        TextField(
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(
            hintText: 'Busca por colonia, calle o ruta',
            prefixIcon: const Icon(Icons.search, color: kGreen),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: Text('No encontramos esa ruta 😕', style: TextStyle(color: Colors.black54))),
          ),
        for (final r in list)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: _badge(r.code, r.color),
              title: Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${r.colonias}\n${r.dias} · ${r.hora} a.m.'),
              ),
              isThreeLine: true,
              trailing: rutas.indexOf(r) == s
                  ? const Icon(Icons.check_circle, color: kGreen)
                  : const Icon(Icons.chevron_right),
              onTap: () {
                sel.value = rutas.indexOf(r);
                tab.value = 0;
              },
            ),
          ),
      ]),
    );
  }
}

// ───────── HORARIOS ─────────
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});
  static const _rows = [
    ('Lunes', 'Orgánico', '7:30 – 9:00', Icons.eco, Color(0xFF2E9E5B)),
    ('Martes', 'Inorgánico', '7:30 – 9:00', Icons.inventory_2, Color(0xFF3B82C4)),
    ('Miércoles', 'Orgánico', '7:30 – 9:00', Icons.eco, Color(0xFF2E9E5B)),
    ('Jueves', 'Inorgánico', '7:30 – 9:00', Icons.inventory_2, Color(0xFF3B82C4)),
    ('Viernes', 'Orgánico', '7:30 – 9:00', Icons.eco, Color(0xFF2E9E5B)),
    ('Sábado', 'Especial / reciclables', '8:00 – 10:00', Icons.recycling, Color(0xFFE08A1E)),
  ];
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 10),
          child: Text('Tu calendario de recolección', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        for (final r in _rows)
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: r.$5.withValues(alpha: .15), child: Icon(r.$4, color: r.$5)),
              title: Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(r.$2),
              trailing: Text(r.$3, style: const TextStyle(color: Colors.black54)),
            ),
          ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Horarios de ejemplo. Se reemplazarán con los datos reales del municipio.',
              style: TextStyle(color: Colors.black45, fontSize: 12)),
        ),
      ]);
}

// ───────── REPORTAR ─────────
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _tipo = 'Basura acumulada';
  bool _consent = false;
  final _desc = TextEditingController();

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Reportar un problema', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _tipo,
          decoration: InputDecoration(
              labelText: 'Tipo de reporte',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          items: const ['Basura acumulada', 'Camión no pasó', 'Tiradero clandestino', 'Contenedor desbordado']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _tipo = v!),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {},
          child: Container(
            height: 130,
            decoration: BoxDecoration(
                border: Border.all(color: kGreen, width: 1.5), borderRadius: BorderRadius.circular(16), color: Colors.white),
            child: const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_a_photo, size: 36, color: kGreen),
                SizedBox(height: 6),
                Text('Agregar foto'),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _desc,
          maxLines: 3,
          decoration: InputDecoration(
              labelText: 'Descripción (opcional)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFFE8F5EC),
          child: CheckboxListTile(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Acepto compartir mi ubicación SOLO para este reporte'),
            subtitle: const Text('No te rastreamos en segundo plano. Se captura una vez, al enviar.'),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: kGreen, padding: const EdgeInsets.all(16)),
          onPressed: _consent
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Gracias! Reporte enviado (demo).')));
                  setState(() {
                    _consent = false;
                    _desc.clear();
                  });
                }
              : null,
          icon: const Icon(Icons.send),
          label: const Text('Enviar reporte'),
        ),
      ]);
}

// ───────── AJUSTES ─────────
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notif = true;
  int _min = 10;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
        ValueListenableBuilder<String?>(
          valueListenable: user,
          builder: (_, u, __) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: const CircleAvatar(backgroundColor: kLime, child: Icon(Icons.person, color: kDark)),
              title: Text(u ?? 'Invitado', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(u == null ? 'Inicia sesión para guardar tus reportes' : 'Sesión iniciada'),
              trailing: TextButton(
                onPressed: () => _toWelcome(context),
                child: Text(u == null ? 'Entrar' : 'Salir'),
              ),
            ),
          ),
        ),
        Card(
          child: Column(children: [
            SwitchListTile(
              value: _notif,
              onChanged: (v) => setState(() => _notif = v),
              title: const Text('Avisarme cuando el camión se acerque'),
              secondary: const Icon(Icons.notifications_active, color: kGreen),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined, color: kGreen),
              title: const Text('Anticipación del aviso'),
              trailing: DropdownButton<int>(
                value: _min,
                underline: const SizedBox(),
                items: const [5, 10, 15, 20].map((e) => DropdownMenuItem(value: e, child: Text('$e min'))).toList(),
                onChanged: _notif ? (v) => setState(() => _min = v!) : null,
              ),
            ),
            const ListTile(
              leading: Icon(Icons.home_work_outlined, color: kGreen),
              title: Text('Mi domicilio'),
              subtitle: Text('Colonia y calle (sin GPS continuo)'),
              trailing: Icon(Icons.chevron_right),
            ),
          ]),
        ),
        const Card(
          color: Color(0xFFE8F5EC),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.shield, color: kGreen),
                SizedBox(width: 8),
                Text('Tu privacidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              SizedBox(height: 8),
              Text('• Tu ubicación se pide solo al enviar un reporte, con tu permiso.'),
              Text('• Toda la comunicación viaja cifrada (HTTPS / TLS).'),
              Text('• Tu contraseña nunca se guarda en texto plano.'),
              Text('• Puedes borrar tus reportes y tu cuenta cuando quieras.'),
            ]),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.admin_panel_settings, color: kDark),
            title: Text('Panel del ayuntamiento'),
            subtitle: Text('Próximamente: mapa de calor y rutas optimizadas'),
          ),
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('ECORECOLECTA v0.3 · Prototipo · ITO\n© 2026 Alejandro Guillermo Enríquez Rodríguez · Todos los derechos reservados\nMapa © OpenStreetMap contributors', textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 12)),
          ),
        ),
      ]);
}
