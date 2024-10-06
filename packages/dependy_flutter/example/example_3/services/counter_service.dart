import 'package:flutter/material.dart';

import 'logger_service.dart';

abstract class CounterService with ChangeNotifier {
  int get counter;

  void increment();

  void decrement();
}

class CounterServiceImpl extends CounterService {
  CounterServiceImpl(
    this._step,
    this.loggerService,
  );

  final LoggerService loggerService;
  final int _step;

  int _counter = 0;

  @override
  int get counter => _counter;

  @override
  void decrement() {
    _counter -= _step;
    notifyListeners();

    loggerService.log('Decremented counter by $_step');
    loggerService.log('Current counter value $_counter');
  }

  @override
  void increment() {
    _counter += _step;
    notifyListeners();

    loggerService.log('Incremented counter by $_step');
    loggerService.log('Current counter value $_counter');
  }
}
