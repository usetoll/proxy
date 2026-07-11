
import 'dart:io';

import 'package:shelf/shelf.dart';

class Source {
  final String ip;
  final String agent;

  Source({required this.ip, required this.agent});

  factory Source.fromRequest(Request request) {
    // shelf exposes the underlying connection info via context
    final connectionInfo =
    request.context['shelf.io.connection_info'] as HttpConnectionInfo?;

    // Respect X-Forwarded-For if you're behind a proxy/load balancer
    final forwarded = request.headers['x-forwarded-for'];
    final ip = forwarded?.split(',').first.trim() ??
        connectionInfo?.remoteAddress.address ??
        'unknown';

    return Source(
      ip: ip,
      agent: request.headers['user-agent'] ?? 'unknown',
    );
  }

  @override
  String toString() {
    return 'Source{ip: $ip, agent: $agent}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Source && runtimeType == other.runtimeType &&
              ip == other.ip && agent == other.agent;

  @override
  int get hashCode => Object.hash(ip, agent);


}