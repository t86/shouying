import 'dart:typed_data';

import 'package:foundation/foundation.dart';

/// System-driver printing for pre-laid-out A4 landscape business documents.
/// Acceptance means handed to the platform, not proof of physical output.
abstract interface class PdfDocumentPrinter {
  Future<Result<void>> printPdfDocument(
    Uint8List bytes, {
    required String name,
    required bool Function() canDispatch,
  });
}

typedef SystemPdfPrint = Future<bool> Function(
  Uint8List bytes,
  String name,
  bool Function() canDispatch,
);

Future<Result<void>> dispatchPdfDocument(
  Uint8List bytes,
  String name,
  bool Function() canDispatch,
  SystemPdfPrint dispatch,
) async {
  const changed = FailureResult<void>(
    AppFailure(
      kind: FailureKind.authentication,
      code: 'device.pdf_context_changed',
      safeMessage: '登录或页面状态已变化，未提交打印',
    ),
  );
  const unknown = FailureResult<void>(
    AppFailure(
      kind: FailureKind.device,
      code: 'device.pdf_result_unknown',
      safeMessage: '打印结果尚未确认，请检查系统打印任务，勿重复提交',
    ),
  );
  bool current() {
    try {
      return canDispatch();
    } on Object {
      return false;
    }
  }

  if (bytes.length < 8 ||
      bytes.length > 64 * 1024 * 1024 ||
      ![
        37,
        80,
        68,
        70,
        45,
      ].asMap().entries.every((e) => bytes[e.key] == e.value) ||
      name.isEmpty ||
      name.length > 200 ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(name)) {
    return const FailureResult(
      AppFailure(
        kind: FailureKind.device,
        code: 'device.pdf_invalid',
        safeMessage: '打印文档格式不正确',
      ),
    );
  }
  if (!current()) return changed;
  final snapshot = Uint8List.fromList(bytes).asUnmodifiableView();
  try {
    final accepted = await dispatch(snapshot, name, current);
    // A confirmed cancellation is retryable. Once dispatched, however, losing
    // context cannot prove that the platform did not already accept the job.
    if (!accepted) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.device,
          code: 'device.pdf_not_accepted',
          safeMessage: '打印已取消或未完成',
        ),
      );
    }
    if (!current()) return unknown;
    return const Success(null);
  } on Object {
    return unknown;
  }
}
