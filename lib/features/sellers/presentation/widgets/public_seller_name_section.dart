import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../domain/entities/my_seller_profile.dart';
import '../../domain/seller_display_name_constraints.dart';
import '../bloc/public_seller_identity_cubit.dart';
import '../bloc/public_seller_identity_state.dart';
import '../utils/public_seller_display_name_validation.dart';
import '../utils/seller_initial_labels.dart';

/// Account-screen editor for buyer-visible seller identity: **photo** + display name.
class PublicSellerNameSection extends StatefulWidget {
  const PublicSellerNameSection({super.key});

  @override
  State<PublicSellerNameSection> createState() =>
      _PublicSellerNameSectionState();
}

class _PublicSellerNameSectionState extends State<PublicSellerNameSection> {
  final _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _pickingImage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final cubit = context.read<PublicSellerIdentityCubit>();
    final st = cubit.state;
    if (st.avatarBusy || st.saving || _pickingImage) return;

    final l10n = context.l10n;
    setState(() => _pickingImage = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (!context.mounted || picked == null) return;

      final bytes = await picked.readAsBytes();
      final contentType = _resolveContentType(picked);
      await cubit.uploadAvatarFromPicker(
        bytes: bytes,
        contentType: contentType,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.imagePickerLoadFailed)));
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  String _resolveContentType(XFile file) {
    final reported = file.mimeType?.trim().toLowerCase();
    if (reported != null && reported.isNotEmpty) return reported;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  bool _hasAvatarVisual(PublicSellerIdentityState state) {
    final p = state.profile;
    if (p == null) return false;
    final u = p.avatarUrl?.trim();
    if (u != null && u.isNotEmpty) return true;
    final path = p.avatarPath?.trim();
    return path != null && path.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final shadow = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.065),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.032),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];

    final Color cardFill = isDark
        ? scheme.surfaceContainerLow
        : Color.alphaBlend(
            scheme.surfaceTint.withValues(alpha: 0.035),
            scheme.surfaceContainerLowest,
          );

    return MultiBlocListener(
      listeners: [
        BlocListener<PublicSellerIdentityCubit, PublicSellerIdentityState>(
          listenWhen: (prev, curr) =>
              prev.initialLoading && !curr.initialLoading && !curr.loadFailed,
          listener: (_, state) {
            _controller.text = state.profile?.displayName ?? '';
          },
        ),
        BlocListener<PublicSellerIdentityCubit, PublicSellerIdentityState>(
          listenWhen: (prev, curr) =>
              prev.saving && !curr.saving && !curr.saveFailed,
          listener: (context, state) {
            _controller.text = state.profile?.displayName ?? '';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.profilePublicSellerNameSaved)),
            );
          },
        ),
        BlocListener<PublicSellerIdentityCubit, PublicSellerIdentityState>(
          listenWhen: (prev, curr) =>
              prev.saving && !curr.saving && curr.saveFailed,
          listener: (context, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.profilePublicSellerNameSaveFailed)),
            );
          },
        ),
        BlocListener<PublicSellerIdentityCubit, PublicSellerIdentityState>(
          listenWhen: (prev, curr) =>
              curr.avatarSnack != PublicSellerAvatarSnack.none &&
              prev.avatarSnack != curr.avatarSnack,
          listener: (context, state) {
            final cubit = context.read<PublicSellerIdentityCubit>();
            final text = switch (state.avatarSnack) {
              PublicSellerAvatarSnack.uploaded =>
                l10n.profilePublicSellerAvatarUpdated,
              PublicSellerAvatarSnack.removed =>
                l10n.profilePublicSellerAvatarRemoved,
              PublicSellerAvatarSnack.uploadFailed =>
                l10n.profilePublicSellerAvatarUploadFailed,
              PublicSellerAvatarSnack.removeFailed =>
                l10n.profilePublicSellerAvatarRemoveFailed,
              PublicSellerAvatarSnack.unsupportedFormat =>
                l10n.profilePublicSellerAvatarUnsupportedType,
              PublicSellerAvatarSnack.none => null,
            };
            if (text != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(text)));
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) cubit.consumeAvatarSnack();
            });
          },
        ),
      ],
      child: BlocBuilder<PublicSellerIdentityCubit, PublicSellerIdentityState>(
        builder: (context, state) {
          if (state.initialLoading) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: cardFill,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: isDark ? 0.26 : 0.17),
                ),
                boxShadow: shadow,
              ),
              child: const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }

          if (state.loadFailed) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: cardFill,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: isDark ? 0.26 : 0.17),
                ),
                boxShadow: shadow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.profilePublicSellerNameLoadFailed,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () =>
                          context.read<PublicSellerIdentityCubit>().load(),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          final busyIdentity = state.avatarBusy || state.saving;
          final hasAvatar = _hasAvatarVisual(state);

          return DecoratedBox(
            decoration: BoxDecoration(
              color: cardFill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.outline.withValues(alpha: isDark ? 0.26 : 0.17),
              ),
              boxShadow: shadow,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.profilePublicSellerAvatarTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.06,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.profilePublicSellerAvatarDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _AvatarPreview(
                        profile: state.profile,
                        diameter: 72,
                        busy: state.avatarBusy || _pickingImage,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.tonal(
                              onPressed: busyIdentity || _pickingImage
                                  ? null
                                  : () => _pickAvatar(context),
                              child: Text(
                                l10n.profilePublicSellerAvatarChangePhoto,
                              ),
                            ),
                            if (hasAvatar) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: busyIdentity
                                    ? null
                                    : () => context
                                          .read<PublicSellerIdentityCubit>()
                                          .removeAvatar(),
                                child: Text(
                                  l10n.profilePublicSellerAvatarRemovePhoto,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.profilePublicSellerNameTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.06,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.profilePublicSellerNameDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    maxLength: SellerDisplayNameConstraints.maxLength,
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n.profilePublicSellerNameFieldLabel,
                      hintText: l10n.profilePublicSellerNameFieldHint,
                      filled: true,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onSubmitted: (_) => _trySave(context),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: state.saving || state.avatarBusy
                        ? null
                        : () => _trySave(context),
                    child: state.saving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onSecondaryContainer,
                            ),
                          )
                        : Text(l10n.profilePublicSellerNameSave),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _trySave(BuildContext context) {
    final l10n = context.l10n;
    final err = validatePublicSellerDisplayName(_controller.text, l10n);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    context.read<PublicSellerIdentityCubit>().save(_controller.text);
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.profile,
    required this.diameter,
    required this.busy,
  });

  final MySellerProfile? profile;
  final double diameter;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayName = profile?.displayName;

    final initials = sellerInitialsFromDisplayName(displayName);
    final trimmedUrl = profile?.avatarUrl?.trim();
    final hasUrl = trimmedUrl != null && trimmedUrl.isNotEmpty;

    final placeholder = CircleAvatar(
      radius: diameter / 2,
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
      foregroundColor: scheme.onSurfaceVariant,
      child: initials.isEmpty
          ? Icon(Icons.person_rounded, size: diameter * 0.48)
          : Text(
              initials,
              style: TextStyle(
                fontSize: diameter * 0.34,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
    );

    Widget imageOrPlaceholder = placeholder;
    if (hasUrl) {
      imageOrPlaceholder = ClipOval(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Image.network(
            trimmedUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => placeholder,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: diameter * 0.42,
                  height: diameter * 0.42,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.outline.withValues(alpha: 0.45),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        imageOrPlaceholder,
        if (busy)
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: diameter * 0.38,
                height: diameter * 0.38,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
