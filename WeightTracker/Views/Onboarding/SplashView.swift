import SwiftUI

struct SplashView: View {
  @State private var progress: CGFloat = 0

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      AppIconView(size: 150)
        .shadow(color: .black.opacity(0.16), radius: 20, y: 14)

      Text("Weight Tracker")
        .font(.system(size: 38, weight: .bold))
        .tracking(-1.4)
        .foregroundStyle(AppTheme.ink)
        .padding(.top, 31)

      Text("H E A L T H   A P P")
        .font(.system(size: 12, design: .monospaced))
        .tracking(2.5)
        .foregroundStyle(AppTheme.ink.opacity(0.62))
        .padding(.top, 8)

      VStack(spacing: 29) {
        GeometryReader { proxy in
          ZStack(alignment: .leading) {
            Capsule().fill(AppTheme.stroke.opacity(0.72))
            Capsule()
              .fill(AppTheme.ink)
              .frame(width: proxy.size.width * progress)
          }
        }
        .frame(width: 180, height: 4)

        Text("Syncing with Apple Health…")
          .font(.system(size: 12, design: .monospaced))
          .foregroundStyle(AppTheme.ink.opacity(0.56))
      }
      .padding(.top, 55)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppTheme.background)
    .onAppear {
      progress = 0
      withAnimation(.easeInOut(duration: 1.25)) {
        progress = 0.64
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Weight Tracker is starting")
  }
}

#Preview {
  SplashView().frame(width: 1080, height: 700)
}
