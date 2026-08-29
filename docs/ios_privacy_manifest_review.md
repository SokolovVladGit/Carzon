# iOS privacy manifest review

## App target conclusion

No `ios/Runner/PrivacyInfo.xcprivacy` is required for the current Runner code.
The app target does not directly call Apple's required-reason APIs: its native
sources contain only Flutter bootstrap, plugin registration, and notification
delegation. Adding an empty or speculative manifest would make an unsupported
privacy declaration.

Flutter and the iOS plugins remain separate SDK dependencies. Their shipped
privacy manifests must be embedded by CocoaPods in the release archive. The
current installed pods include manifests for Firebase Core, Firebase
Installations, Firebase Messaging, GoogleDataTransport, GoogleUtilities,
PromisesObjC, and nanopb; Flutter/plugin manifests must also be checked in the
actual archive because generated plugin artifacts are build-dependent.

## Release archive validation

After creating the signed release archive, the release owner must:

1. Inspect the archive for every `PrivacyInfo.xcprivacy` and confirm dependency
   manifests are embedded; do not infer this from `ios/Pods` alone.
2. Run App Store Connect upload validation and resolve every privacy-manifest or
   required-reason API warning before submission.
3. Re-run this review whenever Runner native code or an iOS plugin is added or
   upgraded.
4. Confirm App Store privacy answers match actual app/backend collection and
   the declarations in all embedded manifests.

This is a repository determination, not completed archive verification. Archive
inspection and App Store Connect validation remain out of Phase 1 local scope.
