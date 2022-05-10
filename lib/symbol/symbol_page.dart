import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stocker/preferences/preferences.dart';
import 'package:stocker/symbol/chart_period_selector.dart';
import 'package:stocker/symbol/symbol_chart.dart';
import 'package:stocker/xtb/model/chart_period.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

class SymbolPage extends StatefulWidget {
  static const navRoute = '/symbol';

  final SymbolData symbol;

  const SymbolPage({Key? key, required this.symbol}) : super(key: key);

  @override
  State<SymbolPage> createState() => _SymbolPageState();
}

class _SymbolPageState extends State<SymbolPage> {
  late Preferences _preferences;
  final BehaviorSubject<ChartPeriod> _period$ = BehaviorSubject();
  static const _SYMBOL_PERIOD_PREFERENCES_ROOT = 'symbol.period';
  static const _SYMBOL_PERIOD_RECENT = 'symbol.period.recent';

  @override
  void initState() {
    super.initState();
    _preferences = Provider.of<Preferences>(context, listen: false);
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
                ChartPeriodSelector(
                  periodChanged: (p) => _periodChanged(p),
                  initialPeriod: period,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
