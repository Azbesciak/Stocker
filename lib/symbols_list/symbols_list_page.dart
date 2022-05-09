import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocker/symbols_list/filtered_symbols_source.dart';
import 'package:stocker/symbols_list/symbol_filter.dart';
import 'package:stocker/symbols_list/symbols_list.dart';

class SymbolsListPage extends StatelessWidget {
  static const navRoute = '/';

  const SymbolsListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FilteredSymbolsSource>(
          create: (ctx) => FilteredSymbolsSource(ctx),
        )
      ],
      child: Scaffold(
        body: Center(
          child: Stack(
            children: [
              SymbolsList(),
              Align(
                alignment: Alignment.bottomCenter,
                child: SymbolFilter(
                  onInputChange: (v) => _updateFilterValue(context, v),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _updateFilterValue(BuildContext context, String v) {
    Provider.of<FilteredSymbolsSource>(context, listen: false).filterValue = v;
  }
}
