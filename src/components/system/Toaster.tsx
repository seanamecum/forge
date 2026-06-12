"use client";

import { useEffect, useState } from "react";

export function Toaster() {
  const [msg, setMsg] = useState<string | null>(null);

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    const onToast = (e: Event) => {
      setMsg((e as CustomEvent<string>).detail);
      clearTimeout(timer);
      timer = setTimeout(() => setMsg(null), 2800);
    };
    window.addEventListener("forge-toast", onToast);
    return () => {
      window.removeEventListener("forge-toast", onToast);
      clearTimeout(timer);
    };
  }, []);

  if (!msg) return null;
  return (
    <div className="fixed bottom-24 left-1/2 z-[99] -translate-x-1/2 rounded-xl border border-gold-400/40 bg-obsidian-800/95 px-5 py-3 text-sm text-cream-100 shadow-gold backdrop-blur lg:bottom-8">
      <span className="mr-2 text-gold-300">✦</span>
      {msg}
    </div>
  );
}
