//
//  LearningModels.swift
//  FlashCardMobile
//

import Foundation

struct Subject: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let icon: String
    var topics: [Topic]

    var displayIcon: String {
        switch name {
        case "Tiếng Anh": return "globe.americas.fill"
        case "Tiếng Trung": return "text.book.closed.fill"
        case "Bài đọc": return "doc.richtext.fill"
        default: return icon
        }
    }

    var localizedName: String {
        switch name {
        case "Tiếng Anh": return L("subject.english")
        case "Tiếng Trung": return L("subject.chinese")
        case "Bài đọc": return L("subject.reading")
        default: return name
        }
    }

    var isReading: Bool { name == "Bài đọc" }
    var isChinese: Bool { name == "Tiếng Trung" }
}

struct Topic: Identifiable, Hashable, Codable {
    var id: Int
    var name: String
    var subjectId: Int
    var flashcards: [Flashcard]
    var readings: [ReadingPassage]

    init(id: Int = 0, name: String, subjectId: Int, flashcards: [Flashcard], readings: [ReadingPassage] = []) {
        self.id = id
        self.name = name
        self.subjectId = subjectId
        self.flashcards = flashcards
        self.readings = readings
    }
}

struct ReadingPassage: Identifiable, Hashable, Codable {
    let id: Int
    let topicId: Int
    let title: String
    let content: String
    let createdAt: String
}

struct Flashcard: Identifiable, Hashable, Codable {
    static let exerciseTypeLabel = "Từ vựng"

    let id: Int
    let question: String
    let answer: String
    let hint: String?
    let options: [String]?
    let correctAnswer: String?
    let exerciseType: String
    let notes: String?
    let radical: String?
    let phonetic: String?

    var isMultipleChoice: Bool {
        options != nil && correctAnswer != nil
    }

    var questionDisplayText: String {
        let s = question.trimmingCharacters(in: .whitespaces)
        guard let lastClose = s.lastIndex(of: ")") else { return s }
        let beforeClose = s[..<lastClose]
        guard let lastOpen = beforeClose.lastIndex(of: "(") else { return s }
        return String(s[..<lastOpen]).trimmingCharacters(in: .whitespaces)
    }

    var pinyinFromQuestion: String? {
        let s = question.trimmingCharacters(in: .whitespaces)
        guard let lastClose = s.lastIndex(of: ")") else { return nil }
        let beforeClose = s[..<lastClose]
        guard let lastOpen = beforeClose.lastIndex(of: "(") else { return nil }
        return String(s[s.index(after: lastOpen)..<lastClose]).trimmingCharacters(in: .whitespaces)
    }

    var displayPhonetic: String? {
        if let p = phonetic, !p.isEmpty { return p }
        return pinyinFromQuestion
    }

    var questionDisplayTextWithPhonetic: String {
        guard let p = displayPhonetic, !p.isEmpty else { return questionDisplayText }
        return "\(questionDisplayText) (\(p))"
    }

    /// Chuỗi để sao chép: "Hán tự (pinyin) - nghĩa"
    var copyText: String {
        let q = questionDisplayTextWithPhonetic
        return "\(q) - \(answer)"
    }
}

// MARK: - Similar Looking Groups

struct SimilarLookingGroup {
    let characters: [String]

    init(_ chars: String...) {
        self.characters = chars
    }

    func contains(_ char: String) -> Bool {
        characters.contains(char)
    }

    func others(excluding char: String) -> [String] {
        characters.filter { $0 != char }
    }

    static func findGroup(for hanzi: String) -> SimilarLookingGroup? {
        groups.first { group in
            group.characters.contains(where: { hanzi.contains($0) })
        }
    }

    static func findAllGroups(for hanzi: String) -> [SimilarLookingGroup] {
        groups.filter { group in
            group.characters.contains(where: { hanzi.contains($0) })
        }
    }

