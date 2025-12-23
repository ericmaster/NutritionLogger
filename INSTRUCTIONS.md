# NutritionLogger - Development Instructions

## Project Overview

**NutritionLogger** (also known as Trail Run Recorder) is a Garmin Connect IQ watch application designed for trail running activities. The app records FIT activity files with custom nutrition tracking capabilities, specifically targeting the Garmin Fenix 7 Pro and similar devices.

### Core Features

- Records running activities with Trail Running sub-sport classification
- Tracks three custom nutrition counters during activity:
  - **Water intake**
  - **Electrolytes intake**
  - **Food intake**
- Real-time display of activity metrics (time, distance, altitude, heart rate)
- FitContributor integration to save custom data fields to FIT files
- Sensor logging for accelerometer and gyroscope data
- Pause/Resume functionality with menu-based controls

---

## Project Structure

```
NutritionLogger/
├── source/
│   ├── NutritionLoggerApp.mc          # Main application entry point
│   ├── NutritionLoggerDelegate.mc     # Input handling and session management
│   ├── NutritionLoggerMenuDelegate.mc # Menu navigation (pause/save/discard)
│   └── NutritionLoggerView.mc         # UI rendering and display logic
├── resources/
│   ├── drawables/
│   │   ├── drawables.xml
│   │   └── launcher_icon.svg
│   ├── layouts/
│   │   └── layout.xml                 # Main layout (minimal, mostly programmatic UI)
│   ├── menus/
│   │   └── menu.xml                   # Pause menu definition
│   └── strings/
│       └── strings.xml                # Localized strings
├── bin/                               # Build output (gitignored)
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
- Maintains nutrition counters and event stack for undo functionality

**Important Variables:**
- `mSession`: ActivityRecording session object
- `mWaterField`, `mElectrolytesField`, `mFoodField`: FitContributor fields
- `mCounters`: Array of three floats tracking intake counts
- `mSelectedIndex`: Currently selected counter (0-2)
- `mEventStack`: Stack for undo functionality
- `logger`: SensorLogger for accelerometer/gyroscope data

**Key Methods:**
- `onStart()`: Initializes sensors and GPS
- `onStop()`: Cleans up session on app exit
- `initFitFields()`: Creates custom FIT fields
- `setFieldByIndex()`: Updates FIT field values
- `resetCounters()`: Resets all counters to zero

### 2. **NutritionLoggerDelegate.mc**

Handles all user input during activity recording.

**Key Responsibilities:**
- Processes button presses and releases
- Starts/pauses/resumes activity recording
- Cycles through nutrition counters
- Records intake events and handles undo
- Manages timer events for UI updates

**Button Mapping (During Recording):**
- **Start/Stop (ENTER)**: Pause activity and show menu
- **Up/Menu**: Cycle up through counters (Water → Food → Electrolytes)
- **Down**: Cycle down through counters
- **Back/Lap (Short Press)**: Record intake for selected counter
- **Back/Lap (Long Press ≥600ms)**: Undo last intake

**Key Methods:**
- `onKey()`: Handles standard key events
- `onKeyPressed()`: Tracks key-down timing
- `onKeyReleased()`: Implements short/long press logic for intake recording
- `onTimerEvent()`: Updates FIT fields on each timer tick

### 3. **NutritionLoggerMenuDelegate.mc**

Manages the pause menu shown when activity is paused.

**Menu Options:**
- **Resume**: Continues recording
- **Save**: Saves FIT file and exits app
- **Discard**: Discards activity and exits app

### 4. **NutritionLoggerView.mc**

Renders the UI and displays activity data.

**Display Elements:**
- Status indicator (Recording/Idle) in red/white
- Elapsed time (HH:MM:SS)
- Distance (meters or kilometers)
- Altitude (meters)
- Heart rate (BPM)
- Three nutrition counters with selected item highlighted in yellow

**Key Methods:**
- `onUpdate()`: Redraws the screen with current data
- `onSensor()`: Receives heart rate updates
- `tick()`: Timer callback for periodic UI refresh

---

## Application States and Flow

### State 0: App Started (Idle)
- Display shows "Idle" status
- Counters are at zero
- Pressing **Start/Stop** begins a new activity

### State 1: Activity Recording
- Display shows "Recording" in red
- Timer is running
- GPS and sensors are active
- User can:
  - Cycle through counters with Up/Down
  - Record intake with Back/Lap (short press)
  - Undo last intake with Back/Lap (long press)
  - Pause with Start/Stop

### State 2: Activity Paused
- Timer is stopped
- Pause menu is displayed
- User can:
  - Resume recording
  - Save activity and exit
  - Discard activity and exit

---

## FIT File Integration

The app uses **FitContributor** to write custom developer fields to the FIT file:

| Field Name | Field ID | Data Type | Units | Description |
|------------|----------|-----------|-------|-------------|
| `water_intake_count` | 1 | FLOAT | count | Number of water intake events |
| `electrolytes_intake_count` | 2 | FLOAT | count | Number of electrolyte intake events |
| `food_intake_count` | 3 | FLOAT | count | Number of food intake events |

These fields are written to **RECORD** messages, meaning they're timestamped with each GPS point during the activity.

---

## Sensor Configuration

### Enabled Sensors:
- **Heart Rate**: Displayed on main screen
- **Pulse Oximetry**: Enabled but not displayed
- **Temperature**: Enabled but not displayed
- **Accelerometer**: Logged via SensorLogger
- **Gyroscope**: Logged via SensorLogger

### GPS:
- **Mode**: Continuous location updates
- **Callback**: `onPosition()` (currently logs but doesn't display)

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
The app uses `Sys.println()` extensively for debugging:
- Key press events
- Session state changes
- Sensor data updates
- Menu actions

### Common Issues

**Issue**: Session fails to start
- **Cause**: Missing permissions or invalid activity type
- **Solution**: Check manifest.xml permissions

**Issue**: Custom fields not appearing in FIT file
- **Cause**: Fields not initialized or session not recording
- **Solution**: Verify `initFitFields()` is called after session creation

**Issue**: Heart rate shows "--"
- **Cause**: Sensor not enabled or no data available
- **Solution**: Ensure `Sensor.SENSOR_HEARTRATE` is enabled in `onShow()`

---

## Extending the Application

### Adding New Counters

1. **Update `NutritionLoggerApp.mc`:**
   - Add new field variable (e.g., `mCaffeineField`)
   - Expand `mCounters` array size
   - Add field initialization in `initFitFields()`
   - Update `setFieldByIndex()` logic

2. **Update `NutritionLoggerView.mc`:**
   - Add label to `labels` array in `onUpdate()`
   - Adjust loop bounds

3. **Update `resources/strings/strings.xml`:**
   - Add new string resource for counter label

### Adding New Sensors

1. Add sensor to `Sensor.setEnabledSensors()` in `onStart()`
2. Handle sensor data in `onSensor()` callback
3. Display data in `NutritionLoggerView.onUpdate()`

### Customizing Button Behavior

Modify `NutritionLoggerDelegate.mc`:
- `onKey()`: Standard button presses
- `onKeyPressed()` / `onKeyReleased()`: For press duration detection
- Adjust `LONG_MS` constant to change long-press threshold

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
- [ ] Configurable counter labels and units
- [ ] Audio/vibration feedback on intake recording
- [ ] Data fields for Connect IQ data screens
- [ ] Auto-pause detection
- [ ] Lap-based nutrition tracking
- [ ] Export nutrition summary to Garmin Connect
- [ ] Customizable button mappings
- [ ] Multiple activity profiles (trail, ultra, hiking)

---

## Support and Contributions

For issues, questions, or contributions, please refer to the project repository.

**Target Device**: Garmin Fenix 7 Pro  
**Language**: Monkey C  
**SDK Version**: Connect IQ 3.3.0+  
**Build System**: Monkey Barrel / Visual Studio Code
