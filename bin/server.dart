import 'dart:io';

import 'package:notclawdbot/client/client_forward.dart';
import 'package:notclawdbot/controller/controller_proxy.dart';
import 'package:notclawdbot/service/service_pow.dart';
import 'package:notclawdbot/service/service_proxy.dart';
import 'package:notclawdbot/service/service_templating.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';


void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;
  final String target = Platform.environment['TARGET'] ?? '';
  final String difficulty = Platform.environment['DIFFICULTY'] ?? '16';

  final ClientForward clientForward = ClientForward(target);
  final ServiceTemplating templating = ServiceTemplating();
  final ServicePow toll = ServicePow(int.parse(difficulty));
  final ServiceForward serviceProxy = ServiceForward(clientForward, templating, toll);

  final ControllerProxy controller = ControllerProxy(serviceProxy);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(controller.handle);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
