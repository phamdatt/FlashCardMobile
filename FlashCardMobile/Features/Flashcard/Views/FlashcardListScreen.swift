//
//  FlashcardListScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct FlashcardListScreen: View {
    let topic: Topic
    let subject: Subject
    @ObservedObject var viewModel: AppViewModel
    @StateObject private var listViewModel: FlashcardListViewModel
    @State private var selectedFlashcard: Flashcard?
    @State private var showPracticePicker = false
    @State private var showAddFlashcard = false
    @State private var showExportSheet = false
    @State private var showImportSheet = false

    init(topic: Topic, subject: Subject, viewModel: AppViewModel) {
        self.topic = topic
        self.subject = subject
        self.viewModel = viewModel
        _listViewModel = StateObject(wrappedValue: FlashcardListViewModel(topic: topic, subject: subject, appViewModel: viewModel))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                practiceButton
                flashcardList
            }
            .padding()
        }
        .background(AppTheme.surface)
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button {
                        viewModel.selectedTabIndex = 2
                    } label: {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Menu {
                    Button {
                        HapticFeedback.impact()
                        showAddFlashcard = true
                    } label: {
                        Label(L("flashcard.add_vocab"), systemImage: "plus")
                    }
                    Button {
                        HapticFeedback.impact()
                        showExportSheet = true
                    } label: {
                        Label(L("flashcard.export_csv"), systemImage: "square.and.arrow.up")
                    }
                    Button {
                        HapticFeedback.impact()
                        showImportSheet = true
                    } label: {
                        Label(L("flashcard.import_csv"), systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            CSVExportSheet(topicId: topic.id, topicName: topic.name, onDismiss: { showExportSheet = false })
        }
        .sheet(isPresented: $showImportSheet) {
            CSVImportSheet(topicId: topic.id, topicName: topic.name, onDismiss: {
                showImportSheet = false
                listViewModel.refreshAfterImport()
            })
        }
        .navigationDestination(item: $selectedFlashcard) { card in
            FlashcardDetailScreen(flashcard: card, listViewModel: listViewModel)
        }
        .sheet(isPresented: $showAddFlashcard) {
            AddFlashcardSheet(viewModel: listViewModel, onDismiss: {
                showAddFlashcard = false
            })
        }
        .sheet(item: Binding(
            get: { listViewModel.flashcardToEdit },
            set: { listViewModel.setFlashcardToEdit($0) }
        )) { card in
            EditFlashcardSheet(flashcard: card, viewModel: listViewModel, onDismiss: {
                listViewModel.clearFlashcardToEdit()
            })
        }
        .alert(L("flashcard.delete_title"), isPresented: Binding(
            get: { listViewModel.flashcardToDelete != nil },
            set: { if !$0 { listViewModel.clearFlashcardToDelete() } }
        )) {
            Button(L("common.cancel"), role: .cancel) {
                HapticFeedback.impact()
                listViewModel.clearFlashcardToDelete()
            }
            Button(L("common.delete"), role: .destructive) {
                HapticFeedback.impact()
                if let c = listViewModel.flashcardToDelete {
                    _ = listViewModel.deleteFlashcard(id: c.id)
                }
            }
        } message: {
            if let c = listViewModel.flashcardToDelete {
                Text(L("flashcard.delete_message", c.questionDisplayText))
            }
        }
        .navigationDestination(isPresented: $showPracticePicker) {
            PracticeAllScreen(subject: subject, topic: listViewModel.topicForPractice)
        }
    }

    private var practiceButton: some View {
        Button {
            HapticFeedback.impact()
            showPracticePicker = true
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                Text(L("flashcard.start_practice"))
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
            }
            .padding(20)
            .foregroundStyle(.white)
            .background(AppTheme.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(HapticButtonStyle())
    }

    private var flashcardList: some View {
        LazyVStack(spacing: 12) {
            ForEach(listViewModel.flashcards) { card in
                FlashcardRow(card: card) {
                    selectedFlashcard = card
                }
                .contextMenu {
                    Button {
                        HapticFeedback.impact()
                        selectedFlashcard = card
                    } label: {
                        Label(L("flashcard.view_detail"), systemImage: "eye")
                    }
                    Button {
                        HapticFeedback.impact()
                        UIPasteboard.general.string = card.copyText
                    } label: {
                        Label(L("common.copy"), systemImage: "doc.on.doc")
                    }
                    Button {
                        HapticFeedback.impact()
                        listViewModel.setFlashcardToEdit(card)
                    } label: {
                        Label(L("common.edit"), systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        HapticFeedback.impact()
                        listViewModel.setFlashcardToDelete(card)
                    } label: {
                        Label(L("common.delete"), systemImage: "trash")
                    }
                } preview: {
                    FlashcardPreviewCard(card: card)
                }
            }
        }
    }
}

struct AddFlashcardSheet: View {
    @ObservedObject var viewModel: FlashcardListViewModel
    let onDismiss: () -> Void
    @State private var question = ""
    @State private var answer = ""
    @State private var hint = ""
    @State private var notes = ""
    @State private var radical = ""
    @State private var phonetic = ""
    @FocusState private var questionFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(L("flashcard.section_vocab")) {
                    TextField(L("flashcard.question_placeholder"), text: $question)
                        .focused($questionFocused)
                    TextField(L("flashcard.answer_placeholder"), text: $answer)
                }
                Section(L("flashcard.section_extra")) {
                    TextField(L("flashcard.hint_placeholder"), text: $hint)
                    TextField(L("flashcard.phonetic_placeholder"), text: $phonetic)
                    TextField(L("flashcard.radical_placeholder"), text: $radical)
                    TextField(L("flashcard.notes_placeholder"), text: $notes)
                }
            }
            .navigationTitle(L("flashcard.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.cancel")) {
                        HapticFeedback.impact()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("common.save")) {
                        HapticFeedback.impact()
                        if viewModel.addFlashcard(
                            question: question,
                            answer: answer,
                            hint: hint.isEmpty ? nil : hint,
                            notes: notes.isEmpty ? nil : notes,
                            radical: radical.isEmpty ? nil : radical,
                            phonetic: phonetic.isEmpty ? nil : phonetic
                        ) {
                            onDismiss()
                        }
                    }
                    .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty || answer.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { questionFocused = true }
        }
    }
}

