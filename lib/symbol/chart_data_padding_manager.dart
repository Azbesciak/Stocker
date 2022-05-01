import 'package:stocker/xtb/model/candle_data.dart';
import 'package:stocker/xtb/model/chart_period.dart';

class ChartUpdateInfo {
  final List<int>? updated;
  final List<int>? added;

  ChartUpdateInfo({this.updated, this.added});
}

class _ChartDataPaddingData {
  final int existingCandleIndex;
  final int lastPaddingIndex;

  const _ChartDataPaddingData({
    required this.existingCandleIndex,
    required this.lastPaddingIndex,
  });
}

class _NoPaddingError extends Error {
  final List<CandleData> data;

  _NoPaddingError({
    required this.data,
  });
}

class ChartDataPaddingManager {
  final int paddingCandles;

  static const double _UNKNOWN_VALUE = double.nan;

  ChartDataPaddingManager({required this.paddingCandles});

  void addPadding(
    List<CandleData> data,
    ChartPeriod period,
  ) {
    if (data.isEmpty) return;
    var latestTime = data.last.ctm;
    var mockCandles = List.generate(
      paddingCandles,
      (i) => _generateMockCandle(latestTime + (i + 1) * period.valueInMs),
    );
    data.addAll(mockCandles);
  }

  ChartUpdateInfo updateChartData(
    List<CandleData> chartData,
    CandleData candle,
    ChartPeriod period,
  ) {
    if (chartData.isEmpty) {
      return _fillChartDataWhenEmpty(chartData, candle, period);
    }
    var indices = _searchData(chartData, candle);
    return _updateWithExistingCandle(
      chartData,
      indices,
      candle,
      period,
    );
  }

  _ChartDataPaddingData _searchData(
    List<CandleData> chartData,
    CandleData candle,
  ) {
    var existingCandleIndex = -1;
    var lastPaddingIndex = -1;
    for (var i = chartData.length - 1; i >= 0; --i) {
      var item = chartData[i];
      if (item.ctm == candle.ctm) {
        existingCandleIndex = i;
      }
      if (isPadding(item)) {
        lastPaddingIndex = i;
      } else {
        break;
      }
    }
    if (lastPaddingIndex == -1) {
      throw _NoPaddingError(data: chartData);
    }
    return _ChartDataPaddingData(
      existingCandleIndex: existingCandleIndex,
      lastPaddingIndex: lastPaddingIndex,
    );
  }

  ChartUpdateInfo _updateWithExistingCandle(
    List<CandleData> chartData,
    _ChartDataPaddingData indices,
    CandleData candle,
    ChartPeriod period,
  ) {
    if (indices.existingCandleIndex >= 0 &&
        indices.existingCandleIndex == indices.lastPaddingIndex) {
      chartData[indices.existingCandleIndex] = candle;
      chartData.add(_generateMockCandle(chartData.last.ctm + period.valueInMs));
      return ChartUpdateInfo(
        updated: [indices.existingCandleIndex],
        added: [chartData.length - 1],
      );
    } else if (indices.existingCandleIndex >= 0 &&
        indices.existingCandleIndex < indices.lastPaddingIndex) {
      chartData[indices.existingCandleIndex] = candle;
      return ChartUpdateInfo(
        updated: [indices.existingCandleIndex],
      );
    } else {
      return _overridePadding(chartData, indices, candle, period);
    }
  }

  ChartUpdateInfo _overridePadding(
    List<CandleData> chartData,
    _ChartDataPaddingData indices,
    CandleData candle,
    ChartPeriod period,
  ) {
    var lastIndex = chartData.length - 1;
    if (indices.lastPaddingIndex != -1) {
      chartData.removeRange(indices.lastPaddingIndex, chartData.length);
    }
    chartData.add(candle);
    addPadding(chartData, period);
    var lenDif = chartData.length - 1 - lastIndex;
    return ChartUpdateInfo(
      added: lenDif > 0 ? _generateIndices(lenDif, lastIndex + 1) : null,
      updated: _generateIndices(
        lastIndex - indices.lastPaddingIndex + 1,
        indices.lastPaddingIndex,
      ),
    );
  }

  List<int> _generateIndices(int lenDif, [int offset = 0]) =>
      List.generate(lenDif, (i) => offset + i);

  ChartUpdateInfo _fillChartDataWhenEmpty(
    List<CandleData> chartData,
    CandleData candle,
    ChartPeriod period,
  ) {
    chartData.add(candle);
    addPadding(chartData, period);
    return ChartUpdateInfo(
      added: _generateIndices(paddingCandles + 1),
    );
  }

  int _findIndexOfClosestToDataPadding(List<CandleData> chartData) {
    var indexOfFirst = -1;
    for (var i = chartData.length - 1; i > 0; --i) {
      if (!isPadding(chartData[i])) break;
      indexOfFirst = i;
    }
    return indexOfFirst;
  }

  CandleData _generateMockCandle(int time) => CandleData(
        close: _UNKNOWN_VALUE,
        high: _UNKNOWN_VALUE,
        low: _UNKNOWN_VALUE,
        open: _UNKNOWN_VALUE,
        ctm: time,
        vol: _UNKNOWN_VALUE,
      );

  bool isPadding(CandleData candle) => candle.low.isNaN;
}
