import SwiftUI

struct WeightImpactCard: View {
  let consumed: Double
  let target: Double
  let protein: Double

  private var remaining: Double { target - consumed }
  private var progress: Double { target > 0 ? min(max(consumed / target, 0), 1) : 0 }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Label("Daily context", systemImage: "sparkles").font(.system(size: 14, weight: .semibold))
      HStack(alignment: .firstTextBaseline) {
        Text("\(Int(consumed.rounded()))").font(.system(size: 40, weight: .light))
        Text("kcal eaten today").font(.system(size: 11)).foregroundStyle(.secondary)
      }
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule().fill(AppTheme.violet.opacity(0.16))
          Capsule().fill(consumed > target ? Color.orange : AppTheme.violet).frame(width: proxy.size.width * progress)
        }
      }.frame(height: 7)
      HStack {
        Text("TARGET \(Int(target))"); Spacer()
        Text(remaining >= 0 ? "\(Int(remaining)) LEFT" : "\(Int(abs(remaining))) OVER")
      }.font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
      Text(insight).font(.system(size: 12)).foregroundStyle(Color(red: 0.18, green: 0.15, blue: 0.45))
      Text("Calorie budgets are estimates; short-term weight changes also reflect hydration and normal variation.")
        .font(.system(size: 9)).foregroundStyle(.secondary)
    }
    .padding(18).background(AppTheme.violet.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
    .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.violet.opacity(0.22)))
  }

  private var insight: String {
    if consumed > target { return "Today is currently above the estimated budget. One day does not determine your weight trend." }
    if protein >= 30 { return "This meal contributes substantial protein while leaving room in today’s estimated budget." }
    return "Add balanced portions and use your multi-week weight trend—not a single meal—to judge progress."
  }
}
