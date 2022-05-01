import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loggy/loggy.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stocker/symbol/chart_data_padding_manager.dart';
import 'package:stocker/xtb/connector.dart';
import 'package:stocker/xtb/model/candle_data.dart';
import 'package:stocker/xtb/model/chart_data.dart';
import 'package:stocker/xtb/model/chart_period.dart';
import 'package:stocker/xtb/model/chart_range_request.dart';
import 'package:stocker/xtb/model/chart_request.dart';
import 'package:stocker/xtb/model/error_data.dart';
import 'package:stocker/xtb/model/symbol_data.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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
  static const FETCH_PERIODS = 300;
  static const CHART_PADDING = 10;
  ChartSeriesController? _seriesController;
  late Future<ChartData> _chartData;
  late TrackballBehavior _trackballBehavior;
  late CrosshairBehavior _crosshairBehavior;
  late ZoomPanBehavior _zoomPanBehavior;
  num? _oldAxisVisibleMin, _oldAxisVisibleMax;
  late bool _isLoadMoreView, _isNeedToUpdateView;
  int _currentPeriodOffset = 0;
  late GlobalKey<State> _globalKey;
  Cancellation? _ticksCancellation;
  late ChartDataPaddingManager _paddingManager;

  @override
  void didUpdateWidget(covariant SymbolChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.symbol != widget.symbol) {
      setState(() {
        _chartData.ignore();
        _fetchNewData();
        _updateRecentData();
      });
    }
  }

  void _fetchNewData() {
    _currentPeriodOffset = 0;
    var period = widget.period;
    _chartData = _fetchData().then((value) {
      _paddingManager.addPadding(value.rateInfos, period);
      return value;
    });
  }

  @override
  void initState() {
    super.initState();
    _paddingManager = ChartDataPaddingManager(paddingCandles: CHART_PADDING);
    _trackballBehavior = TrackballBehavior(
      enable: false,
      activationMode: ActivationMode.singleTap,
    );
    _crosshairBehavior = CrosshairBehavior(
      enable: false,
      activationMode: ActivationMode.singleTap,
    );
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: true,
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );
    _globalKey = GlobalKey();
    _isLoadMoreView = false;
    _isNeedToUpdateView = false;
    _fetchNewData();
    _updateRecentData();
  }

  void _updateRecentData() {
    final connector = Provider.of<XTBApiConnector>(context, listen: false);
    _ticksCancellation?.call();
    var canceled = false;
    final source = StreamController<ChartData>.broadcast();

    var period = widget.period;
    var symbol = widget.symbol.symbol;
    final streamListen =
        _requestLastCandle(source, connector, period, symbol, canceled);
    Cancellation? ticksCancellation;
    final fut = _chartData.then((chartData) {
      if (canceled) {
        return;
      }

      ticksCancellation = connector.getTickPrices(
        symbol: symbol,
        onResult: (data) {
          if (!data.isSuccess()) {
            logError('ERROR [$symbol]: $data');
            return;
          }
          source.sink.add(chartData);
        },
      );
    });
    _ticksCancellation = invokeOnce(() {
      fut.ignore();
      streamListen.cancel();
      canceled = true;
      ticksCancellation?.call();
    });
  }

  StreamSubscription<ChartData> _requestLastCandle(
    StreamController<ChartData> source,
    XTBApiConnector connector,
    ChartPeriod period,
    String symbol,
    bool canceled,
  ) {
    var requestId = 0;
    var recentReceivedId = requestId;
    final streamListen = source.stream
        .throttleTime(
      const Duration(milliseconds: 500),
      leading: true,
      trailing: true,
    )
        .listen((chartData) {
      final myId = ++requestId;
      var start =
          (DateTime.now().millisecondsSinceEpoch / period.valueInMs).ceil() *
              period.valueInMs;
      connector
          .getChartLastRequest(
        params: ChartRequest(
          period: period,
          start: start,
          symbol: symbol,
        ),
      )
          .then((recentChartData) {
        if (canceled ||
            recentReceivedId > myId ||
            recentChartData.rateInfos.isEmpty) {
          return;
        }
        _updateChartData(recentChartData, chartData);
        recentReceivedId = myId;
      });
    });
    return streamListen;
  }

  void _updateChartData(ChartData newData, ChartData chartData) {
    final candle = newData.rateInfos.last;
    var update = _paddingManager.updateChartData(
      chartData.rateInfos,
      candle,
      widget.period,
    );
    _seriesController?.updateDataSource(
      updatedDataIndexes: update.updated,
      addedDataIndexes: update.added,
    );
  }

  Future<ChartData> _fetchData() {
    final connector = Provider.of<XTBApiConnector>(context, listen: false);
    var currentPeriod = widget.period;
    var currentSymbol = widget.symbol.symbol;
    final end = DateTime.now().subtract(
        Duration(minutes: currentPeriod.value * _currentPeriodOffset));
    final start =
        end.subtract(Duration(minutes: currentPeriod.value * FETCH_PERIODS));
    _currentPeriodOffset += FETCH_PERIODS;
    return connector.getChartRangeRequest(
      params: ChartRangeRequest(
        end: end.millisecondsSinceEpoch,
        start: start.millisecondsSinceEpoch,
        period: currentPeriod,
        symbol: currentSymbol,
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
          _isLoadMoreView = true;
          var data = snapshot.data!.rateInfos;
          return _defineChart(data);
        } else if (snapshot.hasError) {
          logInfo(
            'CHART ERROR [${widget.symbol.symbol} ${widget.period.tag}] ${snapshot.error}',
          );
          if (snapshot.error is ErrorData) {
            return Text((snapshot.error as ErrorData).errorDescr);
          } else {
            return Text('${snapshot.stackTrace}');
          }
        }
        // By default, show a loading spinner.
        return const CircularProgressIndicator();
      },
    );
  }

  SfCartesianChart _defineChart(List<CandleData> data) {
    return SfCartesianChart(
      // loadMoreIndicatorBuilder: _buildLoadMoreIndicatorView,
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
        args.visibleMin = _oldAxisVisibleMin!;
        args.visibleMax = _oldAxisVisibleMax!;
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

  ChartAxis _defineXAxis(List<CandleData> data) {
    return DateTimeCategoryAxis(
      dateFormat: _getDateFormat(),
      majorGridLines: const MajorGridLines(width: 0),
      intervalType: DateTimeIntervalType.auto,
    );
  }

  CandleSeries<CandleData, DateTime> _initializeCandleSerie(
    List<CandleData> data,
  ) {
    return CandleSeries<CandleData, DateTime>(
      enableSolidCandles: true,
      dataSource: data,
      onRendererCreated: (ChartSeriesController controller) {
        _seriesController = controller;
      },
      xValueMapper: (CandleData data, _) =>
          DateTime.fromMillisecondsSinceEpoch(data.ctm),
      lowValueMapper: (CandleData data, _) =>
          _paddingManager.isPadding(data) ? null : data.low,
      highValueMapper: (CandleData data, _) =>
          _paddingManager.isPadding(data) ? null : data.high,
      openValueMapper: (CandleData data, _) =>
          _paddingManager.isPadding(data) ? null : data.open,
      closeValueMapper: (CandleData data, _) =>
          _paddingManager.isPadding(data) ? null : data.close,
    );
  }

  DateFormat _getDateFormat() {
    if (widget.period.value < ChartPeriod.H1.value) {
      return DateFormat('HH:mm');
    } else if (widget.period.value < ChartPeriod.D1.value) {
      return DateFormat('dd.MM HH:mm');
    } else {
      return DateFormat('dd.MM.yyyy');
    }
  }

  Widget _buildLoadMoreIndicatorView(
      BuildContext context, ChartSwipeDirection direction) {
    // To know whether reaches the end of the chart
    logInfo('CHART BUILD MORE $direction');
    if (direction == ChartSwipeDirection.start) {
      _isNeedToUpdateView = true;
      _globalKey = GlobalKey<State>();
      return StatefulBuilder(
        key: _globalKey,
        builder: (BuildContext context, StateSetter stateSetter) {
          Widget widget;
          if (_isNeedToUpdateView) {
            widget = const CircularProgressIndicator();
            _fetchMoreData();
          } else {
            widget = Container();
          }
          return widget;
        },
      );
    } else {
      return SizedBox.fromSize(size: Size.zero);
    }
  }

  void _fetchMoreData() {
    _chartData.then(
      (oldData) => _fetchData().catchError((err) {
        if (err is ErrorData && err.errorCode == ErrorData.NO_MORE_DATA_ERR) {
          logInfo('NO MORE CHART DATA');
          return oldData;
        }
        throw err;
      }).then(
        (newData) {
          oldData.rateInfos.insertAll(0, newData.rateInfos);
          _seriesController?.updateDataSource(
            addedDataIndexes: List<int>.generate(
              newData.rateInfos.length,
              (index) => index,
            ),
          );
          logInfo('new data arrived: ${oldData.rateInfos.length}');
          _isLoadMoreView = true;
          _isNeedToUpdateView = false;
          if (_globalKey.currentState != null) {
            (_globalKey.currentState as dynamic).setState(() {});
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _seriesController = null;
    _ticksCancellation?.call();
    super.dispose();
  }
}
