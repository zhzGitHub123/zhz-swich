import {
  Plus,
  Upload,
  RefreshCw,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  Trash2,
  Edit3,
  Eye,
  Star,
  Download,
  Tag,
  Eye as EyeIcon,
  EyeOff,
  Search,
  Moon,
  Sun,
  Monitor,
} from "lucide-react";
import { Glass, GlassButton } from "./glass";
import { useState } from "react";

function Header({ title, sub, actions }: { title: string; sub: string; actions: any }) {
  return (
    <div className="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-4">
      <div>
        <div className="text-slate-500" style={{ fontSize: 12 }}>模块</div>
        <h2 className="text-slate-900 mt-1" style={{ fontSize: 28 }}>{title}</h2>
        <div className="text-slate-600 mt-1">{sub}</div>
      </div>
      <div className="flex flex-wrap items-center gap-2">{actions}</div>
    </div>
  );
}

/* ========== MCP ========== */
const mcpServers = [
  { name: "filesystem", cmd: "npx @mcp/fs", app: "Claude", status: "ok", enabled: true },
  { name: "github", cmd: "npx @mcp/github", app: "Claude · Codex", status: "ok", enabled: true },
  { name: "supabase", cmd: "uvx supabase-mcp", app: "Claude", status: "warn", enabled: true },
  { name: "browser", cmd: "npx @mcp/browser", app: "Gemini", status: "off", enabled: false },
  { name: "postgres", cmd: "uvx pg-mcp", app: "Claude · Codex", status: "ok", enabled: true },
  { name: "slack", cmd: "npx @mcp/slack", app: "Codex", status: "warn", enabled: false },
];

export function McpView() {
  return (
    <div className="flex flex-col gap-5 lg:gap-7">
      <Header
        title="MCP 服务器"
        sub="Model Context Protocol · 上下文桥接"
        actions={
          <>
            <GlassButton><RefreshCw className="h-4 w-4" /> 同步</GlassButton>
            <GlassButton><Upload className="h-4 w-4" /> 导入</GlassButton>
            <GlassButton className="from-violet-300/80 to-fuchsia-300/40"><Plus className="h-4 w-4" /> 新增</GlassButton>
          </>
        }
      />

      <div className="flex flex-wrap items-center gap-2">
        {["全部", "Claude", "Codex", "Gemini", "通义"].map((t, i) => (
          <GlassButton key={t} active={i === 0}>{t}</GlassButton>
        ))}
      </div>

      <div className="grid grid-cols-2 md:grid-cols-6 xl:grid-cols-12 gap-4 lg:gap-5">
        {mcpServers.map((s, i) => (
          <Glass
            key={s.name}
            tint={i % 3 === 0 ? "purple" : i % 3 === 1 ? "blue" : "neutral"}
            elevation={2}
            className="col-span-2 md:col-span-3 xl:col-span-4 p-4 lg:p-5"
          >
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="h-11 w-11 rounded-2xl bg-gradient-to-br from-white/80 to-white/30 border border-white/60 shadow-inner flex items-center justify-center text-slate-800">
                  {s.name.slice(0, 2).toUpperCase()}
                </div>
                <div>
                  <div className="text-slate-900 font-bold">{s.name}</div>
                  <div className="text-slate-600 font-mono" style={{ fontSize: 11 }}>{s.cmd}</div>
                </div>
              </div>
              <StatusPill status={s.status} />
            </div>
            <div className="mt-4 flex items-center justify-between">
              <div className="text-slate-600" style={{ fontSize: 12 }}>{s.app}</div>
              <Toggle on={s.enabled} />
            </div>
          </Glass>
        ))}
      </div>
    </div>
  );
}

function StatusPill({ status }: { status: string }) {
  const map: any = {
    ok: { c: "bg-emerald-200/60 border-emerald-300/70 text-emerald-800", i: <CheckCircle2 className="h-3 w-3" />, t: "正常" },
    warn: { c: "bg-amber-200/60 border-amber-300/70 text-amber-800", i: <AlertTriangle className="h-3 w-3" />, t: "异常" },
    off: { c: "bg-rose-200/60 border-rose-300/70 text-rose-800", i: <XCircle className="h-3 w-3" />, t: "离线" },
  };
  const m = map[status];
  return (
    <span className={`inline-flex items-center gap-1 rounded-full border px-2 py-0.5 ${m.c}`} style={{ fontSize: 10 }}>
      {m.i} {m.t}
    </span>
  );
}

