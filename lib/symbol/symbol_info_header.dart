import 'package:flutter/material.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

class SymbolInfoHeader extends StatelessWidget {
  final SymbolData symbol;
  const SymbolInfoHeader({Key? key, required this.symbol}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                symbol.symbol,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  symbol.categoryName,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          Text(
            symbol.description,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
