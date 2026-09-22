import 'dart:convert';
import 'package:flutter/material.dart' hide Theme;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class DarbVectorTheme {
  static Style? _cachedStyle;

  static const String baseStyleUrl = 'https://tiles.openfreemap.org/styles/dark';
  static const String vectorTilesUrl = 'https://tiles.openfreemap.org/planet/20260913_164504_pt/{z}/{x}/{y}.pbf';

  /// Loads the DARB Vector Style from local assets or remote OpenFreeMap
  static Future<Style> loadStyle({bool forceRefresh = false}) async {
    if (_cachedStyle != null && !forceRefresh) {
      return _cachedStyle!;
    }

    try {
      String styleText;
      try {
        styleText = await rootBundle.loadString('assets/map/darb_style.json');
      } catch (assetErr) {
        debugPrint('[DARB Vector Theme] Asset not found, fetching remote style: $assetErr');
        final resp = await http.get(
          Uri.parse(baseStyleUrl),
          headers: {'User-Agent': 'DARB-Iraq/1.0'},
        ).timeout(const Duration(seconds: 8));
        styleText = resp.body;
      }

      final Map<String, dynamic> styleJson = jsonDecode(styleText);

      // Tile providers for OpenMapTiles vector tiles
      final providers = <String, VectorTileProvider>{
        'openmaptiles': NetworkVectorTileProvider(
          urlTemplate: vectorTilesUrl,
          maximumZoom: 14,
          minimumZoom: 0,
        ),
      };

      // Load sprites
      SpriteStyle? spriteStyle;
      final spriteUri = styleJson['sprite'] as String?;
      if (spriteUri != null && spriteUri.isNotEmpty) {
        try {
          final spriteJsonResp = await http.get(Uri.parse('$spriteUri.json')).timeout(const Duration(seconds: 4));
          if (spriteJsonResp.statusCode == 200) {
            final spriteJson = jsonDecode(spriteJsonResp.body);
            spriteStyle = SpriteStyle(
              atlasProvider: () async {
                final imgResp = await http.get(Uri.parse('$spriteUri.png'));
                return imgResp.bodyBytes;
              },
              index: SpriteIndexReader().read(spriteJson),
            );
          }
        } catch (_) {}
      }

      final theme = ThemeReader().read(styleJson);

      _cachedStyle = Style(
        theme: theme,
        providers: TileProviders(providers),
        sprites: spriteStyle,
        name: 'DARB Dark Navigation Vector Style',
      );

      return _cachedStyle!;
    } catch (e) {
      debugPrint('[DARB Vector Theme] Error initializing vector style: $e. Falling back to StyleReader...');
      _cachedStyle = await StyleReader(uri: baseStyleUrl).read();
      return _cachedStyle!;
    }
  }
}
