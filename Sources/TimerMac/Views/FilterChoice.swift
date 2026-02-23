import Foundation

enum FilterChoice: CaseIterable {
    case today
    case yesterday
    case date
    case from
    case range
    case all

    var title: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .date: return "Specific"
        case .from: return "From"
        case .range: return "Range"
        case .all: return "All"
        }
    }
}
