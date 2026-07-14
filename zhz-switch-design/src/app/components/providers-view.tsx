import { useState } from "react";
import {
  Plus,
  Upload,
  Download,
  ArrowUpDown,
  Filter,
  CheckCircle2,
  MoreHorizontal,
  Sparkles,
} from "lucide-react";
import { Glass, GlassButton } from "./glass";

const providers = [
  { name: "Claude (Anthropic)", app: "Claude Code", status: "active", color: "from-orange-300 to-amber-400", glyph: "✦", model: "opus-4.7" },
  { name: "OpenAI GPT", app: "Codex", status: "idle", color: "from-emerald-300 to-teal-400", glyph: "◎", model: "gpt-4o" },
  { name: "Gemini", app: "Gemini CLI", status: "idle", color: "from-sky-300 to-indigo-400", glyph: "✺", model: "2.5-pro" },
  { name: "DeepSeek", app: "Codex", status: "idle", color: "from-violet-300 to-fuchsia-400", glyph: "❖", model: "v3" },
  { name: "Qwen Max", app: "通义", status: "warn", color: "from-rose-300 to-pink-400", glyph: "✶", model: "max-2026" },
  { name: "本地 Ollama", app: "本地", status: "idle", color: "from-slate-300 to-slate-500", glyph: "◐", model: "llama3.3" },
];

export function ProvidersView() {
  const [active, setActive] = useState(0);

  return (
    <div className="flex flex-col gap-5 lg:gap-7">
      <Header />

      <div className="grid grid-cols-2 md:grid-cols-6 xl:grid-cols-12 gap-4 lg:gap-5">
        {/* Big highlight card */}
        <Glass tint="blue" elevation={3} className="col-span-2 md:col-span-6 xl:col-span-5 xl:row-span-2 p-5 lg:p-6">
          <div className="flex items-start justify-between">
            <div>
              <div className="text-slate-600" style={{ fontSize: 12 }}>当前活跃</div>
              <div className="text-slate-900 mt-1" style={{ fontSize: 22 }}>
                {providers[active].name}
              </div>
              <div className="text-slate-600 mt-1">{providers[active].app} · {providers[active].model}</div>
            </div>
            <div className={`h-14 w-14 rounded-2xl bg-gradient-to-br ${providers[active].color} shadow-[inset_0_1px_0_rgba(255,255,255,0.8),0_12px_30px_-10px_rgba(40,60,160,0.5)] flex items-center justify-center text-white`}>
              {providers[active].glyph}
            </div>
          </div>

          <div className="mt-5 lg:mt-6 grid grid-cols-3 gap-2.5 lg:gap-3">
            {[
              { k: "今日请求", v: "1,284" },
              { k: "Token", v: "342K" },
              { k: "成本", v: "$3.21" },
            ].map((s) => (
              <Glass key={s.k} noHover className="p-3 rounded-2xl">
                <div className="text-slate-600" style={{ fontSize: 11 }}>{s.k}</div>
                <div className="text-slate-900 mt-1">{s.v}</div>
              </Glass>
            ))}
          </div>

          <div className="mt-6 flex items-center gap-2">
            <GlassButton className="from-sky-300/70 to-indigo-300/40">
              <Sparkles className="h-4 w-4" /> 切换提供商
            </GlassButton>
            <GlassButton>编辑配置</GlassButton>
          </div>
        </Glass>

        {/* Provider cards bento */}
        {providers.map((p, i) => (
          <button
            key={p.name}
            onClick={() => setActive(i)}
            className="col-span-1 md:col-span-3 xl:col-span-3 text-left"
          >
            <div className={i === active ? "active-card-border h-full" : "h-full"}>
            <Glass
              elevation={i === active ? 3 : 1}
              tint={i % 2 ? "purple" : "neutral"}
              className="relative p-4 h-full transition-transform hover:-translate-y-0.5"
            >
              <div className="flex items-start justify-between">
                <div className={`h-10 w-10 rounded-xl bg-gradient-to-br ${p.color} shadow-[inset_0_1px_0_rgba(255,255,255,0.8)] flex items-center justify-center text-white`}>
                  {p.glyph}
                </div>
                <span
                  className={
                    "px-2 py-0.5 rounded-full border " +
                    (p.status === "active"
                      ? "bg-emerald-200/60 border-emerald-300/70 text-emerald-800"
                      : p.status === "warn"
                      ? "bg-amber-200/60 border-amber-300/70 text-amber-800"
                      : "bg-white/50 border-white/70 text-slate-700")
                  }
                  style={{ fontSize: 10 }}
                >
                  {p.status === "active" ? "活跃" : p.status === "warn" ? "异常" : "待机"}
                </span>
              </div>
              <div className="mt-3 text-slate-900">{p.name}</div>
              <div className="text-slate-600 mt-0.5" style={{ fontSize: 12 }}>
                {p.app}
              </div>
              {i === active && (
                <span className="absolute bottom-3 right-3 inline-flex items-center gap-1 rounded-xl bg-gradient-to-r from-emerald-400 to-teal-400 px-2.5 py-1 text-white shadow-[0_4px_12px_-2px_rgba(16,185,129,0.6)]" style={{ fontSize: 10 }}>
                  <CheckCircle2 className="h-3 w-3" /> 正在使用
                </span>
              )}
            </Glass>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

function Header() {
  return (
    <div className="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-4">
      <div>
        <div className="text-slate-500" style={{ fontSize: 12 }}>模块 / Providers</div>
        <h2 className="text-slate-900 mt-1" style={{ fontSize: 28 }}>
          提供商管理
        </h2>
        <div className="text-slate-600 mt-1">统一管理 AI 工具的 API 密钥与端点</div>
      </div>
      <div className="flex flex-wrap items-center gap-2">
        <GlassButton><Filter className="h-4 w-4" /> 筛选</GlassButton>
        <GlassButton><ArrowUpDown className="h-4 w-4" /> 排序</GlassButton>
        <GlassButton><Upload className="h-4 w-4" /> 导入</GlassButton>
        <GlassButton><Download className="h-4 w-4" /> 导出</GlassButton>
        <GlassButton className="from-sky-300/80 to-violet-300/50 ring-1 ring-white/60">
          <Plus className="h-4 w-4" /> 新增
        </GlassButton>
        <button className="h-9 w-9 rounded-2xl border border-white/50 bg-white/40 backdrop-blur-xl flex items-center justify-center text-slate-700 hover:bg-white/60">
          <MoreHorizontal className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
}
