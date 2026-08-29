# Provider policy verification

Checked against official/first-party material on 24 August 2026. The purpose is
to constrain CARZON's statements, not to incorporate provider terms or claim a
specific legal compliance status.

| Provider | Official evidence and finding | CARZON wording constraint |
|---|---|---|
| Supabase | [Security](https://supabase.com/docs/guides/security) and [shared responsibility](https://supabase.com/docs/guides/deployment/shared-responsibility-model) describe hosted Auth/Database/Storage/Realtime/Functions and shared responsibility. [User management](https://supabase.com/docs/guides/auth/managing-user-data) confirms admin deletion and that Storage objects can block deletion unless removed first. | Describe Supabase as infrastructure processing CARZON-controlled data. Do not imply deletion instantly erases provider backups/logs or that Supabase compliance transfers to CARZON. |
| Firebase/Google | [Apple data collection guide](https://firebase.google.com/docs/ios/app-store-data-collection) says FirebaseMessaging associates APNs and installation/FCM tokens and collects device/app fields; GoogleDataTransport collects limited SDK performance metadata. | Disclose push/install identifiers and limited diagnostics. Do not claim Firebase Analytics/Crashlytics collection because those SDKs are absent. |
| Apple APNs | [Registering with APNs](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns) explains the app/device-specific token and forwarding it to the provider server; [sending requests](https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns) confirms token and payload transmission. | Disclose token and notification payload processing for delivery. |
| NHTSA | [vPIC material](https://www.nhtsa.gov/document/vpic-flyer-nhtsa%E2%80%99s-product-information-catalog-and-vehicle-listing) confirms VIN-decoder/API use; [privacy policy](https://www.nhtsa.gov/about-nhtsa/privacy-policy) confirms standard request logging such as IP, client and time. | Explicitly disclose raw normalized VIN transmission. Do not say NHTSA receives CARZON account identity; code does not include it. Acknowledge ordinary server-request metadata. |
| EPA / FuelEconomy.gov | [EPA privacy and security notice](https://www.epa.gov/privacy/privacy-and-security-notice) describes normal HTTP request logs including IP, client, requested object and time. | Disclose make/model/year lookup inputs and possible server network metadata, not user email/UUID. |
| ANRE | [Official e-Carburanți announcement](https://anre.md/index.php/in-atentia-consumatorilor-de-carburanti-anre-a-lansat-aplicatia-mobila-a-platformei-e-carburant-3-525) describes public daily fuel-price information. | Treat ANRE as a public factual source. Do not imply affiliation or transmission of CARZON identity fields. |
| Sheriff | [Official fuel page](https://sheriff.md/activities/nefteprodukty/toplivnpr/) publishes access to retail fuel prices. | Treat Sheriff as a public commercial source, preserve explicit non-affiliation wording, and do not imply user-identity transmission. |

The Supabase changelog Markdown endpoint could not be fetched by the available
web reader because of its content type. No new Supabase feature or API was
implemented in this phase; current Supabase docs and the live read-only schema
were used instead.
