/*
 * Copyright (c) 2025. Soyeon Kim <yourmate04@gmail.com>
 */

sealed class InputValidationState {}

sealed class InputValidationDoneState implements InputValidationState {}

sealed class InputValidatingState implements InputValidationState {}

class InputValidStatus implements InputValidationDoneState {
  const InputValidStatus();

  @override
  String toString() => 'InputValidStatus()';
}

sealed class InputInvalidStatus implements InputValidationDoneState {}

class InputIdleStatus implements InputValidationDoneState {
  const InputIdleStatus();

  @override
  String toString() => 'InputIdleStatus()';
}

class InputCustomInvalidStatus implements InputInvalidStatus {
  final String message;

  const InputCustomInvalidStatus({required this.message});

  @override
  String toString() => 'CustomInvalidStatus(message: $message)';
}

class InputAsyncValidatingStatus implements InputValidatingState {
  const InputAsyncValidatingStatus();

  @override
  String toString() => 'AsyncValidatingStatus()';
}

class InputAsyncValidationErrorStatus implements InputInvalidStatus {
  final dynamic error;

  const InputAsyncValidationErrorStatus(this.error);
}
