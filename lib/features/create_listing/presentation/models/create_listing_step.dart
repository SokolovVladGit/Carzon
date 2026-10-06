/// Sequential Create Listing flow inside the existing route.
///
/// Order is the navigation and progress order:
/// identity, characteristics, offer, photos, contact, review.
/// Not a router destination. The page keeps one state owner for every step.
enum CreateListingStep {
  identity,
  characteristics,
  offer,
  photos,
  contact,
  review,
}

extension CreateListingStepX on CreateListingStep {
  int get number => index + 1;

  static int get count => CreateListingStep.values.length;

  CreateListingStep? get previous {
    if (index == 0) return null;
    return CreateListingStep.values[index - 1];
  }

  CreateListingStep? get next {
    final last = CreateListingStep.values.length - 1;
    if (index >= last) return null;
    return CreateListingStep.values[index + 1];
  }
}
