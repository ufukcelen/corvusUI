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
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.2.2"
    }
    let engineVersion = "1.5.1"
    
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
    private var activeStdoutPipe: Pipe?
    private var activeStderrPipe: Pipe?
    
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
    @Published var latestAppTag: String? = nil
    @Published var isNewAppVersionAvailable: Bool = false
    @Published var isAutoUpdating: Bool = false
    @Published var autoUpdateStatus: String? = nil
    
    // Notifications
    @Published var latestNotificationText: String?
    @Published var latestNotificationSender: String?
    private var lastCheckedNotificationTimestamp: Int = 0
    
    // Background polling timer
    private var pollTimer: Timer?
    

    // MARK: - Render Cache & Cleaner
    @Published var renderCacheFolderPath: String {
        didSet {
            UserDefaults.standard.set(renderCacheFolderPath, forKey: "CorvusRenderCacheFolderPath")
            scanRenderCache()
        }
    }
    @Published var renderCacheTotalSizeBytes: Int64 = 0
    @Published var renderCacheFileCount: Int = 0
    @Published var renderCacheItems: [RenderCacheItem] = []
    @Published var isScanningRenderCache: Bool = false
    @Published var isCleaningRenderCache: Bool = false
    @Published var lastCleanedStatus: String? = nil

    // MARK: - Init
    init() {
        // Load user
        let savedUser = UserDefaults.standard.string(forKey: "CorvusActiveUserId") ?? "1"
        self.currentUser = CorvusUser(rawValue: savedUser) ?? .ufuk
        
        // Load theme
        let savedTheme = UserDefaults.standard.string(forKey: "CorvusAppThemeMode") ?? "obsidian"
        self.appThemeMode = AppThemeMode(rawValue: savedTheme) ?? .obsidian
        // Render Cache Folder (default to Desktop)
        let defaultRenderFolder = UserDefaults.standard.string(forKey: "CorvusRenderCacheFolderPath") ??
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").path
        self.renderCacheFolderPath = defaultRenderFolder

        
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
            cleanupLegacyAssets()
            await syncAll()
            startPolling()
            await checkForUpdates()
            scanRenderCache()
        }
    }
    
    deinit {
        pollTimer?.invalidate()
    }
    
    // MARK: - Smart Path Detection
    static func detectBestProjectPath() -> String {
        // 1. Saved custom path in UserDefaults (if valid and not Application Support directory)
        if let saved = UserDefaults.standard.string(forKey: "CorvusProjectPath"),
           !saved.contains("Library/Application Support/Corvus"),
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
        
        // 3. Application Support Corvus Engine (Sync with app bundle on each launch)
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Corvus/Engine")
        if let bundleEnginePath = Bundle.main.path(forResource: "CorvusEngine", ofType: nil),
           let appSupportDir = appSupportDir {
            let targetPath = appSupportDir.path
            let bundleCorvusPy = (bundleEnginePath as NSString).appendingPathComponent("corvus.py")
            let targetCorvusPy = (targetPath as NSString).appendingPathComponent("corvus.py")
            
            if !FileManager.default.fileExists(atPath: targetPath) {
                try? FileManager.default.createDirectory(at: appSupportDir.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? FileManager.default.copyItem(atPath: bundleEnginePath, toPath: targetPath)
            } else {
                // ALWAYS recursively synchronize all bundle engine scripts, project templates, and assets into Application Support
                Self.syncEngineDirectory(from: bundleEnginePath, to: targetPath)
            }
            if FileManager.default.fileExists(atPath: (targetPath as NSString).appendingPathComponent("corvus.py")) {
                return targetPath
            }
            return bundleEnginePath
        }
        
        if let appSupportPath = appSupportDir?.path,
           FileManager.default.fileExists(atPath: (appSupportPath as NSString).appendingPathComponent("corvus.py")) {
            return appSupportPath
        }
        
        return NSHomeDirectory() + "/Desktop"
    }
    
    // Recursively sync engine files from App Bundle into Application Support
    nonisolated static func syncEngineDirectory(from srcDir: String, to dstDir: String) {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(atPath: srcDir) else { return }
        try? fm.createDirectory(atPath: dstDir, withIntermediateDirectories: true)
        
        for item in items {
            if item == ".git" || item == "__pycache__" || item.hasSuffix(".pyc") || item == ".DS_Store" { continue }
            let src = (srcDir as NSString).appendingPathComponent(item)
            let dst = (dstDir as NSString).appendingPathComponent(item)
            
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: src, isDirectory: &isDir) {
                if isDir.boolValue {
                    syncEngineDirectory(from: src, to: dst)
                } else {
                    let shouldUpdate = item.hasSuffix(".py") || item.hasSuffix(".sh") || item.hasSuffix(".command") || !fm.fileExists(atPath: dst)
                    if shouldUpdate {
                        try? fm.removeItem(atPath: dst)
                        try? fm.copyItem(atPath: src, toPath: dst)
                    }
                }
            }
        }
    }

    // MARK: - Legacy Cleanup & Maintenance
    func cleanupLegacyAssets() {
        let fm = FileManager.default
        var cleanedCount = 0
        var freedBytes: Int64 = 0
        
        // 1. Scan Application Support / Corvus for legacy .aep, large video caches, logs
        if let appSupportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Corvus") {
            let legacyFolders = [
                appSupportDir.appendingPathComponent("Engine/Albert"),
                appSupportDir.appendingPathComponent("Engine/Mocas Bey"),
                appSupportDir.appendingPathComponent("Engine/FC Kariyer Duyuru"),
                appSupportDir.appendingPathComponent("Engine/Memleket Duyuru"),
                appSupportDir.appendingPathComponent("Engine/Bfü Duyuru Projesi"),
                appSupportDir.appendingPathComponent("Engine/Tekmaç"),
            ]
            
            for folder in legacyFolders {
                if fm.fileExists(atPath: folder.path) {
                    if let size = try? folder.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        freedBytes += Int64(size)
                    }
                    try? fm.removeItem(at: folder)
                    cleanedCount += 1
                }
            }
        }
        
        // 2. Masaüstündeki hiçbir dosyaya (kullanıcının kendi PSD'leri vb. dahil) KESİNLİKLE DOKUNMAZ!
        // Sadece sistem geçici dizini (/tmp) altındaki corvus_*.jsx betiklerini temizler.
        
        // 3. Clean temporary JSX files in /tmp
        let tmpDir = URL(fileURLWithPath: "/tmp")
        if let tmpFiles = try? fm.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil) {
            for f in tmpFiles where f.lastPathComponent.hasPrefix("corvus_") && f.pathExtension == "jsx" {
                try? fm.removeItem(at: f)
            }
        }
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
        
        // 1. Fetch Corvus Mac UI latest release from GitHub
        var downloadZipUrl: URL? = nil
        var releaseTagFound: String? = nil
        
        if let releaseApiUrl = URL(string: "https://api.github.com/repos/ufukcelen/corvusUI/releases/latest"),
           let (data, response) = try? await URLSession.shared.data(from: releaseApiUrl),
           (response as? HTTPURLResponse)?.statusCode == 200,
           let releaseJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let tagName = releaseJson["tag_name"] as? String {
            releaseTagFound = tagName
            self.latestAppTag = tagName
            
            // Check for downloadable zip asset
            if let assets = releaseJson["assets"] as? [[String: Any]] {
                for asset in assets {
                    if let name = asset["name"] as? String, name.hasSuffix(".zip"),
                       let browserDownloadUrl = asset["browser_download_url"] as? String,
                       let url = URL(string: browserDownloadUrl) {
                        downloadZipUrl = url
                        break
                    }
                }
            }
        } else if let tagsUrl = URL(string: "https://api.github.com/repos/ufukcelen/corvusUI/tags"),
                  let (data, _) = try? await URLSession.shared.data(from: tagsUrl),
                  let tags = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let firstTag = tags.first,
                  let tagName = firstTag["name"] as? String {
            releaseTagFound = tagName
            self.latestAppTag = tagName
        }
        
        if let releaseTag = releaseTagFound {
            let cleanTag = releaseTag.replacingOccurrences(of: "v", with: "").trimmingCharacters(in: .whitespaces)
            let current = self.appVersion.replacingOccurrences(of: "v", with: "").trimmingCharacters(in: .whitespaces)
            if cleanTag.compare(current, options: .numeric) == .orderedDescending {
                self.isNewAppVersionAvailable = true
                
                // If a downloadable zip release asset is available, perform automatic seamless update!
                if let assetUrl = downloadZipUrl {
                    await downloadAndApplyAppUpdate(from: assetUrl, newVersion: releaseTag)
                    return
                }
            } else {
                self.isNewAppVersionAvailable = false
            }
        }
        
        // 1b. Fetch Corvus Mac UI latest commit
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
    
    func downloadAndApplyAppUpdate(from assetUrl: URL, newVersion: String) async {
        guard !isAutoUpdating else { return }
        
        await MainActor.run {
            self.isAutoUpdating = true
            self.autoUpdateStatus = "Yeni Corvus Mac sürümü (\(newVersion)) indiriliyor..."
        }
        
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("corvus_update_" + UUID().uuidString)
        let zipFile = tempDir.appendingPathComponent("CorvusUpdate.zip")
        let extractDir = tempDir.appendingPathComponent("extracted")
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Download update archive
            let (downloadedLocation, _) = try await URLSession.shared.download(from: assetUrl)
            try FileManager.default.moveItem(at: downloadedLocation, to: zipFile)
            
            await MainActor.run {
                self.autoUpdateStatus = "Paket açılıyor ve doğrulanıyor..."
            }
            
            try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)
            
            // Extract using macOS ditto (preserves all permissions and codesign)
            let dittoProcess = Process()
            dittoProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            dittoProcess.arguments = ["-xk", zipFile.path, extractDir.path]
            try dittoProcess.run()
            dittoProcess.waitUntilExit()
            
            // Locate extracted .app bundle
            var extractedAppPath: String? = nil
            let fileManager = FileManager.default
            let directApp = extractDir.appendingPathComponent("Corvus Mac.app").path
            if fileManager.fileExists(atPath: directApp) {
                extractedAppPath = directApp
            } else {
                // Search one level deep
                if let contents = try? fileManager.contentsOfDirectory(atPath: extractDir.path) {
                    for item in contents {
                        if item.hasSuffix(".app") {
                            extractedAppPath = extractDir.appendingPathComponent(item).path
                            break
                        }
                    }
                }
            }
            
            guard let newAppPath = extractedAppPath else {
                throw NSError(domain: "CorvusUpdate", code: 404, userInfo: [NSLocalizedDescriptionKey: "Güncelleme paketi içinde uygulama bulunamadı."])
            }
            
            let currentAppBundlePath = Bundle.main.bundlePath
            let currentPID = ProcessInfo.processInfo.processIdentifier
            
            // Don't self-replace if running directly from Xcode DerivedData in Debug build
            if currentAppBundlePath.contains("DerivedData") {
                await MainActor.run {
                    self.isAutoUpdating = false
                    self.autoUpdateStatus = "Geliştirici modundasınız. Son sürüm (\(newVersion)) indirildi: \(newAppPath)"
                }
                return
            }
            
            await MainActor.run {
                self.autoUpdateStatus = "Yeni sürüm kuruluyor ve Corvus Mac yeniden başlatılıyor..."
            }
            
            // Prepare independent updater script to wait for current process, replace app, and relaunch
            let scriptPath = tempDir.appendingPathComponent("update_runner.sh").path
            let updateScript = [
                "#!/bin/bash",
                "TARGET=\"\(currentAppBundlePath)\"",
                "NEW=\"\(newAppPath)\"",
                "PID=\(currentPID)",
                "while kill -0 $PID 2>/dev/null; do sleep 0.3; done",
                "rm -rf \"$TARGET\"",
                "cp -R \"$NEW\" \"$TARGET\"",
                "xattr -cr \"$TARGET\" 2>/dev/null",
                "open \"$TARGET\"",
                "rm -rf \"\(tempDir.path)\"",
                "exit 0"
            ].joined(separator: "\n")
            try updateScript.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            
            let chmodProcess = Process()
            chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodProcess.arguments = ["+x", scriptPath]
            try chmodProcess.run()
            chmodProcess.waitUntilExit()
            
            // Launch the detached background runner
            let runnerProcess = Process()
            runnerProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
            runnerProcess.arguments = [scriptPath]
            try runnerProcess.run()
            
            // Wait 500ms then terminate current instance
            try await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                NSApp.terminate(nil)
            }
            
        } catch {
            await MainActor.run {
                self.isAutoUpdating = false
                self.autoUpdateStatus = "Güncelleme hatası: \(error.localizedDescription)"
            }
        }
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
                // Standalone fallback: Download latest corvus.py & corvus_bridge.py from GitHub
                if let rawUrl = URL(string: "https://raw.githubusercontent.com/ufukcelen/Corvus/main/corvus.py"),
                   let (data, res) = try? await URLSession.shared.data(from: rawUrl),
                   (res as? HTTPURLResponse)?.statusCode == 200 {
                    let targetPath = (engineDir as NSString).appendingPathComponent("corvus.py")
                    try? data.write(to: URL(fileURLWithPath: targetPath))
                    logLines.append("[CLI Çekirdeği] corvus.py güncellendi.")
                }
                if let rawBridgeUrl = URL(string: "https://raw.githubusercontent.com/ufukcelen/Corvus/main/corvus_bridge.py"),
                   let (dataBridge, resBridge) = try? await URLSession.shared.data(from: rawBridgeUrl),
                   (resBridge as? HTTPURLResponse)?.statusCode == 200 {
                    let targetBridgePath = (engineDir as NSString).appendingPathComponent("corvus_bridge.py")
                    try? dataBridge.write(to: URL(fileURLWithPath: targetBridgePath))
                    logLines.append("[Köprü] corvus_bridge.py güncellendi.")
                }
                // Sync templates from App Bundle into Application Support
                if let bundleEngine = Bundle.main.path(forResource: "CorvusEngine", ofType: nil) {
                    Self.syncEngineDirectory(from: bundleEngine, to: engineDir)
                    logLines.append("[Paket Şablonları] Proje ve şablon varlıkları senkronize edildi.")
                }
            }
            
            // 2. Pull App UI Repo (if git exists)
            let candidateAppDirs = [
                (Bundle.main.bundlePath as NSString).deletingLastPathComponent,
                "/Users/ufukcelen/Desktop/Dev/CorvusUI/Corvus Mac"
            ]
            for appDir in candidateAppDirs {
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
                    break
                }
            }
            
            let finalLogs = logLines
            await MainActor.run {
                self.isUpdatingSubmodule = false
                if self.isNewAppVersionAvailable {
                    self.submoduleUpdateStatus = "⚠️ CLI Motoru güncellendi. Yeni Mac UI sürümü (\(self.latestAppTag ?? "v0.2.1")) için güncel DMG paketini kurmanız gerekir."
                } else {
                    self.submoduleUpdateStatus = "✓ Tüm bileşenler başarıyla güncellendi (v\(self.appVersion))!"
                }
                for line in finalLogs {
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
            "/Applications/Adobe After Effects 2027/aerender",
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
        
        // Photoshop (2027, 2026, 2025, 2024 veya dinamik tespit)
        let psCandidates = [
            "/Applications/Adobe Photoshop 2027",
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
        if !foundPs {
            if let apps = try? FileManager.default.contentsOfDirectory(atPath: "/Applications") {
                let matches = apps.filter { $0.hasPrefix("Adobe Photoshop") }.sorted().reversed()
                if let best = matches.first {
                    photoshopAppName = (best as NSString).deletingPathExtension
                    foundPs = true
                }
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
        env["CA_ASSERT_MAIN_THREAD_TRANSACTIONS"] = "0"
        process.environment = env
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        activeProcess = process
        activeStdoutPipe = stdoutPipe
        activeStderrPipe = stderrPipe
        
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
        
        process.terminationHandler = { [weak self, weak stdoutPipe, weak stderrPipe] proc in
            stdoutPipe?.fileHandleForReading.readabilityHandler = nil
            stderrPipe?.fileHandleForReading.readabilityHandler = nil
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
                self.activeStdoutPipe = nil
                self.activeStderrPipe = nil
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
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            activeProcess = nil
            activeStdoutPipe = nil
            activeStderrPipe = nil
            consoleLogs.append(ProcessLogItem(text: "✗ Süreç başlatılamadı: \(error.localizedDescription)", isError: true, isProgress: false))
        }
    }
    
    func terminateActiveTask() {
        activeStdoutPipe?.fileHandleForReading.readabilityHandler = nil
        activeStderrPipe?.fileHandleForReading.readabilityHandler = nil
        activeStdoutPipe = nil
        activeStderrPipe = nil
        activeProcess?.terminate()
        activeProcess = nil
        isRunningTask = false
        currentTaskTitle = nil
        consoleLogs.append(ProcessLogItem(text: "⚠️ Kullanıcı tarafından durduruldu.", isError: true, isProgress: false))
    }
    

    func addConsoleLog(_ text: String, isError: Bool = false) {
        consoleLogs.append(ProcessLogItem(text: text, isError: isError, isProgress: false))
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

    // MARK: - Render Cache Operations
    func scanRenderCache() {
        guard !renderCacheFolderPath.isEmpty,
              FileManager.default.fileExists(atPath: renderCacheFolderPath) else {
            renderCacheTotalSizeBytes = 0
            renderCacheFileCount = 0
            renderCacheItems = []
            return
        }
        
        isScanningRenderCache = true
        let targetPath = renderCacheFolderPath
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let fm = FileManager.default
            var totalSize: Int64 = 0
            var count = 0
            var items: [RenderCacheItem] = []
            
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: targetPath, isDirectory: &isDir), isDir.boolValue {
                if let contents = try? fm.contentsOfDirectory(atPath: targetPath) {
                    for item in contents {
                        if item.hasPrefix(".") { continue }
                        let fullPath = (targetPath as NSString).appendingPathComponent(item)
                        var itemIsDir: ObjCBool = false
                        if fm.fileExists(atPath: fullPath, isDirectory: &itemIsDir) {
                            let size: Int64
                            let date: Date?
                            let attrs = try? fm.attributesOfItem(atPath: fullPath)
                            date = attrs?[.modificationDate] as? Date
                            
                            if itemIsDir.boolValue {
                                size = Self.calculateFolderSize(at: fullPath)
                            } else {
                                size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
                            }
                            
                            totalSize += size
                            count += 1
                            items.append(RenderCacheItem(
                                name: item,
                                path: fullPath,
                                sizeBytes: size,
                                isDirectory: itemIsDir.boolValue,
                                modDate: date
                            ))
                        }
                    }
                }
            }
            
            items.sort { $0.sizeBytes > $1.sizeBytes }
            
            DispatchQueue.main.async {
                self.renderCacheTotalSizeBytes = totalSize
                self.renderCacheFileCount = count
                self.renderCacheItems = items
                self.isScanningRenderCache = false
            }
        }
    }
    
    nonisolated static func calculateFolderSize(at path: String) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
               resourceValues.isDirectory != true {
                total += Int64(resourceValues.fileSize ?? 0)
            }
        }
        return total
    }
    
    func clearRenderCache() {
        guard !renderCacheFolderPath.isEmpty,
              FileManager.default.fileExists(atPath: renderCacheFolderPath) else {
            return
        }
        
        isCleaningRenderCache = true
        lastCleanedStatus = nil
        let targetPath = renderCacheFolderPath
        let fm = FileManager.default
        
        let prohibitedPaths = [
            "/",
            "/System",
            "/Library",
            "/Applications",
            "/Users",
            "/bin",
            "/sbin",
            "/usr",
            "/var",
            "/etc",
            fm.homeDirectoryForCurrentUser.path
        ]
        
        if prohibitedPaths.contains(targetPath) {
            addConsoleLog("[Render Cache] ⚠️ Güvenlik engeli: Kök veya ana sistem dizinleri temizlenemez!")
            isCleaningRenderCache = false
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var deletedCount = 0
            var freedBytes: Int64 = 0
            let isDesktop = targetPath == fm.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").path
            
            if let contents = try? fm.contentsOfDirectory(atPath: targetPath) {
                for item in contents {
                    if item.hasPrefix(".") { continue }
                    let itemPath = (targetPath as NSString).appendingPathComponent(item)
                    
                    if isDesktop {
                        let lower = item.lowercased()
                        let isRender = lower.hasSuffix(".mp4") || lower.hasSuffix(".mov") || lower.hasSuffix(".avi") ||
                                       lower.contains("fc27") || lower.contains("buaksam") || lower.contains("memleket") ||
                                       lower.contains("haftalik") || lower.contains("canlimac") || lower.contains("thumbnail") ||
                                       lower.contains("aereport") || lower.hasSuffix(".aeplogs")
                        if !isRender {
                            continue
                        }
                    }
                    
                    var isDir: ObjCBool = false
                    if fm.fileExists(atPath: itemPath, isDirectory: &isDir) {
                        let size = isDir.boolValue ? Self.calculateFolderSize(at: itemPath) : ((try? fm.attributesOfItem(atPath: itemPath)[.size] as? NSNumber)?.int64Value ?? 0)
                        do {
                            try fm.removeItem(atPath: itemPath)
                            freedBytes += size
                            deletedCount += 1
                        } catch {}
                    }
                }
            }
            
            let formattedFreed = ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
            DispatchQueue.main.async {
                self.isCleaningRenderCache = false
                self.lastCleanedStatus = "✓ \(deletedCount) öğe silindi, \(formattedFreed) alan kazanıldı!"
                self.addConsoleLog("[Render Cache] Temizleme tamamlandı: \(deletedCount) öğe silindi, \(formattedFreed) disk alanı boşaltıldı.")
                if NSSound(named: "Trash")?.play() != true { NSSound.beep() }
                self.scanRenderCache()
            }
        }
    }

}
