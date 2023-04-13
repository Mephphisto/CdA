import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.AntPlus;
import Toybox.UserProfile;
import Toybox.Sensor;
import Toybox.Math;
import Toybox.Weather;
import Toybox.SensorHistory;

class CdAView extends WatchUi.DataField {

    hidden var mValue as Numeric;
    hidden var mass as Number; // [Kg]
    hidden const R_spec = 287.0500676 as Numeric; // [J /Kg /K]
    hidden const driveTrainEffitiency = 0.97; // [1]
    hidden const roll_fric = 0.006 as Numeric; // [Ns/m]
    

    function initialize() {
        DataField.initialize();
        mValue = 0.0f;
        var profile = UserProfile.getProfile() as Profile;
        mass = profile.weight / 1e3 as Number; // [Kg]
        //DataField.createField("CdA", 666, Fit, options)
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        var obscurityFlags = DataField.getObscurityFlags();

        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.TopLeftLayout(dc));

        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.TopRightLayout(dc));

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.BottomRightLayout(dc));

        // Use the generic, centered layout
        } else {
            View.setLayout(Rez.Layouts.MainLayout(dc));
            var labelView = View.findDrawableById("label");
            labelView.locY = labelView.locY - 16;
            var valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY + 7;
        }

        (View.findDrawableById("label") as Text).setText("CdA");
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        // See Activity.Info in the documentation for available information.
            var power = info.currentPower as Number; // [W]
            if (power != null){
                power *= driveTrainEffitiency;
            } else {
                power = 0;
            }
            var speed = info.currentSpeed as Number; // [m/s]
            var heading = info.currentHeading as Number; // [DEG]
            var pressure = info.ambientPressure as Number; // [N/m^2]
            var abs_temp = 300.0;
            var airSpeed = speed;
            if (Toybox has :Weather){
                var wthCon = Weather.getCurrentConditions() as Weather.CurrentConditions;
                abs_temp = wthCon.temperature + 273.15; //[K]
                airSpeed = speed + wthCon.windSpeed * Math.cos((wthCon.windBearing-heading)/180 * Math.PI);
            }
            var airDensity = 1.293 as Numeric; // [kg/m^3]
            if (pressure != null && abs_temp != null){
                airDensity = pressure / (R_spec * abs_temp);// Ideal Gas Law [kg/m^3]
            }
            var grad = gradient(3);
            var rollLoss = roll_fric * Math.pow(speed,2);
            var kinLoss = mass * 9.81 * grad * speed;
            var Ps = (power - rollLoss - kinLoss);
            var v3Rho = Math.pow(airSpeed,3) * airDensity;
            if(v3Rho > 0){
                mValue = Ps / v3Rho;
            }else {
                mValue = 0;
            }
         
    }

    function gradient(L as Number) as Numeric{
        //var altIt = SensorHistory.getElevationHistory(L, SensorHistory.ORDER_OLDEST_FIRST);
        var grad = 0;
        //var dat_last = altIt.next().data;
        //for (var k = 0; k < 10; k++){
        //    var dta = altIt.next().data;
            //alts
        //}
        return grad;
    }


    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        var value = View.findDrawableById("value") as Text;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
        }
        //value.setTitle("CdA");
        value.setText("CdA\n"+mValue.format("%+.4f"));

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
