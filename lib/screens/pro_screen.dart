import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/wordsearch_themes.dart';
import '../theme/workshop.dart';

/// Word Search PRO: Free-vs-Pro comparison, real purchase, restore, and tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final WordSearchAudio audio;
  final WordSearchSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  WorkshopThemeDef get _t => WorkshopThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    widget.store.lastThanks.addListener(_onThanks);
  }

  
  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Workshop.body(15, theme: _t)),
        backgroundColor: _t.paperDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final store = widget.store;
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => Scaffold(
        backgroundColor: t.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.ink),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('WORD SEARCH PRO',
              style: Workshop.label(15, theme: t)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.settings.isPro)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: t.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.accentDark, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: t.accentDark, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You are PRO — every theme, style, mode and '
                          'difficulty is unlocked. Thank you!',
                          style: Workshop.body(14, theme: t),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buyCard(t, store),
              Workshop.sectionTitle('Free vs Pro', theme: t),
              _compareTable(t),
              Workshop.sectionTitle('Tip jar', theme: t),
              Text(
                'Love the game? A small tip keeps the workshop carving. '
                'Tips are optional and never affect gameplay.',
                style: Workshop.body(13,
                    theme: t, color: t.ink.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 10),
              _tipRow(t, store),
              if (!store.storeReady) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.tile,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.tileEdge),
                  ),
                  child: Text(
                    store.error ??
                        'Store products are not configured yet — purchases '
                        'appear here once they are set up in Play Console.',
                    style: Workshop.body(13,
                        theme: t,
                        color: t.ink.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    widget.audio.click();
                    store.restore();
                  },
                  child: Text('Restore purchases',
                      style: Workshop.body(14, theme: t).copyWith(
                          decoration: TextDecoration.underline)),
                ),
              ),
              ValueListenableBuilder<String?>(
                valueListenable: store.purchaseError,
                builder: (_, err, _) => err == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(err,
                            textAlign: TextAlign.center,
                            style: Workshop.body(13, theme: t)
                                .copyWith(color: Colors.red.shade700)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buyCard(WorkshopThemeDef t, StoreService store) {
    final p = store.proProduct;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.tile, t.soft],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.accentDark, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium, size: 44, color: t.accentDark),
          const SizedBox(height: 8),
          Text('Unlock Word Search PRO',
              style: Workshop.display(22, theme: t),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'One payment. Yours forever. Every theme, style, mode, '
            'difficulty and unlimited hints.',
            style: Workshop.body(14,
                theme: t, color: t.ink.withValues(alpha: 0.75)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          if (p != null)
            Workshop.woodButton(
              theme: t,
              label: 'GET PRO · ${p.price}',
              icon: Icons.lock_open,
              fontSize: 17,
              onTap: store.purchaseInProgress.value
                  ? null
                  : () => store.buyPro(),
            )
          else
            Text(
              'PRO purchase appears here once the product is set up '
              'in Play Console.',
              style: Workshop.body(13,
                  theme: t, color: t.ink.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _compareTable(WorkshopThemeDef t) {
    const rows = [
      ['Puzzles', 'Unlimited', 'Unlimited'],
      ['Difficulties', 'Cozy, Clever', 'Cozy, Clever, Master'],
      ['Modes', 'Relaxed', 'Relaxed + Timed'],
      ['Hints per game', '3', 'Unlimited'],
      ['Workshop themes', '4', 'All 12'],
      ['Tile styles', '2', 'All 8'],
      ['Word categories', '2', 'All 6'],
      ['Custom theme creator', '—', '✓'],
    ];
    return Container(
      decoration: BoxDecoration(
        color: t.tile,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.tileEdge, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: t.soft,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                    width: 72,
                    child: Text('FREE',
                        textAlign: TextAlign.center,
                        style: Workshop.body(12, theme: t).copyWith(
                            fontWeight: FontWeight.w900))),
                SizedBox(
                    width: 72,
                    child: Text('PRO',
                        textAlign: TextAlign.center,
                        style: Workshop.body(12, theme: t).copyWith(
                            fontWeight: FontWeight.w900,
                            color: t.accentDark))),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? Border(
                        bottom:
                            BorderSide(color: t.tileEdge.withValues(alpha: 0.5)))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                      child: Text(rows[i][0],
                          style: Workshop.body(13, theme: t))),
                  SizedBox(
                      width: 72,
                      child: Text(rows[i][1],
                          textAlign: TextAlign.center,
                          style: Workshop.body(12, theme: t))),
                  SizedBox(
                      width: 72,
                      child: Text(rows[i][2],
                          textAlign: TextAlign.center,
                          style: Workshop.body(12, theme: t).copyWith(
                              fontWeight: FontWeight.w800,
                              color: t.accentDark))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tipRow(WorkshopThemeDef t, StoreService store) {
    Widget tipCard(ProductDetails? p, String emoji, String label) {
      final ready = p != null;
      return Expanded(
        child: GestureDetector(
          onTap: !ready || store.purchaseInProgress.value
              ? null
              : () {
                  widget.audio.click();
                  store.buyTip(p);
                },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: ready ? t.tile : t.soft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.tileEdge, width: 1.5),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 4),
                Text(label, style: Workshop.body(13, theme: t)),
                Text(
                  ready ? p.price : 'soon',
                  style: Workshop.body(12, theme: t)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tipCard(store.coffeeProduct, '☕', 'Coffee'),
        const SizedBox(width: 10),
        tipCard(store.chocolateProduct, '🍫', 'Chocolate'),
      ],
    );
  }
}
