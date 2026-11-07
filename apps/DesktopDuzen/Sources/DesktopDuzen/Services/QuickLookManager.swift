import Foundation
import AppKit
import QuickLookUI

public class QuickLookManager: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    public static let shared = QuickLookManager()
    
    private var previewURLs: [URL] = []
    
    public func preview(urls: [URL]) {
        guard !urls.isEmpty else { return }
        self.previewURLs = urls
        
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        
        if panel.isVisible {
            panel.reloadData()
        } else {
            panel.makeKeyAndOrderFront(nil)
        }
    }
    
    public func togglePreview(urls: [URL]) {
        guard let panel = QLPreviewPanel.shared() else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            preview(urls: urls)
        }
    }
    
    // MARK: - QLPreviewPanelDataSource
    
    public func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return previewURLs.count
    }
    
    public func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        guard index >= 0 && index < previewURLs.count else {
            return nil
        }
        return previewURLs[index] as NSURL
    }
}
