import SwiftUI

private enum UsageLayout {
    static let cardPadding: CGFloat = 20
}

struct UsageDashboard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chartProgress: CGFloat = 0

    private let metrics = [
        ("总成本", "$48.62", "+12.4%", Color.blue),
        ("总 Tokens", "4.82M", "输入 3.1M / 输出 1.7M", Color.purple),
        ("请求数", "12,841", "本周 +2,104", Color.pink),
        ("平均成本", "$0.0038", "↓ 0.4¢ vs 上周", Color.green)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ModuleHeader(
                title: "使用统计 · 成本",
                subtitle: "追踪 API 用量与花销趋势",
                eyebrow: "模块 / Usage",
                actions: [
                    ModuleAction(title: "过去 7 天", icon: "calendar"),
                    ModuleAction(title: "导出 CSV", icon: "square.and.arrow.up")
                ]
            )

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                    MetricSummaryCard(title: metric.0, value: metric.1, detail: metric.2, tint: metric.3)
                }
            }

            HStack(spacing: 18) {
                ProviderDistributionCard(progress: chartProgress)
                    .frame(maxWidth: .infinity)
                ApplicationDistributionCard(progress: chartProgress)
                    .frame(width: 330)
            }

            TrendChartCard(progress: chartProgress)
            RequestLogCard()
        }
        .onAppear {
            chartProgress = 0
            guard !reduceMotion else {
                chartProgress = 1
                return
            }
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.7)) {
                    chartProgress = 1
                }
            }
        }
    }
}

private struct MetricSummaryCard: View {
    let title: String
    let value: String
    let detail: String
    let tint: Color

    var body: some View {
        GlassCard(tint: tint, cornerRadius: 21) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.slate600)
                Text(value)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.slate900)
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)
                Label(detail, systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.slate600)
                    .lineLimit(1)
            }
            .padding(UsageLayout.cardPadding)
        }
        .frame(height: 118)
    }
}

private struct ProviderDistributionCard: View {
    let progress: CGFloat

    private let values: [(String, CGFloat, Color)] = [
        ("Claude", 42, .orange), ("GPT", 28, .green), ("Gemini", 16, .indigo),
        ("DeepSeek", 9, .purple), ("Qwen", 5, .pink)
    ]

    var body: some View {
        GlassCard(cornerRadius: 23) {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Text("按提供商分布").fontWeight(.bold)
                    Spacer()
                    Text("过去 7 天").font(.caption).foregroundStyle(Color.slate500)
                }
                VStack(spacing: 13) {
                    ForEach(values, id: \.0) { item in
                        HStack(spacing: 10) {
                            Text(item.0)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.slate700)
                                .frame(width: 62, alignment: .leading)
                            GeometryReader { proxy in
                                Capsule().fill(.white.opacity(0.30))
                                    .overlay(alignment: .leading) {
                                        Capsule()
                                            .fill(LinearGradient(colors: [item.2.opacity(0.55), item.2], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: proxy.size.width * item.1 / 48 * progress)
                                    }
                            }
                            .frame(height: 12)
                            Text("\(Int(item.1))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.slate600)
                                .frame(width: 28)
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .padding(UsageLayout.cardPadding)
        }
        .frame(height: 248)
    }
}

private struct ApplicationDistributionCard: View {
    let progress: CGFloat

    private let slices: [(CGFloat, CGFloat, Color)] = [
        (0, 0.46, .cyan), (0.46, 0.72, .purple), (0.72, 0.88, .pink), (0.88, 1, .orange)
    ]

    var body: some View {
        GlassCard(tint: .purple, cornerRadius: 23) {
            VStack(alignment: .leading, spacing: 10) {
                Text("按应用分布").fontWeight(.bold)
                HStack(spacing: 16) {
                    ZStack {
                        ForEach(Array(slices.enumerated()), id: \.offset) { _, slice in
                            Circle()
                                .trim(from: slice.0, to: slice.0 + (slice.1 - slice.0) * progress)
                                .stroke(slice.2, style: StrokeStyle(lineWidth: 24, lineCap: .butt))
                                .rotationEffect(.degrees(-90))
                        }
                        VStack(spacing: 1) {
                            Text("12.8K").font(.system(size: 15, weight: .bold))
                            Text("请求").font(.caption2).foregroundStyle(Color.slate500)
                        }
                    }
                    .frame(width: 110, height: 110)

                    VStack(alignment: .leading, spacing: 10) {
                        ChartLegend(color: .cyan, title: "Claude Code", value: "46%")
                        ChartLegend(color: .purple, title: "Codex", value: "26%")
                        ChartLegend(color: .pink, title: "Gemini CLI", value: "16%")
                        ChartLegend(color: .orange, title: "其他", value: "12%")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 6)
            }
            .padding(UsageLayout.cardPadding)
        }
        .frame(height: 248)
    }
}

private struct ChartLegend: View {
    let color: Color
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title).foregroundStyle(Color.slate700)
            Spacer()
            Text(value).foregroundStyle(Color.slate500)
        }
        .font(.system(size: 10, weight: .semibold))
    }
}

private struct TrendChartCard: View {
    let progress: CGFloat

