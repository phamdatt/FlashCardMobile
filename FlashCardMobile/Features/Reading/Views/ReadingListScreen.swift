//
//  ReadingListScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct ReadingListScreen: View {
    let topic: Topic
    @State private var selectedPassage: ReadingPassage?

    var body: some View {
        Group {
            if topic.readings.isEmpty {
                ContentUnavailableView(
                    "Chưa có bài đọc",
                    systemImage: "doc.text",
                    description: Text("Chủ đề này chưa có bài đọc nào.")
                )
            } else {
                List(topic.readings) { passage in
                    Button {
                        HapticFeedback.impact()
                        selectedPassage = passage
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(passage.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(String(passage.content.prefix(80)) + (passage.content.count > 80 ? "..." : ""))
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationDestination(item: $selectedPassage) { p in
                    ReadingDetailScreen(passage: p)
                }
            }
        }
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReadingDetailScreen: View {
    let passage: ReadingPassage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(passage.title)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(passage.content)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(AppTheme.surface)
        .navigationTitle("Bài đọc")
        .navigationBarTitleDisplayMode(.inline)
    }
}
