import 'package:stocker/xtb/model/symbol_data.dart';

class FilteredData {
  final List<SymbolData> original;
  final String filter;
  final List<String> keys;
  final Map<String, List<SymbolData>> groups;

  const FilteredData({
    required this.original,
    required this.filter,
    required this.keys,
    required this.groups,
  });
}
