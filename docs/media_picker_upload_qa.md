# Media Picker And Upload QA Checklist

Use this checklist before release for create/edit listing media flows.

Do not use production accounts or real seller contact data for media QA. Use a test account and test listings.

## Test Setup

- Android physical device or emulator with Google Photos / system picker available.
- iOS physical device or simulator with Photos available.
- Test user signed in.
- At least one owner listing with existing gallery photos for edit tests.
- Network controls available:
  - slow network profile, or
  - airplane mode, or
  - OS/network proxy throttle.

## Android

### Picker Permission Denied

1. Start from a fresh install or revoke photo permissions in Android Settings.
2. Open create listing.
3. Tap add photo.
4. Deny access if prompted.

Expected:

- No crash.
- User sees a localized recoverable picker error if the picker reports failure.
- Existing form fields remain unchanged.
- User can retry after changing permissions.

### Picker Cancel

1. Open create listing.
2. Tap add photo.
3. Close/cancel the picker without selecting.

Expected:

- No snackbar/error.
- Existing form fields remain unchanged.
- Add-photo UI remains available.

Repeat for edit listing gallery.

### Large Image

1. Select a large photo from the gallery.
2. Confirm preview appears.
3. Publish/save.

Expected:

- App remains responsive.
- Upload either succeeds or shows a localized recoverable upload error.
- Selected media remains available for retry after failure.

### Many Images / Max Images

1. Add photos until reaching the maximum allowed count.
2. Attempt to add one more.

Expected:

- The app blocks adding beyond the max.
- A localized max-photos message is shown.
- Existing selected photos are not removed.

### Slow Network Upload

1. Select one or more photos.
2. Enable slow network.
3. Publish/save.

Expected:

- Submit/save button is disabled while upload is in progress.
- Progress indicator is visible.
- Duplicate taps do not create duplicate listings or duplicate gallery replacements.

### Airplane Mode During Upload

1. Select one or more photos.
2. Start publish/save.
3. Enable airplane mode during upload.

Expected:

- Upload fails with localized recoverable error.
- Create listing: selected media and form fields remain available for retry.
- Edit listing: staged gallery changes remain available for retry.
- No raw storage path, SQL, RLS, or backend error text appears in UI.

## iOS

### Picker Permission Denied

1. Revoke Photos permission in iOS Settings or use a fresh install.
2. Open create listing.
3. Tap add photo.
4. Deny access if prompted.

Expected:

- No crash.
- User sees a localized recoverable picker error if the picker reports failure.
- Existing form fields remain unchanged.

Repeat for edit listing gallery.

### Picker Cancel

1. Open create listing.
2. Tap add photo.
3. Cancel picker.

Expected:

- No snackbar/error.
- Existing form fields remain unchanged.
- Add-photo UI remains available.

Repeat for edit listing gallery.

## Edit Listing Replacement Failure

### Replace Gallery Then Fail Upload

1. Open an owner listing with existing photos.
2. Add a new photo or replace gallery order.
3. Force upload failure with airplane mode or blocked network.
4. Tap save.

Expected:

- Existing remote gallery is not deleted early.
- Staged local media remains visible after failure.
- Save can be retried.
- Localized upload failure appears.

### Replace Gallery Then Fail Metadata Update

1. Open an owner listing with existing photos.
2. Stage a gallery change.
3. Force the gallery metadata/RPC step to fail if test tooling allows it.

Expected:

- Existing remote gallery remains usable.
- Newly uploaded blobs are cleaned up best-effort.
- User sees localized gallery replace failure.
- Staged gallery changes remain visible for retry.

## Background / Foreground During Upload

1. Select media.
2. Start publish/save.
3. Background the app.
4. Return to foreground.

Expected:

- App does not crash.
- If upload completes, success behavior is unchanged.
- If upload fails/interrupted, localized recoverable error is shown and staged media remains available.

## Pass Criteria

- Picker cancellation is neutral.
- Picker errors are localized and recoverable.
- Upload failures preserve staged media and form state.
- Duplicate submit/save is blocked while in progress.
- Edit listing does not delete old gallery images before replacement succeeds.
- No raw storage paths, user IDs, RLS errors, SQL errors, or service details are shown to users.

## Fail Criteria

- App crashes during picker or upload.
- Cancellation shows an error.
- Upload failure clears selected media or form fields.
- Duplicate taps create duplicate listings or duplicate gallery mutations.
- Existing edit gallery is lost after failed upload or failed replacement.
- Raw backend/storage details are visible in UI.
