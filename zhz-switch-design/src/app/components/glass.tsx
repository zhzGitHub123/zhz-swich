import { ReactNode, HTMLAttributes } from "react";
import { cn } from "./ui/utils";

interface GlassProps extends HTMLAttributes<HTMLDivElement> {
  children?: ReactNode;
  elevation?: 1 | 2 | 3;
  tint?: "neutral" | "blue" | "purple" | "pink" | "amber" | "emerald";
  noHover?: boolean;
}

const tintMap: Record<string, string> = {
  neutral: "from-white/40 to-white/10",
  blue: "from-sky-200/20 to-blue-300/5",
  purple: "from-violet-200/40 to-fuchsia-300/10",
  pink: "from-pink-200/40 to-rose-300/10",
  amber: "from-amber-200/40 to-orange-300/10",
  emerald: "from-emerald-200/40 to-teal-300/10",
};

export function Glass({
  children,
  className,
  elevation = 1,
  tint = "neutral",
  noHover = false,
  ...rest
}: GlassProps) {
  const shadow = "shadow-[0_10px_30px_-12px_rgba(30,40,80,0.18),0_2px_6px_-2px_rgba(30,40,80,0.08)]";

  return (
    <div
      {...rest}
      className={cn(
        "group relative rounded-3xl border border-white/40 backdrop-blur-2xl backdrop-saturate-150 overflow-hidden",
        "bg-gradient-to-br",
        tintMap[tint],
        shadow,
        className
      )}
    >
      {/* refraction highlight */}
      <div className="pointer-events-none absolute inset-0 rounded-3xl">
        <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-white/80 to-transparent" />
        <div className="absolute inset-y-0 left-0 w-px bg-gradient-to-b from-white/60 via-transparent to-transparent" />
        <div className="absolute -top-10 -left-10 h-40 w-40 rounded-full bg-white/30 blur-3xl" />
        <div className="absolute -bottom-16 -right-10 h-48 w-48 rounded-full bg-white/10 blur-3xl" />
      </div>
      {/* scanline texture */}
      <div className="pointer-events-none absolute inset-0">
        {/* scanline texture */}
        <div
          className="absolute inset-0 opacity-[0.04] mix-blend-overlay"
          style={{
            backgroundImage:
              "repeating-linear-gradient(0deg, rgba(255,255,255,0.5) 0 1px, transparent 1px 3px)",
          }}
        />
        {/* flowing hover aurora */}
        {!noHover && <div className="absolute -inset-1 opacity-0 group-hover:opacity-100 transition-opacity duration-700 mix-blend-screen [animation:glassAurora_7s_ease-in-out_infinite]"
          style={{
            background:
              "conic-gradient(from 0deg at 30% 40%, rgba(125,200,255,0.35), rgba(200,150,255,0.30) 25%, rgba(255,180,220,0.30) 50%, rgba(180,255,220,0.30) 75%, rgba(125,200,255,0.35))",
            filter: "blur(38px)",
          }}
        />}
        {/* moving highlight streak */}
        {!noHover && <div className="absolute inset-y-0 -left-1/3 w-1/2 opacity-0 group-hover:opacity-100 transition-opacity duration-500 [animation:glassSheen_3.2s_ease-in-out_infinite] mix-blend-overlay"
          style={{
            background:
              "linear-gradient(110deg, transparent 30%, rgba(255,255,255,0.55) 50%, transparent 70%)",
            filter: "blur(6px)",
          }}
        />}
      </div>
      <div className="relative">{children}</div>
    </div>
  );
}

export function GlassButton({
  children,
  className,
  active,
  ...rest
}: HTMLAttributes<HTMLButtonElement> & { active?: boolean }) {
  return (
    <button
      {...rest}
      className={cn(
        "relative inline-flex items-center gap-2 rounded-2xl px-4 py-2 border border-white/40 backdrop-blur-xl transition-all",
        "bg-gradient-to-br from-white/50 to-white/10 text-slate-800",
        "hover:from-white/70 hover:to-white/20 hover:-translate-y-px",
        "active:translate-y-px active:scale-[0.98]",
        "shadow-[0_6px_20px_-10px_rgba(20,20,40,0.4),inset_0_1px_0_rgba(255,255,255,0.6)]",
        active && "from-sky-300/70 to-indigo-300/40 ring-1 ring-white/60",
        className
      )}
    >
      {children}
    </button>
  );
}
