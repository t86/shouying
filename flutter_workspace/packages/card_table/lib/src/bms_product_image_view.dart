import 'dart:async';
import 'dart:typed_data';

import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_product_image.dart';
import 'package:card_table/src/bms_product_image_picker.dart';
import 'package:flutter/material.dart';

class _Row {
  _Row(this.file, {this.id, this.displayName});
  final BmsPickedImage file;
  final String? displayName;
  int? id;
  String? error;
  BmsUploadedImage? uploaded;
  bool selected = false, valid = true, bound = false;
  String get name => displayName ?? file.name.split('.').first;
}

class BmsUploadProImgView extends StatefulWidget {
  const BmsUploadProImgView({
    required this.loader,
    this.picker = pickBmsProductImages,
    super.key,
  });
  final BmsLoader loader;
  final BmsProductImagePicker picker;
  @override
  State<BmsUploadProImgView> createState() => _BmsUploadProImgViewState();
}

class _BmsUploadProImgViewState extends State<BmsUploadProImgView> {
  BmsProductImageLoader? get _api => widget.loader is BmsProductImageLoader
      ? widget.loader as BmsProductImageLoader
      : null;
  Object? _token;
  int _tab = 0, _version = 0;
  bool _busy = false,
      _invalid = false,
      _missingLoaded = false,
      _defaultLoaded = false,
      _mode = false;
  String? _error, _notice;
  List<_Row> _batch = [];
  List<Map<String, Object?>> _missing = [];
  _Row? _single, _defaultPick;
  String _defaultName = '', _defaultUrl = '';
  Uint8List? _defaultThumbnail;
  @override
  void initState() {
    super.initState();
    _token = _api?.productImageContext;
  }

  @override
  void dispose() {
    _invalid = true;
    _version++;
    unawaited(_releaseAll());
    super.dispose();
  }

  Future<void> _release(BmsPickedImage file) async {
    try {
      await file.release();
    } on Object {
      /* Best effort release; never treat it as an upload result. */
    }
  }

  Future<void> _releaseAll() async {
    for (final row in [..._batch, ?_single, ?_defaultPick]) {
      await _release(row.file);
    }
  }

  bool _current(int version) =>
      mounted &&
      !_invalid &&
      version == _version &&
      _token != null &&
      _token == _api?.productImageContext;
  bool _check(int version) {
    if (_current(version)) return true;
    if (mounted) {
      if (_token != _api?.productImageContext) _invalid = true;
      setState(() => _error = '处理已取消或登录连接状态已变化，请重新打开');
    }
    return false;
  }

  Future<Map<String, Object?>> _request(
    BmsProductImageOperation operation, [
    Map<String, Object?> parameters = const {},
  ]) async {
    final api = _api;
    if (api == null) throw const FormatException('商品图片服务未接入');
    final result = await api.requestProductImage(
      BmsProductImageRequest(operation, parameters: parameters),
    );
    if (result.failureOrNull case final failure?) {
      throw FormatException(failure.safeMessage);
    }
    return result.valueOrNull ?? const {};
  }

