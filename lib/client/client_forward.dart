import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';

class ClientForward {
  final String _target;

  ClientForward(this._target);

  Future<Response> forward(Request request) async {
    final targetUrl = Uri.parse(
        '$_target${request.requestedUri.path}${request.requestedUri.hasQuery
            ? '?${request.requestedUri.query}'
            : ''}');
    final client = http.Client();
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

    forward.headers['host'] = Uri
        .parse(_target)
        .host;

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
}
