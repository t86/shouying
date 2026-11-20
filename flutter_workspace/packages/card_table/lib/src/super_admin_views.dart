import 'dart:async';

import 'package:card_table/src/super_admin_loader.dart';
import 'package:card_table/src/super_admin_models.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

/// S9 超级管理员主导航壳容器
class SuperAdminNavScreen extends StatefulWidget {
  const SuperAdminNavScreen({
    required this.loader,
    this.userName = '超级管理员',
    this.onBack,
    super.key,
  });

  final SuperAdminLoader loader;
  final String userName;
  final VoidCallback? onBack;

  @override
  State<SuperAdminNavScreen> createState() => _SuperAdminNavScreenState();
}

class _SuperAdminNavScreenState extends State<SuperAdminNavScreen> {
  bool _dialogOpen = false;
  bool _loggingOut = false;

  bool _current(SuperAdminLoader loader, int revision) =>
      mounted &&
      identical(widget.loader, loader) &&
      loader.sessionRevision == revision &&
      loader.isAuthenticated &&
      (ModalRoute.of(context)?.isActive ?? true);

  Future<void> _showChangePasswordDialog() async {
    if (_dialogOpen ||
        _loggingOut ||
        widget.loader.isBusy ||
        !widget.loader.isAuthenticated) {
      return;
    }
    _dialogOpen = true;
    final loader = widget.loader;
    final revision = loader.sessionRevision;
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    void clearInvalidSecrets() {
      if (!_current(loader, revision)) {
        oldPwdCtrl.clear();
        newPwdCtrl.clear();
      }
    }

    loader.addListener(clearInvalidSecrets);
    bool pending = false;
    String? error;
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AnimatedBuilder(
          animation: loader,
          builder: (ctx, _) {
            final active = _current(loader, revision);
            return AlertDialog(
              title: const Text('修改超级管理员密码'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: oldPwdCtrl,
                      enabled: active && !pending,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '原密码',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPwdCtrl,
                      enabled: active && !pending,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '新密码',
                        prefixIcon: Icon(Icons.key),
                      ),
                    ),
                    if (pending)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: LinearProgressIndicator(),
                      ),
                    if (!active || error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          !active ? '超级账号会话已变化，请关闭后重新操作' : error!,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: !active || pending || loader.isBusy
                      ? null
                      : () async {
                          if (oldPwdCtrl.text.isEmpty &&
                              newPwdCtrl.text.isEmpty) {
                            update(() => error = '新旧密码不能为空');
                            return;
                          }
                          update(() {
                            pending = true;
                            error = null;
                          });
                          try {
                            final res = await loader.changePassword(
                              oldPassword: oldPwdCtrl.text,
                              newPassword: newPwdCtrl.text,
                              canDispatch: () =>
                                  ctx.mounted &&
                                  (ModalRoute.of(ctx)?.isActive ?? true) &&
                                  _current(loader, revision),
                            );
                            if (!mounted ||
                                !ctx.mounted ||
                                !(ModalRoute.of(ctx)?.isActive ?? true) ||
                                !_current(loader, revision)) {
                              return;
                            }
                            if (res case Success()) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('密码修改成功')),
                              );
                            } else {
                              update(
                                () => error =
                                    res.failureOrNull?.safeMessage ?? '密码修改失败',
                              );
                            }
                          } on Object {
                            if (ctx.mounted &&
                                (ModalRoute.of(ctx)?.isActive ?? true) &&
                                _current(loader, revision)) {
                              update(() => error = '密码修改失败，请重试');
                            }
                          } finally {
                            if (ctx.mounted) update(() => pending = false);
                          }
                        },
                  child: Text(pending ? '正在修改…' : '确认修改'),
                ),
              ],
            );
          },
        ),
      ),
    );
    await Navigator.of(context).push(route);
    await route.completed;
    loader.removeListener(clearInvalidSecrets);
    oldPwdCtrl.dispose();
    newPwdCtrl.dispose();
    _dialogOpen = false;
  }

  Future<void> _logout() async {
    if (_loggingOut || widget.loader.isBusy || !widget.loader.isAuthenticated) {
      return;
    }
    final loader = widget.loader;
    final revision = loader.sessionRevision;
    setState(() => _loggingOut = true);
    try {
      final result = await loader.logout(
        canDispatch: () =>
            mounted &&
            identical(widget.loader, loader) &&
            loader.sessionRevision == revision &&
            (ModalRoute.of(context)?.isActive ?? true),
      );
      if (!mounted ||
          !identical(widget.loader, loader) ||
          !(ModalRoute.of(context)?.isActive ?? true)) {
        return;
      }
      if (result case Success()) {
        if (loader.isAuthenticated || loader.sessionRevision != revision + 1) {
          return;
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('退出成功')));
        widget.onBack?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.failureOrNull?.safeMessage ?? '退出失败，请重试'),
          ),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('退出失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.loader,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(
                Icons.admin_panel_settings,
                color: Colors.indigoAccent,
              ),
              const SizedBox(width: 8),
              const Text(
                '超级管理员后台 (AppInfo)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigoAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '超管最高权限',
                  style: TextStyle(fontSize: 12, color: Colors.indigoAccent),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 6),
                Text(
                  widget.userName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed:
                      widget.loader.isBusy ||
                          !widget.loader.isAuthenticated ||
                          _loggingOut
                      ? null
                      : _showChangePasswordDialog,
                  icon: const Icon(Icons.lock_reset, size: 18),
                  label: const Text('修改密码'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed:
                      widget.loader.isBusy ||
                          !widget.loader.isAuthenticated ||
                          _loggingOut
                      ? null
                      : _logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(_loggingOut ? '正在退出…' : '退出超管'),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ],
        ),
        body: SuperAdminSmgrView(loader: widget.loader),
      ),
    );
  }
}

