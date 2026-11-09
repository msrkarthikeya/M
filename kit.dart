import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const ease = Cubic(.2, .8, .2, 1);
const mut = Color(0x80FFFFFF);
const line = Color(0x1FFFFFFF);
const glass = Color(0x0EFFFFFF);
const kIntro = 1900;
final lite = ValueNotifier<bool>(false);

/// Fade + rise + blur-in, after a delay.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.ms = 0, this.dy = 22, this.blur = 10});
  final Widget child;
  final int ms;
  final double dy, blur;
  @override
  State<Reveal> createState() => _RevealS();
}

class _RevealS extends State<Reveal> {
  bool on = false;
  Timer? t;
  @override
  void initState() {
    super.initState();
    t = Timer(Duration(milliseconds: widget.ms), () {
      if (mounted) setState(() => on = true);
    });
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: on ? 1 : 0),
        duration: const Duration(milliseconds: 900),
        curve: ease,
        child: widget.child,
        builder: (_, v, ch) {
          final b = lite.value ? 0.0 : (1 - v) * widget.blur;
          final w = Opacity(
              opacity: v.clamp(0.0, 1.0).toDouble(),
              child: Transform.translate(offset: Offset(0, (1 - v) * widget.dy), child: ch));
          return b > .2 ? ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: b, sigmaY: b), child: w) : w;
        },
      );
}

/// Press-scale + haptic.
class Tap extends StatefulWidget {
  const Tap({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<Tap> createState() => _TapS();
}

class _TapS extends State<Tap> {
  bool d = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => d = true),
        onTapUp: (_) => setState(() => d = false),
        onTapCancel: () => setState(() => d = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(scale: d ? .93 : 1, duration: const Duration(milliseconds: 180), curve: ease, child: widget.child),
      );
}

/// White text with a light sweep.
class Shimmer extends StatefulWidget {
  const Shimmer(this.text, this.style, {super.key});
  final String text;
  final TextStyle style;
  @override
  State<Shimmer> createState() => _ShimmerS();
}

class _ShimmerS extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, __) {
          final x = -3 + 6 * c.value;
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x + 1, 0),
              colors: const [Colors.white, Color(0xFF6B6B6B), Colors.white],
              stops: const [.3, .5, .7],
            ).createShader(r),
            child: Text(widget.text, style: widget.style.copyWith(color: Colors.white)),
          );
        },
      );
}

/// Drifting particle network background.
class Net extends StatefulWidget {
  const Net({super.key});
  @override
  State<Net> createState() => _NetS();
}

class _NetS extends State<Net> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  final r = Random();
  late final List<List<double>> p = List.generate(
      34, (_) => [r.nextDouble(), r.nextDouble(), (r.nextDouble() - .5) * .0005, (r.nextDouble() - .5) * .0003]);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: lite,
        builder: (_, l, __) => l
            ? const SizedBox.expand()
            : RepaintBoundary(child: CustomPaint(painter: _NetP(p, c), child: const SizedBox.expand())),
      );
}

