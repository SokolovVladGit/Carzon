import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/my_seller_profile.dart';
import '../../domain/seller_display_name_constraints.dart';
import '../bloc/public_seller_identity_cubit.dart';
import '../bloc/public_seller_identity_state.dart';
import '../utils/public_seller_display_name_validation.dart';
import '../utils/seller_initial_labels.dart';

/// Account-screen editor for buyer-visible seller identity: photo + display name.
///
/// When [embeddedInSection] is true, the widget omits outer card chrome so a
/// parent section card can wrap it without nested borders/shadows.
class PublicSellerNameSection extends StatefulWidget {
  const PublicSellerNameSection({super.key, this.embeddedInSection = false});

  /// Omit inner card/decoration — for use inside Profile account grouped card only.
  final bool embeddedInSection;

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

  String _previewBuyerLabel(
    PublicSellerIdentityState state,
    AppLocalizations l10n,
  ) {
    final t = _controller.text.trim();
    if (t.isNotEmpty) return t;
    final p = state.profile?.displayName?.trim();
    if (p != null && p.isNotEmpty) return p;
    return l10n.sellerFallbackName;
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
            return _LoadingBlock(
              embedded: widget.embeddedInSection,
              cardFill: cardFill,
              scheme: scheme,
              isDark: isDark,
              shadow: shadow,
            );
          }

          if (state.loadFailed) {
            return _ErrorBlock(
              embedded: widget.embeddedInSection,
              theme: theme,
              scheme: scheme,
              cardFill: cardFill,
              isDark: isDark,
              shadow: shadow,
              l10n: l10n,
            );
          }

          final busyIdentity = state.avatarBusy || state.saving;
          final hasAvatar = _hasAvatarVisual(state);

          if (widget.embeddedInSection) {
            final pickLabel = hasAvatar
                ? l10n.coverChangePhoto
                : l10n.profilePublicSellerAvatarChangePhoto;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: scheme.primary.withValues(
                        alpha: isDark ? 0.20 : 0.14,
                      ),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                          scheme.primary.withValues(
                            alpha: isDark ? 0.14 : 0.070,
                          ),
                          isDark
                              ? scheme.surfaceContainerLow
                              : scheme.surfaceContainerLowest,
                        ),
                        Color.alphaBlend(
                          scheme.primary.withValues(
                            alpha: isDark ? 0.05 : 0.022,
                          ),
                          isDark
                              ? scheme.surfaceContainerLow
                              : scheme.surfaceContainerLowest,
                        ),
                        Color.alphaBlend(
                          scheme.onSurface.withValues(
                            alpha: isDark ? 0.030 : 0.008,
                          ),
                          isDark
                              ? scheme.surfaceContainerLow
                              : scheme.surfaceContainerLowest,
                        ),
                      ],
                      stops: const [0, 0.52, 1],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _SellerAvatarFrame(
                          diameter: 66,
                          child: _AvatarPreview(
                            profile: state.profile,
                            diameter: 66,
                            busy: state.avatarBusy || _pickingImage,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _previewBuyerLabel(state, l10n),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.05,
                                  height: 1.18,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.96,
                                  ),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l10n.profilePublicSellerBuyerPreviewCaption,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: isDark ? 0.78 : 0.80,
                                  ),
                                  height: 1.30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _PremiumSecondaryActionButton(
                        label: pickLabel,
                        scheme: scheme,
                        isDark: isDark,
                        onPressed: busyIdentity || _pickingImage
                            ? null
                            : () => _pickAvatar(context),
                      ),
                    ),
                    if (hasAvatar) ...[
                      const SizedBox(width: 8),
                      _PremiumTextActionButton(
                        label: l10n.profilePublicSellerAvatarRemovePhoto,
                        scheme: scheme,
                        isDark: isDark,
                        onPressed: busyIdentity
                            ? null
                            : () => context
                                  .read<PublicSellerIdentityCubit>()
                                  .removeAvatar(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 13),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    endIndent: 2,
                    color: scheme.outline.withValues(
                      alpha: isDark ? 0.080 : 0.045,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                TextField(
                  controller: _controller,
                  maxLength: SellerDisplayNameConstraints.maxLength,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.94),
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.profilePublicSellerNameFieldLabel,
                    hintText: l10n.profilePublicSellerNameFieldHint,
                    filled: true,
                    counterText: '',
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: isDark ? 0.86 : 0.88,
                      ),
                    ),
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: isDark ? 0.52 : 0.58,
                      ),
                    ),
                    fillColor: isDark
                        ? Color.alphaBlend(
                            scheme.primary.withValues(alpha: 0.05),
                            scheme.surfaceContainerHigh.withValues(alpha: 0.32),
                          )
                        : Color.alphaBlend(
                            scheme.primary.withValues(alpha: 0.028),
                            scheme.surface,
                          ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: scheme.primary.withValues(
                          alpha: isDark ? 0.22 : 0.16,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: scheme.primary.withValues(
                          alpha: isDark ? 0.78 : 0.68,
                        ),
                        width: 1.5,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: scheme.primary.withValues(
                          alpha: isDark ? 0.22 : 0.16,
                        ),
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _trySave(context),
                ),
                const SizedBox(height: 11),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark
                        ? const <BoxShadow>[]
                        : [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.20),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.045),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: FilledButton(
                    onPressed: state.saving || state.avatarBusy
                        ? null
                        : () => _trySave(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      disabledBackgroundColor: scheme.primary.withValues(
                        alpha: isDark ? 0.32 : 0.40,
                      ),
                      disabledForegroundColor: scheme.onPrimary.withValues(
                        alpha: 0.62,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: state.saving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : Text(
                            l10n.profilePublicSellerNameSave,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.02,
                              color: scheme.onPrimary,
                            ),
                          ),
                  ),
                ),
              ],
            );
          }

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
                      _SellerAvatarFrame(
                        diameter: 72,
                        child: _AvatarPreview(
                          profile: state.profile,
                          diameter: 72,
                          busy: state.avatarBusy || _pickingImage,
                        ),
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

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({
    required this.embedded,
    required this.cardFill,
    required this.scheme,
    required this.isDark,
    required this.shadow,
  });

  final bool embedded;
  final Color cardFill;
  final ColorScheme scheme;
  final bool isDark;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
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
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({
    required this.embedded,
    required this.theme,
    required this.scheme,
    required this.cardFill,
    required this.isDark,
    required this.shadow,
    required this.l10n,
  });

  final bool embedded;
  final ThemeData theme;
  final ColorScheme scheme;
  final Color cardFill;
  final bool isDark;
  final List<BoxShadow> shadow;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final content = Column(
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
          onPressed: () => context.read<PublicSellerIdentityCubit>().load(),
          child: Text(l10n.commonRetry),
        ),
      ],
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.26 : 0.17),
        ),
        boxShadow: shadow,
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
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

