import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocker/favourites/favourites_list.dart';
import 'package:stocker/favourites/favourites_store.dart';
import 'package:stocker/symbols_list/symbols_list_page.dart';

class FavouritesPage extends StatelessWidget {
  static const navRoute = 'favourites';

  const FavouritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Provider.of<FavouritesStore>(context, listen: false)
        .addGroup(FavouritesStore.DEFAULT_GROUP);
    return SafeArea(
      child: Scaffold(
        body: FavouritesList(group: FavouritesStore.DEFAULT_GROUP),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.pushNamed(
              context,
              SymbolsListPage.navRoute,
              arguments: {},
            );
          },
        ),
      ),
    );
  }
}
