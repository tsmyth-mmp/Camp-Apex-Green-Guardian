public class TaskConstants {
    public enum Status { NotStarted, InProgress, Completed, WaitingOnSomeoneElse, Deferred }
    public enum Subject { AcquirePlants }

    public static final Subject DEFAULT_SUBJECT = Subject.AcquirePlants;
    
    public static final Set<Status> EXCLUDED_STATUSES = new Set<Status>{ Status.Completed };

    public static final Map<Status, String> STATUS_LABELS = new Map<Status, String> {
        Status.NotStarted => 'Not Started',
        Status.InProgress => 'In Progress',
        Status.Completed => 'Completed',
        Status.WaitingOnSomeoneElse => 'Waiting on Someone Else',
        Status.Deferred => 'Deferred'
    };

    public static final Map<Subject, String> SUBJECT_LABELS = new Map<Subject, String> {
        Subject.AcquirePlants => 'Acquire Plants'
    };

    public static String getStatusLabel(Status status) { return STATUS_LABELS.get(status); }

    public static String getSubjectLabel(Subject subject) { return SUBJECT_LABELS.get(subject); }

    public static String getDefaultSubjectLabel() { return getSubjectLabel(DEFAULT_SUBJECT); }

}