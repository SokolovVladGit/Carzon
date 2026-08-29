# App Store legal URL readiness

Status updated 29 August 2026. The owner manually verified the canonical public
legal site over HTTPS without authentication, including English default content
and RU/RO language switching. App Store Connect has not yet been configured.

| App Store field | Canonical public URL | Publication status |
|---|---|---|
| Privacy Policy URL | `https://carzon-legal.netlify.app/privacy/` | PUBLIC / OWNER VERIFIED |
| Support URL | `https://carzon-legal.netlify.app/support/` | PUBLIC / OWNER VERIFIED |
| Terms URL | `https://carzon-legal.netlify.app/terms/` | PUBLIC / OWNER VERIFIED |
| Privacy Choices URL | `https://carzon-legal.netlify.app/privacy-choices/` | PUBLIC / OWNER VERIFIED |

Public support email: `carzonsupport@gmail.com` — **PUBLIC / OWNER VERIFIED**.

## Hosting package

- Portable static package: `web/legal/` plus route entry points under
  `web/ru/`, `web/ro/`.
- Canonical production origin: `https://carzon-legal.netlify.app`.
- The route entry points fetch `/legal/legal_content.json`; the eventual host
  serves the repository `web/` layout at the domain root and preserves the
  directory routes.
- Repository web config uses `carzonsupport@gmail.com` and operator display name
  `Carzon`. No deployment was performed by this integration task.

## Future manual App Store Connect entry

- Privacy Policy URL → `https://carzon-legal.netlify.app/privacy/`
- Support URL → `https://carzon-legal.netlify.app/support/`
- Privacy Choices URL → `https://carzon-legal.netlify.app/privacy-choices/`
- Terms → `https://carzon-legal.netlify.app/terms/`

These values are ready for manual entry, but this document does not claim that
App Store Connect is configured.

## Remaining owner/legal decisions

- Governing law and dispute jurisdiction.
- Minimum user age, if a numeric threshold is required.
- Legal review of the final text and the exact App Store metadata entry.
