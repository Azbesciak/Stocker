import 'dart:async';
import 'dart:convert';

import 'package:loggy/loggy.dart';
import 'package:stocker/xtb/model/calendar_data.dart';
import 'package:stocker/xtb/model/chart_data.dart';
import 'package:stocker/xtb/model/chart_request.dart';
import 'package:stocker/xtb/model/credentials.dart';
import 'package:stocker/xtb/model/trading_hours_data.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'json_helper.dart';
import 'model/candle_data.dart';
import 'model/error_data.dart';
import 'model/news_data.dart';
import 'model/result.dart';
import 'model/symbol_data.dart';
import 'model/ticks.dart';
// http://developers.xstore.pro/documentation/

typedef Cancellation = void Function();

Cancellation invokeOnce(Cancellation cancellation) {
  var invoked = false;
  return () {
    if (invoked) {
      return;
    }
    invoked = true;
    cancellation();
  };
}

extension XTBResponseExtension on JsonObj {
  bool get status => this["status"] != false;
}

typedef Callback<T> = void Function(T result);
typedef XTBResponseCallback = Callback<JsonObj>;

class XTBApiSub {
  final XTBResponseCallback callback;
  final Cancellation? cancellation;

  XTBApiSub({required this.callback, this.cancellation});
}

class XTBApiConnector {
  final String url;
  final String streamUrl;
  final String appName;
  late WebSocketChannel _channel;
  final Map<String, XTBApiSub> _streamSubs = {};
  int _outgoingRequestId = 0;
  String? _currentSessionId;
  final Map<int, Cancellation> _streamCancellations = {};


  XTBApiConnector({required this.url, required this.streamUrl, required this.appName});

  void init() {
    _channel = _spawnNewChannel(url);
    _channel.stream.listen((event) {
      var parsedResponse = jsonDecode(event);
      final String responseId = parsedResponse["customTag"];
      final sub = _streamSubs[responseId];
      logInfo("RES [$responseId]: ${trimIfTooLong(event)}");
      if (sub != null) {
        sub.callback(parsedResponse);
        if (sub.cancellation == null) {
          _streamSubs.remove(responseId);
        }
      }
    });
  }

  WebSocketChannel _spawnNewChannel(String url) {
    return WebSocketChannel.connect(
      Uri.parse(url),
    );
  }

  void _executeCommandNoResponse({
    required String command,
    required WebSocketChannel channel,
    JsonObj? inlineArgs,
  }) {
    JsonObj request = {"command": String};
    if (inlineArgs != null) {
      request.addAll(inlineArgs);
    }
    channel.sink.add(jsonEncode(request));
  }

  void dispose() {
    _streamSubs.clear();
    _currentSessionId = null;
    for (final element in _streamCancellations.entries.toList()) {
      element.value();
    }
    _executeCommandNoResponse(command: "logout", channel: _channel);
    _channel.sink.close();
  }

  String _executeCommand({
    required String command,
    required XTBResponseCallback onResult,
    Cancellation? cancellation,
    JsonObj? arguments,
    JsonObj? inlineArgs,
  }) {
    final id = (++_outgoingRequestId).toString();
    JsonObj request = {"command": command, "customTag": id};
    if (arguments != null) {
      request["arguments"] = arguments;
    }
    if (inlineArgs != null) {
      request.addAll(inlineArgs);
    }
    logInfo("REQ [$id]: $command arguments: $arguments, inline: $inlineArgs");
    _streamSubs[id] = XTBApiSub(callback: onResult, cancellation: cancellation);
    _channel.sink.add(jsonEncode(request));
    return id;
  }

  Future<T> _executeFutureCommand<T>({
    required String command,
    required Mapper<JsonObj, T> mapper,
    JsonObj? arguments,
  }) {
    final completer = Completer<T>();
    _executeCommand(
      command: command,
      arguments: arguments,
      onResult: (res) {
        if (res.status) {
          completer.complete(mapper(res));
        } else {
          completer.completeError(ErrorData.fromMap(res));
        }
      },
    );
    return completer.future;
  }

