import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsView extends WatchUi.View {
    private var mDelegate as SettingsDelegate;
    private var mLabels as Array<String>;

    function initialize(delegate as SettingsDelegate) {
        View.initialize();
        mDelegate = delegate;
        mLabels = [
            WatchUi.loadResource(Rez.Strings.settings_water_unit),
            WatchUi.loadResource(Rez.Strings.settings_electrolytes_unit),
            WatchUi.loadResource(Rez.Strings.settings_food_unit)
        ];
    }

    function onLayout(dc as Dc) as Void {
        // Custom drawing, no layout resource needed
    }

    function onUpdate(dc as Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var app = getApp();
        var centerX = dc.getWidth() / 2;
        var startY = dc.getHeight() / 2 - 60;
        
        // Draw title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            30,
            Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.settings_title),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Values to display
        var values = [
            app.mWaterUnit.format("%.0f") + "ml",
            app.mElectrolytesUnit.format("%.0f") + "mg",
            app.mFoodUnit.format("%.0f") + "kcal"
        ];

        var selectedIdx = mDelegate.getSelectedItem();
        
        // Draw settings items
        for (var i = 0; i < 3; i++) {
            var isSelected = (i == selectedIdx);
            var yPos = startY + (i * 40);
            
            if (isSelected) {
                // Highlight selected item
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    yPos,
                    Graphics.FONT_MEDIUM,
                    "> " + mLabels[i] + ": " + values[i] + " <",
                    Graphics.TEXT_JUSTIFY_CENTER
                );
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    yPos,
                    Graphics.FONT_SMALL,
                    mLabels[i] + ": " + values[i],
                    Graphics.TEXT_JUSTIFY_CENTER
                );
            }
        }

        // Draw button hints
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            dc.getHeight() - 60,
            Graphics.FONT_XTINY,
            "UP/DOWN = Select",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            centerX,
            dc.getHeight() - 45,
            Graphics.FONT_XTINY,
            "START = +10 / BACK = -10",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            centerX,
            dc.getHeight() - 30,
            Graphics.FONT_XTINY,
            "MENU = Save & Exit",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
