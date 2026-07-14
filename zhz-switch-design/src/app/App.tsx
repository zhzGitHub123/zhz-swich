import { useState } from "react";
import { SidebarNav, ModuleKey } from "./components/sidebar-nav";
import { ProvidersView } from "./components/providers-view";
import { UsageView } from "./components/usage-view";
import {
  McpView,
  PromptsView,
  SkillsView,
  EnvView,
  SettingsView,
} from "./components/other-views";

export default function App() {
  const [tab, setTab] = useState<ModuleKey>("providers");

  return (
    <div className="relative size-full overflow-hidden">
      {/* Ambient desktop wallpaper */}
      <div className="absolute inset-0 -z-10 bg-gradient-to-br from-[#e8efff] via-[#f3e8ff] to-[#ffe8f1]" />
      <div className="absolute inset-0 -z-10 opacity-90">
        <div className="absolute -top-32 -left-32 h-[42rem] w-[42rem] rounded-full bg-sky-300/40 blur-[120px]" />
        <div className="absolute top-1/3 -right-32 h-[36rem] w-[36rem] rounded-full bg-fuchsia-300/40 blur-[120px]" />
        <div className="absolute -bottom-32 left-1/3 h-[34rem] w-[34rem] rounded-full bg-amber-200/50 blur-[120px]" />
      </div>
      {/* subtle film grain */}
      <div
        className="absolute inset-0 -z-10 opacity-[0.06] mix-blend-overlay pointer-events-none"
        style={{
          backgroundImage:
            "radial-gradient(rgba(0,0,0,0.6) 1px, transparent 1px)",
          backgroundSize: "3px 3px",
        }}
      />

      <div className="h-full w-full p-3 sm:p-4 lg:p-6 flex flex-col lg:flex-row gap-4 lg:gap-6">
        <div className="lg:sticky lg:top-6 lg:self-start lg:h-[calc(100vh-3rem)] shrink-0">
          <SidebarNav current={tab} onChange={setTab} />
        </div>
        <main className="flex-1 min-w-0 overflow-auto px-3 lg:px-4 -mx-3 lg:-mx-4">
          <div className="min-h-full pt-2 pb-12 max-w-[1400px] mx-auto">
            {tab === "providers" && <ProvidersView />}
            {tab === "mcp" && <McpView />}
            {tab === "prompts" && <PromptsView />}
            {tab === "skills" && <SkillsView />}
            {tab === "usage" && <UsageView />}
            {tab === "env" && <EnvView />}
            {tab === "settings" && <SettingsView />}
          </div>
        </main>
      </div>
    </div>
  );
}
