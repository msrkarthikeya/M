import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class Model {
  const Model(this.key, this.name, this.cost);
  final String key, name;
  final int cost; // credits per prompt
}

const models = [
  Model('gpt', 'GPT', 2),
  Model('claude', 'Claude', 3),
  Model('gemini', 'Gemini', 1),
  Model('deepseek', 'DeepSeek', 1),
  Model('llama', 'Llama', 1),
];
Model modelOf(String k) => models.firstWhere((m) => m.key == k);

class Verdict {
  const Verdict(this.winner, this.why);
  final int winner;
  final String why;
}

abstract class Gateway {
  /// Streams the reply word by word.
  Stream<String> chat(String modelKey, String prompt);

  /// Blind judge: receives answers only (no model names), in shuffled order.
  Future<Verdict> judge(String prompt, List<String> answers);
}

class MockGateway implements Gateway {
  final _r = Random();
  @override
  Stream<String> chat(String k, String prompt) async* {
    await Future.delayed(Duration(milliseconds: 700 + _r.nextInt(900)));
    final text = 'This is a demo reply from ${modelOf(k).name}. Real answers will '
        'appear here once the gateway is connected, streaming in word by word '
        'exactly like this.';
    for (final w in text.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 70));
      yield '$w ';
    }
  }

  @override
  Future<Verdict> judge(String prompt, List<String> answers) async {
    await Future.delayed(const Duration(milliseconds: 1400));
    return Verdict(_r.nextInt(answers.length), 'Clearest and most direct reply.');
  }
}

/// TODO: call YOUR backend proxy (which holds the Mesh API key). Never put the key in the app.
class MeshGateway implements Gateway {
  MeshGateway(this.baseUrl, this.authToken);
  final String baseUrl, authToken;
  @override
  Stream<String> chat(String modelKey, String prompt) =>
      throw UnimplementedError('Connect to backend proxy');
  @override
  Future<Verdict> judge(String prompt, List<String> answers) =>
      throw UnimplementedError('Connect to backend proxy');
}

class Wallet extends ChangeNotifier {
  static const limit = 20;
  int credits = limit;
  bool spend(int n) {
    if (credits < n) return false;
    credits -= n;
    notifyListeners();
    return true;
  }

  void refill() { // demo only; real credits come from the server
    credits = limit;
    notifyListeners();
  }
}

final Gateway gateway = MockGateway();
final wallet = Wallet();
