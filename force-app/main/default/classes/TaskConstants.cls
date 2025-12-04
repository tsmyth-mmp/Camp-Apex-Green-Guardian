public class TaskConstants {
    public enum Status { NotStarted, InProgress, Completed, WaitingOnSomeoneElse, Deferred }
    
    public static final Set<Status> EXCLUDED_STATUSES = new Set<Status>{ Status.Completed };

    public static final Map<Status, String> STATUS_LABELS = new Map<Status, String> {
        Status.NotStarted => 'Not Started',
        Status.InProgress => 'In Progress',
        Status.Completed => 'Completed',
        Status.WaitingOnSomeoneElse => 'Waiting on Someone Else',
        Status.Deferred => 'Deferred'
    };

    public static String getStatusLabel(Status status) { return STATUS_LABELS.get(status); }

}