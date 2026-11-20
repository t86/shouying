import 'package:card_table/src/pay_order_models.dart';
import 'package:flutter/material.dart';

String payOrderProductName(
  String name,
  String productId,
  String? Function(String)? productNameFor,
) {
  if (name.trim().isNotEmpty) return name;
  final catalogName = productNameFor?.call(productId);
  return catalogName != null && catalogName.trim().isNotEmpty
      ? catalogName
      : '未知商品（$productId）';
}

/// 未结订单表格组件 (S3.P2.T02)
final class NotPayOrderView extends StatefulWidget {
  const NotPayOrderView({
    required this.items,
    required this.selectedIds,
    required this.onSelectionChanged,
    this.productNameFor,
    this.onRefundItem,
    this.onMoveItem,
    this.onEditPackageItem,
    super.key,
  });

  final List<PayOrderItem> items;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final String? Function(String productId)? productNameFor;
  final ValueChanged<PayOrderItem>? onRefundItem;
  final ValueChanged<PayOrderItem>? onMoveItem;
  final ValueChanged<PayOrderItem>? onEditPackageItem;

  @override
  State<NotPayOrderView> createState() => _NotPayOrderViewState();
}

final class _NotPayOrderViewState extends State<NotPayOrderView> {
  final Set<String> _expandedPackageItemIds = <String>{};

  bool get _isAllSelected =>
      widget.items.isNotEmpty &&
      widget.items.every((it) => widget.selectedIds.contains(it.id));

  void _toggleSelectAll() {
    if (_isAllSelected) {
      widget.onSelectionChanged(<String>{});
    } else {
      widget.onSelectionChanged(widget.items.map((it) => it.id).toSet());
    }
  }

  void _toggleSelectItem(String id) {
    final next = Set<String>.from(widget.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    widget.onSelectionChanged(next);
  }

  void _toggleExpandPackage(String itemId) {
    setState(() {
      if (_expandedPackageItemIds.contains(itemId)) {
        _expandedPackageItemIds.remove(itemId);
      } else {
        _expandedPackageItemIds.add(itemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(
        child: Text(
          '暂无未支付订单',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xff182037)),
                dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => states.contains(WidgetState.selected)
                      ? const Color(0xff1D2C50)
                      : const Color(0xff0D172D),
                ),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                dataTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
                dividerThickness: 1,
                horizontalMargin: 12,
                columnSpacing: 16,
                columns: [
                  DataColumn(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _isAllSelected,
                          onChanged: (_) => _toggleSelectAll(),
                          activeColor: const Color(0xff2362D5),
                        ),
                        const Text('全选'),
                      ],
                    ),
                  ),
                  const DataColumn(label: Text('序号')),
                  const DataColumn(label: Text('状态')),
                  const DataColumn(label: Text('名称')),
                  const DataColumn(label: Text('数量')),
                  const DataColumn(label: Text('待结数')),
                  const DataColumn(label: Text('单价(元)')),
                  const DataColumn(label: Text('小计(元)')),
                  const DataColumn(label: Text('服务员')),
                  const DataColumn(label: Text('授权人')),
                  const DataColumn(label: Text('点单时间')),
                  const DataColumn(label: Text('操作')),
                ],
                rows: [
                  for (var i = 0; i < widget.items.length; i++) ..._buildItemRows(i, widget.items[i]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<DataRow> _buildItemRows(int index, PayOrderItem item) {
    final isSelected = widget.selectedIds.contains(item.id);
    final isPackage = item.isPackage;
    final isExpanded = _expandedPackageItemIds.contains(item.id);

    final mainRow = DataRow(
      selected: isSelected,
      onSelectChanged: (_) => _toggleSelectItem(item.id),
      cells: [
        DataCell(
          Checkbox(
            value: isSelected,
            onChanged: (_) => _toggleSelectItem(item.id),
            activeColor: const Color(0xff2362D5),
          ),
        ),
        DataCell(Text('${index + 1}')),
        DataCell(_buildStatusBadge(item)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                payOrderProductName(
                  item.productName,
                  item.productId,
                  widget.productNameFor,
                ),
                style: TextStyle(
                  decoration: item.isRefunded ? TextDecoration.lineThrough : null,
                  color: item.isRefunded ? Colors.white38 : Colors.white,
                ),
              ),
              if (isPackage) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 18,
                    color: Colors.white70,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _toggleExpandPackage(item.id),
                ),
              ],
            ],
          ),
        ),
        DataCell(Text('${item.count}')),
        DataCell(Text('${item.unpaidCount}')),
        DataCell(Text(item.displayUnitPrice)),
        DataCell(
          Text(
            item.subtotal.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xffFFA726)),
          ),
        ),
        DataCell(Text(item.waiterName.isNotEmpty ? item.waiterName : '自助')),
        DataCell(Text(item.autherName)),
        DataCell(Text(item.orderTime)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!item.isRefunded && widget.onRefundItem != null)
                TextButton(
                  onPressed: () => widget.onRefundItem!(item),
                  child: const Text('退单', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              if (!item.isRefunded && widget.onMoveItem != null)
                TextButton(
                  onPressed: () => widget.onMoveItem!(item),
                  child: const Text('转单', style: TextStyle(color: Color(0xff4B89FF), fontSize: 12)),
                ),
              if (isPackage && widget.onEditPackageItem != null)
                TextButton(
                  onPressed: () => widget.onEditPackageItem!(item),
                  child: const Text('改套餐', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ),
            ],
          ),
        ),
      ],
    );

    if (!isExpanded || !isPackage) {
      return [mainRow];
    }

    final subRows = <DataRow>[];
    for (final detail in item.packageDetails) {
      subRows.add(
        DataRow(
          color: WidgetStateProperty.all(const Color(0xff141D35)),
          cells: [
            const DataCell(SizedBox()),
            const DataCell(SizedBox()),
            const DataCell(
              Text('  └ 明细', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ),
            DataCell(
              Text(
                '    ${payOrderProductName(detail.name, detail.id, widget.productNameFor)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            DataCell(
              Text('${detail.count}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            const DataCell(SizedBox()),
            DataCell(
              Text(detail.price.toStringAsFixed(2), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            const DataCell(SizedBox()),
            const DataCell(SizedBox()),
            const DataCell(SizedBox()),
            const DataCell(SizedBox()),
            const DataCell(SizedBox()),
          ],
        ),
      );
    }

    return [mainRow, ...subRows];
  }

  Widget _buildStatusBadge(PayOrderItem item) {
    final tags = <Widget>[];
    if (item.isOnline) {
      tags.add(_tag('线', const Color(0xffE91E63)));
    }
    if (item.isRefunded) {
      tags.add(_tag('退', Colors.red));
    } else if (item.isRefunding) {
      tags.add(_tag('退单中', Colors.redAccent));
    }
    if (item.discountType == 2) {
      tags.add(_tag('惠', Colors.green));
    } else if (item.discountType == 3) {
      tags.add(_tag('惠2', Colors.teal));
    }
    if (item.isLocked) {
      tags.add(_tag('锁', Colors.blue));
    }
    if (tags.isEmpty) {
      return const Text('正常', style: TextStyle(color: Colors.white54, fontSize: 11));
    }
    return Wrap(spacing: 4, runSpacing: 2, children: tags);
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.25),
      border: Border.all(color: color, width: 0.8),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}
