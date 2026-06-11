"use client";

import { useState } from "react";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { coaches, programs, products } from "@/lib/mock/marketplace";

const TABS = ["Coaches", "Programs", "Affiliate Store"] as const;

export default function MarketplacePage() {
  const [tab, setTab] = useState<(typeof TABS)[number]>("Coaches");

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Marketplace"
        title="Coaches · Programs · Gear"
        subtitle="Curated for athletes. Vetted coaches, real programs, gear we actually use."
      />

      <div className="flex flex-wrap gap-1.5 border-b border-gold-400/10 pb-3">
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`rounded-full px-4 py-1.5 text-[12px] uppercase tracking-wider transition ${
              tab === t ? "bg-gold-400/15 text-gold-200" : "text-cream-200 hover:bg-obsidian-700/50"
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      {tab === "Coaches" && (
        <div className="grid gap-4 lg:grid-cols-3">
          {coaches.map((c) => (
            <div key={c.id} className="card card-hover p-5">
              <div className="mb-2 flex items-center gap-3">
                <div className="grid h-12 w-12 place-items-center rounded-full bg-gold-gradient text-[14px] font-semibold text-obsidian-900">
                  {c.name.split(" ").map((p) => p[0]).join("").slice(0, 2)}
                </div>
                <div>
                  <div className="text-sm text-cream-50">{c.name}</div>
                  <div className="text-[11px] text-obsidian-200">{c.credentials}</div>
                </div>
              </div>
              <div className="text-[11px] text-gold-300">{c.specialty}</div>
              <p className="mt-2 text-[12px] text-cream-200">{c.bio}</p>
              <div className="mt-3 flex items-center justify-between text-[11px] text-obsidian-200">
                <span>★ {c.rating} · {c.clients} clients</span>
                <span className="text-gold-grad">{c.price}</span>
              </div>
              <button className="btn-gold mt-3 w-full text-[11px]">Book intro call</button>
            </div>
          ))}
        </div>
      )}

      {tab === "Programs" && (
        <div className="grid gap-4 lg:grid-cols-3">
          {programs.map((p) => (
            <div key={p.id} className="card card-hover p-5">
              <div className="mb-2 flex items-baseline justify-between gap-2">
                <div className="display text-lg text-cream-50">{p.name}</div>
                <span className="text-sm text-gold-grad">{p.price}</span>
              </div>
              <div className="text-[11px] text-obsidian-200">By {p.coach} · {p.level}</div>
              <p className="mt-2 text-[12px] text-cream-200">{p.focus}</p>
              <div className="mt-3 grid grid-cols-3 gap-2 text-center text-[11px]">
                <div className="rounded-md border border-gold-400/10 bg-obsidian-800/40 p-2">
                  <div className="text-obsidian-200">Weeks</div>
                  <div className="text-cream-100">{p.weeks}</div>
                </div>
                <div className="rounded-md border border-gold-400/10 bg-obsidian-800/40 p-2">
                  <div className="text-obsidian-200">Sessions/wk</div>
                  <div className="text-cream-100">{p.dpw}</div>
                </div>
                <div className="rounded-md border border-gold-400/10 bg-obsidian-800/40 p-2">
                  <div className="text-obsidian-200">Buyers</div>
                  <div className="text-cream-100">{p.buyers}</div>
                </div>
              </div>
              <button className="btn-gold mt-3 w-full text-[11px]">Add to library</button>
            </div>
          ))}
        </div>
      )}

      {tab === "Affiliate Store" && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {products.map((p) => (
            <div key={p.id} className="card card-hover p-4">
              <div className="aspect-square rounded-md bg-obsidian-700/60 grid place-items-center text-3xl text-gold-300/30">
                ❖
              </div>
              <div className="mt-2 text-[11px] text-obsidian-200">{p.brand}</div>
              <div className="text-sm text-cream-50">{p.name}</div>
              <div className="mt-1 flex items-baseline justify-between">
                <span className="text-[11px] text-gold-300">★ {p.rating}</span>
                <span className="text-sm text-gold-grad">{p.price}</span>
              </div>
              {p.tag && <span className="mt-2 inline-block chip chip-gold">{p.tag}</span>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