class _PremiumSecondaryActionButton extends StatelessWidget {
  const _PremiumSecondaryActionButton({
    required this.label,
    required this.scheme,
    required this.isDark,
    required this.onPressed,
  });

  final String label;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        splashFactory: InkRipple.splashFactory,
        splashColor: scheme.primary.withValues(alpha: 0.10),
        highlightColor: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: enabled
                ? Color.alphaBlend(
                    scheme.primary.withValues(alpha: isDark ? 0.07 : 0.040),
                    isDark
                        ? scheme.surfaceContainerLow
                        : scheme.surfaceContainerLowest,
                  )
                : Color.alphaBlend(
                    scheme.onSurface.withValues(alpha: 0.04),
                    scheme.surfaceContainerLow.withValues(
                      alpha: isDark ? 0.55 : 0.70,
                    ),
                  ),
            border: Border.all(
              color: enabled
                  ? scheme.primary.withValues(alpha: isDark ? 0.30 : 0.24)
                  : scheme.outlineVariant.withValues(
                      alpha: isDark ? 0.20 : 0.26,
                    ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11.5),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? scheme.primary.withValues(alpha: isDark ? 0.94 : 0.90)
                      : scheme.onSurfaceVariant.withValues(
                          alpha: isDark ? 0.48 : 0.52,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumTextActionButton extends StatelessWidget {
  const _PremiumTextActionButton({
    required this.label,
    required this.scheme,
    required this.isDark,
    required this.onPressed,
  });

  final String label;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        splashFactory: InkRipple.splashFactory,
        splashColor: scheme.onSurface.withValues(alpha: 0.028),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11.5),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: enabled
                  ? scheme.onSurfaceVariant.withValues(
                      alpha: isDark ? 0.84 : 0.76,
                    )
                  : scheme.onSurfaceVariant.withValues(
                      alpha: isDark ? 0.44 : 0.48,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerAvatarFrame extends StatelessWidget {
  const _SellerAvatarFrame({required this.diameter, required this.child});

  final double diameter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: diameter + 14,
      height: diameter + 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              scheme.primary.withValues(alpha: isDark ? 0.24 : 0.15),
              scheme.surfaceContainerHighest,
            ),
            Color.alphaBlend(
              scheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
              scheme.surfaceContainerLow,
            ),
          ],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: child,
    );
  }
}
