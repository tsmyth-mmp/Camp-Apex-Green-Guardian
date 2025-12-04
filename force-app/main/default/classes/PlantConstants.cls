public class PlantConstants {
    public enum Status { Healthy, Dormant, Sick, Wilting, Deceased }
    public enum Water { Daily, OnceWeekly, OnceMonthly }
    public enum SoilType { IndoorPottingSoil, OutdoorPottingSoil, AllPurposePottingSoil, Sand, Clay }
    public enum Sunlight { FullSun, PartialSun, PartialShade, FullShade }

    private static final Map<Status, String> statusLabels = new Map<Status, String>{
        Status.Healthy => 'Healthy',
        Status.Dormant => 'Dormant',
        Status.Sick => 'Sick',
        Status.Wilting => 'Wilting',
        Status.Deceased => 'Deceased'
    };

    private static final Map<Water, String> waterLabels = new Map<Water, String>{
        Water.Daily => 'Daily',
        Water.OnceWeekly => 'Once Weekly',
        Water.OnceMonthly => 'Once Monthly'
    };

    private static final Map<SoilType, String> soilTypeLabels = new Map<SoilType, String>{
        SoilType.IndoorPottingSoil => 'Indoor Potting Soil',
        SoilType.OutdoorPottingSoil => 'Outdoor Potting Soil',
        SoilType.AllPurposePottingSoil => 'All Purpose Potting Soil',
        SoilType.Sand => 'Sand',
        SoilType.Clay => 'Clay'
    };

    private static final Map<Sunlight, String> sunlightLabels = new Map<Sunlight, String>{
        Sunlight.FullSun => 'Full Sun',
        Sunlight.PartialSun => 'Partial Sun',
        Sunlight.PartialShade => 'Partial Shade',
        Sunlight.FullShade => 'Full Shade'
    };

    public static String getStatusLabel(Status status) {
        return statusLabels.get(status);
    }

    public static String getWaterLabel(Water water) {
        return waterLabels.get(water);
    }

    public static String getSoilTypeLabel(SoilType soilType) {
        return soilTypeLabels.get(soilType);
    }

    public static String getSunlightLabel(Sunlight sunlight) {
        return sunlightLabels.get(sunlight);
    }

    public static String getDefaultWaterLabel() {
        return getWaterLabel(Water.OnceWeekly);
    }

    public static String getDefaultSoilTypeLabel() {
        return getSoilTypeLabel(SoilType.AllPurposePottingSoil);
    }

    public static String getDefaultSunlightLabel() {
        return getSunlightLabel(Sunlight.PartialSun);
    }
}