import '../models/error_code.dart';
import 'database_service.dart';

class FuzzyMatch {
  final ErrorCode error;
  final int score;
  final List<int> codePositions;

  const FuzzyMatch({
    required this.error,
    required this.score,
    required this.codePositions,
  });
}

class FuzzyService {
  static FuzzyService? _instance;
  List<ErrorCode> _all = [];
  List<String> _families = [];
  bool _loaded = false;

  FuzzyService._();
  static FuzzyService get instance => _instance ??= FuzzyService._();

  List<String> get families => _families;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    _all = await DatabaseService.instance.loadAll();

    final seen = <String>{};
    final all = <String>[];
    for (final e in _all) {
      final f = e.prefix;
      if (f.isNotEmpty && seen.add(f)) all.add(f);
    }
    all.sort();
    // SRVO first
    if (all.remove('SRVO')) all.insert(0, 'SRVO');
    _families = all;
    _loaded = true;
  }

  List<FuzzyMatch> search(String query, {String? family}) {
    final candidates = (family != null && family.isNotEmpty)
        ? _all.where((e) => e.prefix == family).toList()
        : _all;

    final q = query.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');

    if (q.isEmpty) {
      return candidates
          .take(100)
          .map((e) => FuzzyMatch(error: e, score: 0, codePositions: []))
          .toList();
    }

    final results = <FuzzyMatch>[];
    for (final e in candidates) {
      // Search only on code, stripping the dash for flexible input
      final codeLower = e.code.toLowerCase();
      final codeStripped = codeLower.replaceAll('-', '');

      // Try on stripped code first (srvo001 → srvo-001)
      final stripped = _scoreStr(q, codeStripped);
      if (stripped != null) {
        // Map positions back to original code with dash
        final mappedPos = _remapPositions(stripped.positions, codeLower);
        results.add(FuzzyMatch(
          error: e,
          score: stripped.score,
          codePositions: mappedPos,
        ));
        continue;
      }

      // Fallback: try on original code with dash (handles "srvo-001" input)
      final orig = _scoreStr(q.replaceAll(RegExp(r'\-'), ''), codeLower);
      if (orig != null) {
        results.add(FuzzyMatch(
          error: e,
          score: orig.score,
          codePositions: orig.positions,
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(200).toList();
  }

  // After matching on stripped code, remap char positions to the original
  // code string that contains a dash (e.g. "srvo001" pos 4 → "srvo-001" pos 5)
  List<int> _remapPositions(List<int> positions, String original) {
    // Build mapping: stripped index → original index
    final map = <int, int>{};
    int si = 0;
    for (int i = 0; i < original.length; i++) {
      if (original[i] != '-') {
        map[si++] = i;
      }
    }
    return positions.map((p) => map[p] ?? p).toList();
  }

  _Score? _scoreStr(String query, String target) {
    final positions = <int>[];
    int score = 0;
    int qi = 0;
    int consecutive = 0;

    for (int ti = 0; ti < target.length && qi < query.length; ti++) {
      if (target[ti] == query[qi]) {
        final prevIsWordBoundary = ti == 0 ||
            target[ti - 1] == ' ' ||
            target[ti - 1] == '-' ||
            target[ti - 1] == '_';

        if (positions.isNotEmpty && positions.last == ti - 1) {
          consecutive++;
          score += 15 * consecutive;
        } else {
          consecutive = 1;
          score += prevIsWordBoundary ? 10 : 2;
        }

        if (prevIsWordBoundary) score += 5;

        positions.add(ti);
        qi++;
      }
    }

    if (qi < query.length) return null;
    score -= target.length ~/ 20;
    return _Score(score: score, positions: positions);
  }
}

class _Score {
  final int score;
  final List<int> positions;
  const _Score({required this.score, required this.positions});
}
