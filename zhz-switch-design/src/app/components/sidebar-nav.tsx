import {
  Boxes,
  Server,
  MessageSquareText,
  Sparkles,
  BarChart3,
  KeyRound,
  Settings,
  Search,
  Command,
} from "lucide-react";
import { Glass } from "./glass";
import { cn } from "./ui/utils";

export type ModuleKey =
  | "providers"
  | "mcp"
  | "prompts"
  | "skills"
  | "usage"
  | "env"
  | "settings";

const items: { key: ModuleKey; label: string; icon: any; tint: any; badge?: string }[] = [
  { key: "providers", label: "提供商", icon: Boxes, tint: "blue", badge: "12" },
  { key: "mcp", label: "MCP 服务器", icon: Server, tint: "purple", badge: "8" },
  { key: "prompts", label: "提示词", icon: MessageSquareText, tint: "pink" },
  { key: "skills", label: "技能", icon: Sparkles, tint: "amber", badge: "新" },
  { key: "usage", label: "使用统计", icon: BarChart3, tint: "emerald" },
  { key: "env", label: "环境变量", icon: KeyRound, tint: "neutral" },
  { key: "settings", label: "设置", icon: Settings, tint: "neutral" },
];

export function SidebarNav({
  current,
  onChange,
}: {
  current: ModuleKey;
  onChange: (k: ModuleKey) => void;
}) {
  return (
    <Glass elevation={2} className="h-full w-full lg:w-64 p-4 pt-4 pb-5 lg:p-5 lg:pb-5 flex flex-col gap-4 rounded-3xl">
      {/* Traffic lights */}
      <div className="flex items-center gap-2 px-1 pt-1">
        <span className="h-3 w-3 rounded-full bg-rose-400 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)]" />
        <span className="h-3 w-3 rounded-full bg-amber-400 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)]" />
        <span className="h-3 w-3 rounded-full bg-emerald-400 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)]" />
        <div className="ml-auto flex items-center gap-1 text-slate-600/80">
          <Command className="h-3.5 w-3.5" />
          <span style={{ fontSize: 11 }}>K</span>
        </div>
      </div>

      {/* Brand */}
      <div className="flex items-center gap-3 px-2 pt-2">
        <div className="relative h-10 w-10 rounded-2xl bg-gradient-to-br from-sky-300/80 via-violet-300/70 to-pink-300/70 shadow-[inset_0_1px_0_rgba(255,255,255,0.8),0_8px_20px_-8px_rgba(80,60,200,0.5)]">
          <div className="absolute inset-0 rounded-2xl bg-white/20 backdrop-blur-md" />
          <span className="absolute inset-0 flex items-center justify-center text-white drop-shadow">
            ⌘
          </span>
        </div>
        <div className="leading-tight">
          <div className="text-slate-800">zhz-switch</div>
          <div className="text-slate-500" style={{ fontSize: 11 }}>
            AI 工具链管家
          </div>
        </div>
      </div>

      {/* Search */}
      <div className="relative mt-4">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-500" />
        <input
          placeholder="搜索…"
          className="w-full rounded-2xl border border-white/50 bg-white/30 backdrop-blur-xl pl-9 pr-3 py-2 text-slate-700 placeholder:text-slate-500/70 outline-none focus:ring-2 focus:ring-sky-300/60"
        />
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto flex flex-col gap-1 mt-1">
        {items.map((it) => {
          const Icon = it.icon;
          const active = current === it.key;
          return (
            <button
              key={it.key}
              onClick={() => onChange(it.key)}
              className={cn(
                "group relative flex items-center gap-3 rounded-2xl px-3 py-2.5 text-left transition-all",
                "hover:bg-white/40",
                active &&
                  "bg-gradient-to-r from-white/70 to-white/30 shadow-[inset_0_1px_0_rgba(255,255,255,0.8),0_8px_24px_-12px_rgba(40,60,160,0.45)] ring-1 ring-white/60"
              )}
            >
              <span
                className={cn(
                  "relative flex h-8 w-8 items-center justify-center rounded-xl",
                  "bg-gradient-to-br from-white/70 to-white/20 border border-white/60 shadow-[inset_0_1px_0_rgba(255,255,255,0.8)]"
                )}
              >
                <Icon className="h-4 w-4 text-slate-700" />
              </span>
              <span className="flex-1 text-slate-800">{it.label}</span>
              {it.badge && (
                <span className="rounded-full bg-white/60 border border-white/70 px-2 py-0.5 text-slate-700 shadow-inner" style={{ fontSize: 10 }}>
                  {it.badge}
                </span>
              )}
              {active && (
                <span className="absolute left-0 top-1/2 -translate-y-1/2 h-6 w-1 rounded-r-full bg-gradient-to-b from-sky-400 to-violet-500 shadow-[0_0_12px_rgba(120,120,255,0.7)]" />
              )}
            </button>
          );
        })}
      </nav>

      <div className="shrink-0">
        <Glass tint="emerald" noHover className="rounded-2xl p-3">
          <div className="relative pr-7">
            <div className="absolute top-0 right-0 h-5 w-5 rounded-lg bg-gradient-to-br from-emerald-300 to-teal-400 shadow-inner flex items-center justify-center text-white" style={{ fontSize: 10 }}>
              ✦
            </div>
            <div className="leading-tight">
              <div className="text-slate-800">同步正常</div>
              <div className="text-slate-600" style={{ fontSize: 11 }}>
                2 秒前 · 4 个应用
              </div>
            </div>
          </div>
        </Glass>
      </div>
    </Glass>
  );
}
