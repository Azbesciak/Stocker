import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:stocker/chart_period_selector.dart';
import 'package:stocker/xtb/model/chart_period.dart';
import 'package:stocker/xtb/model/symbol_data.dart';
import 'package:stocker/xtb/symbol_chart.dart';

class SymbolPage extends StatefulWidget {
  static const navRoute = "/symbol";

  final SymbolData symbol;

  const SymbolPage({Key? key, required this.symbol}) : super(key: key);

  @override
  State<SymbolPage> createState() => _SymbolPageState();
}

class _SymbolPageState extends State<SymbolPage> {
  ChartPeriod _period = ChartPeriod.H1;

  @override
  void initState() {
    super.initState();
  }

  _periodChanged(ChartPeriod period) {
    setState(() {
      _period = period;
    });
  }

  @override
  Widget build(BuildContext context) {
    log("BUILD ${_period.tag}");
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
