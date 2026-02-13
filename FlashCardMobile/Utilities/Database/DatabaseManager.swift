//
//  DatabaseManager.swift
//  FlashCardMobile
//

import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    private let currentSeedVersion = 1

    private init() {
        copyDatabaseIfNeeded()
        openDatabase()
    }

    deinit {
        closeDatabase()
    }

    private func closeDatabase() {
        guard let pointer = db else { return }
        sqlite3_close(pointer)
        db = nil
    }

    private func copyDatabaseIfNeeded() {
        let destURL = Self.databaseURL()
        let fm = FileManager.default
        let savedVersion = UserDefaults.standard.integer(forKey: "db_seed_version")
        let dbExists = fm.fileExists(atPath: destURL.path)
        let needsCopy = !dbExists || savedVersion < currentSeedVersion

        guard needsCopy else { return }

        if let bundleURL = Bundle.main.url(forResource: "flashcards", withExtension: "sqlite")
            ?? Bundle.main.url(forResource: "flashcards", withExtension: "sqlite", subdirectory: "Resources") {
            do {
                if dbExists { try fm.removeItem(at: destURL) }
                try fm.copyItem(at: bundleURL, to: destURL)
                UserDefaults.standard.set(currentSeedVersion, forKey: "db_seed_version")
            } catch {
                print("❌ Error copying database: \(error)")
            }
        } else {
            // No seed - create empty DB
            try? fm.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
    }

    private func openDatabase() {
        let fileURL = Self.databaseURL()
        var pointer: OpaquePointer?
        if sqlite3_open(fileURL.path, &pointer) != SQLITE_OK {
            sqlite3_close(pointer)
            db = nil
            return
        }
        db = pointer
        sqlite3_exec(db, "PRAGMA foreign_keys = ON", nil, nil, nil)
        createPracticeSessionsTable()
        createSRSTables()
    }

    private func createPracticeSessionsTable() {
        let sql = """
            CREATE TABLE IF NOT EXISTS practice_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                practice_date TEXT NOT NULL,
                practice_type TEXT NOT NULL,
                topic_id INTEGER,
                correct_answers INTEGER NOT NULL,
                total_questions INTEGER NOT NULL,
                created_at TEXT DEFAULT (datetime('now','localtime'))
            )
            """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    private func createSRSTables() {
        let progressSQL = """
            CREATE TABLE IF NOT EXISTS flashcard_progress (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                flashcard_id INTEGER NOT NULL UNIQUE,
                ease_factor REAL DEFAULT 2.5,
                interval_days INTEGER DEFAULT 0,
                repetitions INTEGER DEFAULT 0,
                next_review_date TEXT NOT NULL,
                last_review_date TEXT,
                difficulty REAL DEFAULT 0.0,
                total_reviews INTEGER DEFAULT 0,
                correct_reviews INTEGER DEFAULT 0,
                incorrect_reviews INTEGER DEFAULT 0,
                created_at TEXT DEFAULT (datetime('now','localtime')),
                updated_at TEXT DEFAULT (datetime('now','localtime')),
                FOREIGN KEY (flashcard_id) REFERENCES vocabularies(id) ON DELETE CASCADE
            )
            """
        sqlite3_exec(db, progressSQL, nil, nil, nil)
        sqlite3_exec(db, """
            CREATE TABLE IF NOT EXISTS mistake_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                flashcard_id INTEGER NOT NULL,
                practice_date TEXT NOT NULL,
                practice_type TEXT NOT NULL,
                topic_id INTEGER NOT NULL,
                created_at TEXT DEFAULT (datetime('now','localtime')),
                FOREIGN KEY (flashcard_id) REFERENCES vocabularies(id) ON DELETE CASCADE,
                FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
            )
            """, nil, nil, nil)
        sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_progress_flashcard ON flashcard_progress(flashcard_id)", nil, nil, nil)
        sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_progress_next_review ON flashcard_progress(next_review_date)", nil, nil, nil)
    }

    static func databaseURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("FlashCardMobile", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("flashcards.sqlite")
    }

    // MARK: - Backup & Export

    /// Sao lưu database vào Documents/Backups với tên có timestamp.
    /// Trả về URL file backup hoặc nil nếu lỗi.
    func backupDatabase() -> URL? {
        let src = Self.databaseURL()
        let fm = FileManager.default
        guard fm.fileExists(atPath: src.path) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let backupDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Backups", isDirectory: true)
        try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)
        let dest = backupDir.appendingPathComponent("flashcards_\(timestamp).sqlite")

        do {
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.copyItem(at: src, to: dest)
            return dest
        } catch {
            print("❌ Backup failed: \(error)")
            return nil
        }
    }

    /// Tạo bản sao tạm để xuất/chia sẻ. Trả về URL file copy hoặc nil.
    func createExportCopy() -> URL? {
        let src = Self.databaseURL()
        let fm = FileManager.default
        guard fm.fileExists(atPath: src.path) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let tempDir = fm.temporaryDirectory
        let dest = tempDir.appendingPathComponent("flashcards_export_\(timestamp).sqlite")

        do {
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.copyItem(at: src, to: dest)
            return dest
        } catch {
            print("❌ Export copy failed: \(error)")
            return nil
        }
    }

    /// Khôi phục từ file SQLite. Trả về true nếu thành công.
    func restoreDatabase(from sourceURL: URL) -> Bool {
        let dest = Self.databaseURL()
        let fm = FileManager.default
        guard fm.fileExists(atPath: sourceURL.path) else { return false }

        guard sourceURL.startAccessingSecurityScopedResource() else { return false }
        defer { sourceURL.stopAccessingSecurityScopedResource() }

        do {
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
            try fm.copyItem(at: sourceURL, to: dest)

            if db != nil {
                sqlite3_close(db)
                db = nil
            }
            openDatabase()
            return true
        } catch {
            print("❌ Restore failed: \(error)")
            return false
        }
    }

    // MARK: - Load

    func loadAllSubjects() -> [Subject] {
        guard db != nil else { return [] }
        var subjects: [Subject] = []
        let sql = "SELECT id, name, icon FROM subjects ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let icon = String(cString: sqlite3_column_text(stmt, 2))
            let topics = loadTopics(for: id, subjectName: name)
            subjects.append(Subject(id: id, name: name, icon: icon, topics: topics))
        }
        sqlite3_finalize(stmt)
        return subjects
    }

    private func loadTopics(for subjectId: Int, subjectName: String = "") -> [Topic] {
        var topics: [Topic] = []
        let sql = "SELECT id, name FROM topics WHERE subject_id = ? ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_int(stmt, 1, Int32(subjectId))
        let isReading = (subjectName == "Bài đọc")

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let flashcards = loadFlashcards(for: id)
            let readings: [ReadingPassage] = isReading ? loadReadings(for: id) : []
            topics.append(Topic(id: id, name: name, subjectId: subjectId, flashcards: flashcards, readings: readings))
        }
        sqlite3_finalize(stmt)
        return topics
    }

    private func loadReadings(for topicId: Int) -> [ReadingPassage] {
        var list: [ReadingPassage] = []
        let sql = "SELECT id, topic_id, title, content, created_at FROM reading_passages WHERE topic_id = ? ORDER BY sort_order, id"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_int(stmt, 1, Int32(topicId))
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let topicId = Int(sqlite3_column_int(stmt, 1))
            let title = String(cString: sqlite3_column_text(stmt, 2))
            let content = String(cString: sqlite3_column_text(stmt, 3))
            let createdAt = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? ""
            list.append(ReadingPassage(id: id, topicId: topicId, title: title, content: content, createdAt: createdAt))
        }
        sqlite3_finalize(stmt)
        return list
    }

    func loadFlashcards(for topicId: Int) -> [Flashcard] {
        guard db != nil else { return [] }
        let hasNotes = hasColumn(table: "vocabularies", column: "notes")
        let hasRadical = hasColumn(table: "vocabularies", column: "radical")
        let hasPhonetic = hasColumn(table: "vocabularies", column: "phonetic")
        var cols = "id, question, answer, hint"
        if hasNotes { cols += ", notes" }
        if hasRadical { cols += ", radical" }
        if hasPhonetic { cols += ", phonetic" }
        let sql = "SELECT \(cols) FROM vocabularies WHERE topic_id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(topicId))

        var flashcards: [Flashcard] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let question = String(cString: sqlite3_column_text(stmt, 1))
            let answer = String(cString: sqlite3_column_text(stmt, 2))
            let hint: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
            var notes: String? = nil, radical: String? = nil, phonetic: String? = nil
            var idx: Int32 = 4
            if hasNotes { notes = sqlite3_column_text(stmt, idx).map { String(cString: $0) }; idx += 1 }
            if hasRadical { radical = sqlite3_column_text(stmt, idx).map { String(cString: $0) }; idx += 1 }
            if hasPhonetic { phonetic = sqlite3_column_text(stmt, idx).map { String(cString: $0) } }

            flashcards.append(Flashcard(
                id: id,
                question: question,
                answer: answer,
                hint: hint,
                options: nil,
                correctAnswer: nil,
                exerciseType: Flashcard.exerciseTypeLabel,
                notes: notes,
                radical: radical,
                phonetic: phonetic
            ))
        }
        return generateOptions(for: flashcards)
    }

    private func generateOptions(for flashcards: [Flashcard]) -> [Flashcard] {
        guard flashcards.count >= 4 else { return flashcards }
        let allAnswers = flashcards.map { $0.answer }
        return flashcards.map { card in
            let wrongPool = allAnswers.filter { $0 != card.answer }.shuffled()
            let wrongAnswers = Array(wrongPool.prefix(3))
            var allChoices = wrongAnswers + [card.answer]
            allChoices.shuffle()
            let labels = ["A", "B", "C", "D"]
            var options: [String] = []
            var correctLabel = "A"
            for (i, ans) in allChoices.prefix(4).enumerated() {
                options.append("\(labels[i]). \(ans)")
                if ans == card.answer { correctLabel = labels[i] }
            }
            return Flashcard(
                id: card.id,
                question: card.question,
                answer: card.answer,
                hint: card.hint,
                options: options,
                correctAnswer: correctLabel,
                exerciseType: card.exerciseType,
                notes: card.notes,
                radical: card.radical,
                phonetic: card.phonetic
            )
        }
    }

    private func hasColumn(table: String, column: String) -> Bool {
        guard let db = db else { return false }
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, "PRAGMA table_info(\(table))", -1, &stmt, nil) == SQLITE_OK else { return false }
        while sqlite3_step(stmt) == SQLITE_ROW {
            let name = String(cString: sqlite3_column_text(stmt, 1))
            if name == column { return true }
        }
        return false
    }

    func searchFlashcards(query: String) -> [(Flashcard, Topic, Subject)] {
        guard db != nil else { return [] }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        let hasNotes = hasColumn(table: "vocabularies", column: "notes")
        let hasRadical = hasColumn(table: "vocabularies", column: "radical")
        let hasPhonetic = hasColumn(table: "vocabularies", column: "phonetic")
        var cols = "v.id, v.question, v.answer, v.hint"
        if hasNotes { cols += ", v.notes" }
        if hasRadical { cols += ", v.radical" }
        if hasPhonetic { cols += ", v.phonetic" }
        let sql = """
            SELECT \(cols), v.topic_id, t.name as topic_name, t.subject_id, s.name as subject_name
            FROM vocabularies v
            JOIN topics t ON v.topic_id = t.id
            JOIN subjects s ON t.subject_id = s.id
            WHERE LOWER(v.question) LIKE ? OR LOWER(v.answer) LIKE ? OR LOWER(v.hint) LIKE ? OR LOWER(v.notes) LIKE ? OR LOWER(v.phonetic) LIKE ?
            ORDER BY t.name, v.id
            """
        let pattern = "%\(q)%"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        for i in 1...5 { sqlite3_bind_text(stmt, Int32(i), (pattern as NSString).utf8String, -1, nil) }
        var results: [(Flashcard, Topic, Subject)] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let question = String(cString: sqlite3_column_text(stmt, 1))
            let answer = String(cString: sqlite3_column_text(stmt, 2))
            let hint: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
            var notes: String? = nil, radical: String? = nil, phonetic: String? = nil
            var idx: Int32 = 4
            if hasNotes { notes = sqlite3_column_text(stmt, idx).map { String(cString: $0) }; idx += 1 }
            if hasRadical { radical = sqlite3_column_text(stmt, idx).map { String(cString: $0) }; idx += 1 }
            if hasPhonetic { phonetic = sqlite3_column_text(stmt, idx).map { String(cString: $0) }; idx += 1 }
            let topicId = Int(sqlite3_column_int(stmt, idx))
            let topicName = String(cString: sqlite3_column_text(stmt, idx + 1))
            let subjectId = Int(sqlite3_column_int(stmt, idx + 2))
            let subjectName = String(cString: sqlite3_column_text(stmt, idx + 3))
            let flashcard = Flashcard(id: id, question: question, answer: answer, hint: hint, options: nil, correctAnswer: nil, exerciseType: Flashcard.exerciseTypeLabel, notes: notes, radical: radical, phonetic: phonetic)
            let topic = Topic(id: topicId, name: topicName, subjectId: subjectId, flashcards: [flashcard])
            let icon = subjectName == "Tiếng Anh" ? "globe" : (subjectName == "Tiếng Trung" ? "character.book.closed" : "doc.text")
            let subject = Subject(id: subjectId, name: subjectName, icon: icon, topics: [topic])
            results.append((flashcard, topic, subject))
        }
        return results
    }

    func loadFlashcard(byId id: Int) -> Flashcard? {
        guard db != nil else { return nil }
        let hasNotes = hasColumn(table: "vocabularies", column: "notes")
        let hasRadical = hasColumn(table: "vocabularies", column: "radical")
        let hasPhonetic = hasColumn(table: "vocabularies", column: "phonetic")
        var cols = "id, question, answer, hint"
        if hasNotes { cols += ", notes" }
        if hasRadical { cols += ", radical" }
        if hasPhonetic { cols += ", phonetic" }
        let sql = "SELECT \(cols) FROM vocabularies WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(id))
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        let question = String(cString: sqlite3_column_text(stmt, 1))
        let answer = String(cString: sqlite3_column_text(stmt, 2))
        let hint: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
        var notes: String? = nil, radical: String? = nil, phonetic: String? = nil
        var idx: Int32 = 4
        if hasNotes { notes = sqlite3_column_text(stmt, idx).map { String(cString: $0) }; idx += 1 }
        if hasRadical { radical = sqlite3_column_text(stmt, idx).map { String(cString: $0) }; idx += 1 }
        if hasPhonetic { phonetic = sqlite3_column_text(stmt, idx).map { String(cString: $0) } }
        return Flashcard(id: id, question: question, answer: answer, hint: hint, options: nil, correctAnswer: nil, exerciseType: Flashcard.exerciseTypeLabel, notes: notes, radical: radical, phonetic: phonetic)
    }

    // MARK: - SRS

    func getDueFlashcards(subjectId: Int? = nil) -> [Int] {
        guard db != nil else { return [] }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let calendar = Calendar.current
        let startOfTomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let boundStr = formatter.string(from: startOfTomorrow)

        let sql: String
        if subjectId != nil {
            sql = """
                SELECT fp.flashcard_id FROM flashcard_progress fp
                JOIN vocabularies v ON fp.flashcard_id = v.id
                JOIN topics t ON v.topic_id = t.id
                WHERE fp.next_review_date < ? AND t.subject_id = ?
                ORDER BY fp.next_review_date ASC
                """
        } else {
            sql = "SELECT flashcard_id FROM flashcard_progress WHERE next_review_date < ? ORDER BY next_review_date ASC"
        }
        var stmt: OpaquePointer?
        var ids: [Int] = []
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_text(stmt, 1, (boundStr as NSString).utf8String, -1, nil)
        if let id = subjectId { sqlite3_bind_int(stmt, 2, Int32(id)) }
        while sqlite3_step(stmt) == SQLITE_ROW {
            ids.append(Int(sqlite3_column_int(stmt, 0)))
        }
        sqlite3_finalize(stmt)
        return ids
    }

    func getFlashcardProgress(flashcardId: Int) -> FlashcardProgress? {
        guard db != nil else { return nil }
        let sql = """
            SELECT id, flashcard_id, ease_factor, interval_days, repetitions,
                   next_review_date, last_review_date, difficulty, total_reviews,
                   correct_reviews, incorrect_reviews
            FROM flashcard_progress WHERE flashcard_id = ?
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(flashcardId))
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let id = Int(sqlite3_column_int(stmt, 0))
        let flashcardId = Int(sqlite3_column_int(stmt, 1))
        let easeFactor = sqlite3_column_double(stmt, 2)
        let interval = Int(sqlite3_column_int(stmt, 3))
        let repetitions = Int(sqlite3_column_int(stmt, 4))
        let nextReviewStr = String(cString: sqlite3_column_text(stmt, 5))
        let lastReviewStr: String? = sqlite3_column_text(stmt, 6).map { String(cString: $0) }
        let difficulty = sqlite3_column_double(stmt, 7)
        let totalReviews = Int(sqlite3_column_int(stmt, 8))
        let correctReviews = Int(sqlite3_column_int(stmt, 9))
        let incorrectReviews = Int(sqlite3_column_int(stmt, 10))
        let nextReviewDate = formatter.date(from: nextReviewStr) ?? Date()
        let lastReviewDate = lastReviewStr.flatMap { formatter.date(from: $0) }

        return FlashcardProgress(
            id: id,
            flashcardId: flashcardId,
            easeFactor: easeFactor,
            interval: interval,
            repetitions: repetitions,
            nextReviewDate: nextReviewDate,
            lastReviewDate: lastReviewDate,
            difficulty: difficulty,
            totalReviews: totalReviews,
            correctReviews: correctReviews,
            incorrectReviews: incorrectReviews
        )
    }

    func saveFlashcardProgress(_ progress: FlashcardProgress) {
        guard let db = db else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nextReviewStr = formatter.string(from: progress.nextReviewDate)
        let lastReviewStr = progress.lastReviewDate.map { formatter.string(from: $0) }

        let sql = """
            INSERT INTO flashcard_progress (flashcard_id, ease_factor, interval_days, repetitions, next_review_date, last_review_date, difficulty, total_reviews, correct_reviews, incorrect_reviews, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now','localtime'))
            ON CONFLICT(flashcard_id) DO UPDATE SET
                ease_factor = excluded.ease_factor,
                interval_days = excluded.interval_days,
                repetitions = excluded.repetitions,
                next_review_date = excluded.next_review_date,
                last_review_date = excluded.last_review_date,
                difficulty = excluded.difficulty,
                total_reviews = excluded.total_reviews,
                correct_reviews = excluded.correct_reviews,
                incorrect_reviews = excluded.incorrect_reviews,
                updated_at = datetime('now','localtime')
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(progress.flashcardId))
        sqlite3_bind_double(stmt, 2, progress.easeFactor)
        sqlite3_bind_int(stmt, 3, Int32(progress.interval))
        sqlite3_bind_int(stmt, 4, Int32(progress.repetitions))
        sqlite3_bind_text(stmt, 5, (nextReviewStr as NSString).utf8String, -1, nil)
        if let s = lastReviewStr {
            sqlite3_bind_text(stmt, 6, (s as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(stmt, 6)
        }
        sqlite3_bind_double(stmt, 7, progress.difficulty)
        sqlite3_bind_int(stmt, 8, Int32(progress.totalReviews))
        sqlite3_bind_int(stmt, 9, Int32(progress.correctReviews))
        sqlite3_bind_int(stmt, 10, Int32(progress.incorrectReviews))
        sqlite3_step(stmt)
    }

    func recordMistake(flashcardId: Int, practiceType: String, topicId: Int) {
        guard let db = db else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateStr = formatter.string(from: Date())
        let sql = "INSERT INTO mistake_records (flashcard_id, practice_date, practice_type, topic_id) VALUES (?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(flashcardId))
        sqlite3_bind_text(stmt, 2, (dateStr as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (practiceType as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 4, Int32(topicId))
        sqlite3_step(stmt)
    }

    func getMistakeFlashcards(days: Int = 30) -> [Int] {
        guard db != nil else { return [] }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let cutoffStr = formatter.string(from: cutoff)
        let sql = "SELECT DISTINCT flashcard_id FROM mistake_records WHERE practice_date >= ? ORDER BY practice_date DESC"
        var stmt: OpaquePointer?
        var ids: [Int] = []
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_text(stmt, 1, (cutoffStr as NSString).utf8String, -1, nil)
        while sqlite3_step(stmt) == SQLITE_ROW {
            ids.append(Int(sqlite3_column_int(stmt, 0)))
        }
        sqlite3_finalize(stmt)
        return ids
    }

    func recordPracticeSession(practiceDate: String, practiceType: String, topicId: Int, correct: Int, total: Int) {
        guard let db = db else { return }
        let sql = "INSERT INTO practice_sessions (practice_date, practice_type, topic_id, correct_answers, total_questions) VALUES (?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (practiceDate as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (practiceType as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 3, Int32(topicId))
        sqlite3_bind_int(stmt, 4, Int32(correct))
        sqlite3_bind_int(stmt, 5, Int32(total))
        sqlite3_step(stmt)
    }

    func getPracticeSessionCount(topicId: Int) -> Int {
        guard db != nil else { return 0 }
        let sql = "SELECT COUNT(*) FROM practice_sessions WHERE topic_id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(topicId))
        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        return 0
    }

    func getStreakInfo() -> StreakInfo {
        guard db != nil else { return StreakInfo(currentStreak: 0, longestStreak: 0, didPracticeToday: false) }
        let sql = "SELECT DISTINCT practice_date FROM practice_sessions ORDER BY practice_date DESC"
        var stmt: OpaquePointer?
        var dates: [String] = []
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                dates.append(String(cString: sqlite3_column_text(stmt, 0)))
            }
        }
        sqlite3_finalize(stmt)
        guard !dates.isEmpty else { return StreakInfo(currentStreak: 0, longestStreak: 0, didPracticeToday: false) }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        let didPracticeToday = dates.first == todayStr

        let calendar = Calendar.current
        var currentStreak = 0
        var checkDate = didPracticeToday ? Date() : calendar.date(byAdding: .day, value: -1, to: Date())!
        for dateStr in dates {
            let checkStr = formatter.string(from: checkDate)
            if dateStr == checkStr {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if dateStr < checkStr { break }
        }

        var longestStreak = 0, tempStreak = 1
        for i in 0..<dates.count {
            if i == 0 { continue }
            guard let current = formatter.date(from: dates[i]),
                  let previous = formatter.date(from: dates[i - 1]) else { continue }
            let diff = calendar.dateComponents([.day], from: current, to: previous).day ?? 0
            if diff == 1 { tempStreak += 1 }
            else { longestStreak = max(longestStreak, tempStreak); tempStreak = 1 }
        }
        longestStreak = max(longestStreak, tempStreak)

        return StreakInfo(currentStreak: currentStreak, longestStreak: longestStreak, didPracticeToday: didPracticeToday)
    }

    func ensureProgressExists(flashcardId: Int) {
        guard let db = db else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nowStr = formatter.string(from: Date())
        let sql = "INSERT OR IGNORE INTO flashcard_progress (flashcard_id, next_review_date) VALUES (?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(flashcardId))
        sqlite3_bind_text(stmt, 2, (nowStr as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
    }

    // MARK: - Flashcard CRUD

    func insertFlashcard(topicId: Int, question: String, answer: String, hint: String? = nil, notes: String? = nil, radical: String? = nil, phonetic: String? = nil) -> Int? {
        guard let db = db else { return nil }
        let sql = "INSERT INTO vocabularies (topic_id, question, answer, hint, notes, radical, phonetic) VALUES (?, ?, ?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(topicId))
        sqlite3_bind_text(stmt, 2, (question as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (answer as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, ((hint ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 5, ((notes ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 6, ((radical ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 7, ((phonetic ?? "") as NSString).utf8String, -1, nil)
        guard sqlite3_step(stmt) == SQLITE_DONE else { return nil }
        return Int(sqlite3_last_insert_rowid(db))
    }

    func updateFlashcard(id: Int, question: String, answer: String, hint: String? = nil, notes: String? = nil, radical: String? = nil, phonetic: String? = nil) -> Bool {
        guard let db = db else { return false }
        let sql = "UPDATE vocabularies SET question = ?, answer = ?, hint = ?, notes = ?, radical = ?, phonetic = ? WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (question as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (answer as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, ((hint ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, ((notes ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 5, ((radical ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 6, ((phonetic ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 7, Int32(id))
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    func deleteFlashcard(id: Int) -> Bool {
        guard let db = db else { return false }
        let sql = "DELETE FROM vocabularies WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(id))
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    // MARK: - Topic CRUD

    func insertTopic(subjectId: Int, name: String) -> Int? {
        guard let db = db else { return nil }
        let maxOrder = getMaxSortOrderForTopic(subjectId: subjectId)
        let sql = "INSERT INTO topics (name, subject_id, sort_order, is_user_created) VALUES (?, ?, ?, 1)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(subjectId))
        sqlite3_bind_int(stmt, 3, Int32(maxOrder + 1))
        guard sqlite3_step(stmt) == SQLITE_DONE else { return nil }
        return Int(sqlite3_last_insert_rowid(db))
    }

    private func getMaxSortOrderForTopic(subjectId: Int) -> Int {
        guard db != nil else { return 0 }
        let sql = "SELECT COALESCE(MAX(sort_order), 0) FROM topics WHERE subject_id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(subjectId))
        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        return 0
    }

    func updateTopic(id: Int, name: String) -> Bool {
        guard let db = db else { return false }
        let sql = "UPDATE topics SET name = ? WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(id))
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    func deleteTopic(id: Int) -> Bool {
        guard let db = db else { return false }
        let sql = "DELETE FROM topics WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(id))
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    // MARK: - CSV Export / Import

    func exportFlashcardsToCSV(topicId: Int? = nil) -> String {
        guard db != nil else { return "" }
        var sql = "SELECT v.id, v.topic_id, t.name as topic_name, s.name as subject_name, v.question, v.answer, v.hint, v.notes, v.radical, v.phonetic FROM vocabularies v JOIN topics t ON v.topic_id = t.id JOIN subjects s ON t.subject_id = s.id"
        if topicId != nil {
            sql += " WHERE v.topic_id = ?"
        }
        sql += " ORDER BY s.name, t.sort_order, v.id"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return "" }
        defer { sqlite3_finalize(stmt) }
        if let tid = topicId {
            sqlite3_bind_int(stmt, 1, Int32(tid))
        }
        var rows: [[String]] = []
        let header = ["id", "topic_id", "topic_name", "subject_name", "question", "answer", "hint", "notes", "radical", "phonetic"]
        rows.append(header)
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let topicId = Int(sqlite3_column_int(stmt, 1))
            let topicName = String(cString: sqlite3_column_text(stmt, 2))
            let subjectName = String(cString: sqlite3_column_text(stmt, 3))
            let question = String(cString: sqlite3_column_text(stmt, 4))
            let answer = String(cString: sqlite3_column_text(stmt, 5))
            let hint = sqlite3_column_text(stmt, 6).map { String(cString: $0) } ?? ""
            let notes = sqlite3_column_text(stmt, 7).map { String(cString: $0) } ?? ""
            let radical = sqlite3_column_text(stmt, 8).map { String(cString: $0) } ?? ""
            let phonetic = sqlite3_column_text(stmt, 9).map { String(cString: $0) } ?? ""
            rows.append([String(id), String(topicId), topicName, subjectName, escapeCSV(question), escapeCSV(answer), escapeCSV(hint), escapeCSV(notes), escapeCSV(radical), escapeCSV(phonetic)])
        }
        return rows.map { $0.joined(separator: ",") }.joined(separator: "\n")
    }

    private func escapeCSV(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }

    func importFlashcardsFromCSV(_ csv: String, topicId: Int) -> (imported: Int, errors: [String]) {
        guard db != nil else { return (0, ["Cơ sở dữ liệu chưa mở."]) }
        let lines = csv.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count >= 2 else { return (0, ["File CSV không hợp lệ hoặc trống."]) }
        var imported = 0
        var errors: [String] = []
        let headers = parseCSVLine(lines[0]).map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        func col(_ name: String, _ fallback: Int) -> Int {
            headers.firstIndex(where: { $0 == name }) ?? fallback
        }
        let qIdx = col("question", 4)
        let aIdx = col("answer", 5)
        let hIdx = col("hint", 6)
        let nIdx = col("notes", 7)
        let rIdx = col("radical", 8)
        let pIdx = col("phonetic", 9)
        for (i, line) in lines.dropFirst().enumerated() {
            let cols = parseCSVLine(line)
            guard cols.count > max(qIdx, aIdx) else {
                errors.append("Dòng \(i + 2): thiếu cột.")
                continue
            }
            let question = cols[qIdx].trimmingCharacters(in: .whitespaces)
            let answer = cols[aIdx].trimmingCharacters(in: .whitespaces)
            guard !question.isEmpty, !answer.isEmpty else {
                errors.append("Dòng \(i + 2): question và answer không được trống.")
                continue
            }
            let hint = (hIdx < cols.count) ? cols[hIdx].trimmingCharacters(in: .whitespaces) : nil
            let notes = (nIdx < cols.count) ? cols[nIdx].trimmingCharacters(in: .whitespaces) : nil
            let radical = (rIdx < cols.count) ? cols[rIdx].trimmingCharacters(in: .whitespaces) : nil
            let phonetic = (pIdx < cols.count) ? cols[pIdx].trimmingCharacters(in: .whitespaces) : nil
            if let _ = insertFlashcard(topicId: topicId, question: question, answer: answer, hint: hint, notes: notes, radical: radical, phonetic: phonetic) {
                imported += 1
            } else {
                errors.append("Dòng \(i + 2): không thể thêm.")
            }
        }
        return (imported, errors)
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for c in line {
            if c == "\"" {
                inQuotes.toggle()
            } else if (c == "," && !inQuotes) {
                result.append(current)
                current = ""
            } else {
                current.append(c)
            }
        }
        result.append(current)
        return result
    }
}
