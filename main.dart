import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api.dart';
import 'chat.dart';
import 'kit.dart';

final tab = ValueNotifier<int>(1);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.black));
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AI Hub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(primary: Colors.white, surface: Colors.black),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: Colors.white, contentTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
        ),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellS();
}

class _ShellS extends State<Shell> {
  bool intro = true;
  final seen = <int>{1};
  @override
  void initState() {
    super.initState();
    tab.addListener(() => setState(() => seen.add(tab.value)));
    Future.delayed(const Duration(milliseconds: kIntro), () {
      if (mounted) setState(() => intro = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom > 0;
    final pages = <Widget>[const FeaturesPage(), const HomePage(), const ChatPage()];
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: Net()),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 14, 4),
              child: Row(children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => tab.value = 1,
                      onLongPress: () {
                        lite.value = !lite.value;
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lite effects ${lite.value ? 'on' : 'off'}')));
                      },
                      child: const Shimmer('AI Hub', TextStyle(fontSize: 30, fontWeight: FontWeight.w600, letterSpacing: -1.4)),
                    ),
                  ),
                ),
                GestureDetector(onTap: wallet.refill, child: AnimatedBuilder(animation: wallet, builder: (_, __) => Ring(credits: wallet.credits, limit: Wallet.limit))),
              ]),
            ),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: tab,
                builder: (_, t, __) => Stack(fit: StackFit.expand, children: [
                  for (var i = 0; i < 3; i++)
                    IgnorePointer(
                      ignoring: t != i,
                      child: AnimatedOpacity(
                        opacity: t == i ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: AnimatedSlide(offset: t == i ? Offset.zero : const Offset(0, .03), duration: const Duration(milliseconds: 550), curve: ease, child: seen.contains(i) ? pages[i] : const SizedBox.shrink()),
                      ),
                    ),
                ]),
              ),
            ),
            if (!kb) const TabBarX(),
          ]),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !intro,
            child: AnimatedOpacity(
              opacity: intro ? 1 : 0,
              duration: const Duration(milliseconds: 700),
              child: AnimatedScale(scale: intro ? 1 : 1.1, duration: const Duration(milliseconds: 1000), curve: Curves.easeInOutCubic, child: const Intro()),
            ),
          ),
        ),
      ]),
    );
  }
}

class Intro extends StatelessWidget {
  const Intro({super.key});
  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 6; i++) Reveal(ms: i * 80, dy: 26, blur: 14, child: Text('AI Hub'[i] == ' ' ? '\u00a0' : 'AI Hub'[i], style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w600, letterSpacing: -3))),
          ]),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: 120,
              height: 2,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1500),
                curve: ease,
                builder: (_, v, __) => Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: v, child: const ColoredBox(color: Colors.white))),
              ),
            ),
          ),
        ]),
      );
}

class TabBarX extends StatelessWidget {
  const TabBarX({super.key});
  static const ic = [Icons.auto_awesome_rounded, Icons.home_rounded, Icons.chat_bubble_rounded];
  static const lb = ['Features', 'Home', 'Chat'];
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: tab,
        builder: (_, t, __) => Container(
          margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          height: 62,
          decoration: BoxDecoration(color: const Color(0xC7121212), borderRadius: BorderRadius.circular(32), border: Border.all(color: line)),
          child: LayoutBuilder(builder: (_, bx) {
            final w = (bx.maxWidth - 10) / 3;
            return Stack(children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutBack,
                left: 5 + t * w,
                top: 5,
                bottom: 5,
                width: w,
                child: DecoratedBox(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(27), boxShadow: const [BoxShadow(color: Color(0x52FFFFFF), blurRadius: 26)])),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(children: [
                  for (var n = 0; n < 3; n++)
                    Expanded(
                      child: Tap(
                        onTap: () => tab.value = n,
                        child: Center(
                          child: TweenAnimationBuilder<Color?>(
                            tween: ColorTween(end: t == n ? Colors.black : const Color(0x9EFFFFFF)),
                            duration: const Duration(milliseconds: 300),
                            builder: (_, c, __) => Column(mainAxisSize: MainAxisSize.min, children: [
                              AnimatedScale(scale: t == n ? 1.12 : 1, duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack, child: Icon(ic[n], size: 22, color: c)),
                              const SizedBox(height: 3),
                              Text(lb[n], style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: c)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ]);
          }),
        ),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    const b = kIntro;
    final fs = min(60.0, MediaQuery.of(context).size.width * .145);
    const steps = [('Ask', 'Type your question once. Every model gets it at the same time.'), ('Compare', 'Swipe between replies as they stream in, word by word.'), ('Judge', 'A blind judge picks the winner and tells you why.')];
    return ListView(padding: const EdgeInsets.fromLTRB(22, 26, 22, 30), children: [
      Reveal(
        ms: b,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(color: glass, borderRadius: BorderRadius.circular(99), border: Border.all(color: line)),
            child: const Text('5 models. One answer.', style: TextStyle(fontSize: 13.5, color: mut)),
          ),
        ),
      ),
      const SizedBox(height: 22),
      Reveal(ms: b + 150, dy: 40, blur: 14, child: Shimmer('One prompt.\nEvery AI.', TextStyle(fontSize: fs, height: .98, fontWeight: FontWeight.w600, letterSpacing: -fs * .055))),
      const SizedBox(height: 16),
      const Reveal(ms: b + 350, child: Text('Ask once and compare GPT, Claude, Gemini, DeepSeek and Llama side by side. Then let the judge pick the winner.', style: TextStyle(color: mut, fontSize: 16.5, fontWeight: FontWeight.w300, height: 1.55))),
      const SizedBox(height: 26),
      Reveal(ms: b + 500, child: Row(children: [Btn('Try the chat', true, () => tab.value = 2), const SizedBox(width: 10), Btn('See features', false, () => tab.value = 0)])),
      const SizedBox(height: 30),
      const Reveal(ms: b + 650, dy: 30, blur: 16, child: Center(child: Orbit())),
      const SizedBox(height: 30),
      for (var i = 0; i < 3; i++)
        Reveal(
          ms: b + 800 + i * 120,
          dy: 34,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Panel(
              radius: 22,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black, border: Border.all(color: line)), child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(steps[i].$1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -.6)), const SizedBox(height: 4), Text(steps[i].$2, style: const TextStyle(color: mut, fontSize: 14.5, height: 1.5, fontWeight: FontWeight.w300))])),
                ]),
              ),
            ),
          ),
        ),
    ]);
  }
}

