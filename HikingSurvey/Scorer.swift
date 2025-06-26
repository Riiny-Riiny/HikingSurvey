//
//  Scorer.swift
//  HikingSurvey
//
//  Created by Riiny Giir on 5/17/25.
//
import Foundation
import NaturalLanguage //for learning sentiments of the sentence
import _Concurrency

public struct SentimentResult {
    public let score: Double
    public let confidence: Double
}

public class Scorer {
    let tagger = NLTagger(tagSchemes: [.sentimentScore])
    
    func score(_ text: String) -> SentimentResult {
        var sentimentScore = 0.0
        var confidence = 0.0
        tagger.string = text
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .paragraph,
            scheme: .sentimentScore,
            options: []
        ) { sentimentTag, range in
            if let sentimentString = sentimentTag?.rawValue,
               let score = Double(sentimentString) {
                sentimentScore = score
                // NLTagger does not provide explicit confidence, so estimate:
                confidence = min(1.0, abs(score))
            }
            return false
        }
        return SentimentResult(score: sentimentScore, confidence: confidence)
    }

    func scoreAsync(_ text: String) async throws -> SentimentResult {
        try Task.checkCancellation()
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.score(text)
                continuation.resume(returning: result)
            }
        }
    }
}

