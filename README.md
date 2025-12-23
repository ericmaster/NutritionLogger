# Trail Run Recorder (NutritionLogger)

Records a FIT activity as Running/Trail. Aim to target Garmin Fenix 7 Pro.

During Activity it has the ability to record 3 custom counters:
- Water intake
- Electrolytes intake
- Food intake

The app will have 3 modes:
- 0: App Started
- 1: Activity recording
- 2: Activity paused

- During activity recording a screen will display some of the recorded data using FitContributor
- During activity paused a menu will be displayed where the user can
    - Resume the activity
    - Save the activity FIT file (and exit)
    - Discard the activity (and exit)

## Button mapping

On app start/initialization:
- Start/Stop: Start/Pause activity
- Back/Lap: Closes App

During activity recording:
- Start/Stop: Pause Activity
- Up/Menu: Cycle up the custom recording items
- Down: Cycle down the custom recording items
- Light: Record intake of currently selected recording item at the elapsed timestamp
- Back/Lap: Undo intake recording (in case accidentally pressed button)

During activity paused:
- Start/Stop: Select menu item
- Up/Menu: Cycle up the custom recording items
- Down: Cycle down the recording items

## Development Setup

### Step 1: Install Required Software 
- Install Java SDK: The Garmin tools require a Java SDK to run.
- Install Visual Studio Code: Download and install VS Code from the official Visual Studio Code website.
- Install Connect IQ SDK Manager: Download the SDK Manager from the Garmin Developers site.

### Step 2: Configure the SDK Manager
- Launch the SDK Manager and complete the initial setup.
- Use the SDK Manager to download the latest Connect IQ SDK and specific device profiles you wish to target (e.g., Venu 3, Fenix 8).
- Ensure the latest SDK version is set as your "active SDK" within the manager. 

### Step 3: Set up Visual Studio Code
- Install the Monkey C Extension:
    - Open VS Code and go to the Extensions view (Ctrl+Shift+X or Cmd+Shift+X on Mac).
    - Search for "Monkey C" and select the official extension from Garmin.
    - Click Install and restart VS Code when prompted.
- Verify Installation:
    - Open the Command Palette (Ctrl+Shift+P or Cmd+Shift+P on Mac).
    - Type "Verify Installation" and select the Monkey C: Verify Installation command. The output window should confirm the installation is correct.
- Generate a Developer Key:
    - Open the Command Palette again.
    - Type "Generate a Developer Key" and select Monkey C: Generate a Developer Key. This creates a unique key required to sign and build your apps. 

### Step 4: Create a New Project and Run the Simulator 
- Create a Project:
    - Open the Command Palette and select Monkey C: New Project.
    - Follow the prompts to name your project, select the app type (e.g., "Watch Face"), target API level, and the specific watches to support.
- Run the App in the Simulator:
    - With a source file (.mc extension) open in the editor, go to the top menu and select Run > Run Without Debugging (Ctrl+F5 or Cmd+F5).
    - Select your target test watch from the list. The Garmin simulator should launch, displaying your new application. 