# Transient Providers

By default, providers are **singletons**, created once and cached. Set `transient: true` to get a **fresh instance on every resolution**.

## When to Use

- Form validators with per-form state
- HTTP request objects
- Command handlers
- Anything that should not be shared

## Example

```dart
import 'package:dependy/dependy.dart';

class FormValidator {
  final List<String> _errors = [];

  void validate(String field, String value) {
    if (value.isEmpty) _errors.add('$field is required');
  }

  bool get isValid => _errors.isEmpty;
  List<String> get errors => List.unmodifiable(_errors);
}

final module = DependyModule(
  providers: {
    DependyProvider<FormValidator>(
      (_) => FormValidator(),
      transient: true,
    ),
  },
);

void main() async {
  final loginForm = await module<FormValidator>();
  loginForm.validate('email', 'user@example.com');
  loginForm.validate('password', '');
  print(loginForm.isValid); // false

  final signupForm = await module<FormValidator>();
  signupForm.validate('email', 'new@example.com');
  signupForm.validate('password', 'secret123');
  print(signupForm.isValid); // true

  // Each call returned a fresh instance with no shared state.
}
```

## Captive Dependency Detection

A singleton provider **cannot** depend on a transient provider. This would silently capture the transient instance inside the singleton, defeating the purpose of `transient: true`.

Dependy detects this at module construction and throws `DependyCaptiveDependencyException`.

```dart
// This throws DependyCaptiveDependencyException:
final module = DependyModule(
  providers: {
    DependyProvider<FormValidator>(
      (_) => FormValidator(),
      transient: true,
    ),
    DependyProvider<FormService>(
      (resolve) async => FormService(await resolve<FormValidator>()),
      dependsOn: {FormValidator},
      // FormService is singleton (default), but depends on transient FormValidator
    ),
  },
);
```

To fix this, either make `FormService` transient too, or make `FormValidator` a singleton.