struct EditFlashcardSheet: View {
    let flashcard: Flashcard
    @ObservedObject var viewModel: FlashcardListViewModel
    let onDismiss: () -> Void
    @State private var question = ""
    @State private var answer = ""
    @State private var hint = ""
    @State private var notes = ""
    @State private var radical = ""
    @State private var phonetic = ""
    @FocusState private var questionFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(L("flashcard.section_vocab")) {
                    TextField(L("flashcard.question_placeholder"), text: $question)
                        .focused($questionFocused)
                    TextField(L("flashcard.answer_placeholder"), text: $answer)
                }
                Section(L("flashcard.section_extra")) {
                    TextField(L("flashcard.hint_placeholder"), text: $hint)
                    TextField(L("flashcard.phonetic_placeholder"), text: $phonetic)
                    TextField(L("flashcard.radical_placeholder"), text: $radical)
                    TextField(L("flashcard.notes_placeholder"), text: $notes)
                }
            }
            .navigationTitle(L("flashcard.edit_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.cancel")) {
                        HapticFeedback.impact()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("common.save")) {
                        HapticFeedback.impact()
                        if viewModel.updateFlashcard(
                            id: flashcard.id,
                            question: question,
                            answer: answer,
                            hint: hint.isEmpty ? nil : hint,
                            notes: notes.isEmpty ? nil : notes,
                            radical: radical.isEmpty ? nil : radical,
                            phonetic: phonetic.isEmpty ? nil : phonetic
                        ) {
                            onDismiss()
                        }
                    }
                    .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty || answer.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                question = flashcard.question
                answer = flashcard.answer
                hint = flashcard.hint ?? ""
                notes = flashcard.notes ?? ""
                radical = flashcard.radical ?? ""
                phonetic = flashcard.displayPhonetic ?? ""
                questionFocused = true
            }
        }
    }
}

struct FlashcardRow: View {
    let card: Flashcard
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.questionDisplayText)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    if let hint = card.hint, !hint.isEmpty {
                        Text(hint)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(16)
            .cardStyle()
        }
        .buttonStyle(HapticButtonStyle())
    }
}

// MARK: - Flashcard Preview (long-press)

struct FlashcardPreviewCard: View {
    let card: Flashcard

    var body: some View {
        VStack(spacing: 16) {
            Text(card.questionDisplayText)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)

            if let phonetic = card.displayPhonetic, !phonetic.isEmpty {
                Text(phonetic)
                    .font(.title3)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Divider()

            Text(card.answer)
                .font(.title3)
                .foregroundStyle(AppTheme.primary)
                .multilineTextAlignment(.center)

            if let hint = card.hint, !hint.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accentOrange)
                    Text(hint)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if let notes = card.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let radical = card.radical, !radical.isEmpty {
                HStack(spacing: 4) {
                    Text(L("detail.radical_label"))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(radical)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(24)
        .frame(width: 300)
        .background(AppTheme.cardBg)
    }
}

struct PracticeTypePicker: View {
    @Binding var selected: PracticeType
    var subjectName: String? = nil
    let onDismiss: () -> Void

    private var availableTypes: [PracticeType] {
        PracticeType.availableTypes(subjectName: subjectName)
    }

    var body: some View {
        NavigationStack {
            List(availableTypes, id: \.self) { type in
                Button {
                    HapticFeedback.impact()
                    selected = type
                    onDismiss()
                } label: {
                    HStack {
                        Text(type.rawValue)
                        Spacer()
                        if selected == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.primary)
                        }
                    }
                }
            }
            .navigationTitle(L("practice.choose_type"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.close")) {
                        HapticFeedback.impact()
                        onDismiss()
                    }
                }
            }
        }
    }
}
