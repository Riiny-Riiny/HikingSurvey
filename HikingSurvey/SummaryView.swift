//
//  SummaryView.swift
//  HikingSurvey
//
//  Created by Riiny Giir on 5/17/25.
//

import SwiftUI
import Charts

struct SummaryView: View {
    let responses: [Response]
    let theme: Theme
    
    var totalResponses: Int {
        responses.count
    }
    
    var averageSentiment: Double {
        guard !responses.isEmpty else { return 0.0 }
        return responses.reduce(0.0) { $0 + $1.score }
    }
    
    var sentimentDistribution: [(Sentiment, Int)] {
        let counts = Dictionary(grouping: responses) { $0.sentiment }
            .mapValues { $0.count }
        return [
            (.positive, counts[.positive] ?? 0),
            (.moderate, counts[.moderate] ?? 0),
            (.negative, counts[.negative] ?? 0)
        ]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text(NSLocalizedString("Survey Summary", comment: ""))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            // Stats Cards
            HStack(spacing: 16) {
                StatCard(
                    title: NSLocalizedString("Total Responses", comment: ""),
                    value: "\(totalResponses)",
                    icon: "doc.text",
                    color: theme.accent
                )
                
                StatCard(
                    title: NSLocalizedString("Avg Sentiment", comment: ""),
                    value: String(format: "%.2f", averageSentiment),
                    icon: "chart.line.uptrend.xyaxis",
                    color: averageSentiment > 0 ? theme.accent : averageSentiment < 0 ? .red : theme.accent.opacity(0.7)
                )
            }
            
            // Pie Chart
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("Sentiment Distribution", comment: ""))
                    .font(.headline)
                    .padding(.horizontal)
                
                PieChartView(data: sentimentDistribution, theme: theme)
                    .frame(height: 200)
                    .padding(.horizontal)
            }
            
            // Legend
            VStack(spacing: 8) {
                ForEach(sentimentDistribution, id: \.0) { sentiment, count in
                    HStack {
                        Circle()
                            .fill(sentiment.sentimentColor)
                        Text(NSLocalizedString(String(describing: sentiment).capitalized, comment: ""))
                            .font(.subheadline)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .background(theme.background)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct PieChartView: View {
    let data: [(Sentiment, Int)]
    let theme: Theme
    @State private var animatePie = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(data.enumerated()), id: \.offset) { tuple in
                    let index = tuple.offset
                    let (sentiment, count) = tuple.element
                    PieSlice(
                        startAngle: animatePie ? startAngle(for: index) : 0,
                        endAngle: animatePie ? endAngle(for: index) : 0,
                        color: sentiment.sentimentColor
                    )
                    .animation(.easeOut(duration: 0.8).delay(Double(index) * 0.1), value: animatePie)
                }
            }
            .frame(width: min(geometry.size.width, geometry.size.height),
                   height: min(geometry.size.width, geometry.size.height))
            .rotationEffect(.degrees(animatePie ? 0 : -20))
            .onAppear {
                withAnimation {
                    animatePie = true
                }
            }
            .onChange(of: data.map { "\($0.0)-\($0.1)" }.joined(separator: ",")) { _ in
                animatePie = false
                withAnimation {
                    animatePie = true
                }
            }
        }
    }
    
    private func startAngle(for index: Int) -> Double {
        let total = data.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return 0 }
        
        let previousSlices = data.prefix(index).reduce(0) { $0 + $1.1 }
        return (Double(previousSlices) / Double(total)) * 360
    }
    
    private func endAngle(for index: Int) -> Double {
        let total = data.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return 0 }
        
        let currentAndPrevious = data.prefix(index + 1).reduce(0) { $0 + $1.1 }
        return (Double(currentAndPrevious) / Double(total)) * 360
    }
}

struct PieSlice: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 100, y: 100)
            let radius: CGFloat = 80
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: Angle(degrees: startAngle - 90),
                endAngle: Angle(degrees: endAngle - 90),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(color)
    }
}

#Preview {
    SummaryView(
        responses: [
            Response(text: "I love hiking!", score: 0.8, confidence: 0.9),
            Response(text: "Hiking is okay.", score: 0.0, confidence: 0.7),
            Response(text: "I dislike hiking.", score: -0.7, confidence: 0.95),
            Response(text: "Hiking is amazing!", score: 0.9, confidence: 0.8),
            Response(text: "Not my thing.", score: -0.5, confidence: 0.6)
        ],
        theme: .minimal
    )
} 
