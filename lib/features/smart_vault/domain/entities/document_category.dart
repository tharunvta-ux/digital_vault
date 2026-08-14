/// The fixed set of categories a vault document can belong to.
///
/// Adding a new category only ever requires adding another enum value —
/// [label] is derived from the enum's own name, so no other file needs to
/// change (no switch statement to keep in sync).
enum DocumentCategory {
  identity,
  education,
  finance,
  medical,
  legal,
  insurance,
  property,
  other;

  /// Human-readable label for display (e.g. `identity` -> `Identity`).
  String get label => name[0].toUpperCase() + name.substring(1);
}
