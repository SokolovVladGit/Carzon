# App Store Connect privacy answers

Manual-entry worksheet based on the 24 August 2026 code and hosted-schema audit.
Re-check after any SDK, backend, analytics, advertising, payment or data-model
change. This file does not edit App Store Connect.

## Summary

**Data Used to Track You: NO.**

CARZON has no IDFA/ATT, advertising SDK, third-party advertising, cross-company
tracking, data brokerage or sale of user data in the audited implementation.

## Select these data types

| Apple data type | Collected | Linked to user | Tracking | Purpose selections | CARZON evidence |
|---|---:|---:|---:|---|---|
| Contact Info — Email Address | Yes | Yes | No | App Functionality | Supabase email/password Auth, recovery and support email correspondence |
| Contact Info — Name | Yes | Yes | No | App Functionality | Optional seller display name |
| Contact Info — Phone Number | Yes | Yes | No | App Functionality | Optional public listing contact |
| Contact Info — Other User Contact Info | Yes | Yes | No | App Functionality | Optional Telegram username and WhatsApp availability |
| User Content — Photos or Videos | Yes | Yes | No | App Functionality | Listing photos, seller avatar and chat/support images |
| User Content — Emails or Text Messages | Yes | Yes | No | App Functionality | Buyer/seller and support message text |
| User Content — Customer Support | Yes | Yes | No | App Functionality | Support conversation content/attachments and public email support |
| User Content — Other User Content | Yes | Yes | No | App Functionality | Listings/descriptions/specifications, reports/notes and vehicle/VIN content |
| Search History | Yes | Yes | No | App Functionality; Product Personalization | Named saved searches and stored structured criteria |
| Identifiers — User ID | Yes | Yes | No | App Functionality | Supabase UUID and account-linked relationships |
| Identifiers — Device ID | Yes | Yes | No | App Functionality | FCM/APNs/Firebase installation identifiers and optional device ID in the account token row |
| Usage Data — Product Interaction | Yes | Mixed | No | App Functionality; Analytics; Product Personalization | Favorites, saved searches, filter/price alerts, listing views, notification preferences and blocks. Anonymous view dedupe is not account-linked; signed-in use is linked. In App Store Connect use **Linked to User: Yes** because part of this data type is linked. |
| Diagnostics — Performance Data | Yes | No | No | App Functionality | GoogleDataTransport SDK performance metadata such as client event-cache size/drop counts, per Firebase's official Apple disclosure guide |
| Other Data | Yes | Yes | No | App Functionality | Full VIN and normalized vehicle/provider results do not fit a more specific Apple type |

### Purpose constraints

- **Developer Advertising or Marketing:** do not select.
- **Third-Party Advertising:** do not select.
- **Analytics:** select only for Usage Data/Product Interaction (aggregate and
  deduplicated listing-view measurement). Do not describe Firebase Analytics;
  it is not included.
- **Product Personalization:** select for saved searches, favorites and their
  user-configured alerts. Do not imply advertising personalization.
- **Other Purposes:** do not select on current evidence.

## Do not select these categories

- Health & Fitness
- Financial Info
- Purchases
- Precise Location
- Coarse Location (user-entered listing city/region is marketplace content, not
  device-derived location)
- Sensitive Info
- Contacts / address book
- Browsing History
- Other Diagnostic Data
- Crash Data
- Advertising Data
- Audio Data
- Gameplay Content

## Provider disclosure basis

Firebase's official Apple-platform disclosure page states that
FirebaseMessaging records the APNs token and associates it with a Firebase
installation/FCM registration token, and collects device/app fields for topic
operations. It also states that GoogleDataTransport collects limited SDK
performance metadata. FirebaseCore and GoogleUtilities do not themselves
collect data. CARZON does not ship Firebase Analytics or Crashlytics.

Official reference:
https://firebase.google.com/docs/ios/app-store-data-collection
