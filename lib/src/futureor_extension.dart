/*
 * Copyright (c) 2025. Soyeon Kim <yourmate04@gmail.com>
 */

import 'dart:async';

extension FutureOrExtension<T> on FutureOr<T> {
  FutureOr<V> then<V>(V Function(T) f) {
    if (this is Future<T>) {
      return (this as Future<T>).then(f);
    } else {
      return f(this as T);
    }
  }
}