import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stocker/xtb/model/chart_period.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'connector.dart';
import 'model/candle_data.dart';
import 'model/chart_data.dart';
import 'model/chart_request.dart';
import 'model/symbol_data.dart';

class SymbolChartWidget extends StatefulWidget {
  final SymbolData symbol;
  final ChartPeriod period;

  const SymbolChartWidget({
    Key? key,
    required this.symbol,
    required this.period,
  }) : super(key: key);

  @override
  State<SymbolChartWidget> createState() => _SymbolChartWidgetState();
}

class _SymbolChartWidgetState extends State<SymbolChartWidget> {
  late Future<ChartData> _chartData;
  late TrackballBehavior _trackballBehavior;
  late CrosshairBehavior _crosshairBehavior;
  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void didUpdateWidget(covariant SymbolChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.symbol != widget.symbol) {
      setState(() {
        updateChartData();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
      enable: false,
      activationMode: ActivationMode.singleTap,
    );
    _crosshairBehavior = CrosshairBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
    );
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: true,
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );

    updateChartData();
  }

  void updateChartData() {
    final connector = Provider.of<XTBApiConnector>(context, listen: false);
    final end = DateTime.now().millisecondsSinceEpoch;
    final start = DateTime.now()
        .subtract(Duration(minutes: widget.period.value * 1000))
        .millisecondsSinceEpoch;
    _chartData = connector.getChartRangeRequest(
      params: ChartRequest(
        end: end,
        start: start,
        period: widget.period,
        symbol: widget.symbol.symbol,
        ticks: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChartData>(
        future: _chartData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SfCartesianChart(
                zoomPanBehavior: _zoomPanBehavior,
                trackballBehavior: _trackballBehavior,
                crosshairBehavior: _crosshairBehavior,
                primaryXAxis: DateTimeCategoryAxis(
                  dateFormat: getDateFormat(),
                  rangePadding: ChartRangePadding.auto,
                  majorGridLines: MajorGridLines(width: 0),
                  intervalType: DateTimeIntervalType.auto,
                ),
                primaryYAxis: NumericAxis(
                  opposedPosition: true,
                  rangePadding: ChartRangePadding.auto,
                  enableAutoIntervalOnZooming: true,
                  numberFormat: NumberFormat.decimalPattern(),
                ),
                series: <CandleSeries>[
                  CandleSeries<CandleData, DateTime>(
                    dataSource: snapshot.data!.rateInfos,
                    xValueMapper: (CandleData data, _) =>
                        DateTime.fromMillisecondsSinceEpoch(data.ctm),
                    lowValueMapper: (CandleData data, _) =>
                        data.open + data.low,
                    highValueMapper: (CandleData data, _) =>
                        data.open + data.high,
                    openValueMapper: (CandleData data, _) => data.open,
                    closeValueMapper: (CandleData data, _) =>
                        data.open + data.close,
                  )
                ]);
          } else if (snapshot.hasError) {
            return Text('${snapshot.stackTrace}');
          }
          // By default, show a loading spinner.
          return const CircularProgressIndicator();
        });
  }

  DateFormat getDateFormat() {
    if (widget.period.value < ChartPeriod.H1.value)
      return DateFormat("HH:mm");
    else if (widget.period.value < ChartPeriod.D1.value)
      return DateFormat("DD HH:mm");
    else
      return DateFormat.Md();
  }
}
