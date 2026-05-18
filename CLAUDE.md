# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ODON Booking is a Flutter hotel management app with a Node.js/Express + MongoDB backend. It handles room bookings, expenses, salaries, inventory, invoices, and AI-driven business insights.

Each dart file is one screen in the app. The app runs on both Android and web (`flutter run -d chrome`).

## Commands

### Flutter (Frontend)

```bash
flutter run                  # Run on connected device/emulator
flutter run -d web           # Run in browser
flutter build apk            # Build Android APK
flutter build ios            # Build iOS
flutter test                 # Run all tests
flutter analyze              # Static analysis
flutter clean                # Clean build artifacts
```

### Backend (`flutter_mongodb_backend/`)

```bash
npm install                  # Install dependencies
npm start                    # Start Express server (port 3000)
lsof -ti :3000 | xargs kill -9   # Kill stale node process if port busy
```

**Important**: Node does NOT auto-reload on file changes. Always restart the backend after editing `server.js`.

## Architecture

### Frontend (`lib/`)

Feature-based folder structure. New screens should be added inside the relevant feature folder, not directly in `lib/`.

```
lib/
├── main.dart
├── core/
│   ├── api/
│   │   └── api_service.dart          # All HTTP calls — single service
│   └── utils/
│       ├── file_saver.dart           # Conditional export (web/mobile/stub)
│       ├── file_saver_web.dart
│       ├── file_saver_mobile.dart
│       └── file_saver_stub.dart
├── features/
│   ├── auth/
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── bookings/
│   │   ├── room_selection_screen.dart
│   │   ├── view_bookings_screen.dart
│   │   ├── edit_booking_screen.dart
│   │   ├── past_bookings_screen.dart
│   │   ├── future_bookings_screen.dart
│   │   └── selected_day_booking.dart
│   ├── rooms/
│   │   └── room_config_screen.dart
│   ├── financials/
│   │   ├── calculate_profit_page.dart
│   │   ├── expenses_screen.dart
│   │   ├── ViewEditSalariesExpensesScreen.dart
│   │   └── price_settings_screen.dart
│   ├── invoices/
│   │   ├── generate_invoice_screen.dart
│   │   └── invoice.dart
│   ├── inventory/
│   │   ├── add_inventory_item_screen.dart
│   │   └── edit_inventory_item_screen.dart
│   ├── ai_insights/
│   │   ├── ai_insights_page.dart
│   │   └── ai_insights_service.dart
│   └── guests/
│       ├── guests_list_screen.dart
│       ├── guest_detail_screen.dart
│       └── widgets/
│           └── guest_name_autocomplete.dart
└── shared/
    ├── widgets/
    │   └── data_confirmation_dialog.dart
    └── services/
        └── image_processor_service.dart
```

**Entry point**: `lib/main.dart` → `HomeScreen` (`lib/features/home/home_screen.dart`)

**API layer**: `lib/core/api/api_service.dart` — all HTTP calls go through this single service. Currently pointing to the Railway production URL. For a physical Android device use the machine's local IP, for an emulator use `http://10.0.2.2:3000`.

**Import conventions**: Cross-feature imports use `package:odon_booking/` absolute paths. Same-feature imports use relative paths.

**State management**: Plain `StatefulWidget` + `setState()` — no Provider, BLoC, or Riverpod.

### Backend (`flutter_mongodb_backend/`)

Express.js server with Mongoose models and REST routes:

- **Booking** — see full schema below
- **RoomConfig** — single document storing all room definitions; see schema below
- **Guest** — phone-keyed guest directory. See "Guests Feature" section below.
- **Inventory** — hotel inventory items
- **Salary** — employee salary records (`/salaries/month/:year/:month` for monthly queries)
- **Expense** — business expenses with category support (`/expenses/month/:year/:month`)
- **PriceConfig** — single-document store for room prices. `GET /prices` seeds defaults on first run; `PUT /prices` updates them. The `packages` field is a Mixed type so `markModified('packages')` must be called before saving.

