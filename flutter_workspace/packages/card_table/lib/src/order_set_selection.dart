import 'package:foundation/foundation.dart';

import 'package:card_table/src/order_meal.dart';

final class OrderSetChoice {
  const OrderSetChoice({
    required this.detail,
    required this.selectCount,
    this.requirement = '',
  });
  final OrderSetDetail detail;
  final int selectCount;
  final String requirement;
}

/// Selection counts are per set, not multiplied by the number of parent sets.
/// Candidates must come from the current, resolved package configuration.
final class OrderSetSelection {
  OrderSetSelection({
    required this.productId,
    required List<OrderSetDetail> candidates,
    required List<OrderSetChoice> choices,
    this.count = 1,
    this.replacing,
  }) : candidates = List.unmodifiable(candidates),
       choices = List.unmodifiable(choices);
  final String productId;
  final List<OrderSetDetail> candidates;
  final List<OrderSetChoice> choices;
  final int count;
  final OrderSetItem? replacing;
  List<String> get groupIds =>
      choices.map((row) => row.detail.groupId).toList();
  List<String> get detailProductIds =>
      choices.map((row) => row.detail.detailProductId).toList();
  List<int> get detailCounts =>
      choices.map((row) => row.detail.detailCount).toList();
  List<int> get selectCounts => choices.map((row) => row.selectCount).toList();
  List<String> get requirements =>
      choices.map((row) => row.requirement).toList();

  AppFailure? validate() {
    const invalid = AppFailure(
      kind: FailureKind.business,
      code: 'order_set.invalid_selection',
      safeMessage: '套餐明细或选择次数无效，请重新选择',
    );
    bool id(String value) {
      final n = int.tryParse(value);
      return n != null && n > 0 && n <= 9007199254740991;
    }

    bool resolved(OrderSetDetail detail) =>
        detail.typeId == '1' ||
        (detail.typeId == '2' && detail.templateResolved);
    if (!id(productId) ||
        count < 1 ||
        count > 9999 ||
        candidates.isEmpty ||
        choices.isEmpty ||
        candidates.any(
          (row) =>
              row.productId != productId ||
              !id(row.groupId) ||
              !id(row.detailProductId) ||
              row.detailCount <= 0 ||
              !resolved(row),
        )) {
      return invalid;
    }
    final source = replacing;
    if (source != null && (!source.valid || source.groupId == '1')) {
      return invalid;
    }
    final expected = <String, int>{};
    for (final candidate in candidates.where((row) => !row.fixed)) {
      if (candidate.groupSelectCount <= 0) return invalid;
      if (expected.containsKey(candidate.groupId) &&
          expected[candidate.groupId] != candidate.groupSelectCount) {
        return invalid;
      }
      expected[candidate.groupId] = candidate.groupSelectCount;
    }
    if (source != null) {
      if (!expected.containsKey(source.groupId)) return invalid;
      expected
        ..clear()
        ..[source.groupId] = source.selectCount;
    }
    final actual = <String, int>{};
    final fixed = <(String, String), int>{};
    for (final choice in choices) {
      final row = choice.detail;
      if (choice.selectCount <= 0 ||
          choice.selectCount > 9007199254740991 ||
          choice.requirement.length > 200 ||
          (source != null && row.groupId != source.groupId) ||
          !candidates.any(
            (candidate) =>
                candidate.productId == row.productId &&
                candidate.groupId == row.groupId &&
                candidate.detailProductId == row.detailProductId &&
                candidate.detailCount == row.detailCount &&
                resolved(row),
          )) {
        return invalid;
      }
      if (row.fixed) {
        fixed.update(
          (row.groupId, row.detailProductId),
          (n) => n + choice.selectCount,
          ifAbsent: () => choice.selectCount,
        );
      } else {
        actual.update(
          row.groupId,
          (n) => n + choice.selectCount,
          ifAbsent: () => choice.selectCount,
        );
      }
    }
    if (source == null) {
      for (final row in candidates.where((row) => row.fixed)) {
        if (fixed[(row.groupId, row.detailProductId)] != 1) return invalid;
      }
    }
    if (actual.length != expected.length ||
        expected.entries.any((row) => actual[row.key] != row.value)) {
      return invalid;
    }
    return null;
  }
}
