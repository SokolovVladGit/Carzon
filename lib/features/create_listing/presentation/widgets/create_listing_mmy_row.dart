import 'package:flutter/material.dart';

/// Make / model / year as one equal-width group at a normal iPhone width.
class CreateListingMmyRow extends StatelessWidget {
  const CreateListingMmyRow({
    super.key,
    required this.make,
    required this.model,
    required this.year,
  });

  final Widget make;
  final Widget model;
  final Widget year;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final stacked =
            !constraints.maxWidth.isFinite ||
            constraints.maxWidth < 280 ||
            scale > 1.15;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              make,
              const SizedBox(height: 8),
              model,
              const SizedBox(height: 8),
              year,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: make),
              const SizedBox(width: 8),
              Expanded(child: model),
              const SizedBox(width: 8),
              Expanded(child: year),
            ],
          ),
        );
      },
    );
  }
}
