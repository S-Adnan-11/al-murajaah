import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const feedbackEndpoint = String.fromEnvironment('FEEDBACK_ENDPOINT');
const feedbackNotice =
    "Feedback is made public. Please don't include personal information.";

String submissionId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

enum FeedbackStatus {
  confirmed,
  pending,
  unavailable,
  rateLimited,
  invalid,
  conflict,
}

class FeedbackResult {
  const FeedbackResult(this.status, [this.reference]);
  final FeedbackStatus status;
  final int? reference;
}

class FeedbackClient {
  FeedbackClient({this.endpoint = feedbackEndpoint});
  final String endpoint;
  bool get configured {
    final uri = Uri.tryParse(endpoint);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        uri.path == '/feedback' &&
        !uri.hasQuery &&
        !uri.hasFragment;
  }

  Future<FeedbackResult> send(Map<String, dynamic> payload) async {
    if (!configured) return const FeedbackResult(FeedbackStatus.unavailable);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await _send(client, payload).timeout(const Duration(seconds: 20));
    } catch (_) {
      // A timeout may occur after GitHub accepted a request. Retain the ID.
      return const FeedbackResult(FeedbackStatus.pending);
    } finally {
      client.close(force: true);
    }
  }

  Future<FeedbackResult> _send(
    HttpClient client,
    Map<String, dynamic> payload,
  ) async {
    final request = await client.postUrl(Uri.parse(endpoint));
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    request.add(utf8.encode(jsonEncode(payload)));
    final response = await request.close();
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > 4096) {
        throw const FormatException('Response too large');
      }
    }
    return decode(response.statusCode, jsonDecode(utf8.decode(bytes)));
  }

  static FeedbackResult decode(int code, dynamic body) {
    if (body is! Map) return const FeedbackResult(FeedbackStatus.pending);
    if (code == 200 &&
        body['status'] == 'confirmed' &&
        body['reference'] is int &&
        body['reference'] > 0) {
      return FeedbackResult(FeedbackStatus.confirmed, body['reference'] as int);
    }
    return FeedbackResult(switch ((code, body['status'])) {
      (202, 'pending') => FeedbackStatus.pending,
      (503, 'unavailable') => FeedbackStatus.unavailable,
      (429, 'rate_limited') => FeedbackStatus.rateLimited,
      (400, 'invalid') => FeedbackStatus.invalid,
      (409, 'conflict') => FeedbackStatus.conflict,
      _ => FeedbackStatus.pending,
    });
  }
}
