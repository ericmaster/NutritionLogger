# NutritionLogger - Development Instructions

> **⚠️ CRITICAL: AI Assistants Must:**
> 1. Read this file before making changes
> 2. Verify current implementation in code
> 3. **Update BOTH README.md AND instructions.md** when changing code (NON-NEGOTIABLE)
> 4. Maintain current state only - no change history
> 5. Code + Documentation = Atomic Operation

> **IMPORTANT**: Only create SUMMARY.md when explicitly asked.

## Project Overview

Garmin Connect IQ app for trail running with custom nutrition tracking (RPE, Water, Electrolytes, Food). Targets Fenix 7 Pro. Records FIT files with custom fields, displays real-time metrics, includes session menu with save/discard confirmation.

## Project Structure

```
source/
├── NutritionLoggerApp.mc          # Main app, session management, FIT fields
├── NutritionLoggerDelegate.mc     # Input handling, button logic
├── NutritionLoggerView.mc         # Main UI rendering
├── NutritionLoggerMenuDelegate.mc # Menu navigation
├── NutritionLoggerMenuView.mc     # Menu rendering
├── ConfirmationView.mc            # Save/discard confirmation
├── ConfirmationDelegate.mc        # Confirmation input
├── StatusMessageView.mc           # Brief status messages
└── Debug.mc                       # Debug logging

resources/
├── drawables/     # launcher_icon.svg
├── strings/       # Localized strings
└── layouts/       # layout.xml (minimal)
```

## Key Architecture

### NutritionLoggerApp.mc
Main application extending `Application.AppBase`.

**Key Variables:**
- `mSession`: ActivityRecording session
- `mRPE`: Rate of Perceived Exertion (0-4)
- `mCounters`: [water, electrolytes, food]
- `mSelectedIndex`: Current field (0=RPE, 1=Water, 2=Electrolytes, 3=Food, 4=MENU)
- `mRPEField`, `mWaterField`, `mElectrolytesField`, `mFoodField`: FitContributor fields

**Field Constants:**
- `RPE_FIELD = 0`, `WATER_FIELD = 1`, `ELECTROLYTES_FIELD = 2`, `FOOD_FIELD = 3`, `MENU_FIELD = 4`

### NutritionLoggerDelegate.mc
Handles all user input.

**Button Mapping (Idle):**
- START: Start new recording session

**Button Mapping (Recording):**
- START: Increment selected field (or open menu if on MENU_FIELD)
- BACK: Decrement selected field (ignored if on MENU_FIELD)
- UP: Cycle up (4→3→2→1→0→4)
- DOWN: Cycle down (0→1→2→3→4→0)

### NutritionLoggerMenuDelegate.mc
Custom menu using `BehaviorDelegate` (not `MenuInputDelegate`).

**Menu Options:** Resume (0), Save (1), Discard (2)

**Button Mapping:**
- UP/DOWN: Navigate, START: Select, BACK: Return to main view

### NutritionLoggerView.mc
Main UI rendering with cached strings/layout values for performance.

**Display:** Status, time, distance/altitude, HR/temp, 4 data fields + MENU, button hints

## Application States

**0: Idle** - Press START to begin
**1: Recording** - Cycle fields (UP/DOWN), increment (START), decrement (BACK), open menu (cycle to MENU + START)
**2: Menu** - Navigate (UP/DOWN), select (START), cancel (BACK)
**3: Confirmation** - Confirm (START) or cancel (BACK)
**4: Status Message** - Brief message before exit

## FIT File Integration

Custom fields written to RECORD messages:
- `rate_of_perceived_exertion` (UINT8, 0-4)
- `water_intake_count` (UINT8)
- `electrolytes_intake_count` (FLOAT)
- `food_intake_count` (FLOAT)

## Sensors & Permissions

**Enabled:** Heart rate, temperature, accelerometer, gyroscope, GPS
**Required Permissions:** Fit, FitContributor, Positioning, Sensor, SensorHistory, SensorLogging

**Target Devices:** Fenix 5S Plus, Fenix 7 Pro (+ No WiFi variant)
**Min API:** 3.3.0

## Development Setup

**Prerequisites:** Java SDK, VS Code, Connect IQ SDK Manager, Monkey C extension

**Quick Start:**
1. Install SDK Manager → download SDK & device profiles
2. Install Monkey C extension → run `Verify Installation` → `Generate Developer Key`
3. Press `Ctrl+F5` → select device → simulator launches

**Build Commands:**
- `Monkey C: Run` - Launch simulator
- `Monkey C: Build for Device` - Compile for device
- `Monkey C: Export Project` - Create .iq package

## Code Conventions

- **Variables:** `mVariableName` (members), `CONSTANT_NAME`
- **Functions:** `camelCase`
- **Classes:** `PascalCase`
- **Types:** Always explicit: `function myFunc(param as String) as Number { }`

## Common Issues

**Session fails:** Check manifest.xml permissions
**Custom fields missing:** Verify `initFitFields()` called after session creation
**Sensors show "--":** Enable in `onShow()`, wait for data
**Unintended increment:** Use `mIgnoreNextRelease` flag pattern

## Extending the App

### Add Data Field
1. **App.mc:** Add constant before `MENU_FIELD`, update `MENU_FIELD` value, add field variable, update `initFitFields()` and `setFieldByIndex()`
2. **View.mc:** Add label before "MENU", update loop bound, handle display logic
3. **strings.xml:** Add label resource
4. **Delegate.mc:** Update modulo for cycling, handle in increment/decrement

### Add Sensor
1. Add to `Sensor.setEnabledSensors()` in `onShow()`
2. Handle in `onSensor()` callback
3. Display in `onUpdate()`

### Customize Buttons
Modify `Delegate.mc`: `onKey()` (UP/DOWN), `onStartKey()` (increment/menu), `onBackKey()` (decrement)

## Distribution

**Build:** `Export Project` → outputs .iq to bin/
**Sideload:** Copy .iq to `GARMIN/Apps/` on watch

## AI Assistant Guidelines

### Documentation Requirements

**Update BOTH files together when code changes:**
- **README.md:** User docs (button mappings, features, setup)
- **instructions.md:** Tech docs (architecture, classes, patterns)

**Documentation Sync Checklist:**
- [ ] Code implementation updated
- [ ] README.md updated (user-facing)
- [ ] instructions.md updated (technical)
- [ ] Both files reflect CURRENT state only
- [ ] Code comments updated

**Golden Rules:**
1. Always update BOTH files together
2. Current state only (no change history)
3. Same session (atomic operation)
4. Verify against actual code

### Workflow

```
1. Read instructions.md
2. Examine source files
3. Make code changes
4. IMMEDIATELY update README.md
5. IMMEDIATELY update instructions.md
6. Verify consistency
7. Report all changes
```

**Do NOT:**
- Assume docs are current
- Update code without updating docs
- Update one doc without the other
- Add "Recent Changes" sections

---

**Target Device:** Garmin Fenix 7 Pro
**Language:** Monkey C
**SDK:** Connect IQ 3.3.0+
**License:** MIT
