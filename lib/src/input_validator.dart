/*
 * Copyright (c) 2025. Soyeon Kim <yourmate04@gmail.com>
 */

import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'futureor_extension.dart';
import 'validator_status.dart';

final class InputValidator extends ChangeNotifier {
  final InvalidStatus? Function(String str) validate;
  final Future<InvalidStatus?> Function(String str)? validateAsync;
  final Duration asyncValidationDebounceTime;
  final TextEditingController inputController;

  final bool trimText;
  final bool emptyIsIdle;

  InputValidator({
    required this.validate,
    this.validateAsync,
    this.asyncValidationDebounceTime = const Duration(milliseconds: 600),
    required this.inputController,
    this.trimText = true,
    this.emptyIsIdle = true,
  }) {
    inputController.addListener(_listener);
    final preResolvedStream = trimText
        ? _inputStreamController.stream.map((str) => str.trim())
        : _inputStreamController.stream;
    preResolvedStream // TODO: 여기에서 loadingState 먼저 박는 건 어떨까??
        .debounceTime(asyncValidationDebounceTime)
        .listen(_debounceListener);
  }

  final _inputStreamController = StreamController<String>.broadcast();
  late String lastValidatingText = inputController.text;
  CancelableOperation<InputValidationState>? _currentAsyncValidationJob;

  void _listener() {
    final currentStr = inputController.text;
    _inputStreamController.add(currentStr);
  }

  void _debounceListener(String text) {
    _runValidation(text).then((status) => _setCurrentStatus(status, text));
  }

  InputValidationState get currentStatus => _currentStatus;

  InputValidationState _currentStatus = const InputIdleStatus();

  InputValidationState _setCurrentStatus(
      InputValidationState status, String text) {
    // temp arg2
    _currentStatus = status;
    print('_setCurrentStatus: $status, $text');
    notifyListeners();
    return status;
  }

  /// use only isInvalid -> currentError
  InvalidStatus? get currentError => switch (currentStatus) {
        InvalidStatus invalid => invalid,
        _ => null,
      };

  FutureOr<InputValidationState> forceValidateNow() {
    final rawText = inputController.text;
    return _runValidation(trimText ? rawText.trim() : rawText)
        .then((p0) => _setCurrentStatus(p0, rawText));
  }

  FutureOr<InputValidationState> _runValidation(String str) {
    print('runValidation: $str');
    lastValidatingText = str;
    if (emptyIsIdle && str.isEmpty) return const InputIdleStatus();

    final syncValidationResult = validate.call(str) ?? const InputValidStatus();
    if (syncValidationResult case InputValidStatus()) {
      if (validateAsync == null) return const InputValidStatus();

      if (_currentAsyncValidationJob
          case CancelableOperation(:final isCanceled, :final cancel)
          when !isCanceled) {
        cancel();
      }

      _setCurrentStatus(const InputAsyncValidatingStatus(), str);
      final asyncValidationResultFuture = validateAsync!.call(str);
      _currentAsyncValidationJob = CancelableOperation.fromFuture(
          asyncValidationResultFuture, onCancel: () {
        _currentAsyncValidationJob = null;
        print('canceled! $str');
      }).then((asyncInvalidStatus) => asyncInvalidStatus ?? const InputValidStatus(),
          onError: (e, _) => InputAsyncValidationErrorStatus(e));

      return _currentAsyncValidationJob!.value;
    } else {
      return syncValidationResult;
    }
  }

  Future<InputValidationState> get nextDoneState async {
    final isSameValueValidatingNow = lastValidatingText == inputController.text;
    if (isSameValueValidatingNow) {
      return switch (currentStatus) {
        InputValidationDoneState done => done,
        InputValidatingState() => await _currentAsyncValidationJob!.value,
      };
    }
    return await forceValidateNow();
  }

  Future<bool> get isValid async {
    final nextDoneState = await this.nextDoneState;
    return nextDoneState is InputValidStatus;
  }

  Future<bool> get isInvalid async => !await isValid;

  @override
  void dispose() {
    _inputStreamController.close();
    _currentAsyncValidationJob?.cancel();
    inputController.removeListener(_listener);
    super.dispose();
  }
}
