import 'package:notclawdbot/client/client_forward.dart';
import 'package:notclawdbot/service/service_templating.dart';
import 'package:notclawdbot/service/service_pow.dart';
import 'package:shelf/shelf.dart';

class ServiceForward {
  final ClientForward _clientForward;
  final ServiceTemplating _templating;
  final ServicePow _toll;

  ServiceForward(this._clientForward, this._templating, this._toll);

  Future<Response> forward(Request request, List<String> nonces) async {
    final url = request.url.toString();
    final redirect = Response.found('${request.url.host}/notclawdbot.html?url=$url');

    if (nonces.isEmpty) {
      return redirect;
    }

    final List<bool> validated = await nonces.map((nonce) => verifyPow(url, nonce)).wait;
    if (validated.contains(true)) {
      return _clientForward.forward(request);
    }

    return redirect;
  }

  Future<String> getWebPage(String url) async {
    return _templating.render(url, _toll.computeChallenge(url), _toll.difficulty);
  }

  Future<bool> verifyPow(String url, String nonce) async {
    return _toll.verifyPow(challenge: _toll.computeChallenge(url), nonce: nonce);
  }
}