  Cancellation _executeStreamCommand<T>({
    required String subscribeCommand,
    required String unsubscribeCommand,
    required Mapper<JsonObj, T> mapper,
    required Callback<Result<T>> onResult,
    JsonObj? inlineArgs,
  }) {
    final channel = _spawnNewChannel(streamUrl);
    channel.stream.listen((res) {
      logInfo("RES [$subscribeCommand]: $res");
      final result = jsonDecode(res) as JsonObj;
      if (result.status) {
        onResult(Result.success(value: mapper(result["data"])));
      } else {
        onResult(Result.failure(error: ErrorData.fromMap(result)));
      }
    });
    final id = ++_outgoingRequestId;
    final cancellation = invokeOnce(() {
      _streamCancellations.remove(id);
      channel.sink.close();
    });
    _streamCancellations[id] = cancellation;

    JsonObj request = {
      "streamSessionId": _currentSessionId,
      "command": subscribeCommand,
    };
    if (inlineArgs != null) {
      request.addAll(inlineArgs);
    }
    var encoded = jsonEncode(request);
    logInfo("REQ [$subscribeCommand]: $encoded");
    channel.sink.add(encoded);
    return cancellation;
  }

  Future<JsonObj> login(Credentials credentials) {
    return _executeFutureCommand(
      command: "login",
      mapper: identityMapper,
      arguments: {
        "userId": credentials.userId,
        "password": credentials.password,
        "appName": appName,
      },
    ).then((value) {
      _currentSessionId = value["streamSessionId"];
      return value;
    });
  }

  Future<List<SymbolData>> getAllSymbols() {
    return _executeFutureCommand(
        command: "getAllSymbols",
        mapper: returnDataMapper(arrayDataMapper(SymbolData.fromMap)));
  }

  Future<JsonObj> getCurrentUserData() {
    return _executeFutureCommand(
      command: "getCurrentUserData",
      mapper: identityMapper,
    );
  }

  Future<List<JsonObj>> getTrades({bool openedOnly = true}) {
    return _executeFutureCommand(
      command: "getTrades",
      mapper: returnDataMapper(arrayDataMapper(identityMapper)),
      arguments: {"openedOnly": openedOnly},
    );
  }

  Future<List<CalendarData>> getCalendar() {
    return _executeFutureCommand(
      command: "getCalendar",
      mapper: returnDataMapper(arrayDataMapper(CalendarData.fromMap)),
    );
  }

  Future<ChartData> getChartRangeRequest({required ChartRequest params}) {
    return _executeFutureCommand(
      command: "getChartRangeRequest",
      arguments: {'info': params.toMap()},
      mapper: returnDataMapper(ChartData.fromMap),
    );
  }

  Future<List<TradingHoursData>> getTradingHours({
    required List<String> symbols,
  }) {
    return _executeFutureCommand(
      command: "getTradingHours",
      mapper: returnDataMapper(arrayDataMapper(TradingHoursData.fromMap)),
      arguments: {"symbols": symbols},
    );
  }

  Cancellation getCandles({
    required String symbol,
    required Callback<Result<CandleData>> onResult,
  }) {
    return _executeStreamCommand(
      subscribeCommand: "getCandles",
      unsubscribeCommand: "stopCandles",
      onResult: onResult,
      mapper: CandleData.fromMap,
    );
  }

  Cancellation getNews({
    required Callback<Result<NewsData>> onResult,
  }) {
    return _executeStreamCommand(
      subscribeCommand: "getNews",
      unsubscribeCommand: "stopNews",
      onResult: onResult,
      mapper: NewsData.fromMap,
    );
  }

  Cancellation getTickPrices({
    required String symbol,
    required Callback<Result<TicksData>> onResult,
  }) {
    return _executeStreamCommand(
      subscribeCommand: "getTickPrices",
      unsubscribeCommand: "stopTickPrices",
      inlineArgs: {"symbol": symbol},
      onResult: onResult,
      mapper: TicksData.fromMap,
    );
  }
}
