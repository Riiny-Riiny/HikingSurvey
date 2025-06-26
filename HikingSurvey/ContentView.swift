//
//  ContentView.swift
//  HikingSurvey
//
//  Created by Riiny Giir on 5/15/25.
//

import SwiftUI
import CoreData
import UIKit

enum Theme: String, CaseIterable, Identifiable {
    case minimal, mountain, forest
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .mountain: return "Mountain"
        case .forest: return "Forest"
        }
    }
    var accent: Color {
        switch self {
        case .minimal: return Color.blue
        case .mountain: return Color(red: 0.36, green: 0.54, blue: 0.66)
        case .forest: return Color(red: 0.18, green: 0.38, blue: 0.22)
        }
    }
    var card: Color {
        switch self {
        case .minimal: return Color.cardBackground
        case .mountain: return Color(red: 0.93, green: 0.96, blue: 1.0)
        case .forest: return Color(red: 0.90, green: 0.97, blue: 0.92)
        }
    }
    var background: Color {
        switch self {
        case .minimal: return Color(.systemBackground)
        case .mountain: return Color(red: 0.85, green: 0.92, blue: 0.98)
        case .forest: return Color(red: 0.85, green: 0.95, blue: 0.88)
        }
    }
}

class ResponseListViewModel: ObservableObject {
    @Published var responses: [Response] = []
    @Published var selectedFilter: Sentiment? = nil
    private var scoringTask: Task<Void, Never>?
    private let context: NSManagedObjectContext
    
    var filteredResponses: [Response] {
        if let filter = selectedFilter {
            return responses.filter { $0.sentiment == filter }
        } else {
            return responses
        }
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadResponsesFromCoreData()
        if responses.isEmpty {
            Task { @MainActor in
                print("DEBUG: Starting to load sample responses")
                for response in Response.sampleResponses {
                    await addResponseAsync(text: response)
                }
                print("DEBUG: Finished loading all sample responses")
            }
        }
    }
    
    @MainActor
    private func addResponseAsync(text: String) async {
        do {
            let result = try await Scorer().scoreAsync(text)
            let response = Response(text: text, score: result.score, confidence: result.confidence)
            print("DEBUG: Adding response - Text: '\(text)' -> Score: \(result.score), Sentiment: \(response.sentiment)")
            self.responses.insert(response, at: 0)
            self.saveResponseToCoreData(response)
        } catch {
            print("Failed to score text: \(error)")
        }
    }
    
    func addResponse(text: String) {
        Task { @MainActor in
            await addResponseAsync(text: text)
        }
    }
    
    private func loadResponsesFromCoreData() {
        let request: NSFetchRequest<ResponseEntity> = ResponseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            print("DEBUG: Loaded \(entities.count) responses from CoreData")
            responses = entities.compactMap { entity in
                guard let id = entity.id,
                      let text = entity.text else { return nil }
                let response = Response(id: id, text: text, score: entity.score, confidence: entity.confidence)
                print("DEBUG: Loaded response - Text: '\(text)' -> Score: \(entity.score), Sentiment: \(response.sentiment)")
                return response
            }
        } catch {
            print("Failed to fetch responses: \(error)")
        }
    }
    
    private func saveResponseToCoreData(_ response: Response) {
        let entity = ResponseEntity(context: context)
        entity.id = response.id
        entity.text = response.text
        entity.score = response.score
        entity.confidence = response.confidence
        
        do {
            try context.save()
            print("DEBUG: Saved response to CoreData - Text: '\(response.text)'")
        } catch {
            print("Failed to save response: \(error)")
        }
    }
    
    func deleteResponse(_ response: Response) {
        // Remove from CoreData
        let request: NSFetchRequest<ResponseEntity> = ResponseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", response.id as CVarArg)
        do {
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        } catch {
            print("Failed to delete response: \(error)")
        }
        // Remove from local list
        responses.removeAll { $0.id == response.id }
    }
    
    func editResponse(_ response: Response, newText: String) {
        // Update in CoreData
        let request: NSFetchRequest<ResponseEntity> = ResponseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", response.id as CVarArg)
        do {
            let entities = try context.fetch(request)
            for entity in entities {
                entity.text = newText
                // Re-score sentiment
                let result = Scorer().score(newText)
                entity.score = result.score
                entity.confidence = result.confidence
            }
            try context.save()
        } catch {
            print("Failed to edit response: \(error)")
        }
        // Update in-memory list
        if let idx = responses.firstIndex(where: { $0.id == response.id }) {
            let result = Scorer().score(newText)
            responses[idx] = Response(id: response.id, text: newText, score: result.score, confidence: result.confidence)
        }
    }
}