function Toggle({ on: initial = false }: { on?: boolean }) {
  const [on, setOn] = useState(initial);
  return (
    <button
      onClick={() => setOn(!on)}
      className={
        "relative h-7 w-12 rounded-full transition-all border border-white/60 shadow-inner " +
        (on
          ? "bg-gradient-to-r from-emerald-300 to-teal-400"
          : "bg-white/40")
      }
    >
      <span
        className={
          "absolute top-0.5 h-6 w-6 rounded-full bg-white shadow-[0_4px_10px_-2px_rgba(0,0,0,0.3),inset_0_1px_0_rgba(255,255,255,0.9)] transition-all " +
          (on ? "left-[22px]" : "left-0.5")
        }
      />
    </button>
  );
}

/* ========== Prompts ========== */
const prompts = [
  { name: "代码评审专家", cat: "开发", preview: "你是一位资深代码评审专家，请按可读性…", app: "Claude", tag: "review" },
  { name: "PRD 草稿生成", cat: "产品", preview: "根据以下用户故事，输出标准 PRD 文档…", app: "通用", tag: "pm" },
  { name: "SQL 优化助手", cat: "数据", preview: "请分析下方 SQL 的执行计划并给出优化…", app: "Codex", tag: "sql" },
  { name: "翻译润色 (中↔英)", cat: "写作", preview: "保留语气与风格，进行高质量双向翻译…", app: "Gemini", tag: "i18n" },
  { name: "Bug 复盘模板", cat: "开发", preview: "按 5 Whys 方法引导用户复盘根因…", app: "Claude", tag: "ops" },
  { name: "周报生成", cat: "办公", preview: "把零碎的 commit & TODO 列表整理为周报…", app: "通用", tag: "report" },
];

export function PromptsView() {
  return (
    <div className="flex flex-col gap-5 lg:gap-7">
      <Header
        title="提示词库"
        sub="可复用的 AI 提示词预设"
        actions={
          <>
            <GlassButton><Upload className="h-4 w-4" /> 导入</GlassButton>
            <GlassButton><Download className="h-4 w-4" /> 导出</GlassButton>
            <GlassButton className="from-pink-300/80 to-rose-300/40"><Plus className="h-4 w-4" /> 新建</GlassButton>
          </>
        }
      />

      <div className="grid grid-cols-2 md:grid-cols-6 xl:grid-cols-12 gap-4 lg:gap-5">
        {prompts.map((p, i) => (
          <Glass key={p.name} tint={["pink","blue","purple","emerald"][i % 4] as any} className="col-span-4 p-5">
            <div className="flex items-center justify-between">
              <span className="inline-flex items-center gap-1 rounded-full bg-white/60 border border-white/70 px-2 py-0.5 text-slate-700" style={{ fontSize: 10 }}>
                <Tag className="h-3 w-3" /> {p.cat}
              </span>
              <Toggle on />
            </div>
            <div className="text-slate-900 mt-3 font-bold">{p.name}</div>
            <div className="text-slate-600 mt-2 line-clamp-2" style={{ fontSize: 12 }}>{p.preview}</div>
            <div className="mt-4 flex items-center justify-between">
              <div className="text-slate-600" style={{ fontSize: 11 }}>#{p.tag} · {p.app}</div>
              <div className="flex items-center gap-1 text-slate-700">
                <button className="h-7 w-7 rounded-xl bg-white/40 hover:bg-white/60 flex items-center justify-center"><Eye className="h-3.5 w-3.5" /></button>
                <button className="h-7 w-7 rounded-xl bg-white/40 hover:bg-white/60 flex items-center justify-center"><Edit3 className="h-3.5 w-3.5" /></button>
                <button className="h-7 w-7 rounded-xl bg-white/40 hover:bg-white/60 flex items-center justify-center"><Trash2 className="h-3.5 w-3.5" /></button>
              </div>
            </div>
          </Glass>
        ))}
      </div>
    </div>
  );
}

/* ========== Skills ========== */
const skills = [
  { name: "deep-research", v: "1.4.0", repo: "anthropics/skills", rating: 4.9, dl: "12.4k", on: true },
  { name: "verify", v: "0.9.1", repo: "anthropics/skills", rating: 4.7, dl: "8.1k", on: true },
  { name: "code-review", v: "2.1.0", repo: "make-kits/code", rating: 4.8, dl: "9.2k", on: true },
  { name: "supabase", v: "0.3.2", repo: "supabase/mcp-skills", rating: 4.5, dl: "4.6k", on: false },
];

