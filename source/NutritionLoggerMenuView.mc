import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class NutritionLoggerMenuView extends WatchUi.View {
    private var mDelegate as NutritionLoggerMenuDelegate;
    private var mMenuItems as Array<String>;

    function initialize(delegate as NutritionLoggerMenuDelegate) {
        View.initialize();
        mDelegate = delegate;
        mMenuItems = ["Resume", "Save", "Discard"];
    }

    function onLayout(dc as Dc) as Void {
        // Don't use layout resource since we're drawing everything custom
    }

    function onUpdate(dc as Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var startY = dc.getHeight() / 2 - 60;
        
        // Draw title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            30,
            Graphics.FONT_MEDIUM,
            "Session Menu",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw menu items
        var selectedIdx = mDelegate.getSelectedItem();
        
        for (var i = 0; i < mMenuItems.size(); i++) {
            var isSelected = (i == selectedIdx);
            var yPos = startY + (i * 35);
            
            if (isSelected) {
                // Highlight selected item
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    yPos,
                    Graphics.FONT_MEDIUM,
                    "> " + mMenuItems[i] + " <",
                    Graphics.TEXT_JUSTIFY_CENTER
                );
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    yPos,
                    Graphics.FONT_SMALL,
                    mMenuItems[i],
                    Graphics.TEXT_JUSTIFY_CENTER
                );
            }
        }

        // Draw button hints
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            dc.getHeight() - 50,
            Graphics.FONT_XTINY,
            "UP/DOWN = Navigate",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            centerX,
            dc.getHeight() - 35,
            Graphics.FONT_XTINY,
            "START = Select",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            centerX,
            dc.getHeight() - 20,
            Graphics.FONT_XTINY,
            "BACK = Return",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
