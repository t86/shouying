import 'dart:async';

import 'package:card_table/src/card_table_models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

enum CardRegionSelectionKind { all, mine, region }

final class CardRegionSelection {
  const CardRegionSelection.all()
    : kind = CardRegionSelectionKind.all,
      regionId = null;
  const CardRegionSelection.mine()
    : kind = CardRegionSelectionKind.mine,
      regionId = null;
  const CardRegionSelection.region(this.regionId)
    : kind = CardRegionSelectionKind.region;
  final CardRegionSelectionKind kind;
  final String? regionId;
}

/// A visible overflow entry complements touch scrolling; card paging is separate.
final class CardRegionSelector extends StatefulWidget {
  const CardRegionSelector({
    required this.regions,
    required this.selectedRegionId,
    required this.mineSelected,
    required this.showMine,
    required this.lightTheme,
    required this.onSelected,
    super.key,
  });

  static const expandKey = Key('card-regions-expand');
  static const panelKey = Key('card-regions-panel');
  static const mineKey = Key('card-table-mine');
  final List<CardRegion> regions;
  final String? selectedRegionId;
  final bool mineSelected;
  final bool showMine;
  final bool lightTheme;
  final ValueChanged<CardRegionSelection> onSelected;

  @override
  State<CardRegionSelector> createState() => _CardRegionSelectorState();
}

final class _CardRegionSelectorState extends State<CardRegionSelector> {
  final _selectedAnchor = GlobalKey();
  ModalRoute<Object?>? _pickerRoute;
  bool _pickerOpen = false;

  @override
  void didUpdateWidget(CardRegionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedRegions =
        oldWidget.regions.map((r) => '${r.id}:${r.name}').join('|') !=
        widget.regions.map((r) => '${r.id}:${r.name}').join('|');
    if (changedRegions || oldWidget.showMine != widget.showMine) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pickerOpen && (_pickerRoute?.isCurrent ?? false)) {
          Navigator.of(context).pop();
        }
      });
    }
    if (changedRegions ||
        oldWidget.selectedRegionId != widget.selectedRegionId ||
        oldWidget.mineSelected != widget.mineSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final anchor = _selectedAnchor.currentContext;
        if (mounted && anchor != null) {
          unawaited(Scrollable.ensureVisible(anchor, alignment: .5));
        }
      });
    }
  }

  Color get _foreground =>
      widget.lightTheme ? const Color(0xff08080A) : BookingTokens.textPrimary;

  Widget _chip(
    String label,
    bool selected,
    CardRegionSelection choice, {
    Key? key,
  }) {
    if (widget.lightTheme) {
      return Padding(
        key: selected ? _selectedAnchor : null,
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          key: key,
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          backgroundColor: Colors.white,
          selectedColor: const Color(0xff3373E8),
          labelStyle: TextStyle(color: selected ? Colors.white : _foreground),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onSelected: (_) => widget.onSelected(choice),
        ),
      );
    }

    final isPhone = BookingViewportTier.of(context).isPhone;
    return Padding(
      key: selected ? _selectedAnchor : null,
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: key,
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: isPhone ? VisualDensity.compact : VisualDensity.standard,
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 8 : 12,
          vertical: isPhone ? 2 : 4,
        ),
        backgroundColor: const Color(0x66000000),
        selectedColor: BookingTokens.brandPrimary,
        labelStyle: TextStyle(
          color: BookingTokens.textPrimary,
          fontSize: isPhone ? 13 : 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        shape: const StadiumBorder(),
        side: BorderSide(
          color: selected
              ? const Color(0x80FFFFFF)
              : BookingTokens.pillTopHighlight,
          width: 1,
        ),
        onSelected: (_) => widget.onSelected(choice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Conservative estimate: never make a clipped region depend on a hidden gesture.
      final labels = [
        if (widget.showMine) '我的卡台',
        '全部',
        ...widget.regions.map((r) => r.name),
      ];
      var width = 0.0;
      for (final label in labels) {
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        width += painter.width + 48;
        painter.dispose();
      }
      final overflow = width > constraints.maxWidth;
      return Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (widget.showMine)
                    _chip(
                      '我的卡台',
                      widget.mineSelected,
                      const CardRegionSelection.mine(),
                      key: CardRegionSelector.mineKey,
                    ),
                  _chip(
                    '全部',
                    !widget.mineSelected && widget.selectedRegionId == null,
                    const CardRegionSelection.all(),
                  ),
                  for (final region in widget.regions)
                    _chip(
                      region.name,
                      !widget.mineSelected &&
                          widget.selectedRegionId == region.id,
                      CardRegionSelection.region(region.id),
                    ),
                ],
              ),
            ),
          ),
          if (overflow)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: OutlinedButton.icon(
                key: CardRegionSelector.expandKey,
                onPressed: _showPicker,
                icon: const Icon(Icons.expand_more, size: 18),
                label: const Text('其它'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _foreground,
                  backgroundColor: widget.lightTheme
                      ? Colors.white
                      : const Color(0x66000000),
                  side: BorderSide(
                    color: widget.lightTheme
                        ? const Color(0xff9FA8BC)
                        : BookingTokens.pillTopHighlight,
                  ),
                  minimumSize: const Size(68, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      widget.lightTheme ? 8 : 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  Future<void> _showPicker() async {
    if (_pickerOpen) return;
    _pickerOpen = true;
    final choice = await showDialog<CardRegionSelection>(
      context: context,
      builder: (dialogContext) {
        _pickerRoute = ModalRoute.of(dialogContext);
        Widget option(
          String label,
          bool selected,
          CardRegionSelection selection,
        ) => ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          backgroundColor: widget.lightTheme
              ? Colors.white
              : const Color(0xCC000000),
          selectedColor: widget.lightTheme
              ? const Color(0xff3373E8)
              : BookingTokens.brandPrimary,
          side: BorderSide(
            color: selected
                ? const Color(0x80FFFFFF)
                : BookingTokens.pillTopHighlight,
          ),
          labelStyle: TextStyle(
            color: widget.lightTheme && !selected
                ? const Color(0xff08080A)
                : Colors.white,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (_) => Navigator.pop(dialogContext, selection),
        );
        return AlertDialog(
          key: CardRegionSelector.panelKey,
          backgroundColor: widget.lightTheme
              ? Colors.white
              : BookingTokens.surfacePanelDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: widget.lightTheme
                  ? const Color(0xffC4CBD7)
                  : BookingTokens.accentGlowBorder,
            ),
          ),
          title: Text(
            '选择区域',
            style: TextStyle(
              color: widget.lightTheme
                  ? const Color(0xff08080A)
                  : BookingTokens.textPrimary,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (widget.showMine)
                    option(
                      '我的卡台',
                      widget.mineSelected,
                      const CardRegionSelection.mine(),
                    ),
                  option(
                    '全部',
                    !widget.mineSelected && widget.selectedRegionId == null,
                    const CardRegionSelection.all(),
                  ),
                  for (final region in widget.regions)
                    option(
                      region.name,
                      !widget.mineSelected &&
                          widget.selectedRegionId == region.id,
                      CardRegionSelection.region(region.id),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
    _pickerOpen = false;
    _pickerRoute = null;
    if (!mounted || choice == null) return;
    if (choice.kind == CardRegionSelectionKind.region &&
        !widget.regions.any((r) => r.id == choice.regionId)) {
      return;
    }
    if (choice.kind == CardRegionSelectionKind.mine && !widget.showMine) return;
    widget.onSelected(choice);
  }
}
