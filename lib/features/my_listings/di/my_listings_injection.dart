import 'package:get_it/get_it.dart';

import '../../listings/domain/usecases/get_listings.dart';
import '../presentation/bloc/my_listings_cubit.dart';

void registerMyListingsFeature(GetIt sl) {
  // Reuses the existing GetListings use case from the listings feature.
  sl.registerFactory<MyListingsCubit>(
    () => MyListingsCubit(getListings: sl<GetListings>()),
  );
}
