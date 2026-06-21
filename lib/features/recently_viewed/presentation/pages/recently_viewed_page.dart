import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../cubit/recently_viewed_cubit.dart';
import '../cubit/recently_viewed_state.dart';
import '../widgets/recently_viewed_empty_state.dart';
import '../widgets/recently_viewed_entry_tile.dart';

/// Standalone recently viewed screen (local history, guest OK).
class RecentlyViewedPage extends StatefulWidget {
  const RecentlyViewedPage({super.key});

  @override
  State<RecentlyViewedPage> createState() => _RecentlyViewedPageState();
}

class _RecentlyViewedPageState extends State<RecentlyViewedPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<RecentlyViewedCubit>();
      if (cubit.state.status == RecentlyViewedStatus.initial) {
        unawaited(cubit.loadFromStorage());
      }
    });
  }

  Future<void> _confirmClearAll() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recentlyViewedClearConfirmTitle),
        content: Text(l10n.recentlyViewedClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const ValueKey('recently_viewed_clear_confirm_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.recentlyViewedClearConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<RecentlyViewedCubit>().clear();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.recentlyViewedClearFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: light ? const Color(0xFFF7F9FC) : scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.recentlyViewedTitle),
        leading: const AppBackButton(fallback: AppRoutes.menu),
        actions: [
          BlocBuilder<RecentlyViewedCubit, RecentlyViewedState>(
            buildWhen: (prev, curr) => prev.entries != curr.entries,
            builder: (context, state) {
              if (state.entries.isEmpty) return const SizedBox.shrink();
              return TextButton(
                key: const ValueKey('recently_viewed_clear_button'),
                onPressed: _confirmClearAll,
                child: Text(l10n.recentlyViewedClear),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<RecentlyViewedCubit, RecentlyViewedState>(
        builder: (context, state) {
          if (state.status == RecentlyViewedStatus.loading &&
              state.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == RecentlyViewedStatus.failure &&
              state.entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.recentlyViewedLoadFailed,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state.entries.isEmpty) {
            return RecentlyViewedEmptyState(
              onBrowseListings: () => context.go(AppRoutes.listings),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: state.entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return RecentlyViewedEntryTile(
                key: ValueKey('recently_viewed_row_${entry.listingId}'),
                entry: entry,
                onTap: () =>
                    context.push(AppRoutes.listingDetailsPath(entry.listingId)),
              );
            },
          );
        },
      ),
    );
  }
}
