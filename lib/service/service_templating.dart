import 'package:mustache_template/mustache.dart';
import 'package:notclawdbot/template/index.dart';

class ServiceTemplating {
  String render(String url, String challenge, int difficulty) {
    var template = Template(index, name: 'template-filename.html');

    return template.renderString({'challenge': challenge, 'difficulty': difficulty, 'url': url});
  }
}

// $1 -> \$1, \w+ -> \\w+, VERTEX_SHADER = `\ -> VERTEX_SHADER = `\\