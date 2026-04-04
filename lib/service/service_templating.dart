import 'package:mustache_template/mustache.dart';
import 'package:notclawdbot/template/index.dart';

class ServiceTemplating {
  String render(String url) {
    var template = Template(index, name: 'template-filename.html');

    return template.renderString({'nonce': 'hello', 'url': url});
  }
}