export function SkillsView() {
  return (
    <div className="flex flex-col gap-5 lg:gap-7">
      <Header
        title="技能市场"
        sub="发现、安装与管理插件"
        actions={
          <>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-500" />
              <input placeholder="搜索技能…" className="rounded-2xl border border-white/50 bg-white/40 backdrop-blur-xl pl-9 pr-3 py-2 text-slate-700 outline-none focus:ring-2 focus:ring-amber-300/60" />
            </div>
            <GlassButton className="from-amber-300/80 to-orange-300/40"><Plus className="h-4 w-4" /> 安装</GlassButton>
          </>
        }
      />

      <div className="grid grid-cols-2 md:grid-cols-6 xl:grid-cols-12 gap-4 lg:gap-5">
        <Glass tint="amber" elevation={3} className="col-span-2 md:col-span-6 xl:col-span-12 p-5 lg:p-6">
          <div className="flex items-center justify-between">
            <div>
              <div className="text-slate-600" style={{ fontSize: 12 }}>推荐</div>
              <div className="text-slate-900 mt-1 font-bold" style={{ fontSize: 22 }}>deep-research · 多源验证研究</div>
              <div className="text-slate-600 mt-1">扇出搜索 → 反事实验证 → 引文综合</div>
            </div>
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-1 text-amber-700">
                <Star className="h-4 w-4 fill-amber-400 stroke-amber-500" /> 4.9
              </div>
              <GlassButton className="from-amber-300/80 to-orange-300/40"><Download className="h-4 w-4" /> 安装</GlassButton>
            </div>
          </div>
        </Glass>

        {skills.map((s, i) => (
          <Glass key={s.name} tint={i % 2 ? "blue" : "neutral"} className="col-span-1 md:col-span-3 xl:col-span-3 p-4 lg:p-5">
            <div className="flex items-start justify-between">
              <div className="h-11 w-11 rounded-2xl bg-gradient-to-br from-amber-200 to-orange-300 shadow-inner flex items-center justify-center text-white">✦</div>
              <Toggle on={s.on} />
            </div>
            <div className="text-slate-900 mt-3 font-bold">{s.name}</div>
            <div className="text-slate-600" style={{ fontSize: 12 }}>v{s.v} · {s.repo}</div>
            <div className="mt-3 flex items-center justify-between text-slate-700" style={{ fontSize: 12 }}>
              <span className="inline-flex items-center gap-1"><Star className="h-3 w-3 fill-amber-400 stroke-amber-500" /> {s.rating}</span>
              <span>{s.dl}</span>
            </div>
          </Glass>
        ))}
      </div>
    </div>
  );
}

/* ========== Env ========== */
const envs = [
  { k: "ANTHROPIC_API_KEY", v: "sk-ant-************", app: "Claude", level: "高", hidden: true },
  { k: "OPENAI_API_KEY", v: "sk-************", app: "Codex", level: "高", hidden: true },
  { k: "HTTP_PROXY", v: "http://127.0.0.1:7890", app: "全局", level: "中", hidden: false },
  { k: "GEMINI_API_KEY", v: "AIza************", app: "Gemini", level: "高", hidden: true },
  { k: "NO_PROXY", v: "localhost,127.0.0.1", app: "全局", level: "低", hidden: false },
];

