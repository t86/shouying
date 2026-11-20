import 'package:card_table/src/booking_card_display.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Half-hour expected arrival time slots matching `cardDrawer.vue:1288`
/// (`12:00`..`23:30` same business day, `00:00`..`11:30` next morning).
final List<({String wire, String label})> bookingArriveTimeSlots =
    List<({String wire, String label})>.unmodifiable(<({String wire, String label})>[
      for (var hour = 12; hour < 24; hour++) ...[
        (
          wire: '${hour.toString().padLeft(2, '0')}00',
          label: '${hour.toString().padLeft(2, '0')}:00',
        ),
        (
          wire: '${hour.toString().padLeft(2, '0')}30',
          label: '${hour.toString().padLeft(2, '0')}:30',
        ),
      ],
      for (var hour = 0; hour < 12; hour++) ...[
        (
          wire: '${hour.toString().padLeft(2, '0')}00',
          label: '次日 ${hour.toString().padLeft(2, '0')}:00',
        ),
        (
          wire: '${hour.toString().padLeft(2, '0')}30',
          label: '次日 ${hour.toString().padLeft(2, '0')}:30',
        ),
      ],
    ]);

const List<({String wire, String label})> bookingArriveQuickChips =
    <({String wire, String label})>[
      (wire: '2000', label: '20:00'),
      (wire: '2100', label: '21:00'),
      (wire: '2200', label: '22:00'),
      (wire: '2300', label: '23:00'),
    ];

/// Normalizes an arrival time wire string (4-digit `HHmm` or 12-digit `yyyyMMddHHmm`
/// or `HH:mm`) into a `HHmm` slot value when present in [bookingArriveTimeSlots].
String normalizeArriveTimeSlot(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  final hhmm = digits.length >= 12
      ? digits.substring(8, 12)
      : digits.length == 4
      ? digits
      : '';
  if (hhmm.isEmpty) return '';
  for (final slot in bookingArriveTimeSlots) {
    if (slot.wire == hhmm) return slot.wire;
  }
  return '';
}

/// Filters employees by name, code, pinyin (`namePy`), department name, or phone.
List<CardEmployee> filterBookingEmployees(
  List<CardEmployee> employees,
  String query, {
  List<CardDepartment> departments = const <CardDepartment>[],
}) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return employees;
  final deptNames = <String, String>{
    for (final d in departments) d.id: d.name.toLowerCase(),
  };
  return employees
      .where((emp) {
        if (emp.name.toLowerCase().contains(needle)) return true;
        if (emp.code.toLowerCase().contains(needle)) return true;
        if (emp.namePy.toLowerCase().contains(needle)) return true;
        if (emp.phone.toLowerCase().contains(needle)) return true;
        final dept = deptNames[emp.deptId] ?? '';
        return dept.isNotEmpty && dept.contains(needle);
      })
      .toList(growable: false);
}

String bookingEmployeeDisplayLabel(
  CardEmployee emp, {
  Map<String, String> deptNames = const <String, String>{},
}) {
  final parts = <String>[
    emp.name,
    if (emp.code.isNotEmpty) '(${emp.code})',
    if ((deptNames[emp.deptId] ?? '').isNotEmpty) '· ${deptNames[emp.deptId]}',
  ];
  return parts.join(' ');
}

/// Searchable dark employee selector field used in Open/Reserve & Turnover forms.
final class BookingEmployeePickerField extends StatelessWidget {
  const BookingEmployeePickerField({
    required this.label,
    required this.employees,
    required this.selectedId,
    required this.onChanged,
    this.departments = const <CardDepartment>[],
    this.allowClear = true,
    this.showPhoneSubtitle = true,
    this.fieldKey,
    super.key,
  });

  final String label;
  final List<CardEmployee> employees;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final List<CardDepartment> departments;
  final bool allowClear;
  final bool showPhoneSubtitle;
  final Key? fieldKey;