struct InputError: Identifiable {
    let id = UUID()
    let message: String
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ResponseListViewModel
    @State private var showingSummary = false
    @State private var newResponseText = ""
    @State private var isScoring = false
    @State private var responseToDelete: Response? = nil
    @State private var showDeleteAlert = false
    @State private var inputError: InputError? = nil
    @State private var editingResponse: Response? = nil
    @State private var editedText: String = ""
    @State private var showEditSheet = false
    @AppStorage("themeChoice") private var themeChoice: String = Theme.minimal.rawValue
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var showSettings = false
    @Environment(\.dismiss) private var dismiss
    var theme: Theme { Theme(rawValue: themeChoice) ?? .minimal }
    
    init() {
        // This will be set by the environment
        _viewModel = StateObject(wrappedValue: ResponseListViewModel(context: PersistenceController.shared.container.viewContext))
        // Show onboarding if not seen
        _showOnboarding = State(initialValue: !UserDefaults.standard.bool(forKey: "hasSeenOnboarding"))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Theme picker
                HStack {
                    Image(systemName: "paintpalette")
                    Picker(NSLocalizedString("Theme", comment: ""), selection: $themeChoice) {
                        ForEach(Theme.allCases) { theme in
                            Text(NSLocalizedString(theme.displayName, comment: "")).tag(theme.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.bottom, 4)
                // Input field for new response
                HStack {
                    TextField(NSLocalizedString("Type your hiking opinion...", comment: ""), text: $newResponseText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .autocapitalization(.sentences)
                    Button(action: submitNewResponse) {
                        if isScoring {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(newResponseText.isEmpty ? .gray : theme.accent)
                        }
                    }
                    .disabled(newResponseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isScoring)
                }
                .padding(.vertical, 8)
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    Text("All").tag(Sentiment?.none)
                    Text("Positive").tag(Sentiment?.some(.positive))
                    Text("Moderate").tag(Sentiment?.some(.moderate))
                    Text("Negative").tag(Sentiment?.some(.negative))
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
                SentimentBarGraph(responses: viewModel.filteredResponses, theme: theme)
                Text(NSLocalizedString("Opinions on Hiking", comment: ""))
                    .frame(maxWidth: .infinity)
                    .font(.title)
                    .padding(.top, 24)
                List {
                    ForEach(viewModel.filteredResponses) { response in
                        ResponseView(response: response, theme: theme)
                            .transition(.opacity.combined(with: .scale))
                            .onTapGesture {
                                responseToDelete = response
                                showDeleteAlert = true
                            }
                            .onLongPressGesture {
                                editingResponse = response
                                editedText = response.text
                                showEditSheet = true
                            }
                    }
                    .onDelete(perform: deleteResponses)
                }
            }
            .padding(.horizontal)
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSummary = true
                    }) {
                        Image(systemName: "chart.pie")
                            .foregroundColor(theme.accent)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(theme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSummary) {
            SummaryView(responses: viewModel.responses, theme: theme)
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text(NSLocalizedString("Delete Response", comment: "")),
                message: Text(NSLocalizedString("Are you sure you want to delete this response?", comment: "")),
                primaryButton: .destructive(Text(NSLocalizedString("Delete", comment: ""))) {
                    if let response = responseToDelete {
                        withAnimation {
                            viewModel.deleteResponse(response)
                        }
                        // Haptic feedback for deletion
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                },
                secondaryButton: .cancel(Text(NSLocalizedString("Cancel", comment: "")))
            )
        }
        .alert(item: $inputError) { error in
            Alert(title: Text(NSLocalizedString("Input Error", comment: "")), message: Text(NSLocalizedString(error.message, comment: "")), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationView {
                VStack {
                    TextField(NSLocalizedString("Edit your opinion", comment: ""), text: $editedText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Spacer()
                }
                .background(theme.background)
                .navigationTitle(NSLocalizedString("Edit Response", comment: ""))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(NSLocalizedString("Cancel", comment: "")) { showEditSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(NSLocalizedString("Save", comment: "")) {
                            if let response = editingResponse {
                                viewModel.editResponse(response, newText: editedText)
                            }
                            showEditSheet = false
                        }
                        .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(theme: theme) {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(theme: theme)
        }
    }
    
    func submitNewResponse() {
        let trimmed = newResponseText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let error = validateInput(trimmed) {
            inputError = InputError(message: error)
            // Haptic feedback for error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        isScoring = true
        withAnimation {
            viewModel.addResponse(text: trimmed)
        }
        // Haptic feedback for submission
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        // Wait for scoring to finish before clearing (simulate real-time, could be improved with callback)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation {
                newResponseText = ""
                isScoring = false
            }
        }
    }
    
    func validateInput(_ text: String) -> String? {
        if text.isEmpty {
            return "Please enter your hiking opinion."
        }
        if text.count < 5 {
            return "Please enter a longer opinion."
        }
        if viewModel.responses.contains(where: { $0.text.caseInsensitiveCompare(text) == .orderedSame }) {
            return "This opinion has already been submitted."
        }
        return nil
    }
    
    func deleteResponses(at offsets: IndexSet) {
        withAnimation {
            offsets.map { viewModel.filteredResponses[$0] }.forEach { viewModel.deleteResponse($0) }
        }
    }
}

struct SentimentBarGraph: View {
    let responses: [Response]
    let theme: Theme
    var sentimentCounts: [Sentiment: Int] {
        Dictionary(grouping: responses, by: { $0.sentiment })
            .mapValues { $0.count }
    }
    var body: some View {
        HStack(spacing: 16) {
            ForEach([Sentiment.positive, .moderate, .negative], id: \ .self) { sentiment in
                VStack {
                    Text("\(sentimentCounts[sentiment, default: 0])")
                        .font(.headline)
                        .foregroundColor(theme.accent)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(sentiment.sentimentColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(theme.accent, lineWidth: 1.5)
                        )
                        .frame(width: 24, height: CGFloat(sentimentCounts[sentiment, default: 0]) * 16 + 8)
                    Text(String(describing: sentiment).capitalized)
                        .font(.caption2)
                        .foregroundColor(theme.accent)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.card)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .padding(.bottom, 8)
    }
}

struct OnboardingView: View {
    var theme: Theme
    var onDismiss: () -> Void
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "figure.hiking")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(theme.accent)
                Text(NSLocalizedString("Welcome to HikingSurvey!", comment: ""))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text(NSLocalizedString("This app helps analyze how people feel about hiking.", comment: ""))
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
                Button(action: onDismiss) {
                    Text(NSLocalizedString("Get Started", comment: ""))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(theme.accent))
                        .padding(.horizontal)
                }
                Spacer()
            }
        }
    }
}

struct SettingsView: View {
    var theme: Theme
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 48))
                    .foregroundColor(theme.accent)
                    .padding(.top, 32)
                Text(NSLocalizedString("Privacy Policy", comment: ""))
                    .font(.title2)
                    .fontWeight(.bold)
                Text(NSLocalizedString("All analysis is done locally.", comment: ""))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Text(NSLocalizedString("Your data never leaves your device.", comment: ""))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(NSLocalizedString("Settings", comment: ""))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Close", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
