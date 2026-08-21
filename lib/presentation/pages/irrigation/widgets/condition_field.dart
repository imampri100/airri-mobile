import 'package:flutter/material.dart';

import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

const operatorOptions = ['<', '<=', '=', '>=', '>'];

// ini versi Flutter-nya .field dari prototype (label + select operator +
// input angka + unit), dipake di Trigger/Restriction
class ConditionField extends StatefulWidget {
  final String label;
  final String unit;
  final String operatorValue;
  final double numberValue;
  final bool showOperator;
  final bool? enabled;
  final ValueChanged<String>? onOperatorChanged;
  final ValueChanged<double> onValueChanged;
  final ValueChanged<bool>? onEnabledChanged;

  const ConditionField({
    super.key,
    required this.label,
    required this.unit,
    required this.operatorValue,
    required this.numberValue,
    required this.onValueChanged,
    this.showOperator = true,
    this.onOperatorChanged,
    this.enabled,
    this.onEnabledChanged,
  });

  @override
  State<ConditionField> createState() => _ConditionFieldState();
}

class _ConditionFieldState extends State<ConditionField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatNumber(widget.numberValue));
  }

  @override
  void didUpdateWidget(covariant ConditionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.numberValue != widget.numberValue &&
        double.tryParse(_controller.text) != widget.numberValue) {
      _controller.text = _formatNumber(widget.numberValue);
    }
  }

  String _formatNumber(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled ?? true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: IrrigationColors.ink700)),
              if (widget.onEnabledChanged != null)
                Switch(
                  value: isEnabled,
                  activeTrackColor: IrrigationColors.green600,
                  onChanged: widget.onEnabledChanged,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: isEnabled ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !isEnabled,
              child: Row(
                children: [
                  if (widget.showOperator) ...[
                    _Chrome(
                      width: 72,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.operatorValue,
                          isExpanded: true,
                          isDense: true,
                          alignment: Alignment.center,
                          icon: const Icon(Icons.expand_more,
                              size: 16, color: IrrigationColors.ink500),
                          borderRadius:
                              BorderRadius.circular(IrrigationColors.radiusSm),
                          dropdownColor: Colors.white,
                          elevation: 2,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: IrrigationColors.ink900),
                          items: operatorOptions
                              .map((op) => DropdownMenuItem(
                                    value: op,
                                    child: Center(
                                      child: Text(op,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: IrrigationColors.ink900)),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) widget.onOperatorChanged?.call(v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _Chrome(
                      child: TextField(
                        controller: _controller,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(
                            fontSize: 13, color: IrrigationColors.ink900),
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          if (parsed != null) widget.onValueChanged(parsed);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: IrrigationColors.line100,
                      border: Border.all(color: IrrigationColors.line200, width: 1.5),
                      borderRadius: BorderRadius.circular(IrrigationColors.radiusSm),
                    ),
                    child: Text(widget.unit,
                        style: const TextStyle(
                            fontSize: 13, color: IrrigationColors.ink500)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chrome extends StatelessWidget {
  final Widget child;
  final double? width;
  const _Chrome({required this.child, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: IrrigationColors.line200, width: 1.5),
        borderRadius: BorderRadius.circular(IrrigationColors.radiusSm),
        color: Colors.white,
      ),
      child: child,
    );
  }
}
