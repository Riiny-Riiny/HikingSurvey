//
//  ResponseView.swift
//  HikingSurvey
//
//  Created by Riiny Giir on 5/17/25.
//

import SwiftUI

struct ResponseView: View {
    let response: Response
    var theme: Theme = .minimal
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: response.sentiment.icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(response.sentiment.sentimentColor)
                    )
                VStack(alignment: .leading, spacing: 6) {
                    Text(response.text)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(String(format: NSLocalizedString("Sentiment: %.2f", comment: ""), response.score))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: NSLocalizedString("Confidence: %.2f", comment: ""), response.confidence))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    ConfidenceMeter(confidence: response.confidence, theme: theme)
                }
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.card)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.vertical, 6)
    }
}

struct ConfidenceMeter: View {
    let confidence: Double // 0.0 to 1.0
    var theme: Theme = .minimal
    var color: Color {
        switch confidence {
        case 0.75...1.0: return theme.accent
        case 0.4..<0.75: return theme.accent.opacity(0.7)
        default: return .red
        }
    }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 8)
                Capsule()
                    .fill(color)
                    .frame(width: max(8, geo.size.width * confidence), height: 8)
            }
        }
        .frame(height: 8)
        .padding(.vertical, 2)
        .accessibilityLabel(NSLocalizedString("Confidence meter", comment: ""))
        .accessibilityValue("\(Int(confidence * 100)) percent")
    }
}

#Preview {
    VStack(spacing: 16) {
        ResponseView(response: Response(text: "I love hiking!", score: 0.8, confidence: 0.9))
        ResponseView(response: Response(text: "Hiking is okay.", score: 0.0, confidence: 0.7))
        ResponseView(response: Response(text: "I dislike hiking.", score: -0.7, confidence: 0.95))
    }
    .padding()
    .background(Color(.systemBackground))
}
