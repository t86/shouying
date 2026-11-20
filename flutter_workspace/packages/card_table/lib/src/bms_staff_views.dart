import 'dart:async';

import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:flutter/material.dart';

// =============================================================================
// S7.P1.T01 工号生成规则视图
// =============================================================================

class BmsCodeRulesView extends StatefulWidget {
  const BmsCodeRulesView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsCodeRulesView> createState() => _BmsCodeRulesViewState();
}

class _BmsCodeRulesViewState extends State<BmsCodeRulesView> {
  int _passwordType = 1;
  late TextEditingController _passwordCtrl;
  late TextEditingController _bitLenCtrl;
  bool _loading = false;
  bool _loaded = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _passwordCtrl = TextEditingController();
    _bitLenCtrl = TextEditingController(text: '6');
    _loadRule();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _bitLenCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRule() async {
    setState(() {
      _loading = true;
      _loaded = false;
      _message = null;
    });
    final res = await widget.loader.loadGenRule();
    if (mounted) {
      if (res.failureOrNull == null) {
        _loaded = true;
        final rule = res.valueOrNull ?? const BmsGenRule();
        _passwordType = rule.passwdUseCode;
        _passwordCtrl.text = rule.fixedPasswd;
        _bitLenCtrl.text = rule.codeLength.toString();
      } else {
        _message = res.failureOrNull!.safeMessage;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _saveRule() async {
    final length = int.tryParse(_bitLenCtrl.text);
    if (length == null || length < 2 || length > 8) {
      setState(() => _message = '工号位数范围为2-8');
      return;
    }
    if (_passwordType == 2 && !RegExp(r'^\d+$').hasMatch(_passwordCtrl.text)) {
      setState(() => _message = '请输入密码，密码只能为数字');
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    final res = await widget.loader.saveGenRule({
      'passwd_use_code': _passwordType,
      'fixed_passwd': _passwordCtrl.text,
      'code_length': length,
    });
    if (mounted) {
      setState(() {
        _loading = false;
        _message = res.failureOrNull == null
            ? '保存成功'
            : '保存失败: ${res.failureOrNull?.safeMessage}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工号生成规则'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadRule,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _passwordType,
                      decoration: const InputDecoration(labelText: '默认密码生成方式'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('与员工号相同')),
                        DropdownMenuItem(value: 2, child: Text('指定密码')),
                      ],
                      onChanged: (v) => setState(() => _passwordType = v!),
                    ),
                    if (_passwordType == 2)
                      TextField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(labelText: '指定密码'),
                        obscureText: true,
                        keyboardType: TextInputType.number,
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bitLenCtrl,
                      decoration: const InputDecoration(
                        labelText: '工号位数',
                        helperText: '位数范围为2-8，默认为6',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    if (_message != null) ...[
                      Text(
                        _message!,
                        style: const TextStyle(color: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      key: const Key('bms-code-rules-save-btn'),
                      onPressed: _loaded ? _saveRule : null,
                      child: const Text('保存规则'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// =============================================================================
// S7.P1.T02 ~ T06 岗位管理视图
// =============================================================================

class BmsStationConfigView extends StatefulWidget {
  const BmsStationConfigView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsStationConfigView> createState() => _BmsStationConfigViewState();
}

class _BmsStationConfigViewState extends State<BmsStationConfigView> {
  List<BmsStationItem> _stations = [];
  bool _loading = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadStations(
      keyword: _searchCtrl.text.trim(),
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _stations = res.valueOrNull ?? [];
      });
    }
  }

  Future<void> _toggleStatus(BmsStationItem station) async {
    final newStatus = !station.isValid;
    await widget.loader.setStationStatus(station.id, newStatus);
    _loadData();
  }

  Future<void> _deleteStation(BmsStationItem station) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确认删除岗位「${station.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.loader.deleteStation(station.id);
      _loadData();
    }
  }

  void _openStationForm([BmsStationItem? station]) {
    final nameCtrl = TextEditingController(text: station?.name ?? '');
    final descCtrl = TextEditingController(text: station?.desc ?? '');
    bool isWaiter = station?.isWaiter ?? false;
    bool isCashier = station?.isCashier ?? false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                station == null ? '新建岗位' : '编辑岗位',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '岗位名称'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '岗位说明'),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('是否服务员'),
                value: isWaiter,
                onChanged: (v) => setModalState(() => isWaiter = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('是否收银员'),
                value: isCashier,
                onChanged: (v) => setModalState(() => isCashier = v ?? false),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      await widget.loader.saveStation({
                        if (station != null) 'id': station.id,
                        'name': nameCtrl.text.trim(),
                        'desc': descCtrl.text.trim(),
                        'is_waiter': isWaiter ? 1 : 0,
                        'is_cashier': isCashier ? 1 : 0,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    },
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('岗位管理'),
        actions: [
          IconButton(
            key: const Key('bms-station-add-btn'),
            icon: const Icon(Icons.add),
            onPressed: () => _openStationForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: '搜索岗位名称',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _loadData(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _loadData, child: const Text('查询')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _stations.isEmpty
                ? const Center(child: Text('暂无岗位数据'))
                : ListView.separated(
                    itemCount: _stations.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final item = _stations[idx];
                      return ListTile(
                        key: Key('bms-station-item-${item.id}'),
                        title: Text(item.name),
                        subtitle: Text(item.desc.isEmpty ? '无说明' : item.desc),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            Switch(
                              value: item.isValid,
                              onChanged: (_) => _toggleStatus(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _openStationForm(item),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteStation(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// S7.P1.T07 ~ T10 员工管理视图
// =============================================================================

class BmsEmployeeListView extends StatefulWidget {
  const BmsEmployeeListView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsEmployeeListView> createState() => _BmsEmployeeListViewState();
}

class _BmsEmployeeListViewState extends State<BmsEmployeeListView> {
  List<BmsEmployeeItem> _employees = [];
  bool _loading = false;
  bool _resetting = false;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadEmployees(
      keyword: _searchCtrl.text.trim(),
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _employees = res.valueOrNull ?? [];
        _error = res.failureOrNull?.safeMessage;
        _selectedIds.clear();
      });
    }
  }

  Future<void> _batchResetPwd() async {
    if (_resetting) return;
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先勾选需要重置密码的员工')));
      return;
    }
    setState(() => _resetting = true);
    final res = await widget.loader.batchResetEmpPwd(_selectedIds.toList());
    if (mounted) {
      setState(() => _resetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.failureOrNull == null
                ? '已成功重置密码'
                : '重置失败: ${res.failureOrNull!.safeMessage}',
          ),
        ),
      );
    }
  }

  void _openEmployeeForm([BmsEmployeeItem? emp]) {
    final nameCtrl = TextEditingController(text: emp?.name ?? '');
    final empNoCtrl = TextEditingController(text: emp?.empNo ?? '');
    final phoneCtrl = TextEditingController(text: emp?.phone ?? '');
    final stationIdCtrl = TextEditingController(text: emp?.stationId ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emp == null ? '新建员工' : '编辑员工',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '员工姓名'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: empNoCtrl,
              decoration: const InputDecoration(labelText: '工号'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: '手机号'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stationIdCtrl,
              decoration: const InputDecoration(labelText: '岗位ID'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await widget.loader.saveEmployee({
                      if (emp != null) 'id': emp.id,
                      'name': nameCtrl.text.trim(),
                      'emp_no': empNoCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'station_id': stationIdCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadData();
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('员工管理'),
        actions: [
          IconButton(
            key: const Key('bms-emp-batch-reset-pwd-btn'),
            icon: const Icon(Icons.lock_reset),
            tooltip: '批量重置密码',
            onPressed: _loading || _resetting ? null : _batchResetPwd,
          ),
          IconButton(
            key: const Key('bms-emp-add-btn'),
            icon: const Icon(Icons.add),
            tooltip: '新建员工',
            onPressed: () => _openEmployeeForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: '搜索员工姓名/工号/手机',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _loadData(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _loadData, child: const Text('查询')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _employees.isEmpty
                ? const Center(child: Text('暂无员工数据'))
                : ListView.separated(
                    itemCount: _employees.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final item = _employees[idx];
                      final isSelected = _selectedIds.contains(item.id);
                      return CheckboxListTile(
                        key: Key('bms-emp-item-${item.id}'),
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedIds.add(item.id);
                            } else {
                              _selectedIds.remove(item.id);
                            }
                          });
                        },
                        title: Text(
                          '${item.name} (${item.empNo.isEmpty ? '无工号' : item.empNo})',
                        ),
                        subtitle: Text(
                          '手机: ${item.phone} | 岗位: ${item.stationName.isEmpty ? '未分配' : item.stationName}',
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _openEmployeeForm(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// S7.P1.T11 入职审批视图
// =============================================================================

class BmsOnboardingApprovalView extends StatefulWidget {
  const BmsOnboardingApprovalView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsOnboardingApprovalView> createState() =>
      _BmsOnboardingApprovalViewState();
}

class _BmsOnboardingApprovalViewState extends State<BmsOnboardingApprovalView> {
  List<BmsOnboardingApprovalItem> _items = [];
  bool _loading = false;
  int _status = 1, _page = 1, _pageSize = 20, _total = 0;
  final Set<String> _selected = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadOnboardingPage(
      status: _status,
      page: _page,
      pageSize: _pageSize,
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _error = res.failureOrNull?.safeMessage;
        if (res.valueOrNull case final data?) {
          _items = data.items;
          _total = data.total;
          _page = data.page;
          _pageSize = data.pageSize;
          _selected.clear();
        }
      });
    }
  }

  Future<void> _audit(bool pass) async {
    if (_selected.isEmpty) {
      setState(() => _error = '请选择要审批的记录');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(pass ? '批量通过确认' : '批量驳回确认'),
        content: Text('确认处理选中的 ${_selected.length} 条入职申请？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    final result = await widget.loader.auditOnboardingBatch(
      _selected.toList(),
      pass,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result.failureOrNull?.safeMessage;
    });
    if (result.failureOrNull == null) await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('入职审批'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Wrap(
            spacing: 12,
            children: [
              for (final entry in {1: '待审批', 5: '已通过', 2: '已驳回'}.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _status == entry.key,
                  onSelected: _loading
                      ? null
                      : (_) {
                          setState(() {
                            _status = entry.key;
                            _page = 1;
                            _items = [];
                            _selected.clear();
                          });
                          unawaited(_loadData());
                        },
                ),
            ],
          ),
          if (_status == 1)
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                          if (_selected.length == _items.length) {
                            _selected.clear();
                          } else {
                            _selected.addAll(_items.map((e) => e.id));
                          }
                        }),
                  child: const Text('全选/取消全选'),
                ),
                FilledButton(
                  onPressed: _loading ? null : () => _audit(true),
                  child: const Text('批量通过'),
                ),
                OutlinedButton(
                  onPressed: _loading ? null : () => _audit(false),
                  child: const Text('批量驳回'),
                ),
              ],
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(child: Text('暂无待审批员工'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final item = _items[idx];
                      return CheckboxListTile(
                        key: Key('bms-onboarding-item-${item.id}'),
                        value: _selected.contains(item.id),
                        onChanged: _status != 1
                            ? null
                            : (v) => setState(() {
                                if (v == true) {
                                  _selected.add(item.id);
                                } else {
                                  _selected.remove(item.id);
                                }
                              }),
                        title: Text(item.name),
                        subtitle: Text(
                          '申请岗位: ${item.stationName} | 手机: ${item.phone}\n时间: ${item.applyTime}',
                        ),
                        secondary: _status == 1
                            ? IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _edit(item),
                              )
                            : null,
                      );
                    },
                  ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text('第 $_page 页，共 $_total 条'),
              DropdownButton<int>(
                value: _pageSize,
                items: [10, 20, 30, 50]
                    .map(
                      (v) => DropdownMenuItem(value: v, child: Text('$v 条/页')),
                    )
                    .toList(),
                onChanged: _loading
                    ? null
                    : (v) {
                        _pageSize = v!;
                        _page = 1;
                        unawaited(_loadData());
                      },
              ),
              TextButton(
                onPressed: _loading || _page <= 1
                    ? null
                    : () {
                        _page--;
                        unawaited(_loadData());
                      },
                child: const Text('上一页'),
              ),
              TextButton(
                onPressed: _loading || _page * _pageSize >= _total
                    ? null
                    : () {
                        _page++;
                        unawaited(_loadData());
                      },
                child: const Text('下一页'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BmsOnboardingApprovalItem item) async {
    final departments = await widget.loader.loadDepartments();
    final stations = await widget.loader.loadStations();
    if (!mounted) return;
    if (departments.failureOrNull != null || stations.failureOrNull != null) {
      setState(
        () => _error =
            departments.failureOrNull?.safeMessage ??
            stations.failureOrNull?.safeMessage,
      );
      return;
    }
    final name = TextEditingController(text: item.name),
        realName = TextEditingController(text: item.realName),
        upper = TextEditingController(text: item.upperEmpId),
        upperSearch = TextEditingController();
    final upperOptions = <String, String>{
      if (item.upperEmpId.isNotEmpty && item.upperEmpId != '0')
        item.upperEmpId: '员工 ${item.upperEmpId}',
    };
    bool searchingUpper = false;
    var deptId = item.deptId, stationId = item.stationId, sex = item.sex;
    String? error;
    bool saving = false;
    final depts = _flattenDepartments(departments.valueOrNull ?? []);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('编辑入职申请'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '姓名'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: depts.any((e) => e.id == deptId)
                        ? deptId
                        : null,
                    decoration: const InputDecoration(labelText: '部门'),
                    items: depts
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => deptId = v!,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue:
                        stations.valueOrNull!.any((e) => e.id == stationId)
                        ? stationId
                        : null,
                    decoration: const InputDecoration(labelText: '岗位'),
                    items: stations.valueOrNull!
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => stationId = v!,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: sex,
                    decoration: const InputDecoration(labelText: '性别'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('男')),
                      DropdownMenuItem(value: 2, child: Text('女')),
                    ],
                    onChanged: (v) => sex = v!,
                  ),
                  TextField(
                    controller: upperSearch,
                    decoration: const InputDecoration(labelText: '搜索直属上级'),
                  ),
                  TextButton(
                    onPressed: searchingUpper || saving
                        ? null
                        : () async {
                            if (upperSearch.text.trim().isEmpty) return;
                            update(() {
                              searchingUpper = true;
                              error = null;
                            });
                            final result = await widget.loader
                                .loadUpperEmployees(upperSearch.text.trim());
                            if (!ctx.mounted) return;
                            update(() {
                              searchingUpper = false;
                              error = result.failureOrNull?.safeMessage;
                              if (result.valueOrNull case final employees?) {
                                final selectedName = upperOptions[upper.text];
                                upperOptions.clear();
                                if (selectedName != null) {
                                  upperOptions[upper.text] = selectedName;
                                }
                                for (final employee in employees) {
                                  upperOptions[employee.id] = employee.name;
                                }
                              }
                            });
                          },
                    child: const Text('搜索上级'),
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey(upper.text),
                    initialValue: upperOptions.containsKey(upper.text)
                        ? upper.text
                        : '',
                    decoration: const InputDecoration(labelText: '直属上级（可留空）'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('无直属上级')),
                      ...upperOptions.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text('${e.key} - ${e.value}'),
                        ),
                      ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) => update(() => upper.text = v ?? ''),
                  ),
                  TextField(
                    controller: realName,
                    decoration: const InputDecoration(labelText: '真实姓名'),
                  ),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (name.text.trim().isEmpty ||
                          int.tryParse(deptId) == null ||
                          int.tryParse(stationId) == null ||
                          (upper.text.isNotEmpty &&
                              int.tryParse(upper.text) == null)) {
                        update(() => error = '请填写姓名并选择部门、岗位；上级ID只能为数字');
                        return;
                      }
                      update(() {
                        saving = true;
                        error = null;
                      });
                      final result = await widget.loader.saveOnboarding({
                        'id': item.id,
                        'name': name.text.trim(),
                        'dept_id': int.parse(deptId),
                        'station_id': int.parse(stationId),
                        'sex': sex,
                        'upper_emp_id': int.tryParse(upper.text) ?? 0,
                        'real_name': realName.text,
                      });
                      if (!ctx.mounted) return;
                      if (result.failureOrNull != null) {
                        update(() {
                          saving = false;
                          error = result.failureOrNull!.safeMessage;
                        });
                        return;
                      }
                      Navigator.pop(ctx);
                      unawaited(_loadData());
                    },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    // Dialog exit animation can still reference its controllers.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    realName.dispose();
    upper.dispose();
    upperSearch.dispose();
  }
}

List<BmsDepartmentOption> _flattenDepartments(
  List<BmsDepartmentOption> items, [
  String prefix = '',
]) => [
  for (final item in items) ...[
    BmsDepartmentOption(item.id, '$prefix${item.name}'),
    ..._flattenDepartments(item.children, '$prefix${item.name} / '),
  ],
];

// =============================================================================
// S7.P1.T12 商务组订位人视图
// =============================================================================

class BmsBusinessEmpView extends StatefulWidget {
  const BmsBusinessEmpView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsBusinessEmpView> createState() => _BmsBusinessEmpViewState();
}

class _BmsBusinessEmpViewState extends State<BmsBusinessEmpView> {
  List<BmsBusinessEmpItem> _items = [];
  List<BmsEmployeeItem> _candidates = [];
  List<BmsDepartmentOption> _departments = [];
  final _candidateIds = <String>{}, _removeIds = <String>{};
  final _candidateDepts = <String>{}, _selectedDepts = <String>{};
  final _candidateKey = TextEditingController(),
      _selectedKey = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
    unawaited(_loadDepartments());
  }

  @override
  void dispose() {
    _candidateKey.dispose();
    _selectedKey.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    final result = await widget.loader.loadDepartments();
    if (mounted) {
      setState(() {
        _departments = _flattenDepartments(result.valueOrNull ?? []);
        _error = result.failureOrNull?.safeMessage;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadBusinessEmployees(
      keyword: _selectedKey.text,
      deptIds: _selectedDepts.toList(),
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _error = res.failureOrNull?.safeMessage;
        if (res.valueOrNull case final data?) {
          _items = data;
          _removeIds.clear();
          _candidateIds.removeAll(data.map((e) => e.id));
        }
      });
    }
  }

  Future<void> _queryCandidates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.loader.loadBusinessCandidates(
      keyword: _candidateKey.text,
      deptIds: _candidateDepts.toList(),
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _error = result.failureOrNull?.safeMessage;
        if (result.valueOrNull case final data?) {
          _candidates = data;
          _candidateIds.clear();
        }
      });
    }
  }

  Future<void> _add() async {
    if (_candidateIds.isEmpty) {
      setState(() => _error = '请选择需要添加的员工');
      return;
    }
    setState(() => _loading = true);
    final result = await widget.loader.addBusinessEmployees(
      _candidateIds.toList(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result.failureOrNull?.safeMessage;
    });
    if (result.failureOrNull == null) {
      _candidateIds.clear();
      await _loadData();
    }
  }

  Future<void> _remove(List<String> ids) async {
    if (ids.isEmpty) {
      setState(() => _error = '请选择需要删除的员工');
      return;
    }
    setState(() => _loading = true);
    String? failure;
    for (final id in ids) {
      final result = await widget.loader.setBusinessEmp(id, false);
      if (result.failureOrNull != null) {
        failure = result.failureOrNull!.safeMessage;
        break;
      }
    }
    if (!mounted) return;
    await _loadData();
    if (mounted && failure != null) setState(() => _error = failure);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商务组订位人')),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final panels = [
                  Expanded(child: _panel(false)),
                  Expanded(child: _panel(true)),
                ];
                return constraints.maxWidth < 600
                    ? Column(children: panels)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: panels,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(bool selected) {
    final ids = selected ? _removeIds : _candidateIds;
    final deptIds = selected ? _selectedDepts : _candidateDepts;
    final assigned = _items.map((e) => e.id).toSet();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(selected ? '已选商务组订位人' : '待选员工'),
          TextField(
            controller: selected ? _selectedKey : _candidateKey,
            decoration: const InputDecoration(labelText: '姓名/工号'),
            onSubmitted: (_) => selected ? _loadData() : _queryCandidates(),
          ),
          if (_departments.isNotEmpty)
            SizedBox(
              height: 60,
              child: SingleChildScrollView(
                child: Wrap(
                  children: [
                    for (final dept in _departments)
                      FilterChip(
                        label: Text(dept.name),
                        selected: deptIds.contains(dept.id),
                        onSelected: _loading
                            ? null
                            : (v) => setState(() {
                                if (v) {
                                  deptIds.add(dept.id);
                                } else {
                                  deptIds.remove(dept.id);
                                }
                              }),
                      ),
                  ],
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _loading
                    ? null
                    : selected
                    ? _loadData
                    : _queryCandidates,
                child: Text(selected ? '查询已选员工' : '查询待选员工'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          (selected ? _selectedKey : _candidateKey).clear();
                          deptIds.clear();
                          ids.clear();
                          if (!selected) _candidates = [];
                        });
                        if (selected) unawaited(_loadData());
                      },
                child: const Text('重置'),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        if (ids.isNotEmpty) {
                          ids.clear();
                        } else {
                          ids.addAll(
                            selected
                                ? _items.map((e) => e.id)
                                : _candidates
                                      .where((e) => !assigned.contains(e.id))
                                      .map((e) => e.id),
                          );
                        }
                      }),
                child: const Text('全选/取消全选'),
              ),
              FilledButton(
                onPressed: _loading
                    ? null
                    : selected
                    ? () => _remove(ids.toList())
                    : _add,
                child: Text(selected ? '批量删除' : '添加选中'),
              ),
            ],
          ),
          Expanded(
            child: selected
                ? _items.isEmpty
                      ? const Center(child: Text('暂未选择员工'))
                      : ListView(
                          children: [
                            for (final item in _items)
                              CheckboxListTile(
                                key: Key('bms-business-emp-${item.id}'),
                                value: ids.contains(item.id),
                                onChanged: _loading
                                    ? null
                                    : (v) => setState(() {
                                        if (v == true) {
                                          ids.add(item.id);
                                        } else {
                                          ids.remove(item.id);
                                        }
                                      }),
                                title: Text('${item.name} (${item.empNo})'),
                                subtitle: Text(item.deptName),
                                secondary: IconButton(
                                  key: Key('bms-business-remove-${item.id}'),
                                  onPressed: _loading
                                      ? null
                                      : () => _remove([item.id]),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                          ],
                        )
                : _candidates.isEmpty
                ? const Center(child: Text('请查询待选员工'))
                : ListView(
                    children: [
                      for (final item in _candidates)
                        CheckboxListTile(
                          key: Key('bms-business-candidate-${item.id}'),
                          value:
                              assigned.contains(item.id) ||
                              ids.contains(item.id),
                          onChanged: _loading || assigned.contains(item.id)
                              ? null
                              : (v) => setState(() {
                                  if (v == true) {
                                    ids.add(item.id);
                                  } else {
                                    ids.remove(item.id);
                                  }
                                }),
                          title: Text('${item.name} (${item.empNo})'),
                          subtitle: Text(item.deptName),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