    static let groups: [SimilarLookingGroup] = [
        SimilarLookingGroup("会", "合"),
        SimilarLookingGroup("未", "末"),
        SimilarLookingGroup("己", "已", "巳"),
        SimilarLookingGroup("日", "目", "曰"),
        SimilarLookingGroup("人", "入"),
        SimilarLookingGroup("土", "士"),
        SimilarLookingGroup("大", "太", "天", "夭", "夫"),
        SimilarLookingGroup("事", "是", "式", "试"),
        SimilarLookingGroup("买", "卖"),
        SimilarLookingGroup("左", "右"),
        SimilarLookingGroup("干", "千", "于"),
        SimilarLookingGroup("王", "玉"),
        SimilarLookingGroup("刀", "力", "万", "方"),
        SimilarLookingGroup("厂", "广"),
        SimilarLookingGroup("贝", "见"),
        SimilarLookingGroup("木", "本"),
        SimilarLookingGroup("白", "自"),
        SimilarLookingGroup("田", "由", "甲", "申"),
        SimilarLookingGroup("问", "间"),
        SimilarLookingGroup("休", "体"),
        SimilarLookingGroup("今", "令"),
        SimilarLookingGroup("因", "困"),
        SimilarLookingGroup("从", "丛"),
        SimilarLookingGroup("鸟", "乌"),
        SimilarLookingGroup("免", "兔"),
        SimilarLookingGroup("候", "侯"),
        SimilarLookingGroup("拆", "折"),
        SimilarLookingGroup("幻", "幼"),
        SimilarLookingGroup("历", "厉"),
        SimilarLookingGroup("即", "既"),
        SimilarLookingGroup("拔", "拨"),
        SimilarLookingGroup("崇", "祟"),
        SimilarLookingGroup("戍", "戌", "戊"),
        SimilarLookingGroup("赢", "嬴", "羸"),
        SimilarLookingGroup("水", "氷", "永"),
        SimilarLookingGroup("下", "卞"),
        SimilarLookingGroup("矢", "失", "先"),
        SimilarLookingGroup("可", "司", "句"),
        SimilarLookingGroup("西", "酉"),
        SimilarLookingGroup("艮", "良"),
        SimilarLookingGroup("史", "吏", "更"),
        SimilarLookingGroup("目", "自", "且"),
        SimilarLookingGroup("往", "住"),
        SimilarLookingGroup("洒", "酒"),
        SimilarLookingGroup("何", "伺"),
        SimilarLookingGroup("船", "般"),
        SimilarLookingGroup("狠", "狼"),
        SimilarLookingGroup("眼", "眠"),
        SimilarLookingGroup("请", "情", "清", "晴", "睛"),
        SimilarLookingGroup("跑", "抱"),
        SimilarLookingGroup("样", "洋"),
        SimilarLookingGroup("吗", "妈", "马"),
        SimilarLookingGroup("喝", "渴"),
        SimilarLookingGroup("呢", "泥"),
        SimilarLookingGroup("他", "她", "它"),
        SimilarLookingGroup("很", "狠"),
        SimilarLookingGroup("在", "再"),
        SimilarLookingGroup("的", "得", "地"),
        SimilarLookingGroup("进", "近"),
        SimilarLookingGroup("说", "话"),
        SimilarLookingGroup("认", "让"),
        SimilarLookingGroup("课", "颗"),
        SimilarLookingGroup("块", "快"),
        SimilarLookingGroup("到", "倒"),
        SimilarLookingGroup("没", "设"),
        SimilarLookingGroup("找", "我"),
        SimilarLookingGroup("经", "轻"),
        SimilarLookingGroup("跟", "很"),
        SimilarLookingGroup("但", "担"),
        SimilarLookingGroup("难", "准"),
        SimilarLookingGroup("完", "玩"),
        SimilarLookingGroup("观", "馆"),
        SimilarLookingGroup("带", "戴"),
        SimilarLookingGroup("历", "立", "利"),
        SimilarLookingGroup("假", "暇"),
    ]
}
