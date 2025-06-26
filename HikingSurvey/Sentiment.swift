//
//  Sentiment.swift
//  HikingSurvey
//
//  Created by Riiny Giir on 5/17/25.
//

import Foundation
import SwiftUI

enum Sentiment: Equatable {
    // These are the possible sentiment categories for a response.
    // - positive: Indicates a generally favorable or happy sentiment.
    // - negative: Indicates an unfavorable or unhappy sentiment.
    // - moderate: Indicates a neutral or mixed sentiment.
    case positive
    case negative
    case moderate
    
    init(_ score: Double) {
        if score > 0.1 {
            self = .positive
        } else if score < -0.1 {
            self = .negative
        } else {
            self = .moderate
        }
    }
    var icon: String {
        switch self {
        case .positive:
            return "chevron.up.2"
        case .negative:
            return "chevron.down.2"
        case .moderate:
            return "minus"
            
        }
    }
}

extension Sentiment {
    var sentimentColor: Color {
        switch self {
        case .positive:
            return Color.green.opacity(0.85)
        case .negative:
            return Color.red.opacity(0.85)
        case .moderate:
            return Color.yellow.opacity(0.85)
        }
    }
}

extension Color {
    static var cardBackground: Color {
        Color("CardBackground", bundle: nil)
    }
}