    private let values: [CGFloat] = [34, 48, 40, 56, 51, 66, 58, 72, 69, 84, 75, 92, 87, 98]

    var body: some View {
        GlassCard(cornerRadius: 23) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("成本与 Token 趋势").fontWeight(.bold)
                    Spacer()
                    Text("近 14 天").font(.caption).foregroundStyle(Color.slate500)
                }
                ZStack {
                    Canvas { context, size in
                        for index in 0...4 {
                            let y = size.height * CGFloat(index) / 4
                            var grid = Path()
                            grid.move(to: CGPoint(x: 0, y: y))
                            grid.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(grid, with: .color(.white.opacity(0.45)), lineWidth: 1)
                        }
                    }

                    TrendLineShape(values: values, progress: progress)
                        .stroke(
                            LinearGradient(colors: [.cyan, .purple, .pink], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                }
            }
            .padding(UsageLayout.cardPadding)
        }
        .frame(height: 228)
    }
}

private struct TrendLineShape: Shape {
    let values: [CGFloat]
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard values.count > 1 else { return Path() }

        var path = Path()
        for (index, value) in values.enumerated() {
            let x = rect.width * CGFloat(index) / CGFloat(values.count - 1)
            let y = rect.height - rect.height * value / 110
            index == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
        }
        return path.trimmedPath(from: 0, to: progress)
    }
}

private struct RequestLogCard: View {
    private let rows = [
        ["10:24", "Claude Code", "Claude", "opus-4.7", "12.4K", "3.1K", "$0.082"],
        ["10:21", "Codex", "GPT", "gpt-4o", "8.0K", "2.2K", "$0.041"],
        ["10:18", "Claude Code", "Claude", "haiku-4.5", "4.1K", "1.0K", "$0.008"],
        ["10:15", "Gemini CLI", "Gemini", "2.5-pro", "9.2K", "1.7K", "$0.029"],
        ["10:09", "通义", "Qwen", "max-2026", "5.4K", "0.8K", "$0.012"]
    ]
    private let widths: [CGFloat] = [62, 108, 82, 110, 72, 72, 74]

    var body: some View {
        GlassCard(cornerRadius: 23) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("请求日志").fontWeight(.bold)
                    Spacer()
                    HeaderButton(title: "导出", icon: "square.and.arrow.up")
                }
                VStack(spacing: 0) {
                    LogRow(values: ["时间", "应用", "提供商", "模型", "输入", "输出", "成本"], widths: widths, header: true)
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        Divider().overlay(.white.opacity(0.44))
                        LogRow(values: row, widths: widths)
                    }
                }
        .background(Color.themeSurface.opacity(0.20), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.themeBorder.opacity(0.48), lineWidth: 1) }
            }
            .padding(UsageLayout.cardPadding)
        }
        .frame(height: 310)
    }
}

private struct LogRow: View {
    let values: [String]
    let widths: [CGFloat]
    var header = false
    var body: some View {
        HStack(spacing: 8) {
            ForEach(values.indices, id: \.self) { index in
                Text(values[index])
                    .font(.system(size: header ? 10 : 11, weight: header ? .bold : .medium, design: index == 3 ? .monospaced : .default))
                    .foregroundStyle(header ? Color.slate500 : Color.slate800)
                    .frame(width: widths[index], alignment: .leading)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .frame(height: header ? 34 : 38)
    }
}