/// Glowing core with the five models orbiting it.
class Orbit extends StatefulWidget {
  const Orbit({super.key});
  @override
  State<Orbit> createState() => _OrbitS();
}

class _OrbitS extends State<Orbit> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 280,
        height: 280,
        child: AnimatedBuilder(
          animation: c,
          builder: (_, __) {
            final t = c.value * 2 * pi;
            const radii = [70.0, 95.0, 120.0];
            return Transform.translate(
              offset: Offset(0, sin(t * 2) * 8),
              child: Stack(alignment: Alignment.center, children: [
                for (final r in radii) Container(width: r * 2, height: r * 2, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x14FFFFFF)))),
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(center: Alignment(-.3, -.4), colors: [Colors.white, Color(0x8CFFFFFF), Color(0x1FFFFFFF), Colors.black], stops: [0, .24, .55, .74]),
                    boxShadow: [BoxShadow(color: const Color(0x66FFFFFF), blurRadius: 50 + 25 * (.5 + .5 * sin(t * 4)))],
                  ),
                ),
                for (var i = 0; i < models.length; i++)
                  Transform.translate(
                    offset: Offset(cos(t * (i + 1) * (i.isEven ? 1 : -1) + i * 1.256) * radii[i % 3], sin(t * (i + 1) * (i.isEven ? 1 : -1) + i * 1.256) * radii[i % 3]),
                    child: Av(models[i].name[0], size: 30, spin: false),
                  ),
              ]),
            );
          },
        ),
      );
}

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});
  static const f = [
    (Icons.bolt_rounded, 'Ask once, hear from all', 'Send one prompt to up to four models at the same time and watch every answer stream in.', true),
    (Icons.gavel_rounded, 'Blind best-answer judge', 'A judge reads every reply with the model names hidden, then picks a winner and explains why.', true),
    (Icons.speed_rounded, 'Cost meter', 'See what every prompt costs before you send it. No surprise bills.', true),
    (Icons.merge_type_rounded, 'Merge into one answer', 'Fuse the strongest parts of every reply into a single, cleaner answer.', false),
    (Icons.alt_route_rounded, 'Smart router', 'Easy questions go to a fast, cheap model. Hard ones go to a stronger one. You keep your credits.', false),
    (Icons.psychology_rounded, 'Memory that follows you', 'Your language, level and goals carry across every model and every chat.', false),
    (Icons.tune_rounded, 'Personas and prompts', 'One tap switches the whole app into study, code or writing mode.', false),
    (Icons.description_rounded, 'Chat with documents', 'Upload a PDF and get answers that point to the page they came from.', false),
    (Icons.mic_rounded, 'Voice and vision', 'Talk to the models out loud, or show them a photo and ask what it is.', false),
    (Icons.currency_rupee_rounded, 'Pricing built for India', 'Plans priced for local budgets, paid with UPI through Google Play.', false),
  ];
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 26, 20, 30), children: [
        const Reveal(ms: 150, dy: 36, blur: 14, child: Shimmer('Everything\ninside.', TextStyle(fontSize: 50, height: 1, fontWeight: FontWeight.w600, letterSpacing: -2.6))),
        const SizedBox(height: 14),
        const Reveal(ms: 350, child: Text('Three features work today. Seven more are on the way.', style: TextStyle(color: mut, fontSize: 16.5, fontWeight: FontWeight.w300, height: 1.5))),
        const SizedBox(height: 24),
        for (var i = 0; i < f.length; i++)
          Reveal(
            ms: 450 + i * 80,
            dy: 34,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Panel(
                radius: 26,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: f[i].$4 ? Colors.white : Colors.black, border: Border.all(color: f[i].$4 ? Colors.white : line), boxShadow: f[i].$4 ? const [BoxShadow(color: Color(0x4DFFFFFF), blurRadius: 20)] : null), child: Icon(f[i].$1, size: 22, color: f[i].$4 ? Colors.black : Colors.white)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(f[i].$2, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -.6))),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: f[i].$4 ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(99), border: Border.all(color: f[i].$4 ? Colors.white : line)), child: Text(f[i].$4 ? 'Live' : 'Soon', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: f[i].$4 ? Colors.black : mut))),
                        ]),
                        const SizedBox(height: 6),
                        Text(f[i].$3, style: const TextStyle(color: mut, fontSize: 14.5, height: 1.5, fontWeight: FontWeight.w300)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
      ]);
}
