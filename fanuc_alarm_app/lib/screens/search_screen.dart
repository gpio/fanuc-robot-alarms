import 'dart:async';

import 'package:flutter/material.dart';

import '../services/fuzzy_service.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  List<FuzzyMatch> _results = [];
  String? _selectedFamily;
  bool _ready = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await FuzzyService.instance.load();
    if (mounted) {
      setState(() => _ready = true);
      _runSearch();
    }
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _runSearch);
  }

  void _runSearch() {
    if (!_ready) return;
    final results = FuzzyService.instance.search(
      _ctrl.text.trim(),
      family: _selectedFamily,
    );
    if (mounted) setState(() => _results = results);
  }

  void _onFamilyChanged(String? family) {
    setState(() => _selectedFamily = family);
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    final families = FuzzyService.instance.families;
    final query = _ctrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fanuc Robot Alarms'),
        centerTitle: false,
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              children: [
                TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'srvo001, srvo-230, intp…',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white70),
                            onPressed: () {
                              _ctrl.clear();
                              _runSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onQueryChanged,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _Chip(
                        label: 'All',
                        selected: _selectedFamily == null,
                        onTap: () => _onFamilyChanged(null),
                      ),
                      for (final f in families)
                        _Chip(
                          label: f,
                          selected: _selectedFamily == f,
                          onTap: () => _onFamilyChanged(f),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      query.isEmpty
                          ? '${_results.length} alarms'
                          : '${_results.length} result${_results.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ),
                Expanded(
                  child: _results.isEmpty
                      ? const Center(child: Text('No match'))
                      : ListView.separated(
                          controller: _scroll,
                          itemCount: _results.length,
                          separatorBuilder: (ctx, idx) =>
                              const Divider(height: 1, indent: 72),
                          itemBuilder: (context, i) {
                            final m = _results[i];
                            return _FuzzyTile(
                              match: m,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailScreen(error: m.error),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.white : Colors.white60,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? const Color(0xFF003087) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _FuzzyTile extends StatelessWidget {
  final FuzzyMatch match;
  final VoidCallback onTap;

  const _FuzzyTile({required this.match, required this.onTap});

  static const _highlight = Color(0xFFFFD700); // Fanuc yellow

  @override
  Widget build(BuildContext context) {
    final e = match.error;
    return ListTile(
      onTap: onTap,
      leading: _TypeBadge(type: e.type),
      title: _highlighted(
        e.code,
        match.codePositions,
        const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
      ),
      subtitle: Text(
        e.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _highlighted(
    String text,
    List<int> positions,
    TextStyle base, {
    int? maxLines,
  }) {
    if (positions.isEmpty) {
      return Text(text,
          style: base,
          maxLines: maxLines,
          overflow:
              maxLines != null ? TextOverflow.ellipsis : null);
    }
    final posSet = positions.toSet();
    final spans = <TextSpan>[];
    for (int i = 0; i < text.length; i++) {
      if (posSet.contains(i)) {
        spans.add(TextSpan(
          text: text[i],
          style: base.copyWith(
            color: const Color(0xFF003087),
            fontWeight: FontWeight.bold,
            backgroundColor: _highlight.withValues(alpha: 0.35),
          ),
        ));
      } else {
        spans.add(TextSpan(text: text[i], style: base));
      }
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _color(type).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color(type).withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          type.isEmpty ? '?' : (type.length > 5 ? type.substring(0, 5) : type),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: _color(type),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _color(String type) => switch (type) {
        'FATAL' => const Color(0xFFB71C1C),
        'ABORT' || 'ABORT.G' || 'ABORT.L' || 'ABRT' || 'SABRT' =>
          const Color(0xFFE53935),
        'PAUSE' || 'PAUSE.G' || 'PAUSE.L' || 'PAUS' => const Color(0xFFF57C00),
        'WARN' => const Color(0xFFD4A017),
        'SERVO' || 'SERVO2' => const Color(0xFF1565C0),
        'STOP' || 'STOPL' || 'SVSTOP' => const Color(0xFF6A1B9A),
        'SYSTEM' => const Color(0xFF37474F),
        _ => const Color(0xFF455A64),
      };
}
