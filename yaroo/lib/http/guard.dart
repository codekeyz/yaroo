import 'dart:async';

import 'package:meta/meta_meta.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/yaroo.dart';

const classOrMethod = Target({TargetKind.method, TargetKind.classType});

abstract class Guard {
  const Guard();

  FutureOr<bool> canActivate(Application app, Request request);
}

@classOrMethod
class UseGuard {
  final Guard guard;
  const UseGuard(this.guard);
}

@classOrMethod
class UseGuards {
  final List<Guard> guards;
  const UseGuards(this.guards);
}
