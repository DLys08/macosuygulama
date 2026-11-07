import Foundation
import AppKit
import SwiftUI

public class ZonePanel: NSPanel {
    public var zoneID: UUID
    private var trackingArea: NSTrackingArea?
    private var isHoverExpanded = false
    private var preHoverHeight: CGFloat = 42.0
    
    public init(zone: ZoneModel, contentRect: NSRect) {
        self.zoneID = zone.id
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = false
        self.isReleasedWhenClosed = false
        
        updateWindowLevel(isPinnedOnTop: zone.isPinnedOnTop)
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        
        setupTrackingArea()
    }
    
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }
    
    public func updateWindowLevel(isPinnedOnTop: Bool) {
        if isPinnedOnTop {
            self.level = .floating
        } else {
            self.level = .normal
            self.orderBack(nil)
        }
    }
    
    // MARK: - Auto-Expand on Hover
    
    private func setupTrackingArea() {
        if let existing = trackingArea {
            contentView?.removeTrackingArea(existing)
        }
        guard let view = contentView else { return }
        let area = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        view.addTrackingArea(area)
        self.trackingArea = area
    }
    
    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard let zone = AppState.shared.zones.first(where: { $0.id == zoneID }),
              zone.isCollapsed && zone.autoExpandOnHover && AppState.shared.canAutoExpand() else {
            return
        }
        
        if !isHoverExpanded {
            isHoverExpanded = true
            preHoverHeight = frame.height
            var targetFrame = frame
            let targetHeight = zone.expandedHeight > 60 ? zone.expandedHeight : 260.0
            targetFrame.origin.y -= (targetHeight - targetFrame.height)
            targetFrame.size.height = targetHeight
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().setFrame(targetFrame, display: true)
            }
        }
    }
    
    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard let zone = AppState.shared.zones.first(where: { $0.id == zoneID }),
              isHoverExpanded && zone.isCollapsed else {
            return
        }
        
        isHoverExpanded = false
        var targetFrame = frame
        let targetHeight = zone.collapsedHeight
        targetFrame.origin.y += (targetFrame.height - targetHeight)
        targetFrame.size.height = targetHeight
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().setFrame(targetFrame, display: true)
        }
    }
    
    // MARK: - Snapping & Dragging Support
    
    public func snapFrame(_ targetRect: NSRect, otherFrames: [NSRect]) -> NSRect {
        guard AppState.shared.settings.alignmentMode else { return targetRect }
        
        var snapped = targetRect
        let threshold = AppState.shared.settings.snapThreshold
        
        // Snap to other zone edges
        if AppState.shared.settings.snapToNeighbors {
            for other in otherFrames {
                // Snap Left to other's Left
                if abs(snapped.minX - other.minX) < threshold {
                    snapped.origin.x = other.minX
                }
                // Snap Left to other's Right (adjacent)
                else if abs(snapped.minX - (other.maxX + 12)) < threshold {
                    snapped.origin.x = other.maxX + 12
                }
                // Snap Right to other's Right
                else if abs(snapped.maxX - other.maxX) < threshold {
                    snapped.origin.x = other.maxX - snapped.width
                }
                // Snap Right to other's Left (adjacent)
                else if abs(snapped.maxX - (other.minX - 12)) < threshold {
                    snapped.origin.x = other.minX - 12 - snapped.width
                }
                
                // Snap Top to other's Top
                if abs(snapped.maxY - other.maxY) < threshold {
                    snapped.origin.y = other.maxY - snapped.height
                }
                // Snap Bottom to other's Bottom
                else if abs(snapped.minY - other.minY) < threshold {
                    snapped.origin.y = other.minY
                }
            }
        }
        
        // Snap to Grid
        if AppState.shared.settings.snapToGrid {
            let grid = AppState.shared.settings.gridSize
            snapped.origin.x = round(snapped.origin.x / grid) * grid
            snapped.origin.y = round(snapped.origin.y / grid) * grid
        }
        
        return snapped
    }
}
