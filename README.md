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
