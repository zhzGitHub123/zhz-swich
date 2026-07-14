import {
  BarChart,
  Bar,
  ResponsiveContainer,
  XAxis,
  YAxis,
  Tooltip,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
  CartesianGrid,
} from "recharts";
import { Glass, GlassButton } from "./glass";
import { Download, TrendingUp } from "lucide-react";

const barData = [
  { name: "Claude", v: 42, color: "#fb923c" },
  { name: "GPT", v: 28, color: "#10b981" },
  { name: "Gemini", v: 16, color: "#6366f1" },
  { name: "DeepSeek", v: 9, color: "#a855f7" },
  { name: "Qwen", v: 5, color: "#f43f5e" },
];

const trendData = Array.from({ length: 14 }).map((_, i) => ({
  d: `${i + 14}`,
  cost: 1.2 + Math.sin(i / 2) * 0.6 + i * 0.1,
  tok: 80 + Math.cos(i / 1.5) * 30 + i * 4,
}));

const logs = [
  ["10:24", "Claude Code", "Claude", "opus-4.7", "12.4K", "3.1K", "$0.082"],
  ["10:21", "Codex", "GPT", "gpt-4o", "8.0K", "2.2K", "$0.041"],
  ["10:18", "Claude Code", "Claude", "haiku-4.5", "4.1K", "1.0K", "$0.008"],
  ["10:15", "Gemini CLI", "Gemini", "2.5-pro", "9.2K", "1.7K", "$0.029"],
  ["10:09", "通义", "Qwen", "max-2026", "5.4K", "0.8K", "$0.012"],
];

