# Transient Providers

Each resolution returns a fresh instance with its own state.

```dart
import 'package:dependy/dependy.dart';

class LoggerService {
  void log(String message) => print('[Logger]: $message');
}

class FormValidator {
  final LoggerService _logger;
  final List<String> _errors = [];

  FormValidator(this._logger);

  void validate(String field, String value) {
    if (value.isEmpty) _errors.add('$field is required');
    _logger.log('Validated $field');
  }

  bool get isValid => _errors.isEmpty;
  List<String> get errors => List.unmodifiable(_errors);
}

final dependy = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
      (_) => LoggerService(),
    ),
    DependyProvider<FormValidator>(
      (resolve) async {
        final logger = await resolve<LoggerService>();
        return FormValidator(logger);
      },
      dependsOn: {LoggerService},
      transient: true,
    ),
  },
);

void main() async {
  final loginForm = await dependy<FormValidator>();
  loginForm.validate('email', 'user@example.com');
  loginForm.validate('password', '');
  print('Login valid: ${loginForm.isValid}');  // false
  print('Errors: ${loginForm.errors}');        // [password is required]

  final signupForm = await dependy<FormValidator>();
  signupForm.validate('email', 'new@example.com');
  signupForm.validate('password', 'secret123');
  print('Signup valid: ${signupForm.isValid}'); // true
}
```

## Key Points

- `LoggerService` is a singleton, shared across the app.
- `FormValidator` is transient, so each form gets a fresh instance.
- A singleton **cannot** depend on a transient. Dependy throws `DependyCaptiveDependencyException` if you try.
