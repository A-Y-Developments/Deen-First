import Foundation

struct Reciter: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let style: String?

    init(id: Int, name: String, style: String? = nil) {
        self.id = id
        self.name = name
        self.style = style
    }
}
