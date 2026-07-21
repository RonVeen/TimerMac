import Foundation

enum ActivitySheet: Identifiable, Equatable {
    case start(description: String)
    case manual
    case manualFromJob(Job)
    case edit(Activity)
    case copy(Activity)

    var id: String {
        switch self {
        case .start: return "start"
        case .manual: return "manual"
        case .manualFromJob(let job): return "manualFromJob_\(job.id)"
        case .edit(let activity): return "edit_\(activity.id)"
        case .copy(let activity): return "copy_\(activity.id)"
        }
    }

    static func == (lhs: ActivitySheet, rhs: ActivitySheet) -> Bool {
        lhs.id == rhs.id
    }
}
