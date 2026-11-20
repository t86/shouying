import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:flutter/material.dart';

// =============================================================================
// S7.P5.T01 门店信息视图
// =============================================================================

class BmsStoreInfoView extends StatefulWidget {
  const BmsStoreInfoView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsStoreInfoView> createState() => _BmsStoreInfoViewState();
}

class _BmsStoreInfoViewState extends State<BmsStoreInfoView> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _provinceCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStoreInfo() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadStoreInfo();
    if (mounted) {
      if (res.failureOrNull == null) {
        final info = res.valueOrNull ?? const BmsStoreInfo();
        _nameCtrl.text = info.name;
        _phoneCtrl.text = info.phone;
        _provinceCtrl.text = info.province;
        _cityCtrl.text = info.city;
        _districtCtrl.text = info.district;
        _addressCtrl.text = info.address;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _saveStoreInfo() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final res = await widget.loader.saveStoreInfo({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'province': _provinceCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    });
    if (mounted) {
      setState(() {
        _loading = false;
        _message = res.failureOrNull == null ? '门店信息保存成功' : '保存失败';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('门店信息')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '门店名称')),
                    const SizedBox(height: 16),
                    TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: '联系电话')),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _provinceCtrl, decoration: const InputDecoration(labelText: '省份'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: '城市'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _districtCtrl, decoration: const InputDecoration(labelText: '区县'))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: '详细地址')),
                    const SizedBox(height: 24),
                    if (_message != null) ...[
                      Text(_message!, style: const TextStyle(color: Colors.blue)),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      key: const Key('bms-store-info-save-btn'),
                      onPressed: _saveStoreInfo,
                      child: const Text('保存门店信息'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// =============================================================================
// S7.P5.T02 营业日恢复视图
// =============================================================================

class BmsRestoreView extends StatefulWidget {
  const BmsRestoreView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsRestoreView> createState() => _BmsRestoreViewState();
}

class _BmsRestoreViewState extends State<BmsRestoreView> {
  bool _restoring = false;
  String? _statusText;

  Future<void> _restore() async {
    setState(() {
      _restoring = true;
      _statusText = null;
    });
    final res = await widget.loader.restoreWorkday();
    if (mounted) {
      setState(() {
        _restoring = false;
        _statusText = res.failureOrNull == null ? '营业日恢复成功！' : '恢复失败: ${res.failureOrNull?.safeMessage}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('营业日管理')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restore, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('如遇系统非正常关班或需重新开启昨日营业日，可点击下方按钮恢复'),
              const SizedBox(height: 24),
              if (_statusText != null) ...[
                Text(_statusText!, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                key: const Key('bms-restore-btn'),
                onPressed: _restoring ? null : _restore,
                child: Text(_restoring ? '恢复中…' : '恢复营业日'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// S7.P5.T03 渠道管理视图
// =============================================================================

class BmsPayListView extends StatefulWidget {
  const BmsPayListView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsPayListView> createState() => _BmsPayListViewState();
}

class _BmsPayListViewState extends State<BmsPayListView> {
  List<BmsPayChannelItem> _channels = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadPayChannels();
    if (mounted) {
      setState(() {
        _loading = false;
        _channels = res.valueOrNull ?? [];
      });
    }
  }

  Future<void> _toggleUsed(BmsPayChannelItem item) async {
    await widget.loader.setPayChannelUsed(item.id, !item.isUsed);
    _loadChannels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('渠道管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _channels.isEmpty
              ? const Center(child: Text('暂无支付渠道'))
              : ListView.separated(
                  itemCount: _channels.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final c = _channels[idx];
                    return SwitchListTile(
                      key: Key('bms-pay-channel-${c.id}'),
                      title: Text(c.name),
                      subtitle: Text('渠道编码: ${c.code}'),
                      value: c.isUsed,
                      onChanged: (_) => _toggleUsed(c),
                    );
                  },
                ),
    );
  }
}

// =============================================================================
// S7.P5.T04 打印机管理视图
// =============================================================================

class BmsPrintersView extends StatefulWidget {
  const BmsPrintersView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsPrintersView> createState() => _BmsPrintersViewState();
}

class _BmsPrintersViewState extends State<BmsPrintersView> {
  List<BmsPrinterItem> _printers = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadPrinters();
    if (mounted) {
      setState(() {
        _loading = false;
        _printers = res.valueOrNull ?? [];
      });
    }
  }

  void _openPrinterForm([BmsPrinterItem? printer]) {
    final nameCtrl = TextEditingController(text: printer?.name ?? '');
    final ipCtrl = TextEditingController(text: printer?.ip ?? '');
    final portCtrl = TextEditingController(text: printer != null ? printer.port.toString() : '9100');

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(printer == null ? '新建打印机' : '编辑打印机', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '打印机名称')),
            const SizedBox(height: 12),
            TextField(controller: ipCtrl, decoration: const InputDecoration(labelText: 'IP 地址')),
            const SizedBox(height: 12),
            TextField(controller: portCtrl, decoration: const InputDecoration(labelText: '端口号'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await widget.loader.savePrinter({
                      if (printer != null) 'id': printer.id,
                      'name': nameCtrl.text.trim(),
                      'ip': ipCtrl.text.trim(),
                      'port': int.tryParse(portCtrl.text) ?? 9100,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadPrinters();
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
        title: const Text('打印机管理'),
        actions: [
          IconButton(
            key: const Key('bms-printer-add-btn'),
            icon: const Icon(Icons.add),
            onPressed: () => _openPrinterForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _printers.isEmpty
              ? const Center(child: Text('暂无打印机'))
              : ListView.separated(
                  itemCount: _printers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final p = _printers[idx];
                    return ListTile(
                      key: Key('bms-printer-item-${p.id}'),
                      title: Text(p.name),
                      subtitle: Text('地址: ${p.ip}:${p.port} | 纸宽: ${p.paperWidth}mm'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _openPrinterForm(p),
                      ),
                    );
                  },
                ),
    );
  }
}

// =============================================================================
// S7.P5.T05 出品库管理视图
// =============================================================================

class BmsOutLibConfigView extends StatefulWidget {
  const BmsOutLibConfigView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsOutLibConfigView> createState() => _BmsOutLibConfigViewState();
}

class _BmsOutLibConfigViewState extends State<BmsOutLibConfigView> {
  List<BmsMakeLibItem> _libs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadLibs();
  }

  Future<void> _loadLibs() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadMakeLibs();
    if (mounted) {
      setState(() {
        _loading = false;
        _libs = res.valueOrNull ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('出品库管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _libs.isEmpty
              ? const Center(child: Text('暂无出品库'))
              : ListView.separated(
                  itemCount: _libs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final lib = _libs[idx];
                    return ListTile(
                      key: Key('bms-mklib-item-${lib.id}'),
                      title: Text(lib.name),
                      subtitle: Text('关联打印机数量: ${lib.printerIds.length}'),
                    );
                  },
                ),
    );
  }
}

// =============================================================================
// S7.P5.T06 小票管理视图
// =============================================================================

class BmsBillsView extends StatefulWidget {
  const BmsBillsView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsBillsView> createState() => _BmsBillsViewState();
}

class _BmsBillsViewState extends State<BmsBillsView> {
  final _titleCtrl = TextEditingController(text: '结账单');
  final _footerCtrl = TextEditingController(text: '感谢光临，欢迎再次光临！');
  bool _printDetail = true;
  bool _printQr = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadBillConfig();
    if (mounted) {
      if (res.failureOrNull == null) {
        final cfg = res.valueOrNull ?? const BmsBillConfig();
        _titleCtrl.text = cfg.title;
        _footerCtrl.text = cfg.footerText;
        _printDetail = cfg.isPrintDetail;
        _printQr = cfg.isPrintQr;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    await widget.loader.saveBillConfig({
      'title': _titleCtrl.text.trim(),
      'footer_text': _footerCtrl.text.trim(),
      'is_print_detail': _printDetail,
      'is_print_qr': _printQr,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('小票配置已保存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('小票管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: '小票标题')),
                    const SizedBox(height: 16),
                    TextField(controller: _footerCtrl, decoration: const InputDecoration(labelText: '页尾提示语')),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('打印菜品明细'),
                      value: _printDetail,
                      onChanged: (v) => setState(() => _printDetail = v),
                    ),
                    SwitchListTile(
                      title: const Text('打印结算二维码'),
                      value: _printQr,
                      onChanged: (v) => setState(() => _printQr = v),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      key: const Key('bms-bill-save-btn'),
                      onPressed: _saveConfig,
                      child: const Text('保存小票配置'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// =============================================================================
// S7.P5.T07 终端管理视图
// =============================================================================

class BmsTerminalBmsView extends StatefulWidget {
  const BmsTerminalBmsView({super.key, required this.loader});
  final BmsLoader loader;

  @override
  State<BmsTerminalBmsView> createState() => _BmsTerminalBmsViewState();
}

class _BmsTerminalBmsViewState extends State<BmsTerminalBmsView> {
  List<BmsTerminalItem> _terminals = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTerminals();
  }

  Future<void> _loadTerminals() async {
    setState(() => _loading = true);
    final res = await widget.loader.loadTerminals();
    if (mounted) {
      setState(() {
        _loading = false;
        _terminals = res.valueOrNull ?? [];
      });
    }
  }

  Future<void> _clearTerm(BmsTerminalItem item) async {
    await widget.loader.clearTerminal(item.id);
    _loadTerminals();
  }

  Future<void> _showQuickCode(BmsTerminalItem item) async {
    final res = await widget.loader.genQuickCode(item.id);
    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('终端快捷码 - ${item.termCode}'),
          content: Text('生成的快捷码: ${res.valueOrNull ?? "8888"}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('完成'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('终端管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _terminals.isEmpty
              ? const Center(child: Text('暂无终端设备'))
              : ListView.separated(
                  itemCount: _terminals.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final term = _terminals[idx];
                    return ListTile(
                      key: Key('bms-terminal-item-${term.id}'),
                      title: Text('终端编码: ${term.termCode} (${term.isOnline ? "在线" : "离线"})'),
                      subtitle: Text('IP: ${term.ip} | 关联岗位: ${term.stationName} | 打印机: ${term.printerName}'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () => _showQuickCode(term),
                            child: const Text('生成快捷码'),
                          ),
                          OutlinedButton(
                            onPressed: () => _clearTerm(term),
                            child: const Text('清设备'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