Database: MongoDB Atlas (`hotel` database). Connection string is hardcoded in `server.js`.

## Database Schemas

### Booking Schema

```js
{
  // Legacy fields — only present on old single-room bookings
  roomNumber: String,
  roomType:   String,

  // New multi-room format — array, one entry per booked room
  rooms: [{
    roomNumber: String,   // e.g. '101'
    roomType:   String,   // 'Double' | 'Triple' | 'Family' | 'Family Plus'
    pax:        Number,   // 2 / 3 / 4 / 5
  }],

  package:       String,  // 'Full Board' | 'Half Board' | 'Room Only' | 'BnB' | 'Dinner Only'
  mealStart:     String,  // 'Lunch' | 'Dinner' — first meal on arrival day (FB/HB only)
  needDriver:    Boolean, // default false — whether a driver room is required for this booking
  extraDetails:  String,
  checkIn:       Date,
  checkOut:      Date,
  num_of_nights: Number,
  total:         String,
  advance:       String,
  balanceMethod: String,  // 'Bank' | 'Cash'
  guestName:     String,
  guestPhone:    String,
}
```

**Backward compatibility**: Old bookings use the flat `roomNumber`/`roomType` strings. New bookings use the `rooms[]` array and leave the legacy fields absent. All screens that display bookings check `booking['rooms'] != null && rooms.isNotEmpty` to determine the format (`_isNewFormat` pattern).

### RoomConfig Schema

Single document in the `roomconfigs` collection. Seeded automatically on first `GET /room-config` if no document exists.

```js
{
  rooms: [{
    roomNumber: String,                          // '1'–'5', '101'–'107'
    baseType:   String (enum: 'Family'|'Double'),
    floor:      String (enum: 'Ground'|'Upper'),
    isBlocked:  Boolean,                         // default false
  }]
}
```

**Default room layout:**

