public class GardenConstants {
    public enum Status { AwaitingResources, Operational, TemporaryClosure, OverCapacity, PermanentClosure }

    public static final Status DEFAULT_STATUS = Status.AwaitingResources;

    public static final Map<Status, String> STATUS_LABELS = new Map<Status, String> {
        Status.AwaitingResources => 'Awaiting Resources',
        Status.Operational => 'Operational',
        Status.TemporaryClosure => 'Temporary Closure',
        Status.OverCapacity => 'Over Capacity',
        Status.PermanentClosure => 'Permanent Closure'
    };

    public static String getStatusLabel(Status status) { return STATUS_LABELS.get(status); }

    public static String getDefaultStatusLabel() { return getStatusLabel(DEFAULT_STATUS); }


}