export function UsageView() {
  return (
    <div className="flex flex-col gap-5 lg:gap-7">
      <div className="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-4">
        <div>
          <div className="text-slate-500" style={{ fontSize: 12 }}>模块 / Usage</div>
          <h2 className="text-slate-900 mt-1" style={{ fontSize: 28 }}>使用统计 · 成本</h2>
          <div className="text-slate-600 mt-1">追踪 API 用量与花销趋势</div>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <GlassButton>今日</GlassButton>
          <GlassButton active>本周</GlassButton>
          <GlassButton>本月</GlassButton>
          <GlassButton><Download className="h-4 w-4" /> 导出 CSV</GlassButton>
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 xl:grid-cols-12 gap-4 lg:gap-5">
        {[
          { k: "总成本", v: "$48.62", d: "+12.4%", tint: "blue" as const },
          { k: "总 Tokens", v: "4.82M", d: "输入 3.1M / 输出 1.7M", tint: "purple" as const },
          { k: "请求数", v: "12,841", d: "本周 +2,104", tint: "pink" as const },
          { k: "平均成本", v: "$0.0038", d: "↓ 0.4¢ vs 上周", tint: "emerald" as const },
        ].map((s) => (
          <Glass key={s.k} tint={s.tint} elevation={2} className="col-span-1 md:col-span-2 xl:col-span-3 p-4 lg:p-5">
            <div className="text-slate-600" style={{ fontSize: 12 }}>{s.k}</div>
            <div className="text-slate-900 mt-2" style={{ fontSize: 28 }}>{s.v}</div>
            <div className="text-slate-600 mt-1 flex items-center gap-1" style={{ fontSize: 12 }}>
              <TrendingUp className="h-3 w-3" /> {s.d}
            </div>
          </Glass>
        ))}

        {/* 3D Soft bars */}
        <Glass elevation={2} className="col-span-2 md:col-span-4 xl:col-span-7 p-4 lg:p-5">
          <div className="flex items-center justify-between">
            <div className="text-slate-800">按提供商分布</div>
            <div className="text-slate-500" style={{ fontSize: 12 }}>过去 7 天</div>
          </div>
          <div className="h-64 mt-3">
            <ResponsiveContainer>
              <BarChart data={barData}>
                <defs>
                  {barData.map((b, i) => (
                    <linearGradient key={i} id={`bar${i}`} x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor={b.color} stopOpacity={0.95} />
                      <stop offset="100%" stopColor={b.color} stopOpacity={0.4} />
                    </linearGradient>
                  ))}
                  <filter id="softShadow" x="-20%" y="-20%" width="140%" height="140%">
                    <feGaussianBlur in="SourceAlpha" stdDeviation="4" />
                    <feOffset dy="6" />
                    <feComponentTransfer><feFuncA type="linear" slope="0.3" /></feComponentTransfer>
                    <feMerge><feMergeNode /><feMergeNode in="SourceGraphic" /></feMerge>
                  </filter>
                </defs>
                <CartesianGrid stroke="rgba(255,255,255,0.4)" vertical={false} />
                <XAxis dataKey="name" stroke="#475569" tickLine={false} axisLine={false} />
                <YAxis stroke="#475569" tickLine={false} axisLine={false} />
                <Tooltip contentStyle={{ background: "rgba(255,255,255,0.7)", backdropFilter: "blur(10px)", border: "1px solid rgba(255,255,255,0.6)", borderRadius: 12 }} />
                <Bar dataKey="v" radius={[12, 12, 4, 4]} filter="url(#softShadow)">
                  {barData.map((b, i) => (
                    <Cell key={i} fill={`url(#bar${i})`} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Glass>

        <Glass tint="purple" elevation={2} className="col-span-2 md:col-span-4 xl:col-span-5 p-4 lg:p-5">
          <div className="text-slate-800">按应用分布</div>
          <div className="h-64 mt-3">
            <ResponsiveContainer>
              <PieChart>
                <defs>
                  {barData.map((b, i) => (
                    <radialGradient key={i} id={`pie${i}`}>
                      <stop offset="0%" stopColor={b.color} stopOpacity={1} />
                      <stop offset="100%" stopColor={b.color} stopOpacity={0.5} />
                    </radialGradient>
                  ))}
                </defs>
                <Pie data={barData} dataKey="v" innerRadius={55} outerRadius={90} paddingAngle={3} stroke="rgba(255,255,255,0.6)">
                  {barData.map((_, i) => <Cell key={i} fill={`url(#pie${i})`} />)}
                </Pie>
                <Tooltip contentStyle={{ background: "rgba(255,255,255,0.7)", backdropFilter: "blur(10px)", border: "1px solid rgba(255,255,255,0.6)", borderRadius: 12 }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </Glass>

        <Glass elevation={2} className="col-span-2 md:col-span-4 xl:col-span-12 p-4 lg:p-5">
          <div className="flex items-center justify-between">
            <div className="text-slate-800">成本与 Token 趋势</div>
            <div className="text-slate-500" style={{ fontSize: 12 }}>近 14 天</div>
          </div>
          <div className="h-56 mt-3">
            <ResponsiveContainer>
              <LineChart data={trendData}>
                <defs>
                  <linearGradient id="lineCost" x1="0" y1="0" x2="1" y2="0">
                    <stop offset="0%" stopColor="#6366f1" />
                    <stop offset="100%" stopColor="#ec4899" />
                  </linearGradient>
                </defs>
                <CartesianGrid stroke="rgba(255,255,255,0.4)" vertical={false} />
                <XAxis dataKey="d" stroke="#475569" tickLine={false} axisLine={false} />
                <YAxis stroke="#475569" tickLine={false} axisLine={false} />
                <Tooltip contentStyle={{ background: "rgba(255,255,255,0.7)", backdropFilter: "blur(10px)", border: "1px solid rgba(255,255,255,0.6)", borderRadius: 12 }} />
                <Line type="monotone" dataKey="cost" stroke="url(#lineCost)" strokeWidth={3} dot={{ r: 3, fill: "#fff", stroke: "#6366f1", strokeWidth: 2 }} />
                <Line type="monotone" dataKey="tok" stroke="#10b981" strokeWidth={2} strokeDasharray="4 4" dot={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </Glass>

        <Glass elevation={2} className="col-span-2 md:col-span-4 xl:col-span-12 p-4 lg:p-5">
          <div className="flex items-center justify-between mb-3">
            <div className="text-slate-800">请求日志</div>
            <GlassButton><Download className="h-4 w-4" /> 导出</GlassButton>
          </div>
          <div className="rounded-2xl border border-white/50 bg-white/20 overflow-x-auto">
            <table className="w-full min-w-[640px] text-left">
              <thead className="bg-white/30 text-slate-600" style={{ fontSize: 12 }}>
                <tr>
                  {["时间","应用","提供商","模型","输入","输出","成本"].map(h => (
                    <th key={h} className="px-4 py-2.5">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="text-slate-800">
                {logs.map((r, i) => (
                  <tr key={i} className="border-t border-white/40 hover:bg-white/30">
                    {r.map((c, j) => (
                      <td key={j} className="px-4 py-2.5">{c}</td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Glass>
      </div>
    </div>
  );
}
