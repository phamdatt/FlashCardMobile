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
    @State private var showFlipPractice = false
    @State private var showMultipleChoicePractice = false
    @State private var showListeningPractice = false
    @State private var showMeaningToHanziPractice = false
    @State private var practiceType: PracticeType = .flipCard
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
                        Label("Thêm từ vựng", systemImage: "plus")
                    }
                    Button {
                        HapticFeedback.impact()
                        showExportSheet = true
                    } label: {
                        Label("Xuất CSV", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        HapticFeedback.impact()
                        showImportSheet = true
                    } label: {
                        Label("Nhập CSV", systemImage: "square.and.arrow.down")
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
        .alert("Xóa từ vựng?", isPresented: Binding(
            get: { listViewModel.flashcardToDelete != nil },
            set: { if !$0 { listViewModel.clearFlashcardToDelete() } }
        )) {
            Button("Hủy", role: .cancel) {
                HapticFeedback.impact()
                listViewModel.clearFlashcardToDelete()
            }
            Button("Xóa", role: .destructive) {
                HapticFeedback.impact()
                if let c = listViewModel.flashcardToDelete {
                    _ = listViewModel.deleteFlashcard(id: c.id)
                }
            }
        } message: {
            if let c = listViewModel.flashcardToDelete {
                Text("Từ \"\(c.questionDisplayText)\" sẽ bị xóa vĩnh viễn.")
            }
        }
        .sheet(isPresented: $showPracticePicker) {
            PracticeTypePicker(selected: $practiceType, subjectName: subject.name) {
                showPracticePicker = false
                switch practiceType {
                case .flipCard: showFlipPractice = true
                case .multipleChoice: showMultipleChoicePractice = true
                case .listening: showListeningPractice = true
                case .meaningToHanzi: showMeaningToHanziPractice = true
                }
            }
        }
        .fullScreenCover(isPresented: $showFlipPractice) {
            FlipCardPracticeScreen(topic: listViewModel.topicForPractice, subject: subject)
        }
        .fullScreenCover(isPresented: $showMultipleChoicePractice) {
            MultipleChoicePracticeScreen(topic: listViewModel.topicForPractice, subject: subject)
        }
        .fullScreenCover(isPresented: $showListeningPractice) {
            ListeningPracticeScreen(topic: listViewModel.topicForPractice, subject: subject)
        }
        .fullScreenCover(isPresented: $showMeaningToHanziPractice) {
            MeaningToHanziPracticeScreen(topic: listViewModel.topicForPractice, subject: subject)
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
                Text("Bắt đầu luyện tập")
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
                        UIPasteboard.general.string = card.copyText
                    } label: {
                        Label("Sao chép", systemImage: "doc.on.doc")
                    }
                    Button {
                        HapticFeedback.impact()
                        listViewModel.setFlashcardToEdit(card)
                    } label: {
                        Label("Sửa", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        HapticFeedback.impact()
                        listViewModel.setFlashcardToDelete(card)
                    } label: {
                        Label("Xóa", systemImage: "trash")
                    }
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
                Section("Từ vựng") {
                    TextField("Câu hỏi / Hán tự", text: $question)
                        .focused($questionFocused)
                    TextField("Đáp án / Nghĩa", text: $answer)
                }
                Section("Thông tin bổ sung") {
                    TextField("Gợi ý", text: $hint)
                    TextField("Phiên âm / Pinyin", text: $phonetic)
                    TextField("Bộ thủ", text: $radical)
                    TextField("Ghi chú", text: $notes)
                }
            }
            .navigationTitle("Thêm từ vựng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") {
                        HapticFeedback.impact()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
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
                Section("Từ vựng") {
                    TextField("Câu hỏi / Hán tự", text: $question)
                        .focused($questionFocused)
                    TextField("Đáp án / Nghĩa", text: $answer)
                }
                Section("Thông tin bổ sung") {
                    TextField("Gợi ý", text: $hint)
                    TextField("Phiên âm / Pinyin", text: $phonetic)
                    TextField("Bộ thủ", text: $radical)
                    TextField("Ghi chú", text: $notes)
                }
            }
            .navigationTitle("Sửa từ vựng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") {
                        HapticFeedback.impact()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
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
            .navigationTitle("Chọn kiểu luyện tập")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        HapticFeedback.impact()
                        onDismiss()
                    }
                }
            }
        }
    }
}
