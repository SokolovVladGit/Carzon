import 'package:equatable/equatable.dart';

/// One labeled row in the compare spec table.
class CompareSpecRow extends Equatable {
  const CompareSpecRow({
    required this.id,
    required this.label,
    required this.values,
    this.highlightIndices = const {},
  });

  final String id;
  final String label;

  /// One formatted display value per vehicle column (use em dash for missing).
  final List<String> values;

  /// Subtle emphasis on neutral bests (price, mileage, year).
  final Set<int> highlightIndices;

  static const String missingToken = '—';

  bool get allValuesEqual {
    if (values.isEmpty) return true;
    final normalized = values
        .map((v) => v.trim().isEmpty ? missingToken : v.trim())
        .toList();
    return normalized.every((v) => v == normalized.first);
  }

  @override
  List<Object?> get props => [id, label, values, highlightIndices];
}

/// Grouped section of compare rows.
class CompareSpecSection extends Equatable {
  const CompareSpecSection({required this.title, required this.rows});

  final String title;
  final List<CompareSpecRow> rows;

  @override
  List<Object?> get props => [title, rows];
}
