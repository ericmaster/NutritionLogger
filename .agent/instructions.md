# NutritionLogger - Development Instructions

> **IMPORTANT**: Only create a SUMMARY.md file when explicitly asked by the user.

## Project Overview

**NutritionLogger** (also known as Trail Run Recorder) is a Garmin Connect IQ watch application designed for trail running activities. The app records FIT activity files with custom nutrition tracking capabilities, specifically targeting the Garmin Fenix 7 Pro and similar devices.

### Core Features

- Records running activities with Trail Running sub-sport classification
- Tracks Rate of Perceived Exertion (RPE) and three custom nutrition counters:
  - **RPE (Rate of Perceived Exertion)** - Scale 0-4 (maps to RPE 1-2, 3-4, 5-6, 7-8, 9-10)
  - **Water intake**
  - **Electrolytes intake**
  - **Food intake**
- Real-time display of activity metrics (time, distance, altitude, heart rate, SpO2, temperature)
- FitContributor integration to save custom data fields to FIT files
- Sensor logging for accelerometer and gyroscope data
- Session menu with confirmation dialogs for save/discard

---

## Project Structure

```
NutritionLogger/
├── source/
│   ├── NutritionLoggerApp.mc          # Main application entry point
│   ├── NutritionLoggerDelegate.mc     # Input handling and session management
│   ├── NutritionLoggerMenuDelegate.mc # Menu navigation with custom view
│   ├── NutritionLoggerMenuView.mc     # Custom menu rendering
│   ├── NutritionLoggerView.mc         # Main UI rendering and display logic
│   ├── ConfirmationView.mc            # Confirmation dialog view
│   ├── ConfirmationDelegate.mc        # Confirmation dialog input handler
│   ├── StatusMessageView.mc           # Brief status messages
│   └── Debug.mc                       # Debug logging utility
├── resources/
│   ├── drawables/
│   │   ├── drawables.xml
│   │   └── launcher_icon.svg
│   ├── layouts/
│   │   └── layout.xml                 # Main layout (minimal, mostly programmatic UI)
│   ├── menus/
│   │   └── menu.xml                   # Menu resource (not used, kept for reference)
│   └── strings/
│       └── strings.xml                # Localized strings
├── bin/                               # Build output (gitignored)
├── .agent/                            # AI assistant instructions
│   └── instructions.md
├── .vscode/                           # VS Code configuration
├── manifest.xml                       # App manifest with permissions and targets
├── monkey.jungle                      # Build configuration
├── developer_key                      # Developer signing key (gitignored)
├── .gitignore
├── LICENSE                            # MIT License
└── README.md                          # Setup and usage documentation
```

---

## Application Architecture

### 1. **NutritionLoggerApp.mc**

The main application class that extends `Application.AppBase`.

**Key Responsibilities:**
- Manages the activity recording session (`mSession`)
- Initializes FitContributor fields for custom data
- Handles sensor and GPS initialization
- Maintains nutrition counters and RPE value
- Stores reference to main delegate for cross-component communication

**Important Variables:**
- `mSession`: ActivityRecording session object
- `mRPEField`, `mWaterField`, `mElectrolytesField`, `mFoodField`: FitContributor fields
- `mRPE`: Rate of Perceived Exertion (0-4)
- `mCounters`: Array of three numbers tracking intake counts [water, electrolytes, food]
- `mSelectedIndex`: Currently selected field (0=RPE, 1=Water, 2=Electrolytes, 3=Food)
- `mDelegate`: Reference to main NutritionLoggerDelegate
- `logger`: SensorLogger for accelerometer/gyroscope data

**Field Constants:**
- `RPE_FIELD = 0`
- `WATER_FIELD = 1`
- `ELECTROLYTES_FIELD = 2`
- `FOOD_FIELD = 3`

**Key Methods:**
- `onStart()`: Initializes GPS
- `onStop()`: Cleans up session on app exit
- `getInitialView()`: Creates and stores delegate reference
- `initSensorLogger()`: Initializes accelerometer/gyroscope logging
- `initFitFields()`: Creates custom FIT fields
- `setFieldByIndex()`: Updates FIT field values
- `resetCounters()`: Resets all counters and RPE to defaults

### 2. **NutritionLoggerDelegate.mc**

Handles all user input during activity recording.

**Key Responsibilities:**
- Processes button presses and releases
- Starts/stops activity recording
- Cycles through data fields (RPE, Water, Electrolytes, Food)
- Implements short/long press detection for increment/decrement
- Manages timer events for UI updates
- Opens session menu on BACK button

**Button Mapping (Idle):**
- **Start/Stop (ENTER)**: Start new recording session

