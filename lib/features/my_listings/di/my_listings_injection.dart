import 'package:get_it/get_it.dart';

import '../../listings/domain/usecases/delete_listing.dart';
import '../../listings/domain/usecases/get_listings.dart';
import '../../listings/domain/usecases/set_listing_status.dart';
import '../presentation/bloc/my_listings_cubit.dart';

void registerMyListingsFeature(GetIt sl) {
  // Reuses use cases from the listings feature.
  sl.registerFactory<MyListingsCubit>(
    () => MyListingsCubit(
      getListings: sl<GetListings>(),
      setListingStatus: sl<SetListingStatus>(),
      deleteListing: sl<DeleteListing>(),
    ),
  );
}
