import XCTest
@testable import DesktopDuzen

final class DesktopDuzenTests: XCTestCase {
    
    func testThemePresets() {
        XCTAssertGreaterThanOrEqual(ThemePresets.allThemes.count, 11)
        
        let glass = ThemePresets.theme(for: "glass_blur")
        XCTAssertEqual(glass.name, "Liquid Glass")
        XCTAssertFalse(glass.isPro)
        
        let cyberpunk = ThemePresets.theme(for: "cyberpunk_neon")
        XCTAssertEqual(cyberpunk.name, "Cyberpunk")
        XCTAssertTrue(cyberpunk.isPro)
        
        let unknown = ThemePresets.theme(for: "non_existent_id")
        XCTAssertEqual(unknown.id, ThemePresets.glassBlur.id)
    }
    
    func testFolderNameSanitization() {
        let fms = FileManagerService.shared
        XCTAssertEqual(fms.sanitizeFolderName("Test / Zone: 1?"), "Test - Zone- 1-")
        XCTAssertEqual(fms.sanitizeFolderName("   "), "Zone")
        XCTAssertEqual(fms.sanitizeFolderName("My Documents"), "My Documents")
    }
    
    func testFileItemFormatting() {
        let url = URL(fileURLWithPath: "/tmp/sample.pdf")
        let item = FileItem(
            name: "sample.pdf",
            url: url,
            isDirectory: false,
            size: 1048576, // 1 MB
            modificationDate: Date(),
            kindDescription: "PDF Document"
        )
        
        XCTAssertEqual(item.name, "sample.pdf")
        XCTAssertFalse(item.isDirectory)
        XCTAssertTrue(item.formattedSize.contains("MB") || item.formattedSize.contains("1"))
    }
    
    func testZoneModelTabsAndPaths() {
        let baseDir = "/Users/darwin/Desktop/Zones/Work"
        var zone = ZoneModel(
            type: .file,
            title: "Work",
            backingFolderPath: baseDir
        )
        
        XCTAssertEqual(zone.resolvedFolderPath, baseDir)
        
        let tab1 = ZoneTab(title: "Active", subfolderName: "Active", order: 0)
        let tab2 = ZoneTab(title: "Archive", subfolderName: "Archive", order: 1)
        zone.tabs = [tab1, tab2]
        zone.activeTabID = tab1.id
        
        XCTAssertEqual(zone.resolvedFolderPath, "\(baseDir)/Active")
        
        zone.activeTabID = tab2.id
        XCTAssertEqual(zone.resolvedFolderPath, "\(baseDir)/Archive")
    }
    
    func testProEntitlements() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let appState = AppState(customStorageURL: tempDir)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // When Pro is disabled
        appState.license.isPro = false
        appState.license.isMockProActive = false
        
        appState.zones = [
            ZoneModel(title: "Zone 1"),
            ZoneModel(title: "Zone 2"),
            ZoneModel(title: "Zone 3")
        ]
        
        XCTAssertFalse(appState.canAddZone(), "Free tier must limit to 3 zones")
        XCTAssertFalse(appState.canUseTabs(), "Free tier cannot use multi-tabs")
        XCTAssertFalse(appState.canAutoExpand(), "Free tier cannot use auto-expand")
        XCTAssertFalse(appState.canPinOnTop(), "Free tier cannot pin on top")
        
        let proTheme = ThemePresets.cyberpunkNeon
        XCTAssertFalse(appState.canUseTheme(proTheme), "Pro theme locked on Free tier")
        
