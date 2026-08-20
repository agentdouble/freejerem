import CoreGraphics

public enum MouseTargetCalculator {
    public static func target(
        from origin: CGPoint,
        deltaX: CGFloat,
        deltaY: CGFloat,
        visibleBounds: CGRect
    ) -> CGPoint {
        CGPoint(
            x: min(max(origin.x + deltaX, visibleBounds.minX), visibleBounds.maxX),
            y: min(max(origin.y + deltaY, visibleBounds.minY), visibleBounds.maxY)
        )
    }
}
