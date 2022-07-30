import 'package:flutter/material.dart';
import 'package:stocker/symbol/chart_period_item_view.dart';
import 'package:stocker/ui_style.dart';
import 'package:stocker/xtb/model/chart_period.dart';

class ChartPeriodSelector extends StatefulWidget {
  final void Function(ChartPeriod period) periodChanged;
  final ChartPeriod initialPeriod;
  final Axis direction;

  const ChartPeriodSelector({
    super.key,
    required this.initialPeriod,
    required this.periodChanged,
    required this.direction,
  });

  @override
  State<ChartPeriodSelector> createState() => _ChartPeriodSelectorState();
}

class _ChartPeriodSelectorState extends State<ChartPeriodSelector> {
  static const List<ChartPeriod> PERIODS = const [
    ChartPeriod.M1,
    ChartPeriod.M5,
    ChartPeriod.M15,
    ChartPeriod.M30,
    ChartPeriod.H1,
    ChartPeriod.H4,
    ChartPeriod.D1,
    ChartPeriod.W1,
    ChartPeriod.MN1,
  ];

  bool _extended = false;
  late ChartPeriod _selected;

  @override
  void didUpdateWidget(covariant ChartPeriodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPeriod != widget.initialPeriod) {
      setState(() {
        _selected = widget.initialPeriod;
      });
    }
  }

  _updateSelection(ChartPeriod selected) {
    setState(() {
      _extended = false;
      if (_selected != selected) {
        _selected = selected;
        widget.periodChanged(selected);
      }
    });
  }

  _openSelection() {
    setState(() {
      _extended = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPeriod;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(UIStyle.contentMarginMedium),
      child: _buildList(),
    );
  }

  Widget _buildList() {
    if (_extended) {
      return Wrap(
        direction: widget.direction,
        children: [
          ...PERIODS.map(
            (period) => ChartPeriodItemView(
              period: period,
              selected: period == _selected,
              onClick: () => _updateSelection(period),
            ),
          )
        ],
      );
    } else {
      return ChartPeriodItemView(
        period: _selected,
        selected: false,
        onClick: () => _openSelection(),
      );
    }
  }
}