class _NetP extends CustomPainter {
  _NetP(this.p, Listenable l) : super(repaint: l);
  final List<List<double>> p;
  @override
  void paint(Canvas cv, Size s) {
    final dot = Paint()..color = const Color(0x66FFFFFF);
    final ln = Paint()..strokeWidth = .7;
    final pts = <Offset>[];
    for (final q in p) {
      q[0] += q[2];
      q[1] += q[3];
      if (q[0] < 0 || q[0] > 1) q[2] *= -1;
      if (q[1] < 0 || q[1] > 1) q[3] *= -1;
      final o = Offset(q[0] * s.width, q[1] * s.height);
      pts.add(o);
      cv.drawCircle(o, 1.2, dot);
    }
    for (var i = 0; i < pts.length; i++) {
      for (var j = i + 1; j < pts.length; j++) {
        final d = (pts[i] - pts[j]).distance;
        if (d < 110) {
          ln.color = Color.fromRGBO(255, 255, 255, (1 - d / 110) * .16);
          cv.drawLine(pts[i], pts[j], ln);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

/// Credit ring with count tween.
class Ring extends StatelessWidget {
  const Ring({super.key, required this.credits, required this.limit});
  final int credits, limit;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(end: credits.toDouble()),
        duration: const Duration(milliseconds: 800),
        curve: ease,
        builder: (_, v, __) => SizedBox(
          width: 46,
          height: 46,
          child: CustomPaint(
              painter: _RingP(v / limit),
              child: Center(child: Text('${v.round()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
        ),
      );
}

class _RingP extends CustomPainter {
  _RingP(this.f);
  final double f;
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromCircle(center: s.center(Offset.zero), radius: s.width / 2 - 4);
    Paint st(double w, Color col) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = col;
    final sweep = 2 * pi * min(1.0, max(0.0, f));
    c.drawArc(r, 0, 2 * pi, false, st(3, line));
    c.drawArc(r, -pi / 2, sweep, false, st(6, const Color(0x55FFFFFF))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.drawArc(r, -pi / 2, sweep, false, st(3, Colors.white));
  }

  @override
  bool shouldRepaint(_RingP o) => o.f != f;
}

/// Model avatar; spins while the model is working.
class Av extends StatelessWidget {
  const Av(this.l, {super.key, this.dark = false, this.spin = false, this.size = 28});
  final String l;
  final bool dark, spin;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          if (spin)
            const Positioned.fill(
                left: -5, top: -5, right: -5, bottom: -5,
                child: CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dark ? Colors.black : Colors.white,
                boxShadow: spin ? const [BoxShadow(color: Color(0x80FFFFFF), blurRadius: 16)] : null),
            child: Text(l, style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.w700, fontSize: size * .46)),
          ),
        ]),
      );
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.radius = 26});
  final Widget child;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: glass, borderRadius: BorderRadius.circular(radius), border: Border.all(color: line)),
        child: child,
      );
}

/// Panel with a rotating light around its border (winner / judge button).
class GlowBox extends StatefulWidget {
  const GlowBox({super.key, required this.child, this.radius = 26});
  final Widget child;
  final double radius;
  @override
  State<GlowBox> createState() => _GlowS();
}

class _GlowS extends State<GlowBox> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, ch) => Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: SweepGradient(
                transform: GradientRotation(c.value * 2 * pi),
                colors: const [Color(0x1AFFFFFF), Color(0x1AFFFFFF), Colors.white, Color(0x1AFFFFFF)],
                stops: const [0, .55, .78, 1]),
            boxShadow: const [BoxShadow(color: Color(0x1FFFFFFF), blurRadius: 40)],
          ),
          child: Container(
              decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(widget.radius - 1.5)),
              child: ch),
        ),
        child: widget.child,
      );
}

/// One-shot expanding ring (celebration).
class Pulse extends StatelessWidget {
  const Pulse({super.key, this.radius = 26});
  final double radius;
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOut,
          builder: (_, v, __) => Opacity(
            opacity: 1 - v,
            child: Transform.scale(
                scale: 1 + .07 * v,
                child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), border: Border.all(color: Colors.white, width: 2)))),
          ),
        ),
      );
}

class Skel extends StatefulWidget {
  const Skel({super.key});
  @override
  State<Skel> createState() => _SkelS();
}

class _SkelS extends State<Skel> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: .35, end: 1).animate(c),
        child: Column(children: [
          for (final f in [1.0, .86, .62])
            Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                    widthFactor: f,
                    child: Container(height: 11, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: const Color(0x24FFFFFF), borderRadius: BorderRadius.circular(6))))),
        ]),
      );
}

class Btn extends StatelessWidget {
  const Btn(this.t, this.primary, this.on, {super.key});
  final String t;
  final bool primary;
  final VoidCallback on;
  @override
  Widget build(BuildContext context) => Tap(
        onTap: on,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          decoration: BoxDecoration(
              color: primary ? Colors.white : glass,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: primary ? Colors.white : line),
              boxShadow: primary ? const [BoxShadow(color: Color(0x4DFFFFFF), blurRadius: 32)] : null),
          child: Text(t, style: TextStyle(color: primary ? Colors.black : Colors.white, fontWeight: primary ? FontWeight.w600 : FontWeight.w500, fontSize: 15)),
        ),
      );
}
