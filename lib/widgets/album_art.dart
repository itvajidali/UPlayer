import 'package:flutter/cupertino.dart';

class AlbumArt extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool withShadow;

  const AlbumArt({
    super.key,
    required this.imageUrl,
    this.size = 200,
    this.withShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
