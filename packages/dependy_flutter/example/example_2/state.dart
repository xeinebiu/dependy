import 'package:flutter/material.dart';

import 'services/logger_service.dart';

class Example2State with ChangeNotifier {
  Example2State(this.loggerService);

  final LoggerService loggerService;

  int _counter = 0;

  int get counter => _counter;

  void incrementCounter() {
    _counter++;
    notifyListeners();

    loggerService.log("incrementCounter $counter");
  }

  void decrementCounter() {
    _counter--;
    notifyListeners();

    loggerService.log("decrementCounter $counter");
  }
}
