import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../cubit/recent_searches_cubit.dart';
import '../cubit/recent_searches_state.dart';
import '../widgets/recent_search_entry_tile.dart';
import '../widgets/recent_searches_empty_state.dart';

/// Standalone recent searches screen (local history, guest OK).
class RecentSearchesPage extends StatefulWidget {
  const RecentSearchesPage({super.key});

  @override
  State<RecentSearchesPage> createState() => _RecentSearchesPageState();
}

class _RecentSearchesPageState extends State<RecentSearchesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<RecentSearchesCubit>();
      if (cubit.state.status == RecentSearchesStatus.initial) {
        unawaited(cubit.loadFromStorage());
      }
    });
  }

  Future<void> _confirmClearAll() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recentSearchesClearConfirmTitle),
        content: Text(l10n.recentSearchesClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const ValueKey('recent_searches_clear_confirm_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.recentSearchesClearConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<RecentSearchesCubit>().clear();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.recentSearchesClearFailed)));
    }
  }

  Future<void> _deleteEntry(int index) async {
    final l10n = context.l10n;
    final cubit = context.read<RecentSearchesCubit>();
    final entry = cubit.state.entries[index];
    final ok = await cubit.remove(entry);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.recentSearchesRemoveFailed)));
    }
  }

  void _reapplyEntry(int index) {
    final entry = context.read<RecentSearchesCubit>().state.entries[index];
    context.go(
      AppRoutes.listings,
      extra: ListingsFeedLaunch(snapshot: entry.criteria),
    );
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
        title: Text(l10n.recentSearchesTitle),
        leading: const AppBackButton(fallback: AppRoutes.menu),
        actions: [
          BlocBuilder<RecentSearchesCubit, RecentSearchesState>(
            buildWhen: (prev, curr) => prev.entries != curr.entries,
            builder: (context, state) {
              if (state.entries.isEmpty) return const SizedBox.shrink();
              return TextButton(
                key: const ValueKey('recent_searches_clear_button'),
                onPressed: _confirmClearAll,
                child: Text(l10n.recentSearchesClear),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<RecentSearchesCubit, RecentSearchesState>(
        builder: (context, state) {
          if (state.status == RecentSearchesStatus.loading &&
              state.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == RecentSearchesStatus.failure &&
              state.entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.recentSearchesLoadFailed,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state.entries.isEmpty) {
            return RecentSearchesEmptyState(
              onBrowseListings: () => context.go(AppRoutes.listings),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: state.entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return RecentSearchEntryTile(
                key: ValueKey('recent_search_row_$index'),
                entry: entry,
                deleteKey: ValueKey('recent_search_delete_$index'),
                onTap: () => _reapplyEntry(index),
                onDelete: () => _deleteEntry(index),
              );
            },
          );
        },
      ),
    );
  }
}
