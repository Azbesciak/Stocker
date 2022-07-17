import 'package:flutter/material.dart';

class FavouritesButton extends StatelessWidget {
  final bool isFavourite;
  final Function() toggleFavourite;

  const FavouritesButton({
    Key? key,
    required this.isFavourite,
    required this.toggleFavourite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isFavourite
          ? Icon(
              Icons.done,
              color: Colors.green,
            )
          : Icon(Icons.add_circle_outline),
      onPressed: toggleFavourite,
    );
  }
}
