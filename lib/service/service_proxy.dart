import 'package:notclawdbot/client/client_forward.dart';
import 'package:notclawdbot/service/service_templating.dart';
import 'package:notclawdbot/service/service_pow.dart';
import 'package:shelf/shelf.dart';

class ServiceForward {
  final ClientForward _clientForward;
  final ServiceTemplating _templating;
  final ServicePow _toll;

  ServiceForward(this._clientForward, this._templating, this._toll);

  Future<Response> forward(Request request, String? pow) async {
    if (await _toll.verify(pow) == false) {
      return Response.movedPermanently('${request.url.host}/notclawdbot.html?url=${request.url.toString()}');
    }

    return _clientForward.forward(request);
  }

  Future<String> getWebPage(String url) async {
    return _templating.render(url);
  }

  Future<bool> verifyPow(String pow) async {
    return _toll.verify(pow);
  }
}