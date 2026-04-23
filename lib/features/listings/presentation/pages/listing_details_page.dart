import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../domain/entities/listing.dart';
import '../bloc/listing_details_cubit.dart';
import '../bloc/listing_details_state.dart';
import '../utils/listing_formatters.dart';

class ListingDetailsPage extends StatelessWidget {
  const ListingDetailsPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ListingDetailsCubit>()..load(id),
      child: _ListingDetailsView(id: id),
    );
  }
}

class _ListingDetailsView extends StatelessWidget {
  const _ListingDetailsView({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing'),
        actions: [FavoriteToggleButton(listingId: id)],
      ),
      body: BlocBuilder<ListingDetailsCubit, ListingDetailsState>(
        builder: (context, state) {
          switch (state.status) {
            case ListingDetailsStatus.initial:
            case ListingDetailsStatus.loading:
              return const LoadingView();
            case ListingDetailsStatus.failure:
              return ErrorView(
                message: state.errorMessage ?? 'Failed to load listing.',
                onRetry: () => context.read<ListingDetailsCubit>().load(id),
              );
            case ListingDetailsStatus.success:
              return _DetailsBody(listing: state.listing!);
          }
        },
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (listing.coverImageUrl != null && listing.coverImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  listing.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                ),
              ),
            )
          else
            const _ImagePlaceholder(),
          const SizedBox(height: 16),
          Text(listing.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            formatEur(listing.priceEur),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Make', value: listing.make),
          _DetailRow(label: 'Model', value: listing.model),
          _DetailRow(label: 'Year', value: listing.year.toString()),
          _DetailRow(label: 'Mileage', value: formatKm(listing.mileageKm)),
          _DetailRow(label: 'Type', value: formatType(listing.type)),
          _DetailRow(label: 'City', value: listing.city),
          _DetailRow(label: 'Posted', value: formatDate(listing.createdAt)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.directions_car,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
