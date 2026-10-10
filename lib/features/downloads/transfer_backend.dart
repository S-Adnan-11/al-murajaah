import 'package:flutter/services.dart';

import '../../core/audio/sample_catalog.dart';

class TransferStatus {
  const TransferStatus(this.state, this.received, {this.path, this.reason});
  final String state;
  final int received;
  final String? path, reason;
}

abstract interface class TransferBackend {
  Future<int> freeBytes();
  Future<String> start(SampleAsset asset, {required bool wifiOnly});
  Future<TransferStatus> status(String taskId);
  Future<void> cancel(String taskId);
}

/// The OS owns transfer lifetimes; Flutter observes progress and verifies the
/// delivered bytes. No new third-party plugin or second playback service.
class AndroidTransferBackend implements TransferBackend {
  static const channel = MethodChannel('dev.almurajaah/downloads');
  @override
  Future<int> freeBytes() async =>
      (await channel.invokeMethod<num>('freeBytes'))!.toInt();
  @override
  Future<String> start(SampleAsset asset, {required bool wifiOnly}) async =>
      (await channel.invokeMethod<String>('enqueue', {
        'assetId': asset.id,
        'url': asset.url,
        'title': asset.name,
        'wifiOnly': wifiOnly,
      }))!;
  @override
  Future<TransferStatus> status(String taskId) async {
    final data = (await channel.invokeMapMethod<String, dynamic>('status', {
      'taskId': taskId,
    }))!;
    return TransferStatus(
      data['state'] as String,
      (data['received'] as num).toInt(),
      path: data['path'] as String?,
      reason: data['reason'] as String?,
    );
  }

  @override
  Future<void> cancel(String taskId) =>
      channel.invokeMethod<void>('cancel', {'taskId': taskId});
}
