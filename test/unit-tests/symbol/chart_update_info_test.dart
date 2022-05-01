import 'package:stocker/symbol/chart_data_padding_manager.dart';
import 'package:stocker/xtb/model/candle_data.dart';
import 'package:stocker/xtb/model/chart_period.dart';
import 'package:test/test.dart';

void main() {
  group('should add n placeholders if data contains l items', () {
    for (var n in [0, 1, 2, 4, 10, 20]) {
      var chartDataPaddingManager = ChartDataPaddingManager(paddingCandles: n);
      for (var l in [1, 2, 5, 10]) {
        test('n = $n, l = $l', () {
          const period = ChartPeriod.D1;
          var data = _generateDummyData(l, period);
          var original = [...data];
          chartDataPaddingManager.addPadding(data, period);
          expect(
            data.length,
            n + l,
            reason: 'items count should be equal to padding + current',
          );
          expect(
            data.sublist(0, original.length),
            original,
            reason: 'data should be appended, original the same',
          );
          expect(
            data
                .sublist(original.length)
                .every(chartDataPaddingManager.isPadding),
            true,
            reason: 'only paddings should be at the end of the list',
          );
        });
      }
    }
  });

  test('for empty input data nothing happens', () {
    var chartDataPaddingManager = ChartDataPaddingManager(paddingCandles: 10);
    List<CandleData> data = [];
    chartDataPaddingManager.addPadding(data, ChartPeriod.D1);
    expect(data.length, 0, reason: 'no padding should be added to empty input');
  });

  test('candle with the same time should be updated', () {
    var padding = 10;
    var mng = ChartDataPaddingManager(paddingCandles: padding);
    var period = ChartPeriod.D1;
    List<CandleData> data = [
      CandleData(open: 1, close: 1, low: 1, high: 1, ctm: 0, vol: 1)
    ];
    mng.addPadding(data, period);
    expect(data.length, padding + 1, reason: 'padding should be added');
    var newCandle =
        CandleData(open: 2, close: 2, low: 2, high: 2, ctm: 0, vol: 2);
    var updateResult = mng.updateChartData(data, newCandle, period);
    expect(data.length, padding + 1, reason: 'padding should be added');
    expect(data.first, newCandle);
    expect(updateResult.added, null, reason: 'no data should be added');
    expect(updateResult.updated, [0]);
  });

  test('candle with the new time should be added and padding updated', () {
    ChartUpdateInfo updateResult =
        _checkOnNewTimeCandle(ChartPeriod.D1, 10, ChartPeriod.D1.valueInMs);
    expect(
      updateResult.updated,
      [1],
    );
  });

  test('candle with the new time should be added for not continuous data', () {
    var padding = 10;
    ChartUpdateInfo updateResult = _checkOnNewTimeCandle(
      ChartPeriod.D1,
      padding,
      ChartPeriod.D1.valueInMs * 4,
    );
    expect(
      updateResult.updated,
      List.generate(padding, (index) => index + 1),
    );
  });

  test(
      'candle with the new time should be added even if time is after padding, and the old padding should be deleted',
      () {
    var padding = 10;
    ChartUpdateInfo updateResult = _checkOnNewTimeCandle(
      ChartPeriod.D1,
      padding,
      ChartPeriod.D1.valueInMs * 100,
    );
    expect(
      updateResult.updated,
      List.generate(padding, (index) => index + 1),
    );
  });
}

ChartUpdateInfo _checkOnNewTimeCandle(
  ChartPeriod period,
  int padding,
  int newCandleTime,
) {
  var mng = ChartDataPaddingManager(paddingCandles: padding);
  var firstCandle =
      CandleData(open: 1, close: 1, low: 1, high: 1, ctm: 0, vol: 1);
  List<CandleData> data = [firstCandle];
  mng.addPadding(data, period);
  expect(data.length, padding + 1, reason: 'padding should be added');
  var newCandle = CandleData(
    open: 2,
    close: 2,
    low: 2,
    high: 2,
    ctm: newCandleTime,
    vol: 2,
  );
  var updateResult = mng.updateChartData(data, newCandle, period);
  expect(data.length, padding + 2, reason: 'padding should be added');
  expect(data[0], firstCandle, reason: 'first candle should be preserved');
  expect(
    data[1],
    newCandle,
    reason: 'new candle should be added after the initial one',
  );
  expect(
    updateResult.added,
    [data.length - 1],
    reason: 'only one padding candle should be added',
  );
  return updateResult;
}

List<CandleData> _generateDummyData(int l, ChartPeriod period) => List.generate(
      l,
      (index) => CandleData(
        open: 1,
        close: 2,
        low: 0,
        high: 3,
        ctm: index * period.valueInMs,
        vol: 1,
      ),
    );
