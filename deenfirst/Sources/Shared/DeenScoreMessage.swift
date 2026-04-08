import Foundation

/// Contextual messages shown beneath the Deen Score by score range.
enum DeenScoreMessage {
    static func message(for score: Int) -> String {
        switch score {
        case 90...100: return "Excellent day. Masha'Allah, keep this up."
        case 80...89:  return "Strong day. Your consistency is showing."
        case 70...79:  return "Good day! A bit more Quran tomorrow."
        case 60...69:  return "Decent balance. Push for one more session."
        case 50...59:  return "Average day. More Quran or less screen time."
        case 40...49:  return "Tough balance. One focus session can turn this around."
        case 30...39:  return "Heavy phone use. Reset with 10 minutes of Quran."
        default:       return "Difficult day. Don't give up — tomorrow is a fresh start."
        }
    }
}