  Future<void> _run(Future<void> Function(int) run) async {
    if (_busy) return;
    final version = ++_version;
    if (!_check(version)) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await run(version);
    } on FormatException catch (error) {
      if (_current(version)) setState(() => _error = error.message);
    } on Object {
      if (_current(version)) setState(() => _error = '图片处理失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static List<Map<String, Object?>> _rows(Object? raw) {
    if (raw == null) return [];
    if (raw is! List || raw.any((r) => r is! Map)) {
      throw const FormatException('图片数据无法识别');
    }
    return [for (final row in raw) Map<String, Object?>.from(row as Map)];
  }

  static int _id(Object? value) {
    final id = int.tryParse('$value');
    if (id == null || id < 0 || id > 9007199254740991) {
      throw const FormatException('商品编号无效');
    }
    return id;
  }

  Future<List<BmsPickedImage>?> _pick(bool multiple, int version) async {
    final files = await widget.picker(multiple: multiple);
    if (!_current(version)) {
      if (files != null) {
        for (final file in files) {
          await _release(file);
        }
      }
      return null;
    }
    if (files != null &&
        (files.length > 200 || (!multiple && files.length > 1))) {
      for (final file in files) {
        await _release(file);
      }
      throw const FormatException('批量最多200张，单品或默认图片只能选择1张');
    }
    return files == null || files.isEmpty ? null : files;
  }

  void _validate(_Row row) {
    try {
      BmsProductImageFile.validateNameAndSize(row.file.name, row.file.size);
    } on FormatException catch (error) {
      row.valid = false;
      row.error = error.message;
    }
  }

  Future<void> _chooseBatch() => _run((version) async {
    final files = await _pick(true, version);
    if (files == null || !_check(version)) return;
    for (final row in _batch) {
      await _release(row.file);
    }
    if (!_check(version)) return;
    _batch = [for (final file in files) _Row(file)];
    final last = <String, _Row>{};
    for (final row in _batch) {
      _validate(row);
      if (!row.valid) continue;
      final previous = last[row.name];
      if (previous != null) {
        previous.valid = false;
        previous.error = '同名图片以最后一张为准';
      }
      last[row.name] = row;
    }
    setState(() {});
    await _matchAndUpload(version);
  });
  Future<void> _matchAndUpload(int version) async {
    final rows = _batch.where((r) => r.valid && r.uploaded == null).toList();
    if (rows.isEmpty) return;
    final data = await _request(BmsProductImageOperation.check, {
      'pic_names': rows.map((r) => r.name).toList(),
    });
    if (!_check(version)) return;
    final matches = <String, int>{};
    for (final item in _rows(data['items'])) {
      if (item['n'] is! String || matches.containsKey(item['n'])) {
        throw const FormatException('商品匹配结果无法识别');
      }
      matches[item['n'] as String] = _id(item['id']);
    }
    for (final row in rows) {
      if (!_check(version)) return;
      row.id = matches[row.name] ?? 0;
      if (row.id! <= 0) {
        setState(() => row.error = '未检测到对应商品');
        continue;
      }
      await _upload(row, version);
    }
  }

  Future<bool> _upload(_Row row, int version) async {
    if (!_check(version)) return false;
    try {
      _validate(row);
      if (!row.valid) {
        setState(() {});
        return false;
      }
      final bytes = await row.file.readBytes();
      if (!_check(version)) return false;
      final result = await _api!.uploadProductImage(
        BmsProductImageFile(row.file.name, bytes),
        isCurrent: () => _current(version),
      );
      if (!_check(version)) return false;
      if (result.failureOrNull case final failure?) {
        setState(() => row.error = failure.safeMessage);
        return false;
      }
      final uploaded = result.valueOrNull;
      if (uploaded == null) throw const FormatException('存储未返回上传结果');
      setState(() {
        row.uploaded = uploaded;
        row.selected = true;
        row.error = null;
      });
      await _release(row.file);
      return true;
    } on FormatException catch (error) {
      if (_current(version)) setState(() => row.error = error.message);
    } on Object {
      if (_current(version)) setState(() => row.error = '图片读取或上传失败，请重试');
    }
    return false;
  }

  Future<void> _bindBatch() => _run((version) async {
    final selected = <int, _Row>{};
    for (final row in _batch) {
      if (row.selected &&
          !row.bound &&
          row.uploaded != null &&
          row.id != null &&
          row.id! > 0) {
        selected[row.id!] = row;
      }
    }
    if (selected.isEmpty) throw const FormatException('请选择已上传且匹配成功的商品图片');
    await _request(BmsProductImageOperation.bindBatch, {
      'ids': selected.keys.toList(),
      'pic_names': selected.values.map((r) => r.uploaded!.fileName).toList(),
    });
    if (!_check(version)) return;
    for (final row in selected.values) {
      row.selected = false;
      row.bound = true;
      row.error = null;
    }
    setState(() => _notice = '选中商品图片已绑定成功');
  });
  void _cancel() {
    _version++;
    final rows = [..._batch, ?_single, ?_defaultPick];
    for (final row in rows) {
      unawaited(_release(row.file));
    }
    setState(() {
      _batch = [];
      _single = null;
      _defaultPick = null;
      _notice = '已停止后续处理；已发送的存储或绑定请求不能撤回';
      _error = null;
    });
  }

  Future<void> _readMissing(int version) async {
    setState(() => _missingLoaded = false);
    final data = await _request(BmsProductImageOperation.missing);
    if (!_check(version)) return;
    final groups = _rows(data['cates']);
    for (final group in groups) {
      if (group['n'] is! String) throw const FormatException('分类数据无效');
      for (final product in _rows(group['p'])) {
        if (_id(product['id']) <= 0 || product['n'] is! String) {
          throw const FormatException('缺图商品数据无效');
        }
      }
    }
    setState(() {
      _missing = groups;
      _missingLoaded = true;
    });
  }

  Future<void> _singleChoose(Map<String, Object?> product) =>
      _run((version) async {
        final files = await _pick(false, version);
        if (files == null || !_check(version)) return;
        if (_single != null) await _release(_single!.file);
        _single = _Row(
          files.single,
          id: _id(product['id']),
          displayName: '${product['n']}',
        );
        setState(() {});
        await _singleSave(version);
      });
  Future<void> _singleSave(int version) async {
    final row = _single;
    if (row == null) return;
    if (row.uploaded == null && !await _upload(row, version)) return;
    if (!_check(version)) return;
    await _request(BmsProductImageOperation.bindSingle, {
      'prd_id': row.id,
      'prd_name': row.uploaded!.fileName,
    });
    if (!_check(version)) return;
    setState(() {
      _single = null;
      _notice = '商品图片已绑定成功';
    });
    await _readMissing(version);
  }

  Future<void> _readDefault(int version) async {
    setState(() => _defaultLoaded = false);
    final data = await _request(BmsProductImageOperation.getDefault);
    if (!_check(version)) return;
    final mode = _id(data['mode']);
    if (![1, 2].contains(mode) ||
        (data['def_pic_name'] != null && data['def_pic_name'] is! String)) {
      throw const FormatException('默认图片配置无法识别');
    }
    final filename = (data['def_pic_name'] as String?) ?? '',
        prefix = '${data['pic_prefix'] ?? ''}';
    setState(() {
      _mode = mode == 1;
      _defaultName = filename;
      _defaultUrl = filename.isEmpty ? '' : '$prefix$filename';
      _defaultThumbnail = null;
      _defaultLoaded = true;
    });
  }

  Future<void> _chooseDefault() => _run((version) async {
    final files = await _pick(false, version);
    if (files == null || !_check(version)) return;
    if (_defaultPick != null) await _release(_defaultPick!.file);
    final row = _defaultPick = _Row(files.single);
    setState(() {});
    await _stageDefault(row, version);
  });
  Future<void> _stageDefault(_Row row, int version) async {
    if (row.uploaded == null && !await _upload(row, version)) return;
    if (!_check(version)) return;
    setState(() {
      _defaultName = row.uploaded!.fileName;
      _defaultUrl = '';
      _defaultThumbnail = row.uploaded!.thumbnail;
      _notice = '图片已上传存储，点击保存后才生效';
    });
  }

  Future<void> _saveDefault() => _run((version) async {
    await _request(BmsProductImageOperation.saveDefault, {
      'mode': _mode ? 1 : 2,
      'def_pic_name': _defaultName,
    });
    if (!_check(version)) return;
    setState(() => _notice = '默认图片设置已保存');
    await _readDefault(version);
  });
  void _changeTab(int tab) {
    if (_busy) return;
    setState(() {
      _tab = tab;
      _error = null;
      _notice = null;
    });
    if (tab == 1) unawaited(_run(_readMissing));
    if (tab == 2) unawaited(_run(_readDefault));
  }

  Widget _preview(_Row row) => row.uploaded == null
      ? const Icon(Icons.image_outlined)
      : Image.memory(
          row.uploaded!.thumbnail,
          width: 72,
          height: 72,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
        );
  Widget _defaultImage() => _defaultThumbnail != null
      ? Image.memory(_defaultThumbnail!, fit: BoxFit.contain)
      : _defaultUrl.isNotEmpty
      ? Image.network(
          _defaultUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Text('图片预览不可用'),
        )
      : const Text('未设置时使用系统默认图片');
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < 3; i++)
              TextButton(
                onPressed: _busy ? null : () => _changeTab(i),
                child: Text(
                  ['批量上传图片', '图片检测', '商品默认图片'][i],
                  style: TextStyle(
                    fontWeight: _tab == i ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      ),
      if (_busy) const LinearProgressIndicator(),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      if (_notice != null)
        Padding(padding: const EdgeInsets.all(8), child: Text(_notice!)),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_tab == 0) ...[
              const Text(
                '按商品或套餐名称命名图片。支持 PNG/JPG/JPEG，单张小于500KiB，最多200张。同名以最后一张为准。存储上传成功后仍需导入选中才绑定商品。',
              ),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: _busy ? null : _chooseBatch,
                    child: const Text('批量上传'),
                  ),
                  TextButton(
                    onPressed: _busy || _batch.isEmpty
                        ? null
                        : () => _run(_matchAndUpload),
                    child: const Text('重试匹配/上传'),
                  ),
                  TextButton(
                    onPressed: _batch.isEmpty ? null : _cancel,
                    child: const Text('取消当前批次'),
                  ),
                ],
              ),
              if (_batch.isNotEmpty)
                CheckboxListTile(
                  title: const Text('全选已上传图片'),
                  value:
                      _batch
                          .where((r) => r.uploaded != null && !r.bound)
                          .isNotEmpty &&
                      _batch
                          .where((r) => r.uploaded != null && !r.bound)
                          .every((r) => r.selected),
                  onChanged: _busy
                      ? null
                      : (selected) => setState(() {
                          for (final row in _batch) {
                            row.selected =
                                selected == true &&
                                row.uploaded != null &&
                                !row.bound;
                          }
                        }),
                ),
              for (final row in _batch)
                Card(
                  child: CheckboxListTile(
                    value: row.selected,
                    onChanged: _busy || row.uploaded == null || row.bound
                        ? null
                        : (v) => setState(() => row.selected = v == true),
                    secondary: _preview(row),
                    title: Text(row.file.name),
                    subtitle: Text(
                      row.error ??
                          (row.bound
                              ? '已绑定'
                              : row.uploaded == null
                              ? '待匹配/上传'
                              : '已上传存储，待导入'),
                    ),
                  ),
                ),
              FilledButton(
                key: const Key('product-image-bind'),
                onPressed: _busy || _batch.isEmpty ? null : _bindBatch,
                child: const Text('导入选中'),
              ),
            ],
            if (_tab == 1) ...[
              TextButton(
                onPressed: _busy ? null : () => _run(_readMissing),
                child: const Text('重新检测'),
              ),
              if (_missingLoaded)
                Text(
                  '检测完毕，以下${_missing.fold<int>(0, (n, g) => n + _rows(g['p']).length)}个单品/套餐尚无图片',
                ),
              for (final group in _missing) ...[
                Text(
                  '${group['n']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final product in _rows(group['p']))
                  ListTile(
                    title: Text('${product['n']}'),
                    trailing: const Icon(Icons.upload),
                    onTap: _busy ? null : () => _singleChoose(product),
                  ),
              ],
              if (_single != null)
                Card(
                  child: Column(
                    children: [
                      Text(_single!.name),
                      _preview(_single!),
                      Text(_single!.error ?? '图片已上传存储，等待绑定'),
                      TextButton(
                        onPressed: _busy ? null : () => _run(_singleSave),
                        child: const Text('重试当前商品'),
                      ),
                      TextButton(
                        onPressed: _cancel,
                        child: const Text('取消当前商品'),
                      ),
                    ],
                  ),
                ),
            ],
            if (_tab == 2) ...[
              TextButton(
                onPressed: _busy ? null : () => _run(_readDefault),
                child: const Text('重新读取默认设置'),
              ),
              SwitchListTile(
                title: const Text('菜单显示图片'),
                value: _mode,
                onChanged: _busy || !_defaultLoaded
                    ? null
                    : (v) => setState(() => _mode = v),
              ),
              const Text('开启后显示商品对应图片；没有商品图片时使用默认图片，未设置则使用系统默认图片。'),
              SizedBox(height: 140, child: _defaultImage()),
              if (_defaultPick?.error != null)
                Text(
                  _defaultPick!.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _busy || !_defaultLoaded ? null : _chooseDefault,
                    child: const Text('选择默认图片'),
                  ),
                  if (_defaultPick != null && _defaultPick!.uploaded == null)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run((v) => _stageDefault(_defaultPick!, v)),
                      child: const Text('重试默认图片上传'),
                    ),
                  TextButton(
                    onPressed: _busy || !_defaultLoaded
                        ? null
                        : () => setState(() {
                            _defaultName = '';
                            _defaultUrl = '';
                            _defaultThumbnail = null;
                          }),
                    child: const Text('删除默认图片（保存后生效）'),
                  ),
                  TextButton(
                    onPressed: _defaultName.isEmpty
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              content: SizedBox(
                                width: 600,
                                height: 400,
                                child: _defaultImage(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('关闭'),
                                ),
                              ],
                            ),
                          ),
                    child: const Text('查看大图'),
                  ),
                  FilledButton(
                    key: const Key('product-image-default-save'),
                    onPressed: _busy || !_defaultLoaded ? null : _saveDefault,
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
