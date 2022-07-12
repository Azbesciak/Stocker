import 'package:flutter/material.dart';
import 'package:intl/src/intl/number_format.dart';
import 'package:stocker/utils.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

const _BOX_SIZE = 100.0;
const _PADDING_SIZE = 20.0;

class SymbolPriceWidget extends StatelessWidget {
  final SymbolData symbol;

  const SymbolPriceWidget({Key? key, required this.symbol}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final format = getPriceFormat(symbol.precision);
    return Container(
      width: _BOX_SIZE * 2 + _PADDING_SIZE,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          getPriceBox(symbol.bid, format),
          getPriceBox(symbol.ask, format),
        ],
      ),
    );
    return Container();
  }

  SizedBox getPriceBox(double value, NumberFormat format) {
    return SizedBox(
      width: _BOX_SIZE,
      child: Text(
        format.format(value),
        textAlign: TextAlign.center,
      ),
    );
  }
}
