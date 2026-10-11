import AppKit
import SwiftUI

/// Renders the exact icon compiled into the application bundle.
/// Using the bundled ICNS keeps every branded app-icon placement in sync.
struct AppIconView: View {
  let size: CGFloat

  var body: some View {
    Image(nsImage: Self.image)
      .resizable()
      .interpolation(.high)
      .antialiased(true)
      .scaledToFit()
      .frame(width: size, height: size)
      .accessibilityLabel("Weight Tracker app icon")
  }

  private static let image: NSImage = {
    guard let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
      let image = NSImage(contentsOf: url)
    else {
      return NSApplication.shared.applicationIconImage
    }
    return image
  }()
}

#Preview {
  AppIconView(size: 150)
    .padding(40)
    .background(AppTheme.background)
}
