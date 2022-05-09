import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:stocker/xtb/connector.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

class SymbolsSource {
  final BuildContext _ctx;
  final _symbols = BehaviorSubject<List<SymbolData>>();
  Future<List<SymbolData>>? _currentSymbols;

  SymbolsSource(this._ctx);

  Stream<List<SymbolData>> get symbols => _symbols;

  void fetch() {
    _currentSymbols?.ignore();
    var currentStream =
        Provider.of<XTBApiConnector>(_ctx, listen: false).getAllSymbols();
    _currentSymbols = currentStream;
    _symbols.addStream(currentStream.asStream());
  }

  void dispose() {
    _currentSymbols?.ignore();
    _symbols.close();
  }
}
