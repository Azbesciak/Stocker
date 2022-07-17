import 'package:flutter/material.dart';
import 'package:stocker/favourites/symbol_price.dart';
import 'package:stocker/symbol/symbol_page.dart';
import 'package:stocker/xtb/connector.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

class FavouritesListItemWidget extends StatelessWidget {
  final String symbol;
  final XTBApiConnector connector;

  const FavouritesListItemWidget({
    Key? key,
    required this.symbol,
    required this.connector,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SymbolData>(
      future: connector.getSymbol(symbol: symbol),
      builder: (ctx, sna) {
        return SizedBox(
          child: ListTile(
            title: Text(symbol),
            trailing: !sna.hasData && !sna.hasError
                ? CircularProgressIndicator()
                : sna.hasData
                    ? SymbolPriceWidget(symbol: sna.data!)
                    : Text('error: ${sna.error}'),
            onTap: () {
              if (sna.hasData) {
                SymbolPage.goTo(context, sna.data!);
              }
            },
          ),
        );
      },
    );
    ;
  }
}
