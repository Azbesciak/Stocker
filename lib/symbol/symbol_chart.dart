import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loggy/loggy.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stocker/symbol/chart_data_padding_manager.dart';
import 'package:stocker/utils.dart';
import 'package:stocker/xtb/connector.dart';
import 'package:stocker/xtb/model/candle_data.dart';
import 'package:stocker/xtb/model/chart_data.dart';
import 'package:stocker/xtb/model/chart_period.dart';
import 'package:stocker/xtb/model/chart_range_request.dart';
import 'package:stocker/xtb/model/chart_request.dart';
import 'package:stocker/xtb/model/error_data.dart';
import 'package:stocker/xtb/model/symbol_data.dart';
import 'package:stocker/xtb/model/ticks.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SymbolChartWidget extends StatefulWidget {
  final SymbolData symbol;
  final ChartPeriod period;

  const SymbolChartWidget({
    super.key,
    required this.symbol,
    required this.period,
  });

  @override
  State<SymbolChartWidget> createState() => _SymbolChartWidgetState();
}

// https://www.syncfusion.com/kb/12535/how-to-lazily-load-more-data-to-the-chart-sfcartesianchart
class _SymbolChartWidgetState extends State<SymbolChartWidget> {
  static const FETCH_PERIODS = 300;
  static const CHART_PADDING = 10;
  static const ANNOTATION_HEIGHT = 20.0;
  static const ANNOTATION_TEXT_SIZE = 12.0;
  static const ANNOTATION_VERT_PADDING =
      (ANNOTATION_HEIGHT - ANNOTATION_TEXT_SIZE) / 2;
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
  late NumberFormat _numberFormat;
  late ChartDataPaddingManager _paddingManager;
  List<CartesianChartAnnotation> _annotations = [];
  List<PlotBand> _plotBands = [];

  StreamController<TicksData> _ticksData$ = StreamController.broadcast();
  StreamController<ActualRangeChangedArgs> _verticalAxis$ =
      StreamController.broadcast();
  StreamSubscription? _priceAnnotationsSub = null;

