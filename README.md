# Trail Run Recorder (NutritionLogger)

Records a FIT activity as Running/Trail. Aim to target Garmin Fenix 7 Pro.

During Activity it has the ability to record 3 custom counters:
- Water intake
- Electrolytes intake
- Food intake
- **RPE (Rate of Perceived Exertion)**

The app will have 3 modes:
- 0: App Started
- 1: Activity recording
- 2: Menu / Background Recording

- During activity recording a screen will display some of the recorded data using FitContributor
- Pressing Back opens a menu where the user can:
    - Resume the activity (Dismiss menu)
    - Save the activity FIT file (and exit)
    - Discard the activity (and exit)

## Button mapping

On app start/initialization:
- **Start/Stop**: Start activity
- **Back/Lap**: Closes App

During activity recording:
- **Start**: **Add (+1)** to selected item / Increase RPE. When on MENU state, opens Session Menu.
- **Back**: **Undo (-1)** from selected item / Decrease RPE (Cannot decrement when on MENU state)
- **Up / Down**: Cycle through data fields (RPE, Water, Electrolytes, Food, **MENU**)
- **Light**: System Default (Backlight)

### Session Menu

When you cycle to the **MENU** state (via Up/Down) and press **Start**, a Session Menu opens:
- **Resume**: Return to activity recording
- **Save**: Confirm and save the activity, then exit
- **Discard**: Confirm and discard the activity, then exit

In the menu:
- **Up / Down**: Navigate menu items
- **Start**: Select current item
- **Back**: Return to activity without selecting


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

## Side Loading an App

In VSCode

- Use Ctrl + Shift + P (Command + Shift + P on the Mac) to summon the command palette
- In the command palette type "Build for Device" and select Monkey C: Build for Device
- Select the product you wish to build for.
- Choose a directory for the output and click Select Folder
- In your file manager, go to the directory selected in step 4
- Copy the generated PRG files to your device's GARMIN/APPS directory
