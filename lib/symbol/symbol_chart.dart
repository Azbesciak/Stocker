import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stocker/xtb/model/chart_period.dart';
import 'package:stocker/xtb/model/error_data.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../xtb/connector.dart';
import '../xtb/model/candle_data.dart';
import '../xtb/model/chart_data.dart';
import '../xtb/model/chart_request.dart';
import '../xtb/model/symbol_data.dart';

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

// https://www.syncfusion.com/kb/12535/how-to-lazily-load-more-data-to-the-chart-sfcartesianchart
class _SymbolChartWidgetState extends State<SymbolChartWidget> {
  static const FETCH_PERIODS = 50;
  late Future<ChartData> _chartData;
  late TrackballBehavior _trackballBehavior;
  late CrosshairBehavior _crosshairBehavior;
  late ZoomPanBehavior _zoomPanBehavior;
  double? _oldAxisVisibleMin, _oldAxisVisibleMax;
  late bool _isLoadMoreView;
  int _currentPeriodOffset = 0;
  int _newDataSize = 0;

  @override
  void didUpdateWidget(covariant SymbolChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.symbol != widget.symbol) {
      setState(() {
        _currentPeriodOffset = 0;
        _updateChartData(false);
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
    _isLoadMoreView = false;
    _updateChartData(false);
  }

  void _updateChartData(bool append) {
    if (append) {
      _chartData = _chartData.then((oldData) => _fetchData().catchError((err) {
            if (err is ErrorData &&
                err.errorCode == ErrorData.NO_MORE_DATA_ERR) {
              log("NO MORE CHART DATA");
              return oldData;
            }
            throw err;
          }).then(
            (newData) {
              _newDataSize = newData.rateInfos.length;
              return ChartData(
                digits: newData.digits,
                rateInfos: [...newData.rateInfos, ...oldData.rateInfos],
              );
            },
          ));
    } else {
      _chartData = _fetchData();
    }
  }

  Future<ChartData> _fetchData() {
    _newDataSize = 0;
    final connector = Provider.of<XTBApiConnector>(context, listen: false);
    var currentPeriod = widget.period;
    var currentSymbol = widget.symbol.symbol;
    final end = DateTime.now().subtract(
        Duration(minutes: currentPeriod.value * _currentPeriodOffset));
    final start =
        end.subtract(Duration(minutes: currentPeriod.value * FETCH_PERIODS));
    _currentPeriodOffset += FETCH_PERIODS;
    var fetchedData = connector.getChartRangeRequest(
      params: ChartRequest(
        end: end.millisecondsSinceEpoch,
        start: start.millisecondsSinceEpoch,
        period: currentPeriod,
        symbol: currentSymbol,
        ticks: 0,
      ),
    );
    return fetchedData;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChartData>(
        future: _chartData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _isLoadMoreView = true;
            var data = snapshot.data!.rateInfos;
            return _defineCHart(data);
          } else if (snapshot.hasError) {
            log("CHART ERROR [${widget.symbol.symbol} ${widget.period.tag}] ${snapshot.error}");
            if (snapshot.error is ErrorData) {
              return Text((snapshot.error as ErrorData).errorDescr);
            } else {
              return Text('${snapshot.stackTrace}');
            }
          }
          // By default, show a loading spinner.
          return const CircularProgressIndicator();
        });
  }

  SfCartesianChart _defineCHart(List<CandleData> data) {
    return SfCartesianChart(
      loadMoreIndicatorBuilder: _buildLoadMoreIndicatorView,
      onActualRangeChanged: _onActualRangeChanged,
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      crosshairBehavior: _crosshairBehavior,
      primaryXAxis: _defineXAxis(data),
      primaryYAxis: _defineYAxis(),
      series: <CandleSeries>[_initializeCandleSerie(data)],
    );
  }

  void _onActualRangeChanged(ActualRangeChangedArgs args) {
    if (args.orientation == AxisOrientation.horizontal) {
      // // Assigning the old visible min and max after loads the data.
      if (_isLoadMoreView && _oldAxisVisibleMin != null) {
        args.visibleMin = _oldAxisVisibleMin! + _newDataSize;
        args.visibleMax = _oldAxisVisibleMax! + _newDataSize;
        _newDataSize = 0;
      }
      _oldAxisVisibleMin = args.visibleMin;
      _oldAxisVisibleMax = args.visibleMax;
      _isLoadMoreView = false;
    }
  }

  NumericAxis _defineYAxis() {
    return NumericAxis(
      opposedPosition: true,
      rangePadding: ChartRangePadding.additional,
      enableAutoIntervalOnZooming: true,
      anchorRangeToVisiblePoints: false,
      numberFormat: NumberFormat.decimalPattern(),
    );
  }

  DateTimeCategoryAxis _defineXAxis(List<CandleData> data) {
    return DateTimeCategoryAxis(
      // visibleMinimum: data.isNotEmpty
      //     ? DateTime.fromMillisecondsSinceEpoch(
      //         data[max(data.length - 30, 0)].ctm)
      //     : null,
      dateFormat: _getDateFormat(),
      majorGridLines: MajorGridLines(width: 0),
      intervalType: DateTimeIntervalType.auto,
    );
  }

  CandleSeries<CandleData, DateTime> _initializeCandleSerie(
      List<CandleData> data) {
    return CandleSeries<CandleData, DateTime>(
      enableSolidCandles: true,
      dataSource: data,
      xValueMapper: (CandleData data, _) =>
          DateTime.fromMillisecondsSinceEpoch(data.ctm),
      lowValueMapper: (CandleData data, _) => data.open + data.low,
      highValueMapper: (CandleData data, _) => data.open + data.high,
      openValueMapper: (CandleData data, _) => data.open,
      closeValueMapper: (CandleData data, _) => data.open + data.close,
    );
  }

  DateFormat _getDateFormat() {
    if (widget.period.value < ChartPeriod.H1.value) {
      return DateFormat("HH:mm");
    } else if (widget.period.value < ChartPeriod.D1.value) {
      return DateFormat("dd.MM HH:mm");
    } else {
      return DateFormat("dd.MM.yyyy");
    }
  }

  Widget _buildLoadMoreIndicatorView(
      BuildContext context, ChartSwipeDirection direction) {
    // To know whether reaches the end of the chart
    log("CHART BUILD MORE ${direction}");
    if (direction == ChartSwipeDirection.start) {
      // setState(() {
      _updateChartData(true);
      // });
      _chartData.then((value) {
        setState(() {});
      });
      return CircularProgressIndicator();
    } else {
      return SizedBox.fromSize(size: Size.zero);
    }
  }
}
