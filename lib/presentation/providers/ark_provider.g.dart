// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ark_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$arkNotifierHash() => r'ark_notifier_generated_hash';

/// See also [ArkNotifier].
@ProviderFor(ArkNotifier)
final arkNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ArkNotifier, List<ArkNodeModel>>.internal(
  ArkNotifier.new,
  name: r'arkNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$arkNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ArkNotifier = AutoDisposeAsyncNotifier<List<ArkNodeModel>>;

String _$dailyBreadHash() => r'daily_bread_generated_hash';

/// See also [dailyBread].
@ProviderFor(dailyBread)
final dailyBreadProvider =
    AutoDisposeFutureProvider<DailyBreadVerse>.internal(
  dailyBread,
  name: r'dailyBreadProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dailyBreadHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DailyBreadRef = AutoDisposeFutureProviderRef<DailyBreadVerse>;