**Button Mapping (During Recording):**
- **Start/Stop (Short Press)**: Increment selected field
- **Start/Stop (Long Press ≥1000ms)**: Decrement selected field (triggers immediately on hold)
- **Up**: Cycle up through fields (0→3→2→1→0)
- **Down**: Cycle down through fields (0→1→2→3→0)
- **Back/Lap**: Open session menu (recording continues in background)

**Key Variables:**
- `mIgnoreNextRelease`: Flag to prevent unintended increments after certain actions
- `mHoldTimer`: Timer for detecting long press
- `mHoldTriggered`: Whether long press was triggered
- `mLastKeyDownAt`: Timestamp of key press

**Key Methods:**
- `onKey()`: Handles standard key events
- `onStartKey()`: Starts session or initiates increment/decrement logic
- `onKeyReleased()`: Implements short press increment
- `onHoldTimer()`: Callback for long press decrement
- `onBackKey()`: Opens session menu with custom view
- `incrementCounter()`: Increments selected field with feedback
- `decrementCounter()`: Decrements selected field with feedback
- `onTimerEvent()`: Updates FIT fields on each timer tick

### 3. **NutritionLoggerMenuDelegate.mc**

Manages the session menu using custom view and BehaviorDelegate.

**Key Change:** No longer uses `MenuInputDelegate` - changed to `BehaviorDelegate` for custom button handling.

**Menu Options:**
- **Resume** (index 0): Returns to main view, continues recording
- **Save** (index 1): Shows confirmation dialog, then saves and exits
- **Discard** (index 2): Shows confirmation dialog, then discards and exits

**Button Mapping:**
- **Up**: Move selection up
- **Down**: Move selection down  
- **Start/Stop (ENTER)**: Select current menu item
- **Back/Lap (ESC)**: Return to main view without selecting

**Key Variables:**
- `mPostStop`: Whether menu is shown during active session
- `mSelectedItem`: Currently selected menu item (0-2)

**Key Methods:**
- `onKey()`: Handles all button presses (UP/DOWN/ENTER/ESC)
- `onSelectItem()`: Executes action for selected menu item
- `getSelectedItem()`: Returns current selection for view to render

**Important:** When Resume is selected, sets `app.mDelegate.mIgnoreNextRelease = true` to prevent unintended increment upon returning to main view.

### 4. **NutritionLoggerMenuView.mc**

Custom view for rendering the session menu.

**Display Elements:**
- Title: "Session Menu"
- Three menu options with visual highlighting
- Selected item shown in yellow with ">" markers
- Other items shown in gray with smaller font
- Button hints at bottom (UP/DOWN = Navigate, START = Select, BACK = Return)

**Key Methods:**
- `initialize()`: Takes delegate reference to access selected item
- `onUpdate()`: Renders menu with current selection highlighted
- `getSelectedItem()`: Queries delegate for current selection

### 5. **ConfirmationView.mc**

Displays confirmation dialog for save/discard actions.

**Display Elements:**
- Message: "Save Session?" or "Discard Session?"
- Instructions: "START = Confirm" and "BACK = Cancel"

**Key Methods:**
- `initialize()`: Takes message and action symbol
- `onUpdate()`: Renders confirmation dialog
- `getAction()`: Returns the action being confirmed

### 6. **ConfirmationDelegate.mc**

Handles user input on confirmation screen.

**Button Mapping:**
- **Start/Stop (ENTER)**: Confirm action
- **Back/Lap (ESC)**: Cancel and return to menu

**Key Methods:**
- `onKey()`: Handles button presses
- `executeAction()`: Performs save or discard, shows status message, exits app
- `showStatusMessage()`: Displays brief confirmation before exit

### 7. **StatusMessageView.mc**

Shows brief status message before app exit.

**Display Elements:**
- Green text: "Session Saved" or "Session Discarded"
- Centered on screen

### 8. **NutritionLoggerView.mc**

Renders the main UI and displays activity data.

**Display Elements:**
- Status indicator (Recording/Idle) with color coding
- Elapsed time (HH:MM:SS)
- Distance / Altitude
- Heart rate, SpO2, Temperature
- Four data fields with selected item highlighted:
  - RPE with range (e.g., "3-4") and difficulty label
  - Water counter
  - Electrolytes counter
  - Food counter
- Button hints (visual arcs and labels)
- +/- indicators when recording

**Key Features:**
- Pre-computed trigonometry values for performance
- Cached string resources
- Color-coded RPE display (cyan→green→yellow→orange→red)
- Dynamic font sizing for selected field