/// S9.P1 用户与岗位管理视图 (/ManagementSystem/appinfo/smgr)
class SuperAdminSmgrView extends StatefulWidget {
  const SuperAdminSmgrView({required this.loader, super.key});

  final SuperAdminLoader loader;

  @override
  State<SuperAdminSmgrView> createState() => _SuperAdminSmgrViewState();
}

class _SuperAdminSmgrViewState extends State<SuperAdminSmgrView> {
  bool _isLoading = false;
  bool _pendingAction = false;
  bool _confirmationOpen = false;
  int _sessionRevision = 0;
  int _requestEpoch = 0;
  String? _loadError;
  bool _needsInit = true;
  List<SmgrDeptItem> _departments = const [];
  List<SmgrStationItem> _stations = const [];
  List<SmgrStationRow> _stationRows = [];

  int _selectedDeptId = 0;
  String _selectedStationId = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sessionRevision = widget.loader.sessionRevision;
    widget.loader.addListener(_sessionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadData(isInit: true));
    });
  }

  @override
  void didUpdateWidget(covariant SuperAdminSmgrView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.loader, widget.loader)) {
      oldWidget.loader.removeListener(_sessionChanged);
      widget.loader.addListener(_sessionChanged);
      _clearSessionData();
      unawaited(_loadData(isInit: true));
    }
  }

  void _clearSessionData() {
    _sessionRevision = widget.loader.sessionRevision;
    _requestEpoch++;
    _departments = const [];
    _stations = const [];
    _stationRows = [];
    _selectedDeptId = 0;
    _selectedStationId = '';
    _searchCtrl.clear();
    _isLoading = false;
    _pendingAction = false;
    _loadError = null;
    _needsInit = true;
  }

  void _sessionChanged() {
    if (!mounted) return;
    final changed = _sessionRevision != widget.loader.sessionRevision;
    setState(() {
      if (changed || !widget.loader.isAuthenticated) _clearSessionData();
    });
    if (_needsInit && !widget.loader.isBusy && widget.loader.isAuthenticated) {
      unawaited(_loadData(isInit: true));
    }
  }

  bool _current(SuperAdminLoader loader, int revision) =>
      mounted &&
      identical(widget.loader, loader) &&
      loader.isAuthenticated &&
      loader.sessionRevision == revision &&
      (ModalRoute.of(context)?.isActive ?? true);

  bool get _busy =>
      _isLoading || _pendingAction || _confirmationOpen || widget.loader.isBusy;

  @override
  void dispose() {
    _requestEpoch++;
    widget.loader.removeListener(_sessionChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool isInit = false}) async {
    if (_isLoading || widget.loader.isBusy || !widget.loader.isAuthenticated) {
      return;
    }
    final loader = widget.loader;
    final revision = loader.sessionRevision;
    final epoch = ++_requestEpoch;
    if (isInit) _needsInit = false;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final res = await loader.loadEmps(
        isInit: isInit ? 1 : 2,
        deptId: _selectedDeptId,
        stationId: _selectedStationId,
        name: _searchCtrl.text,
        canDispatch: () => _current(loader, revision) && epoch == _requestEpoch,
      );
      if (!_current(loader, revision) || epoch != _requestEpoch) return;
      setState(() {
        if (res case Success(:final value)) {
          if (isInit) {
            _departments = value.departments;
            _stations = value.stations;
          }
          final expanded = {
            for (final row in _stationRows) row.id: row.isExpanded,
          };
          _stationRows = [
            for (final row in value.stationRows)
              row.copyWith(isExpanded: expanded[row.id] ?? false),
          ];
        } else {
          if (isInit) _needsInit = true;
          _loadError = res.failureOrNull?.safeMessage ?? '读取用户列表失败';
        }
      });
    } on Object {
      if (_current(loader, revision) && epoch == _requestEpoch) {
        setState(() {
          if (isInit) _needsInit = true;
          _loadError = '读取用户列表失败，请重试';
        });
      }
    } finally {
      if (_current(loader, revision) && epoch == _requestEpoch) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetFilters() {
    if (_busy) return;
    setState(() {
      _selectedDeptId = 0;
      _selectedStationId = '';
      _searchCtrl.clear();
    });
    unawaited(_loadData());
  }

  Iterable<DropdownMenuItem<int>> _departmentItems(
    List<SmgrDeptItem> items, [
    String parent = '',
  ]) sync* {
    for (final item in items) {
      final path = parent.isEmpty ? item.name : '$parent / ${item.name}';
      yield DropdownMenuItem(
        value: item.id,
        child: Text(path, overflow: TextOverflow.ellipsis),
      );
      yield* _departmentItems(item.children, path);
    }
  }

  void _toggleExpand(int index) {
    setState(() {
      final item = _stationRows[index];
      _stationRows[index] = item.copyWith(isExpanded: !item.isExpanded);
    });
  }

  Future<void> _write(
    Future<Result<void>> Function(
      SuperAdminLoader loader,
      bool Function() guard,
    )
    action,
    String success,
  ) async {
    if (_busy || !widget.loader.isAuthenticated) return;
    final loader = widget.loader;
    final revision = loader.sessionRevision;
    bool guard() => _current(loader, revision);
    setState(() => _pendingAction = true);
    try {
      final res = await action(loader, guard);
      if (!mounted || !guard()) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res is Success<void>
                ? success
                : res.failureOrNull?.safeMessage ?? '操作失败',
          ),
        ),
      );
      if (res case Success()) await _loadData();
    } on Object {
      if (mounted && guard()) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('操作失败，请重试')));
      }
    } finally {
      if (guard()) setState(() => _pendingAction = false);
    }
  }

  Future<void> _setStationEnable(SmgrStationRow row) => _write(
    (loader, guard) => loader.setStationEnable(row.id, canDispatch: guard),
    '岗位已置为有效',
  );

  Future<void> _toggleStationAdmin(SmgrStationRow row) async {
    final grant = !row.isAdmin;
    await _write(
      (loader, guard) =>
          loader.toggleStationAdmin(row.id, grant, canDispatch: guard),
      grant ? '已赋予管理员权限' : '已收回管理员权限',
    );
  }

  Future<void> _resetEmpPassword(SmgrEmpItem emp) async {
    if (_busy || !widget.loader.isAuthenticated) return;
    final loader = widget.loader;
    final revision = loader.sessionRevision;
    setState(() => _confirmationOpen = true);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AnimatedBuilder(
        animation: loader,
        builder: (ctx, _) => AlertDialog(
          title: const Text('重置密码确认'),
          content: Text(
            _current(loader, revision)
                ? '确定要重置员工【${emp.name}（工号: ${emp.code}）】的登录密码吗？'
                : '超级账号会话已变化，请关闭后重新操作',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: _current(loader, revision)
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('确认重置'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _confirmationOpen = false);
    if (confirm != true || !_current(loader, revision)) return;
    await _write(
      (loader, guard) => loader.resetEmpPassword(emp.id, canDispatch: guard),
      '密码重置成功',
    );
  }

  Future<void> _toggleEmpStatus(SmgrEmpItem emp) async {
    final enable = emp.status != '有效';
    await _write(
      (loader, guard) =>
          loader.toggleEmpStatus(emp.id, enable, canDispatch: guard),
      enable ? '已置为有效' : '已置为无效',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部筛选栏
        Material(
          elevation: 1,
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  '部门：',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  width: 180,
                  height: 38,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('dept-$_selectedDeptId-$_sessionRevision'),
                    initialValue: _selectedDeptId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: 0, child: Text('全部部门')),
                      ..._departmentItems(_departments),
                    ],
                    onChanged: _busy || !widget.loader.isAuthenticated
                        ? null
                        : (val) {
                            setState(() => _selectedDeptId = val ?? 0);
                          },
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  '岗位：',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  width: 180,
                  height: 38,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(
                      'station-$_selectedStationId-$_sessionRevision',
                    ),
                    initialValue: _selectedStationId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('全部岗位')),
                      for (final s in _stations)
                        DropdownMenuItem(
                          value: s.id.toString(),
                          child: Text(s.name),
                        ),
                    ],
                    onChanged: _busy || !widget.loader.isAuthenticated
                        ? null
                        : (val) {
                            setState(() => _selectedStationId = val ?? '');
                          },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  height: 38,
                  child: TextField(
                    enabled: !_busy && widget.loader.isAuthenticated,
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: '工号或姓名',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      if (!_busy) unawaited(_loadData(isInit: _needsInit));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _busy || !widget.loader.isAuthenticated
                      ? null
                      : () => _loadData(isInit: _needsInit),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('查询'),
                ),
                TextButton(
                  onPressed: _busy || !widget.loader.isAuthenticated
                      ? null
                      : _resetFilters,
                  child: const Text('重置'),
                ),
                IconButton(
                  onPressed: _busy || !widget.loader.isAuthenticated
                      ? null
                      : () => _loadData(isInit: _needsInit),
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                ),
              ],
            ),
          ),
        ),
        if (_pendingAction) const LinearProgressIndicator(),
        if (_loadError case final error?)
          MaterialBanner(
            content: Text(error),
            actions: [
              TextButton(
                onPressed: _busy ? null : () => _loadData(isInit: _needsInit),
                child: const Text('重试'),
              ),
            ],
          ),
        // 表格内容
        Expanded(
          child: !widget.loader.isAuthenticated
              ? const Center(child: Text('超级账号未登录，请重新登录'))
              : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _stationRows.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '暂无岗位及员工数据',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stationRows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final row = _stationRows[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            leading: IconButton(
                              icon: Icon(
                                row.isExpanded
                                    ? Icons.remove_circle_outline
                                    : Icons.add_circle_outline,
                              ),
                              color: Colors.indigo,
                              onPressed: () => _toggleExpand(index),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  row.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '员工数: ${row.empCount}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: row.status == '有效'
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    row.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: row.status == '有效'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _toggleStationAdmin(row),
                                  child: Text(
                                    row.isAdmin ? '收回管理员' : '设为管理员',
                                    style: TextStyle(
                                      color: row.isAdmin
                                          ? Colors.orange
                                          : Colors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _setStationEnable(row),
                                  child: const Text('置为有效'),
                                ),
                              ],
                            ),
                          ),
                          if (row.isExpanded) ...[
                            const Divider(height: 1),
                            Container(
                              color: Colors.grey.shade50,
                              padding: const EdgeInsets.all(12),
                              child: row.employees.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        '该岗位下暂无员工',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : Table(
                                      columnWidths: const {
                                        0: FlexColumnWidth(1.5),
                                        1: FlexColumnWidth(2),
                                        2: FlexColumnWidth(2),
                                        3: FlexColumnWidth(1.5),
                                        4: FlexColumnWidth(2),
                                        5: FlexColumnWidth(2),
                                      },
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      children: [
                                        TableRow(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                          ),
                                          children: const [
                                            Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                '员工编号',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                '员工姓名',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                '部门名称',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                '状态',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                '重置密码',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                '更改状态',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        for (final emp in row.employees)
                                          TableRow(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Text(emp.code),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Text(
                                                  emp.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Text(emp.deptName),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Text(
                                                  emp.status,
                                                  style: TextStyle(
                                                    color: emp.status == '有效'
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: TextButton(
                                                    onPressed: _busy
                                                        ? null
                                                        : () =>
                                                              _resetEmpPassword(
                                                                emp,
                                                              ),
                                                    child: const Text('重置密码'),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: TextButton(
                                                    onPressed: _busy
                                                        ? null
                                                        : () =>
                                                              _toggleEmpStatus(
                                                                emp,
                                                              ),
                                                    child: Text(
                                                      emp.status == '有效'
                                                          ? '置为无效'
                                                          : '置为有效',
                                                      style: TextStyle(
                                                        color:
                                                            emp.status == '有效'
                                                            ? Colors.red
                                                            : Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
