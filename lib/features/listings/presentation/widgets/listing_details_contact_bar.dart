import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../../shared/ui/whatsapp_contact_icon.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../messaging/presentation/utils/messaging_failure_mapper.dart';
import '../../../messaging/presentation/utils/messaging_user_messages.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_contact.dart';
import '../bloc/listing_details_cubit.dart';
import '../utils/contact_format.dart';

/// Sticky bottom contact bar for the listing details screen: chat action
/// plus phone reveal/copy.
///
/// This widget reads [AuthCubit] and [ListingDetailsCubit] from the
/// surrounding `BlocProvider` scope (provided by the listing details page),
/// so the chat/auth gating and conversation-start behavior are identical to
/// the previous same-library `part`. Only [listing] is passed explicitly.
class ListingDetailsContactBar extends StatefulWidget {
  const ListingDetailsContactBar({super.key, required this.listing});

  final Listing listing;

  @override
  State<ListingDetailsContactBar> createState() =>
      _ListingDetailsContactBarState();
}

class _ListingDetailsContactBarState extends State<ListingDetailsContactBar> {
  bool _phoneRevealed = false;
  bool _openingChat = false;
  bool _loadingContact = false;
  ListingContact? _contact;

  Future<ListingContact?> _ensureContactLoaded(BuildContext context) async {
    if (_contact != null) return _contact;
    if (_loadingContact) return null;
    setState(() => _loadingContact = true);
    try {
      final result = await context
          .read<ListingDetailsCubit>()
          .revealPublicContact(widget.listing.id);
      if (!context.mounted) return null;
      switch (result) {
        case Success(:final value):
          setState(() => _contact = value);
          return value;
        case FailureResult():
          _showError(context);
          return null;
      }
    } finally {
      if (mounted) setState(() => _loadingContact = false);
    }
  }

  Future<void> _onPhoneTap(BuildContext context) async {
    final contact = await _ensureContactLoaded(context);
    if (!context.mounted || contact == null) return;
    final tel = telUriString(contact.phone);
    if (!_phoneRevealed) {
      setState(() => _phoneRevealed = true);
      return;
    }
    if (tel == null) {
      return;
    }
    try {
      final ok = await launchUrl(
        Uri.parse(tel),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) _showError(context);
    } catch (_) {
      if (context.mounted) _showError(context);
    }
  }

  Future<void> _onTelegramTap(BuildContext context) async {
    final contact = await _ensureContactLoaded(context);
    if (!context.mounted || contact == null) return;
    final username = contact.telegramUsername;
    if (username == null || username.isEmpty) {
      _showError(context);
      return;
    }
    await _launchExternal(context, Uri.parse('https://t.me/$username'));
  }

  Future<void> _onWhatsappTap(BuildContext context) async {
    final contact = await _ensureContactLoaded(context);
    if (!context.mounted || contact == null) return;
    final digits = contact.whatsappEnabled
        ? whatsappDigits(contact.phone)
        : null;
    if (digits == null) {
      _showError(context);
      return;
    }
    await _launchExternal(context, Uri.parse('https://wa.me/$digits'));
  }

