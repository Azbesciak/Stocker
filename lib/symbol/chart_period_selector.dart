import 'package:flutter/material.dart';
import 'package:stocker/ui_style.dart';
import 'package:stocker/xtb/model/chart_period.dart';

class ChartPeriodView extends StatelessWidget {
  final ChartPeriod period;
  final bool selected;
  final void Function() onClick;

  const ChartPeriodView({
    Key? key,
    required this.period,
    required this.selected,
    required this.onClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.all(UIStyle.contentMarginSmall),
      child: Material(
        color: selected ? colorScheme.primary : colorScheme.background,
        borderRadius: BorderRadius.circular(UIStyle.popupsBorderRadius),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(UIStyle.popupsBorderRadius),
          child: Padding(
            padding: EdgeInsets.all(UIStyle.contentMarginMedium),
            child: Text(period.tag,
                style: TextStyle(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onBackground)),
          ),
          onTap: () => onClick(),
        ),
      ),
    );
  }
}

class ChartPeriodSelector extends StatefulWidget {
  final void Function(ChartPeriod period) periodChanged;
  final ChartPeriod initialPeriod;

  const ChartPeriodSelector({
    Key? key,
    required this.initialPeriod,
    required this.periodChanged,
  }) : super(key: key);

  @override
  State<ChartPeriodSelector> createState() => _ChartPeriodSelectorState();
}

class _ChartPeriodSelectorState extends State<ChartPeriodSelector> {
  static const List<ChartPeriod> PERIODS = [
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
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...PERIODS.map((period) => ChartPeriodView(
              period: period,
              selected: period == _selected,
              onClick: () => _updateSelection(period),
            ))
      ]);
    } else {
      return ChartPeriodView(
        period: _selected,
        selected: false,
        onClick: () => _openSelection(),
      );
    }
  }
}
