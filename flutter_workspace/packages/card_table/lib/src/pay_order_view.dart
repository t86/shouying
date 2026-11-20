import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/not_pay_order_view.dart'
    show payOrderProductName;
import 'package:flutter/material.dart';

/// 已支付订单详情视图 (S3.P2.T03)
final class PayedOrderView extends StatelessWidget {
  const PayedOrderView({
    required this.record,
    this.productNameFor,
    this.onChangeChannel,
    this.onRefundItem,
    this.onRefundPayed,
    super.key,
  });

  final PayedOrderRecord record;
  final String? Function(String productId)? productNameFor;
  final VoidCallback? onChangeChannel;
  final ValueChanged<PayOrderItem>? onRefundItem;
  final VoidCallback? onRefundPayed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左侧支付途径信息
        SizedBox(
          width: 280,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xff141D35),
              border: Border(right: BorderSide(color: Color(0xff263352))),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (record.pid > 0) ...[
                  Text(
                    '支付单号: ${record.pid}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Color(0xff263352), height: 16),
                ],
                const Text(
                  '支付途径',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: record.channels.isEmpty
                      ? const Center(
                          child: Text(
                            '无支付途径记录',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: record.channels.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: Color(0xff1F2B48),
                            height: 12,
                          ),
                          itemBuilder: (context, index) {
                            final ch = record.channels[index];
                            return _buildChannelItem(ch);
                          },
                        ),
                ),
                if (onChangeChannel != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff4B89FF),
                        side: const BorderSide(color: Color(0xff4B89FF)),
                      ),
                      onPressed: onChangeChannel,
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('更改支付渠道'),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('pay-order-refund-payed'),
                    onPressed: onRefundPayed,
                    icon: const Icon(Icons.undo),
                    label: const Text('已结退单'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 右侧已付商品表格
        Expanded(
          child: record.items.isEmpty
              ? const Center(
                  child: Text(
                    '该支付单暂无商品明细',
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xff182037),
                      ),
                      dataRowColor: WidgetStateProperty.all(
                        const Color(0xff0D172D),
                      ),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      dataTextStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      dividerThickness: 1,
                      columnSpacing: 14,
                      columns: const [
                        DataColumn(label: Text('序号')),
                        DataColumn(label: Text('状态')),
                        DataColumn(label: Text('名称')),
                        DataColumn(label: Text('数量')),
                        DataColumn(label: Text('单价(元)')),
                        DataColumn(label: Text('小计(元)')),
                        DataColumn(label: Text('服务员')),
                        DataColumn(label: Text('授权人')),
                        DataColumn(label: Text('点单时间')),
                        DataColumn(label: Text('操作')),
                      ],
                      rows: [
                        for (var i = 0; i < record.items.length; i++)
                          _buildItemRow(i, record.items[i]),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildChannelItem(PayedChannelItem ch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ch.channelName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              '¥${ch.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xffFFA726),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        if (ch.cardNo != null && ch.cardNo!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '卡号: ${ch.cardNo}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            '储值: ¥${ch.cardStoredAmt.toStringAsFixed(2)} | 赠: ¥${ch.cardDiscountAmt.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
        if (ch.payTime.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '时间: ${ch.payTime}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
        if (ch.cashierName.isNotEmpty) ...[
          Text(
            '结账人: ${ch.cashierName}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ],
    );
  }

  DataRow _buildItemRow(int index, PayOrderItem item) {
    return DataRow(
      cells: [
        DataCell(Text('${index + 1}')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: (item.isRefunded ? Colors.red : Colors.purple).withValues(
                alpha: 0.2,
              ),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: item.isRefunded ? Colors.red : Colors.purple,
                width: 0.8,
              ),
            ),
            child: Text(
              item.isRefunded ? '退' : '结',
              style: TextStyle(
                color: item.isRefunded ? Colors.red : Colors.purpleAccent,
                fontSize: 11,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            payOrderProductName(
              item.productName,
              item.productId,
              productNameFor,
            ),
            style: TextStyle(
              decoration: item.isRefunded ? TextDecoration.lineThrough : null,
              color: item.isRefunded ? Colors.white38 : Colors.white,
            ),
          ),
        ),
        DataCell(Text('${item.count}')),
        DataCell(Text(item.displayUnitPrice)),
        DataCell(
          Text(
            item.subtotal.toStringAsFixed(2),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xffFFA726),
            ),
          ),
        ),
        DataCell(Text(item.waiterName.isNotEmpty ? item.waiterName : '自助')),
        DataCell(Text(item.autherName)),
        DataCell(Text(item.orderTime)),
        DataCell(
          item.isRefunded
              ? const Text(
                  '已退',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                )
              : TextButton(
                  onPressed: onRefundItem != null
                      ? () => onRefundItem!(item)
                      : null,
                  child: const Text(
                    '退单',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
        ),
      ],
    );
  }
}
