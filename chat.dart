import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api.dart';
import 'kit.dart';

class Turn {
  Turn(this.q);
  final String q;
  final List<String> words = [];
  bool done = false, win = false;
  String why = '';
}

const starters = [
  'Explain how UPI works, like I’m 12',
  'Write a Python script that renames files by date',
  'Plan a 3-day trip to Goa on a budget',
  'Rent or buy a home in Bengaluru?',
];

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatS();
}

class _ChatS extends State<ChatPage> {
  final ta = TextEditingController();
  final focus = FocusNode();
  PageController pc = PageController();
  final sc = <String, ScrollController>{};
  final th = <String, List<Turn>>{};
  final subs = <StreamSubscription>[];
  List<String> sel = ['gpt', 'claude'];
  bool locked = false, busy = false, judging = false, judged = false, hasText = false;

  int get cost => sel.fold(0, (s, k) => s + modelOf(k).cost);

  @override
  void initState() {
    super.initState();
    focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final s in subs) {
      s.cancel();
    }
    ta.dispose();
    focus.dispose();
    pc.dispose();
    for (final c in sc.values) {
      c.dispose();
    }
    super.dispose();
  }

  void snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  void toggle(String k) {
    if (locked) return;
    setState(() {
      if (sel.contains(k)) {
        if (sel.length > 1) sel.remove(k);
      } else if (sel.length < 4) {
        sel.add(k);
      }
    });
  }

  void stick() => WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final c in sc.values) {
          if (c.hasClients) c.jumpTo(c.position.maxScrollExtent);
        }
      });

  void send() {
    final q = ta.text.trim();
    if (q.isEmpty || busy || judging) return;
    if (!wallet.spend(cost)) {
      HapticFeedback.heavyImpact();
      snack('Not enough credits');
      return;
    }
    HapticFeedback.lightImpact();
    ta.clear();
    setState(() {
      locked = true;
      busy = true;
      judged = false;
      hasText = false;
      for (final k in sel) {
        (th[k] ??= []).add(Turn(q));
      }
    });
    var left = sel.length;
    for (final k in List.of(sel)) {
      final t = th[k]!.last;
      subs.add(gateway.chat(k, q).listen(
        (w) {
          setState(() => t.words.add(w));
          stick();
        },
        onError: (_) => setState(() => t.words.add('Something went wrong. ')),
        onDone: () {
          setState(() => t.done = true);
          if (--left == 0) setState(() => busy = false);
        },
      ));
    }
    stick();
  }

  Future<void> judge() async {
    if (judging || busy) return;
    if (!wallet.spend(1)) {
      snack('Not enough credits');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => judging = true);
    final answers = sel.map((k) => th[k]!.last.words.join().trim()).toList();
    final v = await gateway.judge(th[sel.first]!.last.q, answers);
    if (!mounted) return;
    pc.animateToPage(v.winner, duration: const Duration(milliseconds: 700), curve: ease);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      judging = false;
      judged = true;
      th[sel[v.winner]]!.last
        ..win = true
        ..why = v.why;
    });
  }

  void reset() {
    for (final s in subs) {
      s.cancel();
    }
    subs.clear();
    final oldSc = sc.values.toList(), oldPc = pc;
    sc.clear();
    pc = PageController();
    setState(() {
      locked = busy = judging = judged = false;
      th.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldPc.dispose();
      for (final c in oldSc) {
        c.dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showJudge = locked && !busy && !judged && sel.length > 1;
    return Column(children: [
      _dock(),
      if (locked) _seg(),
      Expanded(
        child: Stack(children: [
          IgnorePointer(
            ignoring: locked,
            child: AnimatedOpacity(
              opacity: locked ? 0 : 1,
              duration: const Duration(milliseconds: 500),
              child: AnimatedSlide(
                  offset: locked ? const Offset(0, -.05) : Offset.zero,
                  duration: const Duration(milliseconds: 600),
                  curve: ease,
                  child: _hero()),
            ),
          ),
          if (locked)
            PageView.builder(controller: pc, itemCount: sel.length, itemBuilder: (_, i) => _page(sel[i])),
        ]),
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: ease,
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween<double>(begin: .9, end: 1).animate(a), child: c)),
        child: showJudge || judging
            ? Padding(
                key: const ValueKey('j'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Tap(
                  onTap: judge,
                  child: GlowBox(
                    radius: 26,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      child: Text(judging ? 'Judging the answers…' : '✦ Find best answer (1 credit)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('n')),
      ),
      _composer(),
    ]);
  }

  Widget _dock() => SizedBox(
        height: 58,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(20, 8, 12, 8), children: [
          for (final m in models) _chip(m),
          if (locked) Tap(onTap: reset, child: Container(height: 42, padding: const EdgeInsets.symmetric(horizontal: 18), alignment: Alignment.center, child: const Text('+ New chat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)))),
        ]),
      );

  Widget _chip(Model m) {
    final on = sel.contains(m.key);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tap(
        onTap: () => toggle(m.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: ease,
          height: 42,
          padding: const EdgeInsets.fromLTRB(7, 0, 17, 0),
          decoration: BoxDecoration(
              color: on ? Colors.white : glass,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: on ? Colors.white : line),
              boxShadow: on ? const [BoxShadow(color: Color(0x47FFFFFF), blurRadius: 28)] : null),
          child: Opacity(
            opacity: locked && !on ? .4 : 1,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Av(m.name[0], dark: on),
              const SizedBox(width: 8),
              Text(m.name, style: TextStyle(color: on ? Colors.black : Colors.white, fontWeight: on ? FontWeight.w600 : FontWeight.w500, fontSize: 14)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _seg() => Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: glass, borderRadius: BorderRadius.circular(24), border: Border.all(color: line)),
        child: LayoutBuilder(builder: (_, bx) {
          final w = bx.maxWidth / sel.length;
          return AnimatedBuilder(
            animation: pc,
            builder: (_, __) {
              final p = pc.hasClients && pc.position.hasPixels ? (pc.page ?? 0.0) : 0.0;
              return Stack(children: [
                Positioned(left: p * w, top: 0, bottom: 0, width: w, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x59FFFFFF), blurRadius: 24)]))),
                Row(children: [
                  for (var i = 0; i < sel.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          pc.animateToPage(i, duration: const Duration(milliseconds: 500), curve: ease);
                        },
                        child: Center(
                          child: Text('${modelOf(sel[i]).name}${th[sel[i]]!.last.win ? ' ✓' : ''}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color.lerp(Colors.white, Colors.black, (1 - (p - i).abs()).clamp(0.0, 1.0).toDouble()))),
                        ),
                      ),
                    ),
                ]),
              ]);
            },
          );
        }),
      );

  Widget _hero() => ListView(padding: const EdgeInsets.fromLTRB(24, 22, 24, 16), children: [
        for (var i = 0; i < 3; i++)
          Reveal(
            ms: 150 + i * 130,
            dy: 40,
            blur: 14,
            child: Shimmer(['Ask once.', 'See every', 'answer.'][i], const TextStyle(fontSize: 58, height: 1, fontWeight: FontWeight.w600, letterSpacing: -3)),
          ),
        const SizedBox(height: 18),
        const Reveal(ms: 600, child: Text('Compare the best AI models side by side, then let the judge pick the winner.', style: TextStyle(color: mut, fontSize: 16.5, fontWeight: FontWeight.w300, height: 1.5))),
        const SizedBox(height: 26),
        for (var i = 0; i < starters.length; i++)
          Reveal(
            ms: 750 + i * 100,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Tap(
                onTap: () {
                  ta.text = starters[i];
                  setState(() => hasText = true);
                  focus.requestFocus();
                },
                child: Panel(
                  radius: 20,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(children: [Expanded(child: Text(starters[i], style: const TextStyle(fontSize: 15))), const Icon(Icons.north_east_rounded, size: 18)]),
                  ),
                ),
              ),
            ),
          ),
      ]);

  Widget _page(String k) => ListView(
        controller: sc[k] ??= ScrollController(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          for (final t in th[k]!) ...[
            Reveal(
              key: ObjectKey(t),
              dy: 14,
              blur: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .8),
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(6))),
                  child: Text(t.q, style: const TextStyle(color: Colors.black, fontSize: 15.5, fontWeight: FontWeight.w500, height: 1.4)),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.only(bottom: 26), child: _card(modelOf(k), t)),
          ],
        ],
      );

  Widget _card(Model m, Turn t) {
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Av(m.name[0], spin: !t.done, size: 30),
          const SizedBox(width: 12),
          Text(m.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: t.done ? const SizedBox.shrink() : Text(t.words.isEmpty ? 'Thinking' : 'Writing', key: ValueKey(t.words.isEmpty), style: const TextStyle(fontSize: 12.5, color: mut)),
          ),
        ]),
        if (t.win)
          Reveal(
            dy: -10,
            blur: 0,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('✓ Best answer', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(t.why, style: const TextStyle(color: Color(0xB3000000), fontSize: 14, height: 1.4)),
              ]),
            ),
          ),
        const SizedBox(height: 12),
        if (t.words.isEmpty)
          const Skel()
        else if (t.done)
          Text(t.words.join().trim(), style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w300))
        else
          Wrap(children: [
            for (var i = 0; i < t.words.length; i++)
              Reveal(key: ValueKey(i), dy: 8, blur: 6, child: Text(t.words[i], style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w300))),
          ]),
      ]),
    );
    return Reveal(
      key: ObjectKey(t),
      ms: 150,
      child: t.win ? Stack(clipBehavior: Clip.none, children: [GlowBox(child: body), const Positioned.fill(child: Pulse())]) : Panel(child: body),
    );
  }

  Widget _composer() {
    final on = hasText && !busy;
    final f = focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: ease,
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      padding: const EdgeInsets.fromLTRB(20, 4, 6, 4),
      decoration: BoxDecoration(
          color: const Color(0xB3121212),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: f ? const Color(0xB3FFFFFF) : line, width: 1.5),
          boxShadow: f ? const [BoxShadow(color: Color(0x1AFFFFFF), blurRadius: 36)] : null),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child: TextField(
            controller: ta,
            focusNode: focus,
            minLines: 1,
            maxLines: 4,
            cursorColor: Colors.white,
            style: const TextStyle(fontSize: 16.5),
            onChanged: (v) => setState(() => hasText = v.trim().isNotEmpty),
            decoration: InputDecoration(border: InputBorder.none, hintText: 'Ask ${sel.length} model${sel.length > 1 ? 's' : ''} at once', hintStyle: const TextStyle(color: mut), contentPadding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
        AnimatedOpacity(opacity: hasText ? 1 : 0, duration: const Duration(milliseconds: 300), child: Text('−$cost', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: mut))),
        const SizedBox(width: 8),
        Tap(
          onTap: send,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: ease,
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: on ? Colors.white : const Color(0x1AFFFFFF), boxShadow: on ? const [BoxShadow(color: Color(0x66FFFFFF), blurRadius: 26)] : null),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(Icons.arrow_upward_rounded, key: ValueKey(on), color: on ? Colors.black : const Color(0x59FFFFFF)),
            ),
          ),
        ),
      ]),
    );
  }
}