**Key Methods:**
- `onLayout()`: Caches strings and layout values
- `onShow()`: Enables sensors and starts sensor callbacks
- `onUpdate()`: Redraws screen with current data
- `onHide()`: Disables sensors and stops timers
- `onSensor()`: Receives sensor data updates
- `tick()`: Timer callback for periodic UI refresh
- `getRPEColor()`: Returns color based on RPE value

---

## Application States and Flow

### State 0: App Started (Idle)
- Display shows "Idle" status in white/green
- Counters and RPE are at defaults
- Pressing **Start/Stop** begins a new activity
- No button hints displayed

### State 1: Activity Recording
- Display shows "Recording" in red
- Timer is running
- GPS and sensors are active
- Button hints visible (arcs and +/- signs)
- User can:
  - Cycle through fields with Up/Down
  - Increment selected field with Start (short press)
  - Decrement selected field with Start (long press ≥1s)
  - Open session menu with Back

### State 2: Session Menu
- Custom menu view displayed
- Recording continues in background
- Selected item highlighted in yellow
- User can:
  - Navigate with Up/Down
  - Select with Start
  - Cancel with Back

### State 3: Confirmation Dialog
- Shown when Save or Discard selected
- User must confirm or cancel
- Blocks exit until confirmation

### State 4: Status Message (Brief)
- Shows "Session Saved" or "Session Discarded"
- Displays for moment before app exit
- Includes haptic and audio feedback

---

## FIT File Integration

The app uses **FitContributor** to write custom developer fields to the FIT file:

| Field Name | Field ID | Data Type | Units | Description |
|------------|----------|-----------|-------|-------------|
| `rate_of_perceived_exertion` | 0 | UINT8 | level | RPE value (0-4) |
| `water_intake_count` | 1 | UINT8 | count | Number of water intake events |
| `electrolytes_intake_count` | 2 | FLOAT | count | Number of electrolyte intake events |
| `food_intake_count` | 3 | FLOAT | count | Number of food intake events |

These fields are written to **RECORD** messages, meaning they're timestamped with each GPS point during the activity.

---

## Sensor Configuration

### Enabled Sensors:
- **Heart Rate**: Displayed on main screen
- **Pulse Oximetry (SpO2)**: Displayed on main screen
- **Temperature**: Displayed on main screen
- **Accelerometer**: Logged via SensorLogger
- **Gyroscope**: Logged via SensorLogger

### GPS:
- **Mode**: Continuous location updates
- **Callback**: `onPosition()` (currently minimal logging)

---

## Permissions Required

Defined in `manifest.xml`:

- `Fit`: Access to FIT file recording
- `FitContributor`: Write custom developer fields
- `Notifications`: (Reserved for future use)
- `PersistedContent`: (Reserved for future use)
- `PersistedLocations`: (Reserved for future use)
- `Positioning`: GPS access
- `Sensor`: Heart rate, temperature, pulse ox
- `SensorHistory`: Access to historical sensor data
- `SensorLogging`: Log accelerometer/gyroscope data

---

## Target Devices

Currently configured for:
- Fenix 5S Plus
- Fenix 7 Pro
- Fenix 7 Pro (No WiFi variant)

**Minimum API Level**: 3.3.0

---

## Development Setup

### Prerequisites

