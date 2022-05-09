import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocker/symbols_list/filter_data.dart';
import 'package:stocker/symbols_list/filtered_symbols_source.dart';
import 'package:stocker/symbols_list/symbol_list_item.dart';
import 'package:stocker/xtb/model/symbol_data.dart';

class SymbolsList extends StatefulWidget {
  const SymbolsList({Key? key}) : super(key: key);

  @override
  State<SymbolsList> createState() => _SymbolsListState();
}

class _SymbolsListState extends State<SymbolsList> {
  final Map<String, bool> _expansions = HashMap();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FilteredData?>(
      stream:
          Provider.of<FilteredSymbolsSource>(context, listen: false).filtered$,
      initialData: null,
      builder: (ctx, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          var data = snapshot.data!;
          Widget _itemBuilder(
            BuildContext context,
            int index,
            List<SymbolData> items,
          ) {
            return SymbolListItemWidget(symbol: items[index]);
          }

          Widget _headerBuilder(
            BuildContext context,
            bool isExpanded,
            String key,
          ) {
            _expansions[key] = isExpanded;
            return ListTile(title: Text(key));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: ExpansionPanelList(
              expandedHeaderPadding: EdgeInsets.zero,
              elevation: 4,
              expansionCallback: (i, expanded) {
                setState(() {
                  _expansions[data.keys[i]] = !expanded;
                });
              },
              children: [
                ...data.keys.map((e) {
                  var group = data.groups[e]!;
                  var maxHeight = MediaQuery.of(context).size.height / 3 * 2;
                  var groupExpanded = _expansions[e] == true;
                  return ExpansionPanel(
                    isExpanded: groupExpanded,
                    canTapOnHeader: true,
                    headerBuilder: (ctx, expanded) =>
                        _headerBuilder(context, expanded, e),
                    body: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: maxHeight,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemBuilder: (ctx, i) => _itemBuilder(ctx, i, group),
                        itemCount: groupExpanded ? group.length : 0,
                      ),
                    ),
                  );
                })
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Align(
            child: Text('${snapshot.stackTrace}'),
            alignment: Alignment.center,
          );
        }

        // By default, show a loading spinner.
        return Align(
          child: const CircularProgressIndicator(),
          alignment: Alignment.center,
        );
      },
    );
  }
}
