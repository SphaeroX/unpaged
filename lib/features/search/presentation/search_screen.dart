import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:unpaged/features/search/domain/text_search.dart';
import 'package:unpaged/l10n/gen/app_localizations.dart';

/// Full-screen search: a query field and the hits, page by page.
///
/// Returns the tapped hit, or `null` when the user goes back.
class SearchScreen extends StatefulWidget {
  const new({required this.search, this.initialQuery = '', super.key});

  /// Runs a query; hits may arrive over time (large PDFs).
  final Stream<SearchHit> Function(String query) search;

  /// Query to show (and run) when the screen opens.
  final String initialQuery;

  static Future<SearchHit?> show(
    BuildContext context, {
    required Stream<SearchHit> Function(String query) search,
    String initialQuery = '',
  }) => Navigator.of(context).push(
    MaterialPageRoute<SearchHit>(
      builder: (_) => SearchScreen(search: search, initialQuery: initialQuery),
    ),
  );

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _query = TextEditingController(text: widget.initialQuery);
  StreamSubscription<SearchHit>? _running;
  List<SearchHit>? _hits;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().isNotEmpty) _run(widget.initialQuery);
  }

  @override
  void dispose() {
    unawaited(_running?.cancel());
    _query.dispose();
    super.dispose();
  }

  void _run(String query) {
    unawaited(_running?.cancel());
    if (query.trim().isEmpty) return;
    final hits = <SearchHit>[];
    setState(() {
      _hits = hits;
      _searching = true;
    });
    _running = widget
        .search(query)
        .listen(
          (hit) => setState(() => hits.add(hit)),
          onError: (Object _) => setState(() => _searching = false),
          onDone: () => setState(() => _searching = false),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hits = _hits;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: widget.initialQuery.isEmpty,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
          onSubmitted: _run,
        ),
        actions: [
          IconButton(
            tooltip: l10n.search,
            icon: const Icon(Icons.search),
            onPressed: () => _run(_query.text),
          ),
        ],
        bottom: _searching
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: switch (hits) {
        null => const SizedBox.shrink(),
        [] when !_searching => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.searchNoResults, textAlign: TextAlign.center),
          ),
        ),
        _ => Column(
          children: [
            if (hits.length >= searchHitLimit && !_searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  l10n.searchLimited(searchHitLimit),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: hits.length,
                itemBuilder: (context, i) {
                  final hit = hits[i];
                  return ListTile(
                    title: Text(l10n.pageLabel(hit.page)),
                    subtitle: _SnippetText(hit.snippet),
                    onTap: () => Navigator.of(context).pop(hit),
                  );
                },
              ),
            ),
          ],
        ),
      },
    );
  }
}

/// A snippet with its match emphasised.
class _SnippetText extends StatelessWidget {
  const new(this.snippet);

  final Snippet snippet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: snippet.before),
          TextSpan(
            text: snippet.match,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              backgroundColor: scheme.tertiaryContainer,
              color: scheme.onTertiaryContainer,
            ),
          ),
          TextSpan(text: snippet.after),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