1. **Java SDK**: Required for Garmin development tools
2. **Visual Studio Code**: Primary IDE
3. **Connect IQ SDK Manager**: Download from [Garmin Developer Portal](https://developer.garmin.com/)
4. **Monkey C Extension**: Install from VS Code marketplace

### Setup Steps

1. **Install SDK Manager**
   - Download and launch SDK Manager
   - Download latest Connect IQ SDK
   - Download device profiles (Fenix 7 Pro, etc.)
   - Set active SDK version

2. **Configure VS Code**
   - Install "Monkey C" extension by Garmin
   - Run `Monkey C: Verify Installation` from Command Palette
   - Run `Monkey C: Generate a Developer Key` (creates `developer_key` file)

3. **Build and Run**
   - Open any `.mc` file in the project
   - Press `Ctrl+F5` (Run Without Debugging)
   - Select target device from list
   - Simulator will launch with the app

### Build Commands

From VS Code Command Palette:
- `Monkey C: Build for Device` - Compile for specific device
- `Monkey C: Run` - Build and launch simulator
- `Monkey C: Export Project` - Create `.iq` package for distribution

---

## Code Conventions

### Naming Conventions
- **Member variables**: Prefix with `m` (e.g., `mSession`, `mCounters`)
- **Constants**: Use `UPPER_SNAKE_CASE` (e.g., `LONG_MS`)
- **Functions**: Use `camelCase` (e.g., `initFitFields()`)
- **Classes**: Use `PascalCase` (e.g., `NutritionLoggerApp`)

### Import Style
```monkey-c
import Toybox.Module;           // Standard import
using Toybox.Module as Alias;  // Aliased import
```

### Type Annotations
All function parameters and return types should be explicitly typed:
```monkey-c
function myFunction(param as String) as Number {
    return 42;
}
```

---

## Testing and Debugging

### Simulator Testing
1. Launch simulator with `Ctrl+F5`
2. Use on-screen buttons or keyboard shortcuts
3. Monitor console output with `System.println()`

### Debug Output
The app uses `debugLog()` wrapper for debugging:
- Key press events
- Session state changes
- Menu actions
- Field updates

### Common Issues

**Issue**: Session fails to start
- **Cause**: Missing permissions or invalid activity type
- **Solution**: Check manifest.xml permissions

**Issue**: Custom fields not appearing in FIT file
- **Cause**: Fields not initialized or session not recording
- **Solution**: Verify `initFitFields()` is called after session creation

**Issue**: Sensors show "--"
- **Cause**: Sensor not enabled or no data available
- **Solution**: Ensure sensors enabled in `onShow()`, wait for data

**Issue**: Unintended increment after menu resume
- **Cause**: Key release event being processed
- **Solution**: Already fixed with `mIgnoreNextRelease` flag

---

## Recent Changes (Session Menu Improvements)

### Menu Button Behavior
- Menu now uses START button for selection instead of exiting app
- UP/DOWN buttons navigate menu items
- BACK button returns to main view
- Visual highlighting shows selected menu item

### Confirmation Dialogs
- Save and Discard actions now require confirmation
- Prevents accidental data loss
- Clear visual feedback with button instructions

### Status Messages
- Brief "Session Saved" or "Session Discarded" message shown before exit
- Includes haptic and audio feedback

### Bug Fixes
- Fixed unintended value increment when returning from menu
- Uses `mIgnoreNextRelease` flag to skip key release event
- Same pattern used for session start

---

## Extending the Application

### Adding New Data Fields

1. **Update `NutritionLoggerApp.mc`:**
   - Add field constant (e.g., `const CAFFEINE_FIELD = 4`)
   - Add field variable (e.g., `mCaffeineField`)
   - Add value variable or expand array
   - Add field initialization in `initFitFields()`
   - Update `setFieldByIndex()` logic

2. **Update `NutritionLoggerView.mc`:**
   - Add label to `labels` array in `onUpdate()`
   - Adjust loop bounds and display logic

3. **Update `resources/strings/strings.xml`:**
   - Add new string resource for field label

4. **Update `NutritionLoggerDelegate.mc`:**
   - Update modulo operations for cycling (e.g., `% 5` instead of `% 4`)

### Adding New Sensors

1. Add sensor to `Sensor.setEnabledSensors()` in `onShow()`
2. Handle sensor data in `onSensor()` callback
3. Display data in `NutritionLoggerView.onUpdate()`

### Customizing Button Behavior

Modify `NutritionLoggerDelegate.mc`:
- `onKey()`: Standard button presses
- `onStartKey()` / `onKeyReleased()`: For press duration detection
- Adjust timer duration in `onStartKey()` to change long-press threshold

---

## Distribution

### Creating a Release Build

1. Run `Monkey C: Export Project` from Command Palette
2. Select target devices
3. Output `.iq` file will be in `bin/` directory
4. Upload to Garmin Connect IQ Store or sideload to device

### Sideloading to Device

1. Connect watch via USB
2. Copy `.iq` file to `GARMIN/Apps/` folder
3. Disconnect and launch app from watch

---

## License

This project is licensed under the MIT License. See `LICENSE` file for details.

**Copyright (c) 2025 Eric Aguayo**

---

## Future Enhancements

Potential features to consider:
- [ ] Configurable field labels and units
- [ ] Data fields for Connect IQ data screens
- [ ] Auto-pause detection
- [ ] Lap-based nutrition tracking
- [ ] Export nutrition summary to Garmin Connect
- [ ] Customizable button mappings
- [ ] Multiple activity profiles (trail, ultra, hiking)
- [ ] Custom RPE ranges
- [ ] Nutrition goals and alerts

---

## Support and Contributions

For issues, questions, or contributions, please refer to the project repository.

**Target Device**: Garmin Fenix 7 Pro  
**Language**: Monkey C  
**SDK Version**: Connect IQ 3.3.0+  
**Build System**: Monkey Barrel / Visual Studio Code
