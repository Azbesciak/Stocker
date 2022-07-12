import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';
import 'package:provider/provider.dart';
import 'package:stocker/favourites/favourites_list_item.dart';
import 'package:stocker/favourites/favourites_store.dart';
import 'package:stocker/xtb/connector.dart';

class FavouritesList extends StatelessWidget {
  final String group;

  const FavouritesList({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final connector = Provider.of<XTBApiConnector>(context, listen: false);
    final favourites = Provider.of<FavouritesStore>(context, listen: false);
    return StreamBuilder<List<String>>(
      stream: favourites.watchGroup$(group),
      builder: (ctx, snap) {
        if (snap.hasError) {
          logError('error', snap.error);
          return Text('error occurred: ${snap.error}');
        }
        if (!snap.hasData || snap.data == null) {
          return CircularProgressIndicator();
        }
        return ListView.builder(
          itemBuilder: (context, index) => FavouritesListItemWidget(
            connector: connector,
            symbol: snap.data![index],
          ),
          itemCount: snap.data!.length,
        );
      },
    );
  }
}
