import 'package:flutter/material.dart';
import 'package:stocker/symbol/symbol_page.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

@immutable
class SymbolListItemWidget extends StatelessWidget {
  final SymbolData symbol;
  final bool isFavourite;

  final Function() toggleFavourite;

  const SymbolListItemWidget({
    super.key,
    required this.symbol,
    required this.isFavourite,
    required this.toggleFavourite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(symbol.symbol),
        trailing: IconButton(
          icon: isFavourite
              ? Icon(
                  Icons.done,
                  color: Colors.green,
                )
              : Icon(Icons.add_circle_outline),
          onPressed: toggleFavourite,
        ),
        onTap: () => SymbolPage.goTo(context, symbol),
        title: Text(symbol.description),
      ),
    );
  }
}