  @override
  void didUpdateWidget(covariant SymbolChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.symbol != widget.symbol) {
      setState(() {
        if (oldWidget.symbol.precision != widget.symbol.precision) {
          _numberFormat = _getNumberFormat();
        }
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
    _numberFormat = _getNumberFormat();
    _initializeAskBid();
    _priceAnnotationsSub = _updatePriceAnnotations();
    _fetchNewData();
    _updateRecentData();
  }

  Future<dynamic> _initializeAskBid() {
    return _ticksData$.addStream(
      _provideApiConnector()
          .getTickPrices(
            symbols: [widget.symbol.symbol],
            referenceTimestamp: widget.symbol.time,
          )
          .asStream()
          .onErrorReturn([])
          .mapNotNull((p0) => p0.isNotEmpty ? p0.first : null),
    );
  }

  StreamSubscription<Null> _updatePriceAnnotations() {
    return CombineLatestStream([
      _throttleStream(source: _ticksData$),
      _throttleStream(source: _verticalAxis$),
    ], (params) {
      _updateLastPriceIndicator(
        params[0] as TicksData,
        params[1] as ActualRangeChangedArgs,
      );
    }).listen((value) {});
  }

  void _updateRecentData() {
    final connector = _provideApiConnector();
    _ticksCancellation?.call();
    var canceled = false;
    final candleSource = StreamController<ChartData>.broadcast();

    var period = widget.period;
    var symbol = widget.symbol.symbol;
    final streamListen =
        _requestLastCandle(candleSource, connector, period, symbol, canceled);
    Cancellation? ticksCancellation;
    final fut = _chartData.then((chartData) {
      if (canceled) {
        return;
      }

      ticksCancellation = connector.getTickPrices$(
        symbol: symbol,
        onResult: (data) {
          if (!data.isSuccess()) {
            logError('ERROR [$symbol]: $data');
            return;
          }
          if (data.value != null) {
            _ticksData$.sink.add(data.value!);
          }
          candleSource.sink.add(chartData);
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

  XTBApiConnector _provideApiConnector() =>
      Provider.of<XTBApiConnector>(context, listen: false);

  void _updateLastPriceIndicator(TicksData data, ActualRangeChangedArgs args) {
    setState(() {
      _plotBands.clear();
      _plotBands.addAll([
        plotBand(data.ask, Colors.green),
        plotBand(data.bid, Colors.red),
      ]);
      _annotations.clear();
      _annotations.addAll([
        priceAnnotation(data.bid, Colors.red, Colors.white, args),
        priceAnnotation(data.ask, Colors.green, Colors.white, args),
      ]);
    });
  }

  PlotBand plotBand(double price, Color color) {
    return PlotBand(
      start: price,
      end: price,
      borderWidth: 1,
      borderColor: color,
    );
  }

  CartesianChartAnnotation priceAnnotation(
    double price,
    Color color,
    Color textColor,
    ActualRangeChangedArgs args,
  ) {
    var priceDiff = args.actualMax - args.actualMin;
    final height = _calculatePriceAnnotationPosition(price, args, priceDiff);

    return CartesianChartAnnotation(
      region: AnnotationRegion.plotArea,
      coordinateUnit: CoordinateUnit.percentage,
      x: '100%',
      y: '${(1 - height) * 100}%',
      horizontalAlignment: ChartAlignment.near,
      widget: SizedBox(
        height: ANNOTATION_HEIGHT,
        width: 80,
        child: CustomPaint(
          painter: PriceTagPaint(color),
          child: Padding(
            padding: EdgeInsets.only(left: 10, top: ANNOTATION_VERT_PADDING),
            child: Text(
              _numberFormat.format(price),
              style: TextStyle(
                fontSize: ANNOTATION_TEXT_SIZE,
                color: textColor,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  num _calculatePriceAnnotationPosition(
    double price,
    ActualRangeChangedArgs args,
    priceDiff,
  ) {
    return price < args.actualMin
        ? 0
        : price > args.actualMax
            ? 1
            : priceDiff > 0
                ? (price - args.actualMin) / (priceDiff)
                : 0.5;
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
    final streamListen = _throttleStream(source: source).listen((chartData) {
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

  Stream<T> _throttleStream<T>({
    required StreamController<T> source,
    int duration = 500,
  }) =>
      source.stream.throttleTime(
        Duration(milliseconds: duration),
        leading: true,
        trailing: true,
      );

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
    final connector = _provideApiConnector();
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
          return _defineChart(snapshot.data!);
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

  SfCartesianChart _defineChart(ChartData data) {
    return SfCartesianChart(
      // loadMoreIndicatorBuilder: _buildLoadMoreIndicatorView,
      onActualRangeChanged: _onActualRangeChanged,
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      crosshairBehavior: _crosshairBehavior,
      primaryXAxis: _defineXAxis(data.rateInfos),
      primaryYAxis: _defineYAxis(),
      series: <CandleSeries>[_initializeCandleSerie(data.rateInfos)],
      annotations: _annotations,
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
    } else {
      _verticalAxis$.add(args);
    }
  }

  NumericAxis _defineYAxis() {
    return NumericAxis(
      opposedPosition: true,
      rangePadding: ChartRangePadding.additional,
      enableAutoIntervalOnZooming: true,
      anchorRangeToVisiblePoints: false,
      numberFormat: _getNumberFormat(),
      plotBands: _plotBands,
    );
  }

  NumberFormat _getNumberFormat() => getPriceFormat(widget.symbol.precision);

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
    _priceAnnotationsSub?.cancel();
    super.dispose();
  }
}

class PriceTagPaint extends CustomPainter {
  PriceTagPaint(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    Path path = Path();

    path
      ..moveTo(0, size.height * .5)
      ..lineTo(size.width * .13, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * .13, size.height)
      ..lineTo(0, size.height * .5)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
