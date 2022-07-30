import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stocker/favourites/favourites_button.dart';
import 'package:stocker/favourites/favourites_store.dart';
import 'package:stocker/preferences/preferences.dart';
import 'package:stocker/symbol/chart_period_selector.dart';
import 'package:stocker/symbol/symbol_chart.dart';
import 'package:stocker/symbol/symbol_info_header.dart';
import 'package:stocker/xtb/model/chart_period.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

class SymbolPage extends StatefulWidget {
  static const navRoute = '/symbol';

  static goTo(BuildContext context, SymbolData symbol) {
    Navigator.pushNamed(
      context,
      SymbolPage.navRoute,
      arguments: {'symbol': symbol},
    );
  }

  final SymbolData symbol;

  const SymbolPage({super.key, required this.symbol});

  @override
  State<SymbolPage> createState() => _SymbolPageState();
}

class _SymbolPageState extends State<SymbolPage> {
  late Preferences _preferences;
  late final FavouritesStore _favourites;
  late final Stream<bool> _allFavourites$;
  late StreamSubscription<bool> _behaviorSub;

  final BehaviorSubject<ChartPeriod> _period$ = BehaviorSubject();
  static const _SYMBOL_PERIOD_PREFERENCES_ROOT = 'symbol.period';
  static const _SYMBOL_PERIOD_RECENT = 'symbol.period.recent';

  @override
  void initState() {
    super.initState();
    _preferences = Provider.of<Preferences>(context, listen: false);
    _favourites = Provider.of<FavouritesStore>(context, listen: false);
    _allFavourites$ = _favourites
        .watchAllFavourites(
          aggregator: (v, g) => v.any(
            (s) => s.any((e) => e == widget.symbol.symbol),
          ),
        )
        .distinct();
    _behaviorSub = _allFavourites$.listen((event) {});
    updatePeriodFromPreferences();
  }

  void updatePeriodFromPreferences() async {
    String? period = await _preferences.get(_getPreferencesKey());
    if (period == null) {
      period =
          (await _preferences.get(_SYMBOL_PERIOD_RECENT)) ?? ChartPeriod.H1.tag;
    }
    final chartPeriod = ChartPeriod.of(period);
    if (chartPeriod != null) {
      _period$.add(chartPeriod);
    }
  }

  _periodChanged(ChartPeriod period) {
    _preferences.save(_getPreferencesKey(), period.tag);
    _preferences.save(_SYMBOL_PERIOD_RECENT, period.tag);
    _period$.add(period);
  }

  String _getPreferencesKey() =>
      _SYMBOL_PERIOD_PREFERENCES_ROOT + '.' + widget.symbol.symbol;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: StreamBuilder<ChartPeriod>(
          stream: _period$,
          builder: (_, snap) {
            if (!snap.hasData) return Container();
            final period = snap.data!;
            return Stack(
              children: [
                Center(
                  child: SymbolChartWidget(
                    symbol: widget.symbol,
                    period: period,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // runAlignment: WrapAlignment.spaceEvenly,
                    // direction: Axis.horizontal,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 2),
                        child: ChartPeriodSelector(
                          periodChanged: (p) => _periodChanged(p),
                          initialPeriod: period,
                          direction: Axis.vertical,
                        ),
                      ),
                      SymbolInfoHeader(symbol: widget.symbol),
                      _favouritesButton()
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _favouritesButton() {
    return SizedBox(
      height: 60,
      width: 40,
      child: StreamBuilder<bool>(
        builder: (ctx, snap) {
          if (snap.hasData) {
            return FavouritesButton(
              isFavourite: snap.data!,
              toggleFavourite: () {
                final symbol = widget.symbol.symbol;
                if (snap.data!) {
                  _favourites.removeFromFavourites(
                    symbol,
                    FavouritesStore.DEFAULT_GROUP,
                  );
                } else {
                  _favourites.addToFavourites(
                    symbol,
                    FavouritesStore.DEFAULT_GROUP,
                  );
                }
              },
            );
          } else if (snap.hasError) {
            return Icon(Icons.error_outline);
          } else {
            return CircularProgressIndicator();
          }
        },
        stream: _allFavourites$,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _behaviorSub.cancel();
  }
}
