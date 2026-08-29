import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../models/legal_document_content.dart';
import '../models/legal_section_content.dart';

/// Final localized legal document rendered from the same structured source used
/// by the portable public legal site.
class LegalPage extends StatefulWidget {
  const LegalPage({super.key, this.kind = LegalDocumentKind.notices});

  final LegalDocumentKind kind;

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  Future<LegalDocumentContent>? _documentFuture;
  String? _languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_documentFuture == null || _languageCode != languageCode) {
      _languageCode = languageCode;
      _documentFuture = loadLegalDocumentContent(
        kind: widget.kind,
        languageCode: languageCode,
      );
    }
  }

  @override
  void didUpdateWidget(covariant LegalPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _documentFuture = loadLegalDocumentContent(
        kind: widget.kind,
        languageCode: _languageCode ?? 'ru',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = _languageCode ?? 'ru';
    return FutureBuilder<LegalDocumentContent>(
      future: _documentFuture,
      builder: (context, snapshot) {
        final document = snapshot.data;
        final scheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: _legalPageBackground(context),
          appBar: AppBar(
            leading: const AppBackButton(fallback: AppRoutes.settings),
            title: Text(document?.title ?? context.l10n.legalTitle),
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: scheme.onSurface,
            systemOverlayStyle: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _legalCanvasGradient(context),
                stops: const [0, 0.42, 1],
              ),
            ),
            child: switch (snapshot.connectionState) {
              ConnectionState.waiting || ConnectionState.active => const Center(
                child: CircularProgressIndicator(),
              ),
              _ when snapshot.hasError => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    languageCode == 'ro'
                        ? 'Documentul nu a putut fi încărcat.'
                        : 'Не удалось загрузить документ.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              _ => _LegalBody(document: document!),
            },
          ),
        );
      },
    );
  }
}

class _LegalBody extends StatelessWidget {
  const _LegalBody({required this.document});

  final LegalDocumentContent document;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 32 + bottomInset),
      children: [
        _LegalIntro(text: document.intro),
        for (final section in document.sections) ...[
          const SizedBox(height: 28),
          _LegalSectionBlock(section: section),
        ],
      ],
    );
  }
}

class _LegalIntro extends StatelessWidget {
  const _LegalIntro({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      key: const ValueKey<String>('legal_document_intro'),
      decoration: AppTheme.filterAlertManagementSurface(
        scheme,
        borderRadius: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _LegalSectionBlock extends StatelessWidget {
  const _LegalSectionBlock({required this.section});

  final LegalSectionContent section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurface.withValues(alpha: isDark ? 0.90 : 0.88),
      height: 1.55,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.heading,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < section.paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Text(section.paragraphs[i], style: bodyStyle),
        ],
        if (section.bullets.isNotEmpty) ...[
          if (section.paragraphs.isNotEmpty) const SizedBox(height: 12),
          for (final item in section.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 9, right: 10),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(child: Text(item, style: bodyStyle)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

Color _legalPageBackground(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    scheme.primary.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.05 : 0.018,
    ),
    scheme.surface,
  );
}

List<Color> _legalCanvasGradient(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  if (scheme.brightness == Brightness.dark) {
    return AppTheme.editorialDarkFilterCanvasGradient(scheme);
  }
  return [
    Color.alphaBlend(
      scheme.surfaceTint.withValues(alpha: 0.008),
      scheme.surface,
    ),
    Color.alphaBlend(scheme.primary.withValues(alpha: 0.032), scheme.surface),
    scheme.surface,
  ];
}
