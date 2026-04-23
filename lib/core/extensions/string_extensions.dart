extension StringX on String {
  bool get isBlank => trim().isEmpty;
  bool get isNotBlank => trim().isNotEmpty;

  String? get nullIfBlank => isBlank ? null : this;
}