  Future<void> _onCopyPhone(BuildContext context, String rawPhone) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: rawPhone.trim()));
      messenger.showSnackBar(SnackBar(content: Text(l10n.contactPhoneCopied)));
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.contactActionFailed)),
        );
      }
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.contactActionFailed)));
  }

  Future<void> _launchExternal(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _showError(context);
    } catch (_) {
      if (context.mounted) _showError(context);
    }
  }

  Future<void> _onChatTap(BuildContext context) async {
    final l10n = context.l10n;
    final auth = context.read<AuthCubit>().state;
    if (auth.status != AuthStatus.authenticated || auth.user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.messagingSignInRequired),
          action: SnackBarAction(
            label: l10n.commonSignIn,
            onPressed: () => context.go(AppRoutes.signIn),
          ),
        ),
      );
      return;
    }
    final listing = widget.listing;
    if (listing.sellerId == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.messagingUnavailableNoSeller)),
      );
      return;
    }
    if (listing.sellerId == auth.user!.id) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.messagingCannotMessageSelf)));
      return;
    }

    setState(() => _openingChat = true);
    try {
      final result = await context
          .read<ListingDetailsCubit>()
          .startConversationForListing(listing.id);
      if (!context.mounted) return;
      switch (result) {
        case FailureResult(:final failure):
          final kind = messagingFailureKindFrom(failure);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                messagingFailureMessage(l10n, kind, isSendAction: true),
              ),
            ),
          );
        case Success(:final value):
          await context.push(AppRoutes.messagesThreadPath(value));
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final phone = _contact?.phone;
    final tel = telUriString(phone);
    final telegram = _contact?.telegramUsername;
    final whatsappDigitsValue = (_contact?.whatsappEnabled ?? false)
        ? whatsappDigits(phone)
        : null;
    final footerDecoration = AppTheme.editorialDarkFilterFooter(scheme);
    final divider = scheme.outlineVariant.withValues(alpha: 0.4);

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration:
            footerDecoration ??
            BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: divider, width: 0.5)),
            ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SizedBox(
              height: _bottomButtonHeight,
              child: Row(
                children: [
                  _ChatPillButton(
                    loading: _openingChat,
                    onPressed: _openingChat ? null : () => _onChatTap(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PhonePrimaryPill(
                      tel: tel,
                      rawPhone: phone,
                      revealed: _phoneRevealed,
                      contactLoaded: _contact != null,
                      loading: _loadingContact,
                      onTap: _loadingContact
                          ? null
                          : () => _onPhoneTap(context),
                      onCopy: (tel == null || !_phoneRevealed || phone == null)
                          ? null
                          : () => _onCopyPhone(context, phone),
                    ),
                  ),
                  if (telegram != null) ...[
                    const SizedBox(width: 8),
                    _IconContactButton(
                      tooltip: l10n.contactTelegram,
                      icon: const Icon(CarzonIcons.send, size: 20),
                      onPressed: () => _onTelegramTap(context),
                    ),
                  ],
                  if (whatsappDigitsValue != null) ...[
                    const SizedBox(width: 8),
                    _IconContactButton(
                      tooltip: l10n.contactWhatsapp,
                      icon: const WhatsappContactIcon(size: 20),
                      onPressed: () => _onWhatsappTap(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const double _bottomButtonHeight = 50;
const double _bottomButtonRadius = 12;

RoundedRectangleBorder _bottomButtonShape() => const RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(_bottomButtonRadius)),
);

class _ChatPillButton extends StatelessWidget {
  const _ChatPillButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      height: _bottomButtonHeight,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onSurface,
                ),
              )
            : const Icon(CarzonIcons.chat, size: 20),
        label: Text(l10n.chatLabel),
        style: FilledButton.styleFrom(
          backgroundColor: isDark
              ? Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.10),
                  scheme.surfaceContainerHigh,
                )
              : scheme.surfaceContainerHighest.withValues(alpha: 0.9),
          foregroundColor: scheme.onSurface.withValues(
            alpha: isDark ? 0.94 : 1,
          ),
          side: isDark
              ? BorderSide(color: scheme.outline.withValues(alpha: 0.28))
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: _bottomButtonShape(),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PhonePrimaryPill extends StatelessWidget {
  const _PhonePrimaryPill({
    required this.tel,
    required this.rawPhone,
    required this.revealed,
    required this.contactLoaded,
    required this.loading,
    required this.onTap,
    required this.onCopy,
  });

  final String? tel;
  final String? rawPhone;
  final bool revealed;
  final bool contactLoaded;
  final bool loading;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    ButtonStyle buttonStyle({bool disabled = false}) => FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      shape: _bottomButtonShape(),
      backgroundColor: disabled ? theme.colorScheme.surfaceContainerHigh : null,
      textStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );

    if (loading || !contactLoaded) {
      return SizedBox(
        height: _bottomButtonHeight,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Icon(CarzonIcons.eye, size: 20),
          label: Text(l10n.contactShowPhone),
          style: buttonStyle(),
        ),
      );
    }

    if (tel == null) {
      return SizedBox(
        height: _bottomButtonHeight,
        child: FilledButton.icon(
          onPressed: null,
          icon: const Icon(CarzonIcons.phoneOff, size: 20),
          label: Text(l10n.phoneNotProvided),
          style: buttonStyle(disabled: true),
        ),
      );
    }

    if (!revealed) {
      return SizedBox(
        height: _bottomButtonHeight,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(CarzonIcons.eye, size: 20),
          label: Text(l10n.contactShowPhone),
          style: buttonStyle(),
        ),
      );
    }

    return SizedBox(
      height: _bottomButtonHeight,
      child: FilledButton(
        onPressed: onTap,
        style: buttonStyle().copyWith(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.only(left: 18, right: 6),
          ),
        ),
        child: Row(
          children: [
            const Icon(CarzonIcons.phoneCall, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                rawPhone!.trim(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (onCopy != null) ...[
              const SizedBox(width: 6),
              _InlineCopyAction(tooltip: l10n.contactCopyPhone, onTap: onCopy!),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconContactButton extends StatelessWidget {
  const _IconContactButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: _bottomButtonHeight,
      height: _bottomButtonHeight,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: _bottomButtonShape(),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Tooltip(message: tooltip, child: icon),
      ),
    );
  }
}

class _InlineCopyAction extends StatelessWidget {
  const _InlineCopyAction({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(CarzonIcons.copy, size: 18),
          ),
        ),
      ),
    );
  }
}
