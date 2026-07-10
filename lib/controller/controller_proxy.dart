import 'dart:io';

import 'package:notclawdbot/service/service_pow.dart';
import 'package:notclawdbot/service/service_proxy.dart';
import 'package:shelf/shelf.dart';

class ControllerProxy {
  final ServiceForward _service;
  static const cookieId = 'USETOLL';

  ControllerProxy(this._service);

  Future<Response> handle(Request request) {
    if (request.url.path.startsWith('notclawdbot.html') &&
        request.url.queryParameters.containsKey('nonce')) {
      return handlePowVerify(request);
    }

    if (request.url.path.startsWith('notclawdbot.html')) {
      return handleWebPage(request);
    }

    final cookies = request.headers['Cookie'];
    final regex = RegExp('(?:^|;)\\s*$cookieId=([^;]*)');
    final Iterable<RegExpMatch> matches = regex.allMatches(cookies ?? '');
    final List<String> nonces = matches
        .map((match) => match.group(1)?.trim())
        .whereType<String>()
        .toList();

    return _service.forward(request, nonces);
  }

  Future<Response> handleWebPage(Request request) async {
    final String url = request.url.queryParameters['url']!;
    final String page = await _service.getWebPage(url);
    return Response.ok(page, headers: {'Content-Type': 'text/html'});
  }

  Future<Response> handlePowVerify(Request request) async {
    final String nonce = request.url.queryParameters['nonce']!;
    final String url = request.url.queryParameters['url'] ?? '';
    if (await _service.verifyPow(url, nonce)) {
      return Response.found('/$url', headers: {
        'Set-Cookie': '$cookieId=$nonce; Expires=${HttpDate.format(ServicePow.expiration())}'
      });
    }

    return Response.badRequest();
  }
}
