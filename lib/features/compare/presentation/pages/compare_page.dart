import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../cubit/compare_cubit.dart';
import '../cubit/compare_page_cubit.dart';
import '../cubit/compare_state.dart';
import '../widgets/compare_empty_states.dart';
import '../widgets/compare_spec_view.dart';

/// Standalone compare screen (local set, no auth required in v1).
class ComparePage extends StatelessWidget {
  const ComparePage({super.key, this.pageCubit});

  /// Optional override for tests; production uses [sl].
  final ComparePageCubit? pageCubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    final page = Scaffold(
      backgroundColor: light ? const Color(0xFFF7F9FC) : scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.compareTitle),
        leading: const AppBackButton(fallback: AppRoutes.menu),
      ),
      body: BlocBuilder<CompareCubit, CompareState>(
        builder: (context, state) {
          void goBrowse() => context.go(AppRoutes.listings);

          if (state.isEmpty) {
            return CompareEmptyState(onBrowseListings: goBrowse);
          }
          if (state.hasOneItem) {
            return CompareNeedOneMoreState(
              item: state.items.first,
              onBrowseListings: goBrowse,
            );
          }
          return CompareSpecView(
            items: state.items,
            onClear: () => context.read<CompareCubit>().clear(),
          );
        },
      ),
    );

    if (pageCubit != null) {
      return BlocProvider.value(value: pageCubit!, child: page);
    }
    return BlocProvider(create: (_) => sl<ComparePageCubit>(), child: page);
  }
}
