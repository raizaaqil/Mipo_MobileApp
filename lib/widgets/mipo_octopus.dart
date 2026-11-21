import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Suasana hati Mipo. `calm` = tampilan bawaan (ceria biasa).
/// happy = senang sekali, worried = cemas, panic = panik.
enum PetMood { happy, calm, worried, panic }

/// Karakter Mipo: gurita biru 2D yang digambar lewat kode (tanpa file gambar).
///
/// - Tentakel bergerak bergelombang seperti di dalam air
/// - Wajah ceria + satu tentakel melambai ("welcome")
/// - Mata berkedip sendiri dan mengikuti kursor / jari
/// - Diketuk -> melompat kecil, mata jadi "^ ^", gelombang tentakel menguat
///
/// Pakai: `MipoOctopus(size: 150)`
class MipoOctopus extends StatefulWidget {
  const MipoOctopus({
    super.key,
    this.size = 150,
    this.interactive = true,
    this.waveHello = true,
    this.mood = PetMood.calm,
  });

  /// Lebar karakter. Tingginya otomatis 1.15 x lebar.
  final double size;

  /// Kalau false, tidak ada reaksi sentuh dan mata tidak mengikuti kursor.
  final bool interactive;

  /// Satu tentakel di sisi kanan melambai menyapa.
  final bool waveHello;

  /// Ekspresi wajah. Bawaan: calm (sama seperti sebelumnya).
  final PetMood mood;

  @override
  State<MipoOctopus> createState() => _MipoOctopusState();
}

class _MipoOctopusState extends State<MipoOctopus>
    with TickerProviderStateMixin {
  // Satu putaran = 6 detik. Semua gerakan memakai kelipatan bulat dari
  // putaran ini, jadi loop-nya mulus tanpa loncatan.
  late final AnimationController _loop;
  // Reaksi saat diketuk.
  late final AnimationController _react;

  Offset _lookTarget = Offset.zero;
  Offset _lookNow = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _react = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _loop.addListener(() {
      // Gerakkan arah pandang pelan-pelan menuju target (halus).
      _lookNow = Offset.lerp(_lookNow, _lookTarget, 0.14)!;
    });
  }

  @override
  void dispose() {
    _loop.dispose();
    _react.dispose();
    super.dispose();
  }

  double get _height => widget.size * 1.15;

  void _updateLook(Offset local) {
    if (!widget.interactive) return;
    final dx = (local.dx / widget.size) * 2 - 1;
    final dy = (local.dy / _height) * 2 - 1;
    _lookTarget = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
  }

  void _poke() {
    if (!widget.interactive) return;
    _react.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final painter = _OctopusPainter(
      loop: _loop,
      react: _react,
      look: () => _lookNow,
      waveHello: widget.waveHello,
      mood: widget.mood,
    );

    Widget body = SizedBox(
      width: widget.size,
      height: _height,
      child: RepaintBoundary(
        child: CustomPaint(painter: painter),
      ),
    );

    if (widget.interactive) {
      body = MouseRegion(
        cursor: SystemMouseCursors.click,
        onExit: (_) => _lookTarget = Offset.zero,
        child: Listener(
          onPointerHover: (e) => _updateLook(e.localPosition),
          onPointerMove: (e) => _updateLook(e.localPosition),
          onPointerUp: (_) => _lookTarget = Offset.zero,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _poke,
            child: body,
          ),
        ),
      );
    }

    return Semantics(label: 'Mipo, gurita biru yang ceria', child: body);
  }
}

class _OctopusPainter extends CustomPainter {
  _OctopusPainter({
    required this.loop,
    required this.react,
    required this.look,
    required this.waveHello,
    required this.mood,
  }) : super(repaint: Listenable.merge([loop, react]));

  final Animation<double> loop;
  final Animation<double> react;
  final Offset Function() look;
  final bool waveHello;
  final PetMood mood;

  // Palet biru.
  static const _blue = Color(0xFF5B9FE3);
  static const _blueLight = Color(0xFF8CC4F5);
  static const _blueDark = Color(0xFF3F7FC4);
  static const _ink = Color(0xFF2B3A55);
  static const _cheek = Color(0xFFFF9EB5);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = loop.value; // 0..1 per 6 detik
    final phase = t * math.pi * 2 * 3; // gelombang tiap 2 detik

    // Reaksi ketukan: r 0..1, pulse naik-turun dengan sin.
    final r = react.value;
    final pulse = (react.isAnimating || r > 0) ? math.sin(math.pi * r) : 0.0;
    final happy = pulse > 0.25 ? 1.0 : 0.0;