  CardEmployee? get _selected {
    final id = selectedId ?? '';
    if (id.isEmpty) return null;
    for (final emp in employees) {
      if (emp.id == id) return emp;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final deptNames = <String, String>{
      for (final d in departments) d.id: d.name,
    };
    final selected = _selected;
    final displayText = selected == null
        ? '请选择（支持姓名/工号/拼音搜索）'
        : bookingEmployeeDisplayLabel(selected, deptNames: deptNames);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          key: fieldKey,
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final picked = await showBookingEmployeePickerDialog(
              context: context,
              title: '选择$label',
              employees: employees,
              departments: departments,
              selectedId: selectedId ?? '',
              allowClear: allowClear,
            );
            if (picked != null) onChanged(picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: BookingTokens.surfaceInput,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (allowClear && selected != null)
                    IconButton(
                      tooltip: '清空',
                      icon: const Icon(
                        Icons.clear,
                        size: 16,
                        color: BookingTokens.textMuted,
                      ),
                      onPressed: () => onChanged(''),
                    ),
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.search,
                      size: 18,
                      color: BookingTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected == null
                    ? BookingTokens.textMuted
                    : BookingTokens.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ),
        if (showPhoneSubtitle && selected != null && selected.phone.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              '电话：${selected.phone}',
              style: const TextStyle(
                color: BookingTokens.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// Modal searchable employee picker dialog supporting Enter/Esc keyboard control.
/// Returns `''` when cleared, employee id when chosen, or `null` when dismissed.
Future<String?> showBookingEmployeePickerDialog({
  required BuildContext context,
  required String title,
  required List<CardEmployee> employees,
  List<CardDepartment> departments = const <CardDepartment>[],
  String selectedId = '',
  bool allowClear = true,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _BookingEmployeePickerDialog(
      title: title,
      employees: employees,
      departments: departments,
      selectedId: selectedId,
      allowClear: allowClear,
    ),
  );
}

final class _BookingEmployeePickerDialog extends StatefulWidget {
  const _BookingEmployeePickerDialog({
    required this.title,
    required this.employees,
    required this.departments,
    required this.selectedId,
    required this.allowClear,
  });

  final String title;
  final List<CardEmployee> employees;
  final List<CardDepartment> departments;
  final String selectedId;
  final bool allowClear;

  @override
  State<_BookingEmployeePickerDialog> createState() =>
      _BookingEmployeePickerDialogState();
}

final class _BookingEmployeePickerDialogState
    extends State<_BookingEmployeePickerDialog> {
  final TextEditingController _search = TextEditingController();
  late String _currentId;

  @override
  void initState() {
    super.initState();
    _currentId = widget.selectedId;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_currentId);

  @override
  Widget build(BuildContext context) {
    final deptNames = <String, String>{
      for (final d in widget.departments) d.id: d.name,
    };
    final filtered = filterBookingEmployees(
      widget.employees,
      _search.text,
      departments: widget.departments,
    );
    final isPhone = BookingViewportTier.of(context).isPhone;
    return Theme(
      data: BookingTheme.dark(),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
          const SingleActivator(LogicalKeyboardKey.enter): _confirm,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _confirm,
        },
        child: AlertDialog(
          backgroundColor: BookingTokens.surfaceDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x8832B9FF)),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              color: BookingTokens.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: isPhone ? double.maxFinite : 420,
            height: isPhone ? 340 : 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  key: const Key('booking-employee-search'),
                  controller: _search,
                  autofocus: true,
                  style: const TextStyle(
                    color: BookingTokens.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: '搜索姓名 / 工号 / 拼音 / 部门 / 电话',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (filtered.length == 1) {
                      Navigator.of(context).pop(filtered.first.id);
                    } else {
                      _confirm();
                    }
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            '未找到匹配员工',
                            style: TextStyle(color: BookingTokens.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: BookingTokens.tableBorder,
                          ),
                          itemBuilder: (context, index) {
                            final emp = filtered[index];
                            final selected = emp.id == _currentId;
                            final dept = deptNames[emp.deptId] ?? '';
                            return ListTile(
                              dense: true,
                              selected: selected,
                              selectedTileColor: BookingTokens.brandPrimary
                                  .withValues(alpha: 0.22),
                              title: Text(
                                emp.code.isEmpty
                                    ? emp.name
                                    : '${emp.name} (${emp.code})',
                                style: const TextStyle(
                                  color: BookingTokens.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (dept.isNotEmpty) dept,
                                  if (emp.phone.isNotEmpty) emp.phone,
                                ].join(' · '),
                                style: const TextStyle(
                                  color: BookingTokens.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: BookingTokens.accentGlowBorder,
                                    )
                                  : null,
                              onTap: () {
                                setState(() => _currentId = emp.id);
                                Navigator.of(context).pop(emp.id);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            if (widget.allowClear)
              TextButton(
                onPressed: () => Navigator.of(context).pop(''),
                child: const Text(
                  '清空选择',
                  style: TextStyle(color: BookingTokens.textSecondary),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '取消',
                style: TextStyle(color: BookingTokens.textMuted),
              ),
            ),
            FilledButton(
              onPressed: _confirm,
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expected arrival time selector with half-hour dropdown & quick time chips.
final class BookingArriveTimeField extends StatelessWidget {
  const BookingArriveTimeField({
    required this.value,
    required this.onChanged,
    this.label = '预定到达时间',
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final slotValue = normalizeArriveTimeSlot(value);
    final formatted = BookingCardDisplay.formatArriveTime(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String>(
          key: ValueKey<String>('arrive-time-$slotValue'),
          initialValue: slotValue,
          isExpanded: true,
          dropdownColor: BookingTokens.surfaceDialog,
          decoration: InputDecoration(
            labelText: label,
            helperText:
                slotValue.isEmpty && value.isNotEmpty && formatted.isNotEmpty
                ? '当前保留值：$formatted'
                : null,
          ),
          items: <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(value: '', child: Text('不指定到达时间')),
            for (final slot in bookingArriveTimeSlots)
              DropdownMenuItem<String>(
                value: slot.wire,
                child: Text(slot.label),
              ),
          ],
          onChanged: (next) => onChanged(next ?? ''),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final chip in bookingArriveQuickChips)
              ChoiceChip(
                label: Text(chip.label),
                selected: slotValue == chip.wire,
                showCheckmark: false,
                selectedColor: BookingTokens.brandPrimary,
                backgroundColor: BookingTokens.surfaceFooter,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: slotValue == chip.wire
                      ? Colors.white
                      : BookingTokens.textSecondary,
                ),
                side: BorderSide(
                  color: slotValue == chip.wire
                      ? BookingTokens.brandPrimary
                      : BookingTokens.tableBorder,
                ),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onChanged(chip.wire),
              ),
          ],
        ),
      ],
    );
  }
}

/// Status reason badge text for disabled seats in transfer / multi-reserve pickers.
String bookingSeatDisabledReason(
  CardTable seat, {
  required String currentSeatId,
}) {
  if (seat.id == currentSeatId) return '当前台';
  return switch (seat.businessStatus) {
    2 => '已锁定',
    3 || 8 => '已预订',
    4 => '已开台',
    5 => '点单中',
    6 => '部分结',
    7 => '已结账',
    _ => '不可选',
  };
}

/// Full-featured dark region-grouped seat grid picker used by Transfer and
/// Multi-table Reserve. Non-empty / current seats stay visible but dimmed with
/// explicit status reasons so operators have full floor awareness.
final class BookingSeatPickerGrid extends StatefulWidget {
  const BookingSeatPickerGrid({
    required this.regions,
    required this.tables,
    required this.currentSeatId,
    required this.selectedIds,
    required this.onToggleSeat,
    this.multiSelect = false,
    super.key,
  });

  final List<CardRegion> regions;
  final List<CardTable> tables;
  final String currentSeatId;
  final Set<String> selectedIds;
  final ValueChanged<CardTable> onToggleSeat;
  final bool multiSelect;

  @override
  State<BookingSeatPickerGrid> createState() => _BookingSeatPickerGridState();
}

final class _BookingSeatPickerGridState extends State<BookingSeatPickerGrid> {
  String? _selectedRegionId;
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _search.text.trim().toLowerCase();
    final filtered = widget.tables
        .where((seat) {
          if (_selectedRegionId != null && seat.regionId != _selectedRegionId) {
            return false;
          }
          if (keyword.isNotEmpty &&
              !seat.name.toLowerCase().contains(keyword)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    final regionOrder = <String>[for (final r in widget.regions) r.id];
    final regionNames = <String, String>{
      for (final r in widget.regions) r.id: r.name,
    };
    final grouped = <String, List<CardTable>>{};
    for (final seat in filtered) {
      grouped.putIfAbsent(seat.regionId, () => <CardTable>[]).add(seat);
    }
    final orderedGroupIds = <String>[
      for (final id in regionOrder)
        if (grouped.containsKey(id)) id,
      for (final id in grouped.keys)
        if (!regionOrder.contains(id)) id,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ChoiceChip(
              label: const Text('全部区域'),
              selected: _selectedRegionId == null,
              showCheckmark: false,
              selectedColor: BookingTokens.brandPrimary,
              backgroundColor: BookingTokens.surfaceFooter,
              labelStyle: TextStyle(
                fontSize: 12,
                color: _selectedRegionId == null
                    ? Colors.white
                    : BookingTokens.textSecondary,
              ),
              onSelected: (_) => setState(() => _selectedRegionId = null),
            ),
            for (final region in widget.regions)
              ChoiceChip(
                label: Text(region.name),
                selected: _selectedRegionId == region.id,
                showCheckmark: false,
                selectedColor: BookingTokens.brandPrimary,
                backgroundColor: BookingTokens.surfaceFooter,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _selectedRegionId == region.id
                      ? Colors.white
                      : BookingTokens.textSecondary,
                ),
                onSelected: (_) =>
                    setState(() => _selectedRegionId = region.id),
              ),
            SizedBox(
              width: 190,
              height: 36,
              child: TextField(
                key: const Key('booking-seat-picker-search'),
                controller: _search,
                style: const TextStyle(
                  color: BookingTokens.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  hintText: '搜索卡台名',
                  prefixIcon: Icon(Icons.search, size: 16),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: orderedGroupIds.isEmpty
              ? const Center(
                  child: Text(
                    '暂无匹配卡台',
                    style: TextStyle(color: BookingTokens.textMuted),
                  ),
                )
              : ListView.builder(
                  itemCount: orderedGroupIds.length,
                  itemBuilder: (context, groupIdx) {
                    final regionId = orderedGroupIds[groupIdx];
                    final seats = grouped[regionId]!;
                    final regionName = regionNames[regionId] ?? '其他区域';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '$regionName (${seats.where((s) => s.businessStatus == 1 && s.id != widget.currentSeatId).length}/${seats.length} 空闲)',
                              style: const TextStyle(
                                color: BookingTokens.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final seat in seats)
                                _buildSeatTile(seat),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSeatTile(CardTable seat) {
    final selectable =
        seat.id != widget.currentSeatId && seat.businessStatus == 1;
    final selected = widget.selectedIds.contains(seat.id);
    final baseColor = BookingTokens.statusColor(seat.businessStatus);
    final disabledReason = selectable
        ? null
        : bookingSeatDisabledReason(seat, currentSeatId: widget.currentSeatId);

    return Opacity(
      opacity: selectable ? 1.0 : 0.42,
      child: Material(
        color: selectable ? baseColor : baseColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: ValueKey<String>('seat-picker-${seat.id}'),
          borderRadius: BorderRadius.circular(8),
          onTap: selectable ? () => widget.onToggleSeat(seat) : null,
          child: Container(
            width: 112,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? BookingTokens.accentGlowBorder
                    : Colors.white24,
                width: selected ? 2.2 : 1,
              ),
              boxShadow: selected
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x8832B9FF),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        seat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: BookingTokens.accentGlowBorder,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (disabledReason != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xAA08080A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      disabledReason,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Text(
                    '低消 ¥${seat.assignedMinConsumeAmount} · ${BookingCardDisplay.capacity(seat)}人',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
