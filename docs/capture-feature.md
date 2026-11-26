# StreetMend: Capture / Report an Issue

## What was added

Capture opens a separate flow above Home or Reports, preserving the selected tab and its state. Existing submitted reports remain sample data. The capture flow never inserts into that list or sends a report to an authority.

1. Issue: one photo (camera or gallery), one of five existing categories or Other Issue (Specify), which requires a custom title, a required description (up to 1,000 characters), and an optional landmark.
2. Location: explicit Use My Location action, or pan/zoom the map beneath the centre pin. GPS is a candidate, not an automatic confirmation. Users can also enter signed latitude/longitude if GPS or map imagery is unavailable. Confirm This Location records the candidate.
3. Review: photo, issue details, confirmed coordinates, location source, edit actions, and a disabled Submit button explaining that no backend is connected.

The draft is held in memory for this capture session. Navigation between steps preserves it. Closing asks before discarding entered information; restarting the application loses the draft. Native photo pickers may create temporary cache files managed by the OS. Nothing is uploaded. Android picker recovery runs when Home opens and offers any recovered image in a new capture flow; the other in-memory fields cannot be recovered after process death.

## Code organization

- `lib/capture/report_draft.dart`: plain draft data, category choices, coordinate validation. Latitude and longitude retain full numeric precision; review displays six decimal places. Accuracy depends on the device, not decimal count.
- `capture_page.dart`: form, validation, step navigation, photo actions and discard confirmation.
- `location_picker_page.dart`: GPS candidate, manual map selection, coordinate entry and explicit confirmation. A request identifier prevents a late GPS response from replacing a manual selection.
- `review_report_page.dart`: reads the draft and offers edits; no submission code.
- `services/photo_service.dart`: native image picker, file size/decode checks, and Android lost-image recovery. Requests no full photo metadata; this is not a guarantee that the image file has no EXIF metadata. A future upload pipeline must handle metadata explicitly.
- `services/location_service.dart`: single current-position request after permission, timeout handling, and settings access. No continuous tracking.
- `widgets/draft_photo.dart`: image preview.
- `widgets/issue_map.dart`: interactive map, fixed pin, attribution and tile-loading error message. It never requests GPS itself.

The default Kuala Lumpur map centre is labelled as a browsing starting point. It cannot be confirmed until the citizen actively selects a position. It is never represented as measured GPS. Manual selection retains its own source label.

## Dependencies and permissions

Four direct dependencies were added: `image_picker`, `geolocator`, `flutter_map`, and `latlong2`. Their required transitive dependencies are recorded in `pubspec.lock`; no additional state-management, geocoding, database or authentication package was added.

- iOS `Info.plist`: camera, photo-library and When In Use location explanations. No microphone, Always location, or background modes.
- Android main manifest: internet (map imagery), coarse location and fine location. Photo selection uses the system picker/camera intent without adding broad storage permissions. No background-location permission was added.
- Flutter regenerates native plugin registration and Swift package integration for these dependencies.

### iOS build requirement

The project uses Swift Package Manager. The installed `geolocator_apple` package reads `BYPASS_PERMISSION_LOCATION_ALWAYS` while evaluating its package manifest. Use this environment variable for iOS builds/runs so the plugin compiles without Always-authorization support:

```sh
BYPASS_PERMISSION_LOCATION_ALWAYS=1 flutter run
BYPASS_PERMISSION_LOCATION_ALWAYS=1 flutter build ios --simulator --debug
```

For IDE or CI launches, pass the same environment variable to the Flutter build process. Do not add an Always permission description to work around this setting. Build configurations previously resolved without it may need their Swift package build state refreshed. The app code only asks for When In Use authorization.

Full Xcode, an iOS runtime, and (for a physical iPhone) signing configuration are required. The implementation environment has Command Line Tools selected and no Xcode app in `/Applications`; the attempted iOS build stopped with `Application not configured for iOS`. Native build/device validation is therefore outstanding, not claimed as passed.

## Maps and privacy

Standard OpenStreetMap tiles are used over HTTPS with application identification and visible attribution/copyright URL. flutter_map's native cache uses HTTP caching headers. No bulk/offline download feature is implemented. Tiles need a network connection, and the provider can see the IP address and viewed map area. The UI explains this. The tile URL can be supplied using `--dart-define=MAP_TILE_URL=...`; attribution must also be updated if changing provider.

OpenStreetMap's public tile service has no availability guarantee. Select an appropriate hosted provider before a public rollout. See https://operations.osmfoundation.org/policies/tiles/.

## Verification and device checklist

Automated tests use controlled photo/GPS services; they do not prove that physical camera hardware or GPS works. The map test uses the actual FlutterMap widget with in-memory image tiles, so gesture handling is exercised without contacting the tile provider.

On an iPhone, verify camera permission acceptance/denial, photo picker cancellation and HEIC photos, approximate/precise location, disabled location services, permanent denial with Settings recovery, map panning, airplane mode, negative coordinate entry, editing review information, keyboard layout and draft discard. Android process-death image recovery also needs a device check.

Future Supabase work should persist the confirmed latitude/longitude (not the original GPS reading), location source, confirmation time and applicable device accuracy alongside authenticated report ownership. Image storage, access policies, upload metadata handling and real error/success responses belong to that later phase.


## Location and custom-issue corrections

- The three actions are Use My Current Location, Choose on Map, and Manual Location. Device permission is requested only by the first action.
- Applied coordinates, GPS candidates and map movement synchronize coordinate fields and map position. Unapplied/invalid coordinate edits block confirmation. Review reads only the explicitly confirmed location.
- Map widgets now respond to changed coordinates after their initial creation, including when a Review widget is reused.
- Location sources are displayed separately: device location (GPS/browser), map selection and manual coordinates. Device accuracy is shown in Review only for a device-derived position; moving the pin clears that accuracy.
- Location notes are unverified text, not geocoding. Typing dPulze mall does not relocate the pin. Road/landmark search is not implemented or connected; the Location screen states this explicitly. No additional packages or permissions were added for these corrections.
- Other Issue requires a nonblank custom title of at most 100 characters. Its title, category, photo and description are included in Review. Switching category hides the custom title without erasing it from the draft.
