import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../enum/enum.dart';

/// A secure, isolate-based service designed to process intensive sorting
/// operations on highly populated media libraries without frame degradation.
class SortService {
  /// The singleton instance of [SortService].
  static final SortService instance = SortService._internal();

  /// Returns the global implementation of [SortService].
  factory SortService() => instance;

  SortService._internal();

  /// Asynchronously sorts a large collection of [AssetEntity] locally off the main thread.
  ///
  /// This implementation maps internal entity structures into lightweight payloads,
  /// executing the computational overhead within a separate dart isolate via [compute].
  ///
  /// - [assets]: The raw unsorted batch of entities retrieved from the native layer.
  /// - [sortOrder]: The designated [PickerSortOrder] strategy.
  Future<List<AssetEntity>> sortAssets(
      List<AssetEntity> assets, PickerSortOrder sortOrder) async {
    if (assets.isEmpty || sortOrder == PickerSortOrder.newest) return assets;

    // Isolate boundary mapping
    final mappedPayload = <Map<String, dynamic>>[];
    for (var i = 0; i < assets.length; i++) {
       final a = assets[i];
       mappedPayload.add({
         'index': i,
         'createDt': a.createDateTime.millisecondsSinceEpoch,
         'res': a.width * a.height, // High performance, synchronous proxy for file size.
       });
    }

    final sortedPayloads = await compute(_sortPayloads, {
      'assets': mappedPayload,
      'order': sortOrder.toString(),
    });

    return sortedPayloads.map((p) => assets[p['index'] as int]).toList();
  }
}

/// The independent isolate execution block for media sorting.
List<Map<String, dynamic>> _sortPayloads(Map<String, dynamic> message) {
  final List<Map<String, dynamic>> contextAssets =
      List.from(message['assets'] as List);
  final String orderStr = message['order'] as String;

  if (orderStr.contains('oldest')) {
    contextAssets.sort(
        (a, b) => (a['createDt'] as int).compareTo(b['createDt'] as int));
  } else if (orderStr.contains('largest')) {
    contextAssets.sort((a, b) => (b['res'] as int).compareTo(a['res'] as int));    
  } else if (orderStr.contains('smallest')) {
    contextAssets.sort((a, b) => (a['res'] as int).compareTo(b['res'] as int));    
  }

  return contextAssets;
}