        // When Pro is enabled
        appState.license.isPro = true
        XCTAssertTrue(appState.canAddZone(), "Pro tier allows unlimited zones")
        XCTAssertTrue(appState.canUseTabs(), "Pro tier allows multi-tabs")
        XCTAssertTrue(appState.canAutoExpand(), "Pro tier allows auto-expand")
        XCTAssertTrue(appState.canPinOnTop(), "Pro tier allows pin on top")
        XCTAssertTrue(appState.canUseTheme(proTheme), "Pro theme unlocked on Pro tier")
    }
    
    func testExportAndImportJSON() {
        let tempDir1 = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let tempDir2 = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: tempDir1)
            try? FileManager.default.removeItem(at: tempDir2)
        }
        
        let appState = AppState(customStorageURL: tempDir1)
        appState.zones = [
            ZoneModel(title: "Test Zone Alpha", frame: CGRect(x: 50, y: 50, width: 300, height: 200)),
            ZoneModel(title: "Test Zone Beta", frame: CGRect(x: 400, y: 50, width: 300, height: 200))
        ]
        
        guard let exportedJSON = appState.exportConfigurationJSON() else {
            XCTFail("Failed to export JSON")
            return
        }
        
        XCTAssertTrue(exportedJSON.contains("Test Zone Alpha"))
        XCTAssertTrue(exportedJSON.contains("Test Zone Beta"))
        
        let newAppState = AppState(customStorageURL: tempDir2)
        let success = newAppState.importConfigurationJSON(exportedJSON)
        XCTAssertTrue(success)
        XCTAssertEqual(newAppState.zones.count, 2)
        XCTAssertEqual(newAppState.zones[0].title, "Test Zone Alpha")
    }
    
    func testFileMoveCollisionHandling() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let sourceFile = tempDir.appendingPathComponent("document.txt")
        try? "Hello World".write(to: sourceFile, atomically: true, encoding: .utf8)
        
        let targetSubDir = tempDir.appendingPathComponent("TargetSubDir")
        try? FileManager.default.createDirectory(at: targetSubDir, withIntermediateDirectories: true)
        
        // Existing file with same name in target
        let existingFile = targetSubDir.appendingPathComponent("document.txt")
        try? "Pre-existing content".write(to: existingFile, atomically: true, encoding: .utf8)
        
        // Move with .keepBoth
        let movedURL = FileManagerService.shared.moveFile(from: sourceFile, toDirectory: targetSubDir, collisionOption: .keepBoth)
        XCTAssertNotNil(movedURL)
        XCTAssertEqual(movedURL?.lastPathComponent, "document 1.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: existingFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: movedURL!.path))
    }
    
    func testAutoSortRuleMatching() {
        let rules = AutoSortRule.defaultRules
        let imageRule = rules.first(where: { $0.name == "Images & Screenshots" })
        XCTAssertNotNil(imageRule)
        XCTAssertTrue(imageRule!.extensions.contains("png"))
        XCTAssertTrue(imageRule!.extensions.contains("jpg"))
        XCTAssertFalse(imageRule!.extensions.contains("pdf"))
        
        let docRule = rules.first(where: { $0.name == "Documents & PDFs" })
        XCTAssertNotNil(docRule)
        XCTAssertTrue(docRule!.extensions.contains("pdf"))
        XCTAssertTrue(docRule!.extensions.contains("docx"))
    }
    
    func testAlignmentSnapping() {
        let panel = ZonePanel(
            zone: ZoneModel(title: "Snapping Test"),
            contentRect: NSRect(x: 100, y: 100, width: 300, height: 200)
        )
        
        let otherZoneRect = NSRect(x: 400, y: 100, width: 300, height: 200)
        
        // Test near-edge snap
        let origSettings = AppState.shared.settings
        defer { AppState.shared.settings = origSettings }
        
        AppState.shared.settings.alignmentMode = true
        AppState.shared.settings.snapToNeighbors = true
        AppState.shared.settings.snapToGrid = false
        AppState.shared.settings.snapThreshold = 14.0
        
        // Dragging to x: 405 (within 14px of 400)
        let candidate = NSRect(x: 405, y: 105, width: 300, height: 200)
        let snapped = panel.snapFrame(candidate, otherFrames: [otherZoneRect])
        
        XCTAssertEqual(snapped.origin.x, 400, "Should snap to matching left edge")
        XCTAssertEqual(snapped.origin.y, 100, "Should snap to matching bottom edge")
    }
}
