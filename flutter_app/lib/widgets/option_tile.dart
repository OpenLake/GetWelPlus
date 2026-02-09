import 'package:flutter/material.dart';


class StyledRadioTile extends StatelessWidget {
  final int value;
  final int groupValue;
  final String title;
  final ValueChanged<int?> onChanged;

  const StyledRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == groupValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.green
                : Colors.grey.withOpacity(0.3),
          ),
          color: isSelected
              ? Colors.green.withOpacity(0.12)
              : Colors.transparent,
        ),
        child: RadioListTile.adaptive(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: Colors.green,
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
