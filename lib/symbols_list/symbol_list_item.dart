import 'package:flutter/material.dart';
import 'package:stocker/symbol/symbol_page.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

@immutable
class SymbolListItemWidget extends StatelessWidget {
  final SymbolData symbol;

  const SymbolListItemWidget({Key? key, required this.symbol})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(symbol.symbol),
        onTap: () {
          Navigator.pushNamed(
            context,
            SymbolPage.navRoute,
            arguments: {'symbol': symbol},
          );
        },
        title: Text(symbol.description),
      ),
    );
  }
}
