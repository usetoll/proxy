import 'package:notclawdbot/service/service_proxy.dart';
import 'package:shelf/shelf.dart';

class ControllerProxy {
  final ServiceForward _service;
  static const cookieId = 'NOTCLAWDBOT';

  ControllerProxy(this._service);

  Future<Response> handle(Request request) {
    if (request.url.path.startsWith('notclawdbot.html') &&
        request.url.queryParameters.containsKey('pow')) {
      return handlePowVerify(request);
    }

    if (request.url.path.startsWith('notclawdbot.html')) {
      return handleWebPage(request);
    }

    final cookies = request.headers['Cookie'];
    final regex = RegExp('(?:^|;)\\s*$cookieId=([^;]*)');
    final match = regex.firstMatch(cookies ?? '');
    final pow = match?.group(1)?.trim();
    print('pow=$pow, regex=$cookies');

    return _service.forward(request, pow);
  }

  Future<Response> handleWebPage(Request request) async {
    final String url = request.url.queryParameters['url']!;
    final String page = await _service.getWebPage(url);
    return Response.ok(page, headers: {'Content-Type': 'text/html'});
  }

  Future<Response> handlePowVerify(Request request) async {
    final String pow = request.url.queryParameters['pow']!;
    final String url = request.url.queryParameters['url'] ?? '';
    if (await _service.verifyPow(pow)) {
      return Response.movedPermanently('/$url', headers: {
        'Set-Cookie': '$cookieId=$pow'
      });
    }

    return Response.badRequest();
  }
}
