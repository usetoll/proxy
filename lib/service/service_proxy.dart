import 'dart:async';

import 'package:notclawdbot/client/client_forward.dart';
import 'package:notclawdbot/dto/source.dart';
import 'package:notclawdbot/service/service_templating.dart';
import 'package:notclawdbot/service/service_pow.dart';
import 'package:shelf/shelf.dart';

class ServiceForward {
  final ClientForward _clientForward;
  final ServiceTemplating _templating;
  final ServicePow _toll;

  DateTime _nextExpirationDate = DateTime.now();

  DateTime get nextExpirationDate {
   return _nextExpirationDate;
 }

  ServiceForward(this._clientForward, this._templating, this._toll);

  void startCron(Duration validityPeriod) {
    Timer.periodic(validityPeriod, (timer) {
      _nextExpirationDate = DateTime.now().add(validityPeriod);
    });

    _nextExpirationDate = DateTime.now().add(validityPeriod);
  }

  Future<Response> forward(Request request, List<String> nonces) async {
    final url = request.url.toString();
    final redirect = Response.found('${request.url.host}/notclawdbot.html?url=$url');

    if (nonces.isEmpty) {
      return redirect;
    }

    final List<bool> validated = await nonces.map((nonce) => verifyPow(Source.fromRequest(request), nonce)).wait;
    if (validated.contains(true)) {
      return _clientForward.forward(request);
    }

    return redirect;
  }

  Future<String> getWebPage(String url, Source source) async {
    return _templating.render(url, _toll.computeChallenge(source, _nextExpirationDate), _toll.difficulty);
  }

  Future<bool> verifyPow(Source source, String nonce) async {
    return _toll.verifyPow(challenge: _toll.computeChallenge(source, _nextExpirationDate), nonce: nonce);
  }
}