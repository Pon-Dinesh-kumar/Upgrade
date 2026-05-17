import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final Widget? loading;
  final Widget Function(Object, StackTrace)? error;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: error ?? (e, st) => Center(child: Text('Error: $e')),
      loading: () => loading ?? const Center(child: CircularProgressIndicator()),
    );
  }
}
