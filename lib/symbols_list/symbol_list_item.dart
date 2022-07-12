import 'package:flutter/material.dart';
import 'package:stocker/symbol/symbol_page.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

@immutable
class SymbolListItemWidget extends StatelessWidget {
  final SymbolData symbol;

  const SymbolListItemWidget({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(symbol.symbol),
        onTap: () => SymbolPage.goTo(context, symbol),
        title: Text(symbol.description),
      ),
    );
  }
}
