import 'package:flutter/material.dart';
import 'package:intl/src/intl/number_format.dart';
import 'package:stocker/utils.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

const _BOX_SIZE = 100.0;
const _PADDING_SIZE = 20.0;
const _MAIN_TEXT_SIZE = 15.0;
const _MINOR_TEXT_SIZE = 10.0;

class SymbolPriceWidget extends StatelessWidget {
  final SymbolData symbol;

  const SymbolPriceWidget({Key? key, required this.symbol}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final format = getPriceFormat(symbol.precision);
    final subColor = Theme.of(context).textTheme.caption?.color;
    return Container(
      width: 2 * _BOX_SIZE + _PADDING_SIZE,
      alignment: Alignment.center,
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getPriceBox(
                value: symbol.bid,
                format: format,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: _MAIN_TEXT_SIZE,
                  fontWeight: FontWeight.bold,
                ),
              ),
              getPriceBox(
                value: symbol.low,
                format: format,
                style: TextStyle(
                  fontSize: _MINOR_TEXT_SIZE,
                  color: subColor,
                ),
                prefix: 'Min: ',
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getPriceBox(
                value: symbol.ask,
                format: format,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: _MAIN_TEXT_SIZE,
                  fontWeight: FontWeight.bold,
                ),
              ),
              getPriceBox(
                value: symbol.high,
                format: format,
                style: TextStyle(
                  fontSize: _MINOR_TEXT_SIZE,
                  color: subColor,
                ),
                prefix: 'Min: ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  SizedBox getPriceBox({
    required double value,
    required NumberFormat format,
    required TextStyle style,
    String? prefix,
  }) {
    var formattedValue = format.format(value);
    return SizedBox(
      width: _BOX_SIZE,
      child: Text(
        prefix == null ? formattedValue : '${prefix}${formattedValue}',
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}
