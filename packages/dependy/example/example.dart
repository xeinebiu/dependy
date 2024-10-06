import 'package:dependy/dependy.dart';

/// Check other examples on the source

class CounterService {
  int _count = 0;

  int increment() => ++_count;
}

final dependy = DependyModule(
  providers: {
    DependyProvider<CounterService>(
      (_) => CounterService(),
    ),
  },
);

void main() async {
  final counterService = await dependy<CounterService>();

  print('Initial Count: ${counterService.increment()}');
  print('After Increment: ${counterService.increment()}');
}
