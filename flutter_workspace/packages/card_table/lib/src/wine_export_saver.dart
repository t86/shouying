import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:card_table/src/wine_export_saver_stub.dart'
    if (dart.library.io) 'package:card_table/src/wine_export_saver_native.dart'
    if (dart.library.js_interop) 'package:card_table/src/wine_export_saver_web.dart'
    as platform;

Future<Result<String>> saveWineExport(
  ProtocolBinaryFile file, {
  bool Function()? canSave,
}) async {
  const stale = FailureResult<String>(
    AppFailure(
      kind: FailureKind.authentication,
      code: 'export.context_changed',
      safeMessage: '页面、登录或连接已变化，导出已取消',
    ),
  );
  bool allowed() {
    try {
      return canSave?.call() ?? true;
    } on Object {
      return false;
    }
  }

  if (!allowed()) return stale;
  try {
    final location = await platform.save(file, canSave: allowed);
    return allowed() ? Success(location) : stale;
  } on Object {
    if (!allowed()) return stale;
    return const FailureResult(
      AppFailure(
        kind: FailureKind.unknown,
        code: 'wine.export_save_failed',
        safeMessage: '文件保存失败，请检查下载目录权限后重试',
      ),
    );
  }
}
