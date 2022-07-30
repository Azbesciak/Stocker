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
              Icons.star,
              color: Colors.orangeAccent,
            )
          : Icon(Icons.star_border),
      onPressed: toggleFavourite,
    );
  }
}
