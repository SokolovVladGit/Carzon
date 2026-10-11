import '../../../listings/domain/entities/listing.dart';

/// Database-backed ranges already enforced by the characteristics editors.
const int kCreateListingQuickCylinderMax = 16;
const int kCreateListingQuickDoorMax = 6;
const int kCreateListingQuickSeatMax = 15;

/// Frequent counts shown as one-tap chips. The picker still offers 1…max.
const List<int> kCreateListingCommonCylinders = [3, 4, 6, 8];
const List<int> kCreateListingCommonDoors = [2, 3, 4, 5];
const List<int> kCreateListingCommonSeats = [2, 4, 5, 7];

enum CreateListingQuickChoiceKind {
  drivetrain,
  transmission,
  doors,
  seats,
  cylinders,
}

/// Current authoritative values for the five quick-choice fields.
class CreateListingQuickChoiceValues {
  const CreateListingQuickChoiceValues({
    this.drivetrain,
    this.transmissionType,
    this.doors,
    this.seats,
    this.engineCylinders,
  });

  final ListingDrivetrain? drivetrain;
  final ListingTransmissionType? transmissionType;
  final int? doors;
  final int? seats;
  final int? engineCylinders;
}

/// Missing supported fields, in the product order.
List<CreateListingQuickChoiceKind> createListingMissingQuickChoices(
  CreateListingQuickChoiceValues values,
) {
  return [
    if (values.drivetrain == null) CreateListingQuickChoiceKind.drivetrain,
    if (values.transmissionType == null)
      CreateListingQuickChoiceKind.transmission,
    if (values.doors == null) CreateListingQuickChoiceKind.doors,
    if (values.seats == null) CreateListingQuickChoiceKind.seats,
    if (values.engineCylinders == null) CreateListingQuickChoiceKind.cylinders,
  ];
}

bool createListingQuickChoicesVisible({
  required bool onCharacteristicsStep,
  required bool vinConfirmed,
  required bool manualIdentityReady,
  required bool resolving,
  required List<CreateListingQuickChoiceKind> missing,
}) {
  if (!onCharacteristicsStep || resolving || missing.isEmpty) return false;
  return vinConfirmed || manualIdentityReady;
}

/// How many leading questions stay on screen before the seller asks for more.
const int kCreateListingQuickChoicesPreviewCount = 2;

/// Questions shown without an extra tap. Three or more keep the tail hidden
/// until [extrasOpen] is true.
List<CreateListingQuickChoiceKind> createListingVisibleQuickChoices(
  List<CreateListingQuickChoiceKind> missing, {
  required bool extrasOpen,
}) {
  if (missing.length <= kCreateListingQuickChoicesPreviewCount || extrasOpen) {
    return missing;
  }
  return missing.take(kCreateListingQuickChoicesPreviewCount).toList();
}

int createListingHiddenQuickChoiceCount(
  List<CreateListingQuickChoiceKind> missing, {
  required bool extrasOpen,
}) {
  return missing.length -
      createListingVisibleQuickChoices(missing, extrasOpen: extrasOpen).length;
}

List<int> createListingQuickCountChoices(CreateListingQuickChoiceKind kind) {
  return switch (kind) {
    CreateListingQuickChoiceKind.cylinders => kCreateListingCommonCylinders,
    CreateListingQuickChoiceKind.doors => kCreateListingCommonDoors,
    CreateListingQuickChoiceKind.seats => kCreateListingCommonSeats,
    CreateListingQuickChoiceKind.drivetrain ||
    CreateListingQuickChoiceKind.transmission => const [],
  };
}

int createListingQuickCountMax(CreateListingQuickChoiceKind kind) {
  return switch (kind) {
    CreateListingQuickChoiceKind.cylinders => kCreateListingQuickCylinderMax,
    CreateListingQuickChoiceKind.doors => kCreateListingQuickDoorMax,
    CreateListingQuickChoiceKind.seats => kCreateListingQuickSeatMax,
    CreateListingQuickChoiceKind.drivetrain ||
    CreateListingQuickChoiceKind.transmission => 0,
  };
}
