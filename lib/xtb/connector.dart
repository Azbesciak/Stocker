import 'dart:async';
import 'dart:convert';
import 'dart:developer';

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
import 'model/symbol_data.dart';
import 'model/ticks.dart';
// http://developers.xstore.pro/documentation/

typedef Cancellation = void Function();

extension XTBResponseExtension on JsonObj {
  bool get status => this["status"] == true;
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
  final String appName;
  late WebSocketChannel _channel;
  final Map<String, XTBApiSub> _streamSubs = {};
  int _outgoingRequestId = 0;

  XTBApiConnector({required this.url, required this.appName});

  void init() {
    _channel = WebSocketChannel.connect(
      Uri.parse(url),
    );
    _channel.stream.listen((event) {
      var parsedResponse = jsonDecode(event);
      final String responseId = parsedResponse["customTag"];
      final sub = _streamSubs[responseId];
      log("RESPONSE [$responseId]: $event");
      if (sub != null) {
        sub.callback(parsedResponse);
        if (sub.cancellation == null) {
          _streamSubs.remove(responseId);
        }
      }
    });
  }

  void _executeCommandNoResponse(
      {required String command, JsonObj? inlineArgs}) {
    JsonObj request = {"command": String};
    if (inlineArgs != null) {
      request.addAll(inlineArgs);
    }
    _channel.sink.add(jsonEncode(request));
  }

  void dispose() {
    _streamSubs.clear();
    _executeCommandNoResponse(command: "logout");
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
    log("REQUEST [$id]: $command arguments: $arguments, inline: $inlineArgs");
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
      onResult: (res) => {
        if (res.status)
          {completer.complete(mapper(res))}
        else
          {completer.completeError(ErrorData.fromMap(res))}
      },
    );
    return completer.future;
  }

  Cancellation _executeStreamCommand({
    required String subscribeCommand,
    required String unsubscribeCommand,
    required Callback<JsonObj> callback,
    JsonObj? inlineArgs,
  }) {
    String id = "";
    void cancellation() {
      if (_streamSubs.remove(id) != null) {
        _executeCommandNoResponse(
            command: unsubscribeCommand, inlineArgs: inlineArgs);
      }
    }

    id = _executeCommand(
      command: subscribeCommand,
      inlineArgs: inlineArgs,
      onResult: callback,
      cancellation: cancellation,
    );
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
    );
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

  Future<List<TradingHoursData>> getTradingHours(
      {required List<String> symbols}) {
    return _executeFutureCommand(
      command: "getTradingHours",
      mapper: returnDataMapper(arrayDataMapper(TradingHoursData.fromMap)),
      arguments: {"symbols": symbols},
    );
  }

  Cancellation getCandles({
    required String symbol,
    required Callback<CandleData> callback,
  }) {
    return _executeStreamCommand(
      subscribeCommand: "getCandles",
      unsubscribeCommand: "stopCandles",
      callback: (res) => callback(CandleData.fromMap(res)),
    );
  }

  Cancellation getNews({
    required Callback<NewsData> callback,
  }) {
    return _executeStreamCommand(
      subscribeCommand: "getNews",
      unsubscribeCommand: "stopNews",
      callback: (res) => callback(NewsData.fromMap(res)),
    );
  }

  Cancellation getTickPrices({
    required String symbol,
    required Callback<TicksData> callback,
  }) {
    return _executeStreamCommand(
      subscribeCommand: "getTickPrices",
      unsubscribeCommand: "stopTickPrices",
      inlineArgs: {"symbol": symbol},
      callback: (res) => callback(TicksData.fromMap(res)),
    );
  }
}