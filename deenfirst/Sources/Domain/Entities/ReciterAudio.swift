import Foundation

struct ReciterAudio: Codable, Hashable {
    let reciterId: Int
    let reciterName: String
    let url: String
    let originalUrl: String

    enum CodingKeys: String, CodingKey {
        case reciterId
        case reciterName
        case url
        case originalUrl
    }
}
