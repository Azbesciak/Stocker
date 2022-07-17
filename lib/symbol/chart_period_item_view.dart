import 'package:flutter/material.dart';
import 'package:stocker/ui_style.dart';
import 'package:stocker/xtb/model/chart_period.dart';

class ChartPeriodItemView extends StatelessWidget {
  final ChartPeriod period;
  final bool selected;
  final void Function() onClick;

  const ChartPeriodItemView({
    super.key,
    required this.period,
    required this.selected,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(UIStyle.contentMarginSmall),
      child: Material(
        color: selected ? colorScheme.primary : colorScheme.background,
        borderRadius: BorderRadius.circular(UIStyle.popupsBorderRadius),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(UIStyle.popupsBorderRadius),
          child: SizedBox(
            width: 40,
            height: 30,
            child: Align(
              child: Text(
                period.tag,
                style: TextStyle(
                  color:
                      selected ? colorScheme.onPrimary : colorScheme.onBackground,
                ),
              ),
            ),
          ),
          onTap: () => onClick(),
        ),
      ),
    );
  }
}
