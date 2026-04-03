import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

Future<Response> proxyHandler(Request request) async {
  final targetBase = Platform.environment['TARGET'];
  if (targetBase == null) {
    return Response.internalServerError(body: 'TARGET environment variable not set\n');
  }

  final targetUrl = Uri.parse('$targetBase${request.requestedUri.path}${request.requestedUri.hasQuery ? '?${request.requestedUri.query}' : ''}');  final client = http.Client();
  final forward = http.Request(request.method, targetUrl);
  forward.body = await request.readAsString();

  const excludedHeaders = {
    'host',
    'content-length',
    'transfer-encoding',
    'connection',
  };

  request.headers.forEach((key, value) {
    if (!excludedHeaders.contains(key.toLowerCase())) {
      forward.headers[key] = value;
    }
  });

  forward.headers['host'] = Uri.parse(targetBase).host;

  try {
    final response = await client.send(forward);

    final responseBody = await response.stream.toBytes();
    return Response(
      response.statusCode,
      headers: response.headers,
      body: responseBody,
    );
  } catch (e) {
    return Response.internalServerError(body: 'Proxy error: $e\n');
  } finally {
    client.close();
  }
}

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(proxyHandler);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
