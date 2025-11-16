import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coords, TileLayer options) {
    final url = options.urlTemplate!
        .replaceAll('{z}', coords.z.toString())
        .replaceAll('{x}', coords.x.toString())
        .replaceAll('{y}', coords.y.toString());

    return CachedNetworkImageProvider(url);
  }
}