export function EnvView() {
  const [reveal, setReveal] = useState<Record<number, boolean>>({});
  return (
    <div className="flex flex-col gap-5 lg:gap-7">
      <Header
        title="环境变量"
        sub="API 密钥、代理与全局参数"
        actions={
          <>
            <GlassButton><Upload className="h-4 w-4" /> 从 .env 导入</GlassButton>
            <GlassButton><Download className="h-4 w-4" /> 导出</GlassButton>
            <GlassButton className="from-sky-300/80 to-violet-300/40"><Plus className="h-4 w-4" /> 新增</GlassButton>
          </>
        }
      />

      <Glass tint="amber" className="p-4 flex items-center gap-3">
        <AlertTriangle className="h-5 w-5 text-amber-700" />
        <div className="text-slate-800">检测到 <b>HTTP_PROXY</b> 在 Codex 与全局存在冲突。</div>
        <GlassButton className="ml-auto">查看建议</GlassButton>
      </Glass>

      <Glass elevation={2} className="overflow-x-auto">
        <table className="w-full min-w-[720px] text-left">
          <thead className="bg-white/30 text-slate-600" style={{ fontSize: 12 }}>
            <tr>
              {["变量名","值","应用","优先级","操作"].map(h => (
                <th key={h} className="px-5 py-3">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="text-slate-800">
            {envs.map((e, i) => (
              <tr key={i} className="border-t border-white/40 hover:bg-white/30">
                <td className="px-5 py-3 font-mono">{e.k}</td>
                <td className="px-5 py-3 font-mono">
                  <div className="flex items-center gap-2">
                    <span>{e.hidden && !reveal[i] ? "•••••••••••••••" : e.v}</span>
                    {e.hidden && (
                      <button onClick={() => setReveal({ ...reveal, [i]: !reveal[i] })} className="h-6 w-6 rounded-lg bg-white/40 hover:bg-white/60 flex items-center justify-center">
                        {reveal[i] ? <EyeOff className="h-3.5 w-3.5" /> : <EyeIcon className="h-3.5 w-3.5" />}
                      </button>
                    )}
                  </div>
                </td>
                <td className="px-5 py-3">{e.app}</td>
                <td className="px-5 py-3">
                  <span className={
                    "rounded-full px-2 py-0.5 border " +
                    (e.level === "高" ? "bg-rose-200/60 border-rose-300/70 text-rose-800" :
                     e.level === "中" ? "bg-amber-200/60 border-amber-300/70 text-amber-800" :
                     "bg-emerald-200/60 border-emerald-300/70 text-emerald-800")
                  } style={{ fontSize: 11 }}>{e.level}</span>
                </td>
                <td className="px-5 py-3">
                  <div className="flex items-center gap-1">
                    <button className="h-7 w-7 rounded-xl bg-white/40 hover:bg-white/60 flex items-center justify-center"><Edit3 className="h-3.5 w-3.5" /></button>
                    <button className="h-7 w-7 rounded-xl bg-white/40 hover:bg-white/60 flex items-center justify-center"><Trash2 className="h-3.5 w-3.5" /></button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Glass>
    </div>
  );
}

/* ========== Settings ========== */
export function SettingsView() {
  return (
    <div className="flex flex-col gap-5 lg:gap-7">
      <Header title="系统设置" sub="通用偏好与数据管理" actions={null} />

      <div className="grid grid-cols-2 md:grid-cols-6 xl:grid-cols-12 gap-4 lg:gap-5">
        <Glass tint="blue" elevation={2} className="col-span-2 md:col-span-6 xl:col-span-6 p-4 lg:p-5">
          <div className="text-slate-900 mb-4 font-bold">外观</div>
          <div className="grid grid-cols-3 gap-3">
            {[
              { k: "浅色", Icon: Sun, active: false },
              { k: "深色", Icon: Moon, active: false },
              { k: "跟随系统", Icon: Monitor, active: true },
            ].map(({ k, Icon, active }) => (
              <button key={k} className={
                "rounded-2xl p-4 border transition-all " +
                (active
                  ? "bg-gradient-to-br from-sky-300/70 to-indigo-300/40 border-white/70 ring-1 ring-white/70 shadow-[inset_0_1px_0_rgba(255,255,255,0.8)]"
                  : "bg-white/30 border-white/50 hover:bg-white/50")
              }>
                <Icon className="h-5 w-5 text-slate-700 mb-2" />
                <div className="text-slate-800 font-bold">{k}</div>
              </button>
            ))}
          </div>

          <div className="mt-6 space-y-3">
            <Row label="开机启动" right={<Toggle on />} />
            <Row label="最小化到托盘" right={<Toggle on />} />
            <Row label="启用胶片颗粒" right={<Toggle />} />
            <Row label="启用扫描线纹理" right={<Toggle on />} />
          </div>
        </Glass>

        <Glass tint="purple" elevation={2} className="col-span-2 md:col-span-6 xl:col-span-6 p-4 lg:p-5">
          <div className="text-slate-900 mb-4 font-bold">数据 & 备份</div>
          <div className="space-y-3">
            <Row label="数据库位置" right={<span className="text-slate-600 font-mono" style={{ fontSize: 12 }}>~/Library/zhz-switch</span>} />
            <Row label="自动备份" right={<Toggle on />} />
            <Row label="缓存大小" right={<span className="text-slate-700">142 MB</span>} />
          </div>
          <div className="mt-5 flex flex-wrap gap-2">
            <GlassButton>立即备份</GlassButton>
            <GlassButton>从备份恢复</GlassButton>
            <GlassButton>清空缓存</GlassButton>
          </div>
        </Glass>

        <Glass elevation={2} className="col-span-2 md:col-span-6 xl:col-span-12 p-4 lg:p-5">
          <div className="flex items-center justify-between">
            <div>
              <div className="text-slate-900 font-bold">关于 zhz-switch</div>
              <div className="text-slate-600 mt-1" style={{ fontSize: 12 }}>版本 1.2.6 · macOS Sonoma · MIT License</div>
            </div>
            <div className="flex items-center gap-2">
              <GlassButton>检查更新</GlassButton>
              <GlassButton>贡献者</GlassButton>
            </div>
          </div>
        </Glass>
      </div>
    </div>
  );
}

function Row({ label, right }: { label: string; right: any }) {
  return (
    <div className="flex items-center justify-between rounded-2xl bg-white/30 border border-white/50 px-4 py-3">
      <div className="text-slate-800">{label}</div>
      <div>{right}</div>
    </div>
  );
}
