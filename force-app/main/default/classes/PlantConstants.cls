public class PlantConstants {
    public enum Status { Healthy, Dormant, Sick, Wilting, Deceased }
    public enum Water { Daily, OnceWeekly, OnceMonthly }
    public enum SoilType { IndoorPottingSoil, OutdoorPottingSoil, AllPurposePottingSoil, Sand, Clay }
    public enum Sunlight { FullSun, PartialSun, PartialShade, FullShade }

    public static final Water DEFAULT_WATER = Water.OnceWeekly;
    public static final SoilType DEFAULT_SOIL_TYPE = SoilType.AllPurposePottingSoil;
    public static final Sunlight DEFAULT_SUNLIGHT = Sunlight.PartialSun;

    public static final Set<Status> UNHEALTHY_STATUSES = new Set<Status> { Status.Sick, Status.Wilting, Status.Deceased };

    public static final Map<Status, String> STATUS_LABELS = new Map<Status, String>{
        Status.Healthy => 'Healthy',
        Status.Dormant => 'Dormant',
        Status.Sick => 'Sick',
        Status.Wilting => 'Wilting',
        Status.Deceased => 'Deceased'
    };
    public static final Map<Water, String> WATER_LABELS = new Map<Water, String>{
        Water.Daily => 'Daily',
        Water.OnceWeekly => 'Once Weekly',
        Water.OnceMonthly => 'Once Monthly'
    };
    public static final Map<SoilType, String> SOIL_LABELS = new Map<SoilType, String>{
        SoilType.IndoorPottingSoil => 'Indoor Potting Soil',
        SoilType.OutdoorPottingSoil => 'Outdoor Potting Soil',
        SoilType.AllPurposePottingSoil => 'All Purpose Potting Soil',
        SoilType.Sand => 'Sand',
        SoilType.Clay => 'Clay'
    };
    public static final Map<Sunlight, String> SUNLIGHT_LABELS = new Map<Sunlight, String>{
        Sunlight.FullSun => 'Full Sun',
        Sunlight.PartialSun => 'Partial Sun',
        Sunlight.PartialShade => 'Partial Shade',
        Sunlight.FullShade => 'Full Shade'
    };

    public static String getStatusLabel(Status status) { return STATUS_LABELS.get(status); }

    public static String getWaterLabel(Water water) { return WATER_LABELS.get(water); }

    public static String getSoilTypeLabel(SoilType soilType) { return SOIL_LABELS.get(soilType); }

    public static String getSunlightLabel(Sunlight sunlight) { return SUNLIGHT_LABELS.get(sunlight); }

    public static String getDefaultWaterLabel() { return getWaterLabel(DEFAULT_WATER); }

    public static String getDefaultSoilTypeLabel() { return getSoilTypeLabel(DEFAULT_SOIL_TYPE); }

    public static String getDefaultSunlightLabel() { return getSunlightLabel(DEFAULT_SUNLIGHT); }

    public static Status getStatusEnum(String label) {
        for (Status s : Status.values()) 
            if (STATUS_LABELS.get(s) == label) 
                return s;
        return null;
    }

    public static Water getWaterEnum(String label) {
        for (Water w : Water.values()) 
            if (WATER_LABELS.get(w) == label) 
                return w;
        return null;
    }
    
    public static SoilType getSoilTypeEnum(String label) {
        for (SoilType st : SoilType.values()) 
            if (SOIL_LABELS.get(st) == label) 
                return st;
        return null;
    }

    public static Sunlight getSunlightEnum(String label) {
        for (Sunlight sl : Sunlight.values()) 
            if (SUNLIGHT_LABELS.get(sl) == label) 
                return sl;
        return null;
    }

    public static List<String> getAllStatusLabels() {
        return new List<String>(STATUS_LABELS.values());
    }
    public static List<String> getAllWaterLabels() {
        return new List<String>(WATER_LABELS.values());
    }
    public static List<String> getAllSoilTypeLabels() {
        return new List<String>(SOIL_LABELS.values());
    }
    public static List<String> getAllSunlightLabels() {
        return new List<String>(SUNLIGHT_LABELS.values());
    }
}