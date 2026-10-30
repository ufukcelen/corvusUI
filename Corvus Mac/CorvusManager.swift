//
//  CorvusManager.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI
import Foundation
import Combine
import AppKit

@MainActor
final class CorvusManager: ObservableObject {
    static let shared = CorvusManager()
    
    // MARK: - Constants
    let firebaseBaseURL = "https://tellal-otomasyon-default-rtdb.europe-west1.firebasedatabase.app/tellal_db"
    let ntfyCalendarTopic = "tellal_takvim_sync_u_y_8832"
    let ntfyChatTopic = "tellal_chat_sync_u_y_8832"
    let appVersion = "0.1.1"
    let engineVersion = "1.5.0"
    
    // MARK: - Published Properties
    @Published var currentUser: CorvusUser = .ufuk {
        didSet {
            UserDefaults.standard.set(currentUser.rawValue, forKey: "CorvusActiveUserId")
            saveLocalUser()
        }
    }
    
    // Theme Mode
    @Published var appThemeMode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(appThemeMode.rawValue, forKey: "CorvusAppThemeMode")
        }
    }
    
    @Published var calendarItems: [CalendarItem] = []
    @Published var chatMessages: [ChatMessage] = []
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date? = nil
    
    // Process Execution & Logs
    @Published var consoleLogs: [ProcessLogItem] = []
    @Published var isRunningTask: Bool = false
    @Published var currentTaskTitle: String? = nil
    private var activeProcess: Process?
    
    // System Settings & Status
    @Published var corvusProjectPath: String {
        didSet {
            UserDefaults.standard.set(corvusProjectPath, forKey: "CorvusProjectPath")
            checkSystemHealth()
        }
    }
    
    @Published var pythonExecutablePath: String {
        didSet {
            UserDefaults.standard.set(pythonExecutablePath, forKey: "CorvusPythonPath")
            checkSystemHealth()
        }
    }
    
    @Published var aerenderFound: Bool = false
    @Published var aerenderPath: String = ""
    @Published var photoshopFound: Bool = false
    @Published var photoshopAppName: String = ""
    @Published var apiKeyFound: Bool = false
    
    // Software & Submodule Engine Updates
    @Published var isUpdatingSubmodule: Bool = false
    @Published var submoduleUpdateStatus: String? = nil
    @Published var isCheckingForUpdates: Bool = false
    @Published var updateCheckResult: String? = nil
    @Published var latestAppCommit: String? = nil
    @Published var latestCliCommit: String? = nil
    @Published var lastUpdateCheckDate: Date? = nil
    
    // Notifications
    @Published var latestNotificationText: String?
    @Published var latestNotificationSender: String?
    private var lastCheckedNotificationTimestamp: Int = 0
    
    // Background polling timer
    private var pollTimer: Timer?
    
    // MARK: - Init
    init() {
        // Load user
        let savedUser = UserDefaults.standard.string(forKey: "CorvusActiveUserId") ?? "1"
        self.currentUser = CorvusUser(rawValue: savedUser) ?? .ufuk
        
        // Load theme
        let savedTheme = UserDefaults.standard.string(forKey: "CorvusAppThemeMode") ?? "obsidian"
        self.appThemeMode = AppThemeMode(rawValue: savedTheme) ?? .obsidian
        
        // Load project path with smart discovery (Submodule > App Support > Dev Folder > Saved)
        self.corvusProjectPath = Self.detectBestProjectPath()
        
        // Smart python path detection
        let pythonCandidates = [
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]
        let defaultPython = pythonCandidates.first { FileManager.default.fileExists(atPath: $0) } ?? "/usr/bin/python3"
        self.pythonExecutablePath = UserDefaults.standard.string(forKey: "CorvusPythonPath") ?? defaultPython
        
        // Initial health check
        checkSystemHealth()
        
        // Initial sync
        Task {
            await syncAll()
            startPolling()
            await checkForUpdates()
        }
    }
    
    deinit {
        pollTimer?.invalidate()
    }
    
    // MARK: - Smart Path Detection
    static func detectBestProjectPath() -> String {
        // 1. Saved custom path in UserDefaults (if valid)
        if let saved = UserDefaults.standard.string(forKey: "CorvusProjectPath"),
           FileManager.default.fileExists(atPath: (saved as NSString).appendingPathComponent("corvus.py")) {
            return saved
        }
        
        // 2. Submodule inside local developer repository (CorvusEngine)
        let candidateDevSubmodules = [
            "/Users/ufukcelen/Desktop/Dev/CorvusUI/Corvus Mac/CorvusEngine",
            NSHomeDirectory() + "/Desktop/Dev/CorvusUI/Corvus Mac/CorvusEngine",
            "/Users/ufukcelen/Desktop/The Projeler/Duyurular/Youtube Duyuru Otomasyon"
        ]
        for p in candidateDevSubmodules {
            if FileManager.default.fileExists(atPath: (p as NSString).appendingPathComponent("corvus.py")) {
                return p
            }
        }
        
        // 3. Application Support Corvus Engine (Writable directory for distributed app)
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Corvus/Engine")
        if let appSupportPath = appSupportDir?.path,
           FileManager.default.fileExists(atPath: (appSupportPath as NSString).appendingPathComponent("corvus.py")) {
            return appSupportPath
        }
        
        // 4. Bundled inside .app Resources/CorvusEngine -> copy to Application Support for write access
        if let bundleEnginePath = Bundle.main.path(forResource: "CorvusEngine", ofType: nil),
           let appSupportDir = appSupportDir {
            let targetPath = appSupportDir.path
            if !FileManager.default.fileExists(atPath: targetPath) {
                try? FileManager.default.createDirectory(at: appSupportDir.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? FileManager.default.copyItem(atPath: bundleEnginePath, toPath: targetPath)
                if FileManager.default.fileExists(atPath: (targetPath as NSString).appendingPathComponent("corvus.py")) {
                    return targetPath
                }
            }
            return bundleEnginePath
        }
        
        return NSHomeDirectory() + "/Desktop"
    }
    
    // MARK: - Software & Submodule Updates
    func checkForUpdates() async {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        updateCheckResult = "GitHub güncellemeleri taranıyor..."
        
        defer {
            isCheckingForUpdates = false
            lastUpdateCheckDate = Date()
        }
        
        // 1. Fetch Corvus Mac UI latest commit
        if let url = URL(string: "https://api.github.com/repos/ufukcelen/corvusUI/commits/main"),
           let (data, _) = try? await URLSession.shared.data(from: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let commit = json["commit"] as? [String: Any],
           let message = commit["message"] as? String {
            let firstLine = message.components(separatedBy: .newlines).first ?? message
            let author = (commit["author"] as? [String: Any])?["name"] as? String ?? "Ufuk"
            self.latestAppCommit = "\(firstLine) (\(author))"
        }
        
        // 2. Fetch Corvus Engine CLI latest commit
        if let url = URL(string: "https://api.github.com/repos/ufukcelen/Corvus/commits/main"),
           let (data, _) = try? await URLSession.shared.data(from: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let commit = json["commit"] as? [String: Any],
           let message = commit["message"] as? String {
            let firstLine = message.components(separatedBy: .newlines).first ?? message
            let author = (commit["author"] as? [String: Any])?["name"] as? String ?? "Ufuk"
            self.latestCliCommit = "\(firstLine) (\(author))"
        }
        
        updateCheckResult = "✓ GitHub bağlantısı kuruldu. En son sürümler denetlendi."
    }
    
    func updateAllComponents() {
        guard !isUpdatingSubmodule else { return }
        isUpdatingSubmodule = true
        submoduleUpdateStatus = "Tüm güncellemeler çekiliyor..."
        
        Task.detached(priority: .userInitiated) {
            var logLines: [String] = []
            let engineDir = await self.corvusProjectPath
            let gitPath = "/usr/bin/git"
            
            // 1. Pull CLI Submodule
            if FileManager.default.fileExists(atPath: (engineDir as NSString).appendingPathComponent(".git")) {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: gitPath)
                proc.arguments = ["-C", engineDir, "pull", "origin", "main"]
                let pipe = Pipe()
                proc.standardOutput = pipe
                proc.standardError = pipe
                try? proc.run()
                proc.waitUntilExit()
                let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                logLines.append("[CLI Çekirdeği] " + (out.isEmpty ? "Güncel" : out.trimmingCharacters(in: .whitespacesAndNewlines)))
            } else {
                // Standalone fallback: Download latest corvus.py from GitHub
                if let rawUrl = URL(string: "https://raw.githubusercontent.com/ufukcelen/Corvus/main/corvus.py"),
                   let (data, res) = try? await URLSession.shared.data(from: rawUrl),
                   (res as? HTTPURLResponse)?.statusCode == 200 {
                    let targetPath = (engineDir as NSString).appendingPathComponent("corvus.py")
                    try? data.write(to: URL(fileURLWithPath: targetPath))
                    logLines.append("[CLI Çekirdeği] corvus.py GitHub'dan doğrudan indirildi.")
                }
            }
            
            // 2. Pull App UI Repo (if git exists)
            let appDir = "/Users/ufukcelen/Desktop/Dev/CorvusUI/Corvus Mac"
            if FileManager.default.fileExists(atPath: (appDir as NSString).appendingPathComponent(".git")) {
                let proc2 = Process()
                proc2.executableURL = URL(fileURLWithPath: gitPath)
                proc2.arguments = ["-C", appDir, "pull", "origin", "main"]
                let pipe2 = Pipe()
                proc2.standardOutput = pipe2
                proc2.standardError = pipe2
                try? proc2.run()
                proc2.waitUntilExit()
                let out2 = String(data: pipe2.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                logLines.append("[Corvus Mac UI] " + (out2.isEmpty ? "Güncel" : out2.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
            
            await MainActor.run {
                self.isUpdatingSubmodule = false
                self.submoduleUpdateStatus = "✓ Tüm bileşenler başarıyla güncellendi!"
                for line in logLines {
                    self.consoleLogs.append(ProcessLogItem(text: line, isError: false, isProgress: false))
                }
                self.checkSystemHealth()
            }
        }
    }
    
    func updateSubmoduleEngine() {
        updateAllComponents()
    }
    
    // MARK: - Polling
    func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.syncAll(silent: true)
                await self.checkIncomingNotifications()
            }
        }
    }
    
    // MARK: - Health Check
    func checkSystemHealth() {
        // Aerender
        let aeCandidates = [
            "/Applications/Adobe After Effects 2026/aerender",
            "/Applications/Adobe After Effects 2025/aerender",
            "/Applications/Adobe After Effects 2024/aerender"
        ]
        var foundAe = false
        for p in aeCandidates {
            if FileManager.default.fileExists(atPath: p) {
                aerenderPath = p
                foundAe = true
                break
            }
        }
        aerenderFound = foundAe
        
        // Photoshop
        let psCandidates = [
            "/Applications/Adobe Photoshop 2026",
            "/Applications/Adobe Photoshop 2025",
            "/Applications/Adobe Photoshop 2024"
        ]
        var foundPs = false
        for p in psCandidates {
            if FileManager.default.fileExists(atPath: p) {
                photoshopAppName = (p as NSString).lastPathComponent
                foundPs = true
                break
            }
        }
        photoshopFound = foundPs
        
        // API key
        let apiFile = (corvusProjectPath as NSString).appendingPathComponent("api.txt")
        apiKeyFound = FileManager.default.fileExists(atPath: apiFile)
    }
    
    // MARK: - Local Files Sync
    private func saveLocalUser() {
        let userFile = (corvusProjectPath as NSString).appendingPathComponent("user.txt")
        try? currentUser.rawValue.write(toFile: userFile, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Sync All
    func syncAll(silent: Bool = false) async {
        if !silent { isSyncing = true }
        async let cal = syncCalendar()
        async let ch = syncChat()
        _ = await (cal, ch)
        lastSyncDate = Date()
        if !silent { isSyncing = false }
    }
    
    // MARK: - Calendar Sync (Firebase RTDB + Local File)
    func syncCalendar() async {
        guard let url = URL(string: "\(firebaseBaseURL)/takvim.json") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            var remoteLines: [String] = []
            if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let isBos = jsonObj["bos_mu"] as? Bool, isBos {
                    remoteLines = []
                } else if let satirlar = jsonObj["satirlar"] as? [String] {
                    remoteLines = satirlar
                } else if let satirlarDict = jsonObj["satirlar"] as? [String: String] {
                    remoteLines = Array(satirlarDict.values)
                }
            } else if let arr = try? JSONSerialization.jsonObject(with: data) as? [String] {
                remoteLines = arr
            }
            
            // Filter out Gemini AI entries
            let cleanLines = remoteLines.filter { line in
                let l = line.trimmingCharacters(in: .whitespaces)
                return !l.contains("Gemini AI") && !l.contains("[Gemini AI]") && !l.hasPrefix("Gemini AI:")
            }
            
            let parsed = cleanLines.enumerated().map { (idx, line) in
                CalendarItem(rawText: line, fallbackIndex: idx + 1)
            }
            
            self.calendarItems = parsed
            
            // Sync to local takvim.txt
            let localPath = (corvusProjectPath as NSString).appendingPathComponent("takvim.txt")
            let localContent = cleanLines.joined(separator: "\n") + (cleanLines.isEmpty ? "" : "\n")
            try? localContent.write(toFile: localPath, atomically: true, encoding: .utf8)
            
        } catch {
            // Fallback: read local takvim.txt
            let localPath = (corvusProjectPath as NSString).appendingPathComponent("takvim.txt")
            if let content = try? String(contentsOfFile: localPath, encoding: .utf8) {
                let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                self.calendarItems = lines.enumerated().map { CalendarItem(rawText: $0.element, fallbackIndex: $0.offset + 1) }
            }
        }
    }
    
    func saveCalendar(lines: [String]) async {
        // 1. Write local takvim.txt
        let localPath = (corvusProjectPath as NSString).appendingPathComponent("takvim.txt")
        let content = lines.joined(separator: "\n") + (lines.isEmpty ? "" : "\n")
        try? content.write(toFile: localPath, atomically: true, encoding: .utf8)
        
        // 2. Upload to Firebase RTDB
        guard let url = URL(string: "\(firebaseBaseURL)/takvim.json") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "satirlar": lines,
            "bos_mu": lines.isEmpty,
            "son_guncelleme": Int(Date().timeIntervalSince1970),
            "guncelleyen": currentUser.name
        ]
        
        if let body = try? JSONSerialization.data(withJSONObject: payload) {
            request.httpBody = body
            _ = try? await URLSession.shared.data(for: request)
        }
        
        // 3. Ntfy broadcast
        let ntfyUrl = URL(string: "https://ntfy.sh")!
        var ntfyReq = URLRequest(url: ntfyUrl)
        ntfyReq.httpMethod = "POST"
        ntfyReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let ntfyMsg = lines.isEmpty ? "__BOS_TAKVIM__" : lines.joined(separator: "\n")
        let ntfyPayload: [String: Any] = [
            "topic": ntfyCalendarTopic,
            "title": "Corvus Takvim Güncellemesi",
            "message": ntfyMsg,
            "priority": 3,
            "tags": ["calendar"]
        ]
        if let ntfyBody = try? JSONSerialization.data(withJSONObject: ntfyPayload) {
            ntfyReq.httpBody = ntfyBody
            _ = try? await URLSession.shared.data(for: ntfyReq)
        }
        
        // Re-sync
        await syncCalendar()
    }
    
    // MARK: - Calendar Operations
    func addBroadcast(program: String, day: String, time: String, info: String?) async {
        var existing = calendarItems.map { $0.formattedRawLine() }
        let nextNo = existing.count + 1
        var newLine = "\(nextNo)-) \(program) - \(day) - \(time)"
        if let info = info, !info.trimmingCharacters(in: .whitespaces).isEmpty {
            newLine += " | Bilgi: \(info.trimmingCharacters(in: .whitespaces))"
        }
        existing.append(newLine)
        await saveCalendar(lines: existing)
    }
    
    func cancelBroadcast(item: CalendarItem) async {
        var updatedLines: [String] = []
        for (idx, existing) in calendarItems.enumerated() {
            var copy = existing
            if existing.id == item.id {
                copy.isCancelled.toggle()
                if copy.isCancelled { copy.isDone = false }
            }
            updatedLines.append(copy.formattedRawLine(newIndex: idx + 1))
        }
        await saveCalendar(lines: updatedLines)
    }
    
    func toggleDone(item: CalendarItem) async {
        var updatedLines: [String] = []
        for (idx, existing) in calendarItems.enumerated() {
            var copy = existing
            if existing.id == item.id {
                copy.isDone.toggle()
                if copy.isDone { copy.isCancelled = false }
            }
            updatedLines.append(copy.formattedRawLine(newIndex: idx + 1))
        }
        await saveCalendar(lines: updatedLines)
    }
    
    func deleteBroadcast(item: CalendarItem) async {
        let filtered = calendarItems.filter { $0.id != item.id }
        let reindexed = filtered.enumerated().map { (idx, it) in
            it.formattedRawLine(newIndex: idx + 1)
        }
        await saveCalendar(lines: reindexed)
    }
    
    func clearAllBroadcasts() async {
        await saveCalendar(lines: [])
    }
    
    // MARK: - Chat Sync (Firebase RTDB + Local File)
    func syncChat() async {
        guard let url = URL(string: "\(firebaseBaseURL)/chat.json") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            var remoteLines: [String] = []
            if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let raw = jsonObj["mesajlar"] as? [String] {
                    remoteLines = raw
                } else if let rawDict = jsonObj["mesajlar"] as? [String: String] {
                    remoteLines = Array(rawDict.values)
                }
            } else if let arr = try? JSONSerialization.jsonObject(with: data) as? [String] {
                remoteLines = arr
            }
            
            // Clean bot messages
            let cleanLines = remoteLines.filter { line in
                let l = line.trimmingCharacters(in: .whitespaces)
                return !l.contains("Gemini AI") && !l.hasPrefix("Gemini AI:") && !(l.contains("🤖") && l.contains("Gemini"))
            }
            
            let parsed = cleanLines.map { ChatMessage(rawText: $0) }
            
            // Audio chime if new message from other user
            if parsed.count > self.chatMessages.count && !self.chatMessages.isEmpty {
                if let last = parsed.last, last.sender != currentUser.name {
                    NSSound(named: "Glass")?.play()
                }
            }
            
            self.chatMessages = parsed
            
            // Save local chat.txt
            let localPath = (corvusProjectPath as NSString).appendingPathComponent("chat.txt")
            let content = cleanLines.joined(separator: "\n") + (cleanLines.isEmpty ? "" : "\n")
            try? content.write(toFile: localPath, atomically: true, encoding: .utf8)
            
        } catch {
            // Local fallback
            let localPath = (corvusProjectPath as NSString).appendingPathComponent("chat.txt")
            if let content = try? String(contentsOfFile: localPath, encoding: .utf8) {
                let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                self.chatMessages = lines.map { ChatMessage(rawText: $0) }
            }
        }
    }
    
    func sendMessage(_ text: String) async {
        let cleanText = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
        guard !cleanText.isEmpty else { return }
        
        let newLine = "\(currentUser.name): \(cleanText)"
        var updated = chatMessages.map { $0.rawText }
        updated.append(newLine)
        if updated.count > 60 {
            updated = Array(updated.suffix(60))
        }
        
        // Write local
        let localPath = (corvusProjectPath as NSString).appendingPathComponent("chat.txt")
        let content = updated.joined(separator: "\n") + "\n"
        try? content.write(toFile: localPath, atomically: true, encoding: .utf8)
        
        // Upload Firebase
        guard let url = URL(string: "\(firebaseBaseURL)/chat.json") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "mesajlar": updated,
            "son_guncelleme": Int(Date().timeIntervalSince1970)
        ]
        if let body = try? JSONSerialization.data(withJSONObject: payload) {
            request.httpBody = body
            _ = try? await URLSession.shared.data(for: request)
        }
        
        // Ntfy
        let ntfyUrl = URL(string: "https://ntfy.sh")!
        var ntfyReq = URLRequest(url: ntfyUrl)
        ntfyReq.httpMethod = "POST"
        ntfyReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let ntfyPayload: [String: Any] = [
            "topic": ntfyChatTopic,
            "title": "Corvus Chat - \(currentUser.name)",
            "message": content,
            "priority": 3,
            "tags": ["speech_balloon"]
        ]
        if let ntfyBody = try? JSONSerialization.data(withJSONObject: ntfyPayload) {
            ntfyReq.httpBody = ntfyBody
            _ = try? await URLSession.shared.data(for: ntfyReq)
        }
        
        await syncChat()
    }
    
    func clearChat() async {
        let localPath = (corvusProjectPath as NSString).appendingPathComponent("chat.txt")
        try? "".write(toFile: localPath, atomically: true, encoding: .utf8)
        
        guard let url = URL(string: "\(firebaseBaseURL)/chat.json") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "mesajlar": [],
            "son_guncelleme": Int(Date().timeIntervalSince1970)
        ]
        if let body = try? JSONSerialization.data(withJSONObject: payload) {
            request.httpBody = body
            _ = try? await URLSession.shared.data(for: request)
        }
        
        // Ntfy
        let ntfyUrl = URL(string: "https://ntfy.sh")!
        var ntfyReq = URLRequest(url: ntfyUrl)
        ntfyReq.httpMethod = "POST"
        ntfyReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let ntfyPayload: [String: Any] = [
            "topic": ntfyChatTopic,
            "title": "Corvus Chat",
            "message": "__BOS_CHAT__",
            "priority": 3,
            "tags": ["speech_balloon"]
        ]
        if let ntfyBody = try? JSONSerialization.data(withJSONObject: ntfyPayload) {
            ntfyReq.httpBody = ntfyBody
            _ = try? await URLSession.shared.data(for: ntfyReq)
        }
        
        await syncChat()
    }
    
    // MARK: - Notifications (Ntfy)
    func checkIncomingNotifications() async {
        let topic = currentUser.receiveNotificationTopic
        let since = lastCheckedNotificationTimestamp > 0 ? "\(lastCheckedNotificationTimestamp + 1)" : "all"
        guard let url = URL(string: "https://ntfy.sh/\(topic)/json?poll=1&since=\(since)") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }
            
            for line in text.components(separatedBy: .newlines) {
                guard let lineData = line.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                      let event = json["event"] as? String, event == "message" else { continue }
                
                let time = json["time"] as? Int ?? 0
                if time > lastCheckedNotificationTimestamp {
                    lastCheckedNotificationTimestamp = time
                    if let msg = json["message"] as? String {
                        self.latestNotificationText = msg
                        self.latestNotificationSender = currentUser.otherUser.name
                        
                        // Local macOS User Notification
                        deliverMacNotification(title: "Corvus - \(currentUser.otherUser.name)", body: msg)
                    }
                }
            }
        } catch {}
    }
    
    func sendNotification(message: String, priority: Int = 4) async -> Bool {
        let clean = message.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return false }
        
        guard let url = URL(string: "https://ntfy.sh") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "topic": currentUser.sendNotificationTopic,
            "title": "Corvus - \(currentUser.name)",
            "message": clean,
            "priority": priority,
            "tags": ["loudspeaker", "bell"]
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return false }
        request.httpBody = body
        
        do {
            let (_, res) = try await URLSession.shared.data(for: request)
            if let http = res as? HTTPURLResponse, http.statusCode == 200 {
                return true
            }
        } catch {}
        return false
    }
    
    private func deliverMacNotification(title: String, body: String) {
        let script = "display notification \"\(body.replacingOccurrences(of: "\"", with: "'"))\" with title \"\(title)\" sound name \"Glass\""
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        try? proc.run()
    }
    
    // MARK: - Process Execution (Bridge Runner)
    func runBridgeTask(arguments: [String], title: String) {
        guard !isRunningTask else { return }
        
        isRunningTask = true
        currentTaskTitle = title
        consoleLogs.append(ProcessLogItem(text: "========== \(title) Başlatıldı ==========", isError: false, isProgress: false))
        
        let bridgeScript = Bundle.main.path(forResource: "corvus_bridge", ofType: "py") ??
            (corvusProjectPath as NSString).appendingPathComponent("corvus_bridge.py")
        
        // If not in bundle or project dir, use our workspace copy
        let effectiveBridge = FileManager.default.fileExists(atPath: bridgeScript) ? bridgeScript :
            "/Users/ufukcelen/Desktop/Dev/CorvusUI/Corvus Mac/Corvus Mac/corvus_bridge.py"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonExecutablePath)
        
        var allArgs = [effectiveBridge, "--dir", corvusProjectPath]
        allArgs.append(contentsOf: arguments)
        process.arguments = allArgs
        
        // Set environment
        var env = ProcessInfo.processInfo.environment
        env["PYTHONUNBUFFERED"] = "1"
        process.environment = env
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        activeProcess = process
        
        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                for line in str.components(separatedBy: .newlines) where !line.isEmpty {
                    let isProg = line.contains("PROGRESS:") || line.contains("%")
                    self.consoleLogs.append(ProcessLogItem(text: line, isError: false, isProgress: isProg))
                }
            }
        }
        
        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                for line in str.components(separatedBy: .newlines) where !line.isEmpty {
                    self.consoleLogs.append(ProcessLogItem(text: line, isError: true, isProgress: false))
                }
            }
        }
        
        process.terminationHandler = { [weak self] proc in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isRunningTask = false
                let code = proc.terminationStatus
                if code == 0 {
                    self.consoleLogs.append(ProcessLogItem(text: "✓ [BAŞARILI] İşlem tamamlandı (Kod 0).", isError: false, isProgress: false))
                    NSSound(named: "Glass")?.play()
                } else {
                    self.consoleLogs.append(ProcessLogItem(text: "✗ [HATA] İşlem sonlandı (Çıkış Kodu: \(code)).", isError: true, isProgress: false))
                }
                self.activeProcess = nil
                self.currentTaskTitle = nil
                
                // Re-sync after any task run
                await self.syncAll()
            }
        }
        
        do {
            try process.run()
        } catch {
            isRunningTask = false
            currentTaskTitle = nil
            consoleLogs.append(ProcessLogItem(text: "✗ Süreç başlatılamadı: \(error.localizedDescription)", isError: true, isProgress: false))
        }
    }
    
    func terminateActiveTask() {
        activeProcess?.terminate()
        isRunningTask = false
        currentTaskTitle = nil
        consoleLogs.append(ProcessLogItem(text: "⚠️ Kullanıcı tarafından durduruldu.", isError: true, isProgress: false))
    }
    
    func clearConsole() {
        consoleLogs.removeAll()
    }
    
    // MARK: - Dynamic Days
    func getDynamicNext7Days() -> [(label: String, value: String)] {
        let calendar = Calendar.current
        let today = Date()
        let dayNames = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]
        
        var results: [(String, String)] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                let weekday = calendar.component(.weekday, from: date)
                // Sunday is 1 in Apple calendar -> index 6
                let trIndex = (weekday + 5) % 7
                let dayName = dayNames[trIndex]
                
                if i == 0 {
                    results.append(("Bugün (\(dayName))", "Bugün (\(dayName))"))
                } else {
                    results.append((dayName, dayName))
                }
            }
        }
        return results
    }
}
