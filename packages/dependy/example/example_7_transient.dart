import 'package:dependy/dependy.dart';

class LoggerService {
  void log(String message) {
    print('[Logger]: $message');
  }
}

class AuthService {
  final LoggerService _logger;

  AuthService(this._logger);

  void authenticate(String user) {
    _logger.log('Authenticating $user');
  }
}

class FormValidator {
  final LoggerService _logger;
  final List<String> _errors = [];

  FormValidator(this._logger);

  void validate(String field, String value) {
    if (value.isEmpty) {
      _errors.add('$field is required');
    }
    _logger.log('Validated $field');
  }

  bool get isValid => _errors.isEmpty;

  List<String> get errors => List.unmodifiable(_errors);
}

// LoggerService and AuthService are singletons — shared across the app.
// FormValidator is transient — a fresh instance for every form submission.
//
// Note: a singleton cannot depend on a transient provider.
// Dependy enforces this at module creation to prevent the "captive dependency"
// anti-pattern. A transient can safely depend on singletons.
final dependy = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
      (_) => LoggerService(),
    ),
    DependyProvider<AuthService>(
      (dependy) async {
        final logger = await dependy<LoggerService>();
        return AuthService(logger);
      },
      dependsOn: {LoggerService},
    ),
    DependyProvider<FormValidator>(
      (dependy) async {
        final logger = await dependy<LoggerService>();
        return FormValidator(logger);
      },
      dependsOn: {LoggerService},
      transient: true,
    ),
  },
);

void main() async {
  // Each call returns a fresh FormValidator with its own error state
  final loginForm = await dependy<FormValidator>();
  loginForm.validate('email', 'user@example.com');
  loginForm.validate('password', '');
  print('Login valid: ${loginForm.isValid}'); // false
  print('Errors: ${loginForm.errors}'); // [password is required]

  final signupForm = await dependy<FormValidator>();
  signupForm.validate('email', 'new@example.com');
  signupForm.validate('password', 'secret123');
  print('Signup valid: ${signupForm.isValid}'); // true

  // AuthService is a singleton — same instance everywhere
  final auth = await dependy<AuthService>();
  auth.authenticate('user@example.com');
}