    // Badan naik-turun pelan + lompat kecil saat diketuk.
    final bob = math.sin(phase) * 0.012 * h - pulse * 0.07 * h;

    final headCx = w * 0.5;
    final headCy = h * 0.37 + bob;
    final rx = w * 0.34;
    final ry = h * 0.30;
    final bottomY = headCy + h * 0.24;

    // Bayangan lembut di "dasar air".
    final shadowScale = 1 - pulse * 0.15;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.97),
        width: w * 0.55 * shadowScale,
        height: h * 0.04,
      ),
      Paint()..color = _blueDark.withOpacity(0.14),
    );

    // ---------------------------------------------------- Tentakel
    final boost = 1 + 1.3 * pulse;
    // Urutan gambar: tepi dulu, tengah belakangan (kesan kedalaman).
    const order = [0, 7, 1, 6, 2, 5, 3, 4];
    for (final i in order) {
      _drawTentacle(canvas, w, h, i, headCx, bottomY, phase, boost);
    }

    // ---------------------------------------------------- Kepala
    final head = Path()
      ..moveTo(headCx - rx + w * 0.02, bottomY)
      ..cubicTo(
        headCx - rx - w * 0.04, headCy - h * 0.05,
        headCx - rx * 0.75, headCy - ry,
        headCx, headCy - ry,
      )
      ..cubicTo(
        headCx + rx * 0.75, headCy - ry,
        headCx + rx + w * 0.04, headCy - h * 0.05,
        headCx + rx - w * 0.02, bottomY,
      )
      ..quadraticBezierTo(
        headCx, bottomY + h * 0.05,
        headCx - rx + w * 0.02, bottomY,
      )
      ..close();

    final headRect = Rect.fromCenter(
      center: Offset(headCx, headCy),
      width: rx * 2.2,
      height: ry * 2.2,
    );
    canvas.drawPath(
      head,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.55),
          radius: 1.05,
          colors: [_blueLight, _blue, _blueDark],
          stops: [0.0, 0.55, 1.0],
        ).createShader(headRect),
    );

    // Bintik-bintik di kepala.
    final spot = Paint()..color = Colors.white.withOpacity(0.18);
    canvas.drawCircle(Offset(headCx + w * 0.12, headCy - h * 0.17), w * 0.035, spot);
    canvas.drawCircle(Offset(headCx + w * 0.2, headCy - h * 0.1), w * 0.022, spot);
    canvas.drawCircle(Offset(headCx + w * 0.04, headCy - h * 0.22), w * 0.018, spot);

    // Kilau cahaya di kiri atas.
    canvas.save();
    canvas.translate(headCx - w * 0.17, headCy - h * 0.15);
    canvas.rotate(-0.55);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.13, height: w * 0.06),
      Paint()..color = Colors.white.withOpacity(0.5),
    );
    canvas.restore();

    // ---------------------------------------------------- Wajah
    _drawFace(canvas, w, h, headCx, headCy, t, happy, pulse);
  }

  // ------------------------------------------------------------ Tentakel
  void _drawTentacle(
    Canvas canvas,
    double w,
    double h,
    int i,
    double headCx,
    double bottomY,
    double phase,
    double boost,
  ) {
    final spread = (i / 7) * 2 - 1; // -1 (kiri) .. 1 (kanan)
    final isArm = waveHello && i == 7;

    final rootX = headCx + spread * w * (isArm ? 0.25 : 0.26);
    final rootY = bottomY - h * 0.015 + math.sin(math.pi * (i / 7)) * h * 0.02;

    // Panjang: tengah lebih panjang dari tepi.
    var length = h * (0.36 - spread.abs() * 0.07);
    // Sudut dari arah lurus ke bawah. Positif = ke kanan.
    var angle = spread * 0.38;

    if (isArm) {
      // Melambai ke kanan-atas.
      length = h * 0.23;
      angle = 1.55 + math.sin(phase * 1.4) * 0.38;
    }

    const n = 22;
    final pts = <Offset>[];
    for (var k = 0; k <= n; k++) {
      final s = k / n;
      final along = length * s;
      final bx = rootX + math.sin(angle) * along + spread * w * 0.05 * s * s;
      final by = rootY + math.cos(angle) * along;

      final wavePhase = phase - s * 3.4 + i * 0.85;
      final amp = (w * 0.012 + w * 0.055 * s) * (isArm ? 0.8 : boost);
      final wob = math.sin(wavePhase) * amp * s;
      final lift = math.cos(wavePhase) * w * 0.012 * s;

      // Gelombang dibuat tegak lurus arah tentakel.
      pts.add(Offset(
        bx + wob * math.cos(angle),
        by - wob * math.sin(angle) + lift,
      ));
    }

    // Lebar mengecil dari pangkal ke ujung.
    double widthAt(double s) =>
        w * 0.078 * math.pow(1 - s, 0.75).toDouble() + w * 0.009;

    final left = <Offset>[];
    final right = <Offset>[];
    for (var k = 0; k <= n; k++) {
      final p = pts[k];
      final prev = pts[math.max(k - 1, 0)];
      final next = pts[math.min(k + 1, n)];
      final tan = next - prev;
      final len = tan.distance == 0 ? 1.0 : tan.distance;
      final nx = -tan.dy / len;
      final ny = tan.dx / len;
      final half = widthAt(k / n) / 2;
      left.add(Offset(p.dx + nx * half, p.dy + ny * half));
      right.add(Offset(p.dx - nx * half, p.dy - ny * half));
    }

    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (var k = 1; k <= n; k++) {
      path.lineTo(left[k].dx, left[k].dy);
    }
    // Ujung membulat.
    final tipR = widthAt(1.0) / 2;
    path.arcToPoint(
      right.last,
      radius: Radius.circular(tipR),
      clockwise: false,
    );
    for (var k = n; k >= 0; k--) {
      path.lineTo(right[k].dx, right[k].dy);
    }
    path.close();

    // Tentakel tengah sedikit lebih terang.
    final tone = 1 - spread.abs();
    final color = Color.lerp(_blueDark, _blue, 0.45 + tone * 0.55)!;
    canvas.drawPath(path, Paint()..color = color);

    // Garis kilau tipis di sepanjang tentakel.
    final shine = Path()..moveTo(pts[2].dx, pts[2].dy);
    for (var k = 3; k <= n - 5; k++) {
      shine.lineTo(pts[k].dx, pts[k].dy);
    }
    canvas.drawPath(
      shine,
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012
        ..strokeCap = StrokeCap.round,
    );

    // Bulatan penghisap kecil.
    final cup = Paint()..color = _blueLight.withOpacity(0.7);
    for (var k = 7; k <= n - 4; k += 3) {
      final s = k / n;
      canvas.drawCircle(pts[k], widthAt(s) * 0.17, cup);
    }
  }

  // ---------------------------------------------------------------- Wajah
  void _drawFace(Canvas canvas, double w, double h, double cx, double cy,
      double t, double happy, double pulse) {
    final lk = look();
    final eyeY = cy + h * 0.03;
    final eyeDx = w * 0.155;

    // Kedip: dua kali tiap 6 detik.
    double blinkAt(double c) {
      final d = (t - c).abs();
      return d < 0.014 ? 1 - d / 0.014 : 0.0;
    }

    final blink = math.max(blinkAt(0.26), blinkAt(0.73));

    // Pipi merona.
    final isHappyMood = mood == PetMood.happy;
    final sad = mood == PetMood.worried || mood == PetMood.panic;
    // Saat senang, ekspresi dibuat lebih lebar (seperti baru diketuk).
    final lively = isHappyMood ? math.max(pulse, 0.55) : pulse;
    final cheek = Paint()
      ..color = _cheek.withOpacity(sad ? 0.22 : 0.55 + lively * 0.25);
    for (final sx in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + sx * (eyeDx + w * 0.05), eyeY + h * 0.095),
          width: w * 0.1,
          height: w * 0.06,
        ),
        cheek,
      );
    }

    // Alis terangkat (ramah). Naik lebih tinggi saat senang.
    final brow = Paint()
      ..color = _ink.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014
      ..strokeCap = StrokeCap.round;
    final browLift = h * (0.012 + 0.01 * lively);
    // Cemas: ujung alis sebelah dalam naik. Panik: lebih miring lagi.
    final tilt = mood == PetMood.panic ? 1.7 : (mood == PetMood.worried ? 1.0 : 0.0);
    for (final sx in [-1.0, 1.0]) {
      final bx = cx + sx * eyeDx;
      final by = eyeY - h * 0.105 - browLift;
      final p = Path()
        ..moveTo(bx + sx * w * 0.04, by + h * 0.012 + tilt * h * 0.012)
        ..quadraticBezierTo(
          bx,
          by - h * 0.014 + tilt * h * 0.012,
          bx - sx * w * 0.04,
          by + h * 0.012 - tilt * h * 0.024,
        );
      canvas.drawPath(p, brow);
    }

    // Mata.
    for (final sx in [-1.0, 1.0]) {
      final ex = cx + sx * eyeDx;
      if (happy > 0.5 || isHappyMood) {
        // Mata "^ ^" saat senang.
        final arc = Path()
          ..moveTo(ex - w * 0.05, eyeY + h * 0.012)
          ..quadraticBezierTo(ex, eyeY - h * 0.05, ex + w * 0.05, eyeY + h * 0.012);
        canvas.drawPath(
          arc,
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.022
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }

      final open = 1 - blink * 0.92;
      final big = mood == PetMood.panic ? 1.18 : 1.0; // panik: mata melebar
      final eyeW = w * 0.092 * big;
      final eyeH = w * 0.112 * open * big;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, eyeY), width: eyeW, height: eyeH),
        Paint()..color = Colors.white,
      );
      if (open > 0.25) {
        final pupilC = Offset(ex + lk.dx * w * 0.02, eyeY + lk.dy * w * 0.02);
        canvas.drawOval(
          Rect.fromCenter(
            center: pupilC,
            width: w * 0.062 * (mood == PetMood.panic ? 0.8 : 1.0),
            height: w * 0.074 * open,
          ),
          Paint()..color = _ink,
        );
        // Kilau mata.
        canvas.drawCircle(
          pupilC + Offset(-w * 0.014, -w * 0.016 * open),
          w * 0.014,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          pupilC + Offset(w * 0.012, w * 0.014 * open),
          w * 0.007,
          Paint()..color = Colors.white.withOpacity(0.85),
        );
      }
    }

    final my = cy + h * 0.145;

    if (mood == PetMood.worried) {
      // Bibir melengkung ke bawah (cemas).
      canvas.drawPath(
        Path()
          ..moveTo(cx - w * 0.05, my + h * 0.028)
          ..quadraticBezierTo(cx, my - h * 0.004, cx + w * 0.05, my + h * 0.028),
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.02
          ..strokeCap = StrokeCap.round,
      );
    } else if (mood == PetMood.panic) {
      // Mulut kecil terbuka "o" (panik).
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, my + h * 0.03),
          width: w * 0.06,
          height: h * 0.062,
        ),
        Paint()..color = _ink,
      );
    } else {
      // Mulut: senyum lebar terbuka, makin besar saat senang.
      final mw = w * (0.062 + 0.022 * lively);
      final mh = h * (0.052 + 0.035 * lively);
      final mouth = Path()
        ..moveTo(cx - mw, my)
        ..quadraticBezierTo(cx, my + h * 0.012, cx + mw, my)
        ..quadraticBezierTo(cx + mw * 0.75, my + mh * 1.5, cx, my + mh * 1.5)
        ..quadraticBezierTo(cx - mw * 0.75, my + mh * 1.5, cx - mw, my)
        ..close();
      canvas.drawPath(mouth, Paint()..color = _ink);

      canvas.save();
      canvas.clipPath(mouth);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, my + mh * 1.45),
          width: mw * 1.3,
          height: mh * 1.0,
        ),
        Paint()..color = const Color(0xFFFF8FA8),
      );
      canvas.restore();
    }

    // Tetes keringat dingin saat cemas / panik (turun pelan, berulang tiap 2 detik).
    if (sad) {
      final ph = (t * 3) % 1.0;
      final a = math.sin(math.pi * ph);
      final r = w * 0.022;
      final dx = cx + w * 0.27;
      final dy = cy - h * 0.12 + ph * h * 0.07;
      final drop = Path()
        ..moveTo(dx, dy - r * 2.2)
        ..quadraticBezierTo(dx + r * 1.3, dy - r * 0.1, dx, dy + r)
        ..quadraticBezierTo(dx - r * 1.3, dy - r * 0.1, dx, dy - r * 2.2)
        ..close();
      canvas.drawPath(
        drop,
        Paint()..color = const Color(0xFFDDF0FF).withOpacity(0.95 * a),
      );
      canvas.drawPath(
        drop,
        Paint()
          ..color = _blueDark.withOpacity(0.5 * a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.006,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OctopusPainter old) =>
      old.waveHello != waveHello || old.mood != mood;
}
