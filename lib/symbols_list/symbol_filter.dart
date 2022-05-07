import 'package:flutter/material.dart';
import 'package:stocker/ui_style.dart';

class SymbolFilter extends StatelessWidget {
  final void Function(String v) onInputChange;

  const SymbolFilter({
    Key? key,
    required this.onInputChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(UIStyle.contentMarginSmall),
        child: TextField(
          onChanged: onInputChange,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Query',
          ),
        ),
      ),
    );
  }
}