| Room | Floor  | Base Type | Notes           |
|------|--------|-----------|-----------------|
| 1    | Ground | Family    |                 |
| 2    | Ground | Double    |                 |
| 3    | Ground | Double    |                 |
| 4    | Ground | Double    | Blocked (manager's room) |
| 5    | Ground | Family    |                 |
| 101  | Upper  | Family    |                 |
| 102  | Upper  | Double    |                 |
| 103  | Upper  | Double    |                 |
| 104  | Upper  | Double    |                 |
| 105  | Upper  | Double    |                 |
| 106  | Upper  | Double    |                 |
| 107  | Upper  | Family    |                 |

**Routes**: `GET /room-config` (seeds defaults if empty), `PUT /room-config` (body: `{ rooms: [...] }`)

## Room Type System

Effective room type is derived at booking time — it is NOT stored in RoomConfig:

- `Double` base + no extra bed → **Double** (2 pax)
- `Double` base + extra bed → **Triple** (3 pax)
- `Family` base + no extra bed → **Family** (4 pax)
- `Family` base + extra bed → **Family Plus** (5 pax)

The extra-bed state per room is tracked in `_extraBedRooms` (a `Set<String>`) in `room_selection_screen.dart` during booking creation. The extra bed toggle is the small `+` button on selected room cards.

## Multi-Room Booking Flow

One booking document = one guest = potentially multiple rooms. All rooms share the same package, check-in/out dates, and guest details.

`lib/features/bookings/room_selection_screen.dart`:
- Fetches room config from DB on load
- Highlights booked rooms for the selected date range (overlap detection)
- Tap a room card to select/deselect; tap the `+` badge to toggle extra bed
- Deducts inventory items across all selected rooms on save
- Saves ONE booking with `rooms[]` array

## Home Screen

`lib/features/home/home_screen.dart` — dashboard entry point after login.

**Today / Tomorrow tab toggle**: `TabController` with `_dayOffset` (0 or 1). All computed values (`_active`, `_meals`, `_occupiedCount`) recompute from `_selectedDay` on each rebuild — no extra API calls needed.

**Room map**: 2D grid showing each room tile coloured by the active booking's package. Empty rooms are grey.

**Meal count logic** (`_meals` getter):

Two passes are done for each selected day:

1. **Staying guests** (`_active` — checkIn ≤ day < checkOut):
   - `BnB`: breakfast only if NOT check-in day (driver prepares for next morning)
   - `Full Board` check-in day: if `mealStart == 'Lunch'` → lunch + dinner; else → dinner only
   - `Full Board` other days: breakfast + lunch + dinner
   - `Half Board` check-in day: if `mealStart == 'Lunch'` → lunch + dinner; else → dinner only
   - `Half Board` other days: breakfast + dinner
   - `Dinner Only`: dinner every day

2. **Departing guests** (`_checkingOutOn` — checkOut == day):
   - FB / HB / BnB: add breakfast (guests leave after breakfast on checkout morning)
   - RO / Dinner Only: nothing

**Package color codes:**

| Package    | Color      | Hex         |
|------------|------------|-------------|
| Full Board | Green      | `0xFF16A34A` |
| Half Board | Blue       | `0xFF2563EB` |
| BnB        | Purple     | `0xFF7C3AED` |
| Room Only  | Cyan       | `0xFF0891B2` |
| Dinner Only| Orange     | `0xFFEA580C` |

**Package abbreviations** used on room tiles: FB, HB, B&B, RO, DO.

## View Bookings Screen

`lib/features/bookings/view_bookings_screen.dart`

- Calendar badge = room count (not booking count); uses `Stack` + `Positioned(bottom: -5, right: -5)` with `Clip.none` to avoid RenderFlex overflow in the fixed-height calendar cell
- **Collapse/expand toggle**: thin indigo strip with chevron icon between the calendar and the booking list. Tapping it hides/shows the month summary banner + calendar (`AnimatedSize`). State: `_calendarExpanded` (default `true`)
- Booking card shows a yellow "Driver Room Required" badge (with car icon) when `needDriver == true`
- Room chips are colour-coded by room type: Family Plus = deepOrange, Family = orange, Triple = teal, Double = indigo
- **Data fetching**: `initState` fires two calls in parallel — `_fetchBookingsForDay` (today's list) and `_fetchMonthEvents` (calendar markers). Day taps call `_fetchBookingsForDay` again. The month data already contains all day data, so these are redundant — if optimising, derive selected-day bookings from `_events` locally instead.

## Edit Booking Screen

`lib/features/bookings/edit_booking_screen.dart`

Handles both old and new booking formats via `_isNewFormat` flag. New format shows per-room type dropdowns; legacy shows single text fields. Includes:
- Package dropdown (including Dinner Only)
- First Meal on Arrival dropdown (shown only for Full Board / Half Board)
- Driver Room checkbox (`_needDriver`)
- Balance method checkboxes (Bank / Cash)

## Guests Feature

Phone-keyed guest directory. Guests are auto-populated from booking saves — there is no manual "add guest" flow.

### Guest Schema

```js
{
  phone: String,   // unique, indexed — primary lookup key
  name:  String,
  // timestamps: createdAt, updatedAt
}
```

### Backend behaviour (`flutter_mongodb_backend/server.js`)

- `upsertGuest(name, phone)` helper: called from `POST /bookings` and `PUT /bookings/:id`. **Skips if `phone` is empty/whitespace** — guests without a phone are not added to the DB.
- `GET /guests` — lists all guests via aggregation, joining the bookings collection to attach `bookingCount` and `lastBooking` fields. Sorted by `lastBooking` desc.
- `GET /guests/search?q=...` — case-insensitive substring match on name OR phone, capped at 10 results, sorted by `updatedAt` desc. Used by the autocomplete.
- `GET /guests/:phone` — single guest by phone.
- `GET /guests/:phone/bookings` — full booking history for a guest, sorted by `checkIn` desc.
- **One-time backfill**: `backfillGuestsIfNeeded()` runs inside `GET /guests` when the guests collection is empty, extracting distinct (phone, name) pairs from existing bookings.

### Frontend

- `lib/features/guests/guests_list_screen.dart` — guest directory: gradient summary banner (total guests + total bookings), search bar (filters local list), guest cards with avatar + name + phone + last visit + booking count pill. Pull to refresh.
- `lib/features/guests/guest_detail_screen.dart` — single-guest view: hero card with name/phone/last-visit, three stat cards (bookings / room-nights / revenue), full booking history. Tapping a booking opens `EditBookingScreen`.
- `lib/features/guests/widgets/guest_name_autocomplete.dart` — drop-in replacement for the guest-name TextField. Uses `RawAutocomplete` with the parent's existing controllers, debounces queries by 250ms, requires ≥2 characters before searching. Selecting a suggestion fills the phone controller. Wired into both `room_selection_screen.dart` (Add Booking) and `edit_booking_screen.dart`.
- Guests tile on the home dashboard (`lib/features/home/home_screen.dart`) — pink (`0xFFDB2777`) `people_alt_rounded` icon.

## Driver Room Feature

- **Add booking** (`lib/features/bookings/room_selection_screen.dart`): "Requires Driver Room" checkbox with car icon. State: `bool _needDriver = false`. Sent as `needDriver: bool` in the booking payload.
- **Edit booking** (`lib/features/bookings/edit_booking_screen.dart`): Same checkbox, pre-populated from `booking['needDriver'] == true`.
- **View bookings** (`lib/features/bookings/view_bookings_screen.dart`): Amber badge shown below room chips when `needDriver == true`.
- **DB**: `needDriver: Boolean` with `default: false` in Booking schema. Both `POST /bookings` and `PUT /bookings/:id` explicitly pass `needDriver: req.body.needDriver ?? false`. PUT uses `{ $set: updateData }` to guarantee the field is written.

## Packages

Available package types: `Full Board`, `Half Board`, `Room Only`, `BnB`, `Dinner Only`

`mealStart` field (`'Lunch'` or `'Dinner'`) is only relevant for Full Board and Half Board. It records what the first meal on the arrival day is. Reset to null when package is changed to anything else.

## Key Dependencies

| Package                               | Purpose                                        |
| ------------------------------------- | ---------------------------------------------- |
| `http`                                | API calls                                      |
| `table_calendar`                      | Calendar date picker                           |
| `pdf` + `path_provider` + `open_file` | Invoice PDF generation and opening             |
| `google_fonts`                        | Typography (outfit font also bundled as asset) |
| `image_picker`                        | Inventory image selection                      |
| `month_picker_dialog`                 | Month selection for financial reports          |
| `intl`                                | Date/currency formatting                       |

## Invoice PDF Notes

- Check-in time is fixed at **2:00 PM**, check-out at **11:00 AM** — displayed inline on the PDF.
- Extra hour charge note (LKR 1,000/hr) appears in red below the stay info.
- Guest phone number is optional — shown under guest name in "BILL TO" if provided.
- Fixed notes use `-` instead of `•` bullets because Helvetica has no Unicode bullet support.
- Uses `pw.Font.helvetica()` built-in fonts. Do NOT swap to TTF via `rootBundle` — font files are declared under `fonts:` not `assets:` in pubspec.yaml so rootBundle cannot load them.

## Switching Between Local and Production Backend

In [lib/core/api/api_service.dart](lib/core/api/api_service.dart), toggle `baseUrl`:
- Local dev (physical device): `http://<your-LAN-IP>:3000` (run `ipconfig getifaddr en0` to find it)
- Emulator: `http://10.0.2.2:3000`
- Production: Railway URL (currently active)
