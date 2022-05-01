import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  ChartPeriod _period = ChartPeriod.H1;
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
      period = await _preferences.get(_SYMBOL_PERIOD_RECENT);
    }
    if (period != null && period != _period.tag) {
      final recentPeriod = ChartPeriod.of(period)!;
      _period = recentPeriod;
      setState(() {
        // to ensure update
        _period = recentPeriod;
      });
    }
  }

  _periodChanged(ChartPeriod period) {
    _preferences.save(_getPreferencesKey(), period.tag);
    _preferences.save(_SYMBOL_PERIOD_RECENT, period.tag);
    setState(() {
      _period = period;
    });
  }

  String _getPreferencesKey() =>
      _SYMBOL_PERIOD_PREFERENCES_ROOT + '.' + widget.symbol.symbol;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: SymbolChartWidget(symbol: widget.symbol, period: _period),
            ),
            ChartPeriodSelector(
              periodChanged: (period) => _periodChanged(period),
              initialPeriod: _period,
            ),
          ],
        ),
      ),
    );
  }
}
