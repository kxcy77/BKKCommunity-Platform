import SwiftUI

public struct WhatsAppIconView: View {
    public var size: CGFloat = 24
    
    public init(size: CGFloat = 24) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Official WhatsApp Green Circle
            Circle()
                .fill(Color(hex: "#25D366"))
                .frame(width: size, height: size)
            
            // Official Vector Handset & Chat Bubble Icon
            WhatsAppVectorShape()
                .fill(Color.white)
                .frame(width: size * 0.6, height: size * 0.6)
        }
    }
}

// Exact Official Vector Path for WhatsApp Logo
struct WhatsAppVectorShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scaleX = rect.width / 24.0
        let scaleY = rect.height / 24.0
        
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        
        // Exact official SVG path
        var subpath = Path()
        subpath.move(to: CGPoint(x: 17.472, y: 14.382))
        subpath.addCurve(to: CGPoint(x: 15.442, y: 13.415), control1: CGPoint(x: 17.175, y: 14.233), control2: CGPoint(x: 15.714, y: 13.515))
        subpath.addCurve(to: CGPoint(x: 14.772, y: 13.565), control1: CGPoint(x: 15.169, y: 13.316), control2: CGPoint(x: 14.971, y: 13.267))
        subpath.addCurve(to: CGPoint(x: 13.832, y: 14.729), control1: CGPoint(x: 14.575, y: 13.862), control2: CGPoint(x: 14.005, y: 14.531))
        subpath.addCurve(to: CGPoint(x: 13.188, y: 14.804), control1: CGPoint(x: 13.659, y: 14.928), control2: CGPoint(x: 13.485, y: 14.903))
        subpath.addCurve(to: CGPoint(x: 10.798, y: 13.329), control1: CGPoint(x: 12.891, y: 14.654), control2: CGPoint(x: 11.933, y: 14.341))
        subpath.addCurve(to: CGPoint(x: 9.145, y: 11.27), control1: CGPoint(x: 9.915, y: 12.541), control2: CGPoint(x: 9.318, y: 11.568))
        subpath.addCurve(to: CGPoint(x: 9.293, y: 10.664), control1: CGPoint(x: 8.972, y: 10.973), control2: CGPoint(x: 9.127, y: 10.812))
        subpath.addCurve(to: CGPoint(x: 9.739, y: 10.144), control1: CGPoint(x: 9.427, y: 10.531), control2: CGPoint(x: 9.591, y: 10.317))
        subpath.addCurve(to: CGPoint(x: 10.037, y: 9.647), control1: CGPoint(x: 9.888, y: 9.97), control2: CGPoint(x: 9.937, y: 9.846))
        subpath.addCurve(to: CGPoint(x: 10.012, y: 9.127), control1: CGPoint(x: 10.136, y: 9.449), control2: CGPoint(x: 10.087, y: 9.276))
        subpath.addCurve(to: CGPoint(x: 9.096, y: 6.92), control1: CGPoint(x: 9.937, y: 8.978), control2: CGPoint(x: 9.343, y: 7.515))
        subpath.addCurve(to: CGPoint(x: 8.427, y: 6.41), control1: CGPoint(x: 8.854, y: 6.341), control2: CGPoint(x: 8.609, y: 6.42))
        subpath.addCurve(to: CGPoint(x: 7.857, y: 6.4), control1: CGPoint(x: 8.254, y: 6.402), control2: CGPoint(x: 8.056, y: 6.4))
        subpath.addCurve(to: CGPoint(x: 7.065, y: 6.772), control1: CGPoint(x: 7.659, y: 6.4), control2: CGPoint(x: 7.337, y: 6.474))
        subpath.addCurve(to: CGPoint(x: 6.025, y: 9.251), control1: CGPoint(x: 6.793, y: 7.069), control2: CGPoint(x: 6.025, y: 7.788))
        subpath.addCurve(to: CGPoint(x: 7.238, y: 12.325), control1: CGPoint(x: 6.025, y: 10.713), control2: CGPoint(x: 7.09, y: 12.126))
        subpath.addCurve(to: CGPoint(x: 12.315, y: 16.812), control1: CGPoint(x: 7.387, y: 12.523), control2: CGPoint(x: 9.334, y: 15.525))
        subpath.addCurve(to: CGPoint(x: 14.009, y: 17.437), control1: CGPoint(x: 13.024, y: 17.118), control2: CGPoint(x: 13.577, y: 17.301))
        subpath.addCurve(to: CGPoint(x: 15.88, y: 17.555), control1: CGPoint(x: 14.721, y: 17.664), control2: CGPoint(x: 15.369, y: 17.632))
        subpath.addCurve(to: CGPoint(x: 17.886, y: 16.142), control1: CGPoint(x: 16.451, y: 17.47), control2: CGPoint(x: 17.638, y: 16.836))
        subpath.addCurve(to: CGPoint(x: 18.059, y: 14.729), control1: CGPoint(x: 18.134, y: 15.448), control2: CGPoint(x: 18.134, y: 14.853))
        subpath.addCurve(to: CGPoint(x: 17.472, y: 14.382), control1: CGPoint(x: 17.985, y: 14.605), control2: CGPoint(x: 17.787, y: 14.531))
        subpath.closeSubpath()

        path.addPath(subpath.applying(transform))
        return path
    }
}
