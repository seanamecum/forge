"use client";

import { useState, useRef, useEffect } from "react";
import { coachReply, CoachMessage } from "@/lib/ai/coach";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { user, today } from "@/lib/mock/user";

const QUICK_PROMPTS = [
  "What should I do today?",
  "Why am I tired?",
  "What should I eat?",
  "Should I train hard today?",
  "Why is my bench not increasing?",
  "How do I recover from this injury?",
  "What should I change this week?",
];

export default function CoachPage() {
  const [messages, setMessages] = useState<CoachMessage[]>([
    {
      role: "coach",
      text: `Hi ${user.name.split(" ")[0]}. I see your full picture — sleep, HRV, today's workout, what you've eaten, the shoulder you've been rehabbing, the lift you tested Monday. Ask me anything.`,
      suggestions: QUICK_PROMPTS.slice(0, 4),
    },
  ]);
  const [input, setInput] = useState("");
  const [thinking, setThinking] = useState(false);
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, thinking]);

  function send(q: string) {
    if (!q.trim()) return;
    const userMsg: CoachMessage = { role: "user", text: q };
    setMessages((m) => [...m, userMsg]);
    setInput("");
    setThinking(true);
    setTimeout(() => {
      setMessages((m) => [...m, coachReply(q)]);
      setThinking(false);
    }, 700);
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr,320px]">
      <div>
        <SectionTitle
          eyebrow="The Brain"
          title="AI Coach"
          subtitle="Trained on your training, nutrition, recovery, sleep, supplements, wearables, injuries, and goals."
          right={
            <span className="hidden sm:inline-flex chip chip-gold">
              <span className="dot dot-gold animate-pulse-gold" /> Live · Synced 2m ago
            </span>
          }
        />

        <div className="card relative flex h-[640px] flex-col overflow-hidden">
          {/* Messages */}
          <div className="flex-1 space-y-4 overflow-y-auto px-5 py-5">
            {messages.map((m, i) => (
              <MessageBubble key={i} msg={m} onSuggest={send} />
            ))}
            {thinking && (
              <div className="flex items-center gap-2 text-[11px] uppercase tracking-[0.2em] text-gold-300">
                <span className="animate-pulse-gold">✦</span> coach is thinking
                <span className="ml-1 inline-flex gap-1">
                  <span className="dot dot-gold animate-pulse-gold" />
                  <span className="dot dot-gold animate-pulse-gold" style={{ animationDelay: "0.2s" }} />
                  <span className="dot dot-gold animate-pulse-gold" style={{ animationDelay: "0.4s" }} />
                </span>
              </div>
            )}
            <div ref={endRef} />
          </div>

          {/* Composer */}
          <div className="border-t border-gold-400/10 bg-obsidian-900/60 px-4 py-3">
            <form
              onSubmit={(e) => {
                e.preventDefault();
                send(input);
              }}
              className="flex items-center gap-2"
            >
              <input
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Ask the Coach…"
                className="input flex-1"
              />
              <button type="submit" className="btn-gold">
                Ask
              </button>
            </form>
          </div>
        </div>
      </div>

      <aside className="space-y-4">
        <div className="card p-5">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Coach context</div>
          <div className="mt-2 space-y-1.5 text-xs">
            <ContextRow label="Forge Score" value={`${today.forgeScore} (+${today.forgeScoreDelta})`} />
            <ContextRow label="Recovery" value={`${today.recovery}`} />
            <ContextRow label="HRV" value={`${today.hrv} ms (Δ ${today.hrvDelta})`} />
            <ContextRow label="Sleep" value={`${today.sleepHours} h`} />
            <ContextRow label="Protein" value={`${today.proteinIn}/${user.targets.protein} g`} />
            <ContextRow label="Hydration" value={`${today.hydrationPct}%`} />
            <ContextRow label="Injury" value="R shoulder · phase 3" />
            <ContextRow label="Goal" value="Athletic performance" />
            <ContextRow label="Streak" value={`${user.streakDays} d 🔥`} />
          </div>
        </div>

        <div className="card p-5">
          <div className="text-[10px] uppercase tracking-[0.22em] text-gold-300">Quick prompts</div>
          <div className="mt-2 space-y-1.5">
            {QUICK_PROMPTS.map((q) => (
              <button
                key={q}
                onClick={() => send(q)}
                className="block w-full rounded-md border border-gold-400/10 bg-obsidian-800/50 px-3 py-2 text-left text-[12px] text-cream-200 hover:border-gold-400/30 hover:text-cream-50"
              >
                {q}
              </button>
            ))}
          </div>
        </div>

        <div className="rounded-lg border border-gold-400/10 bg-obsidian-800/30 p-4 text-[11px] text-obsidian-200">
          The Coach offers educational guidance — not medical advice. For severe pain, concussion, or
          concerning bloodwork: see a licensed clinician.
        </div>
      </aside>
    </div>
  );
}

function MessageBubble({
  msg,
  onSuggest,
}: {
  msg: CoachMessage;
  onSuggest: (q: string) => void;
}) {
  if (msg.role === "user") {
    return (
      <div className="flex justify-end">
        <div className="max-w-[80%] rounded-2xl rounded-tr-sm bg-gold-400/10 px-4 py-2.5 text-sm text-cream-50 border border-gold-400/20">
          {msg.text}
        </div>
      </div>
    );
  }

  return (
    <div className="flex gap-3">
      <div className="grid h-8 w-8 shrink-0 place-items-center rounded-full border border-gold-400/30 bg-obsidian-900 text-gold-300">
        ✦
      </div>
      <div className="max-w-[88%] space-y-3">
        <div className="rounded-2xl rounded-tl-sm border border-gold-400/15 bg-obsidian-800/70 px-4 py-3 text-[14px] leading-relaxed text-cream-100">
          {msg.text}
        </div>

        {msg.steps && (
          <details className="rounded-lg border border-gold-400/10 bg-obsidian-900/50 p-3">
            <summary className="cursor-pointer text-[10px] uppercase tracking-[0.18em] text-gold-300">
              Reasoning chain · {msg.steps.length} steps
            </summary>
            <ol className="mt-2 space-y-1 text-[12px] text-cream-200">
              {msg.steps.map((s, i) => (
                <li key={i} className="flex gap-2">
                  <span className="text-gold-300/70">{i + 1}.</span>
                  <span>{s}</span>
                </li>
              ))}
            </ol>
          </details>
        )}

        {msg.cards && (
          <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
            {msg.cards.map((c, i) => (
              <div
                key={i}
                className={`rounded-md border p-3 text-[11px] ${
                  c.tone === "good"
                    ? "border-forge-green/30 bg-forge-green/5"
                    : c.tone === "warn"
                    ? "border-forge-amber/30 bg-forge-amber/5"
                    : c.tone === "bad"
                    ? "border-forge-ruby/30 bg-forge-ruby/5"
                    : "border-gold-400/15 bg-obsidian-800/40"
                }`}
              >
                <div className="text-[9px] uppercase tracking-[0.18em] text-obsidian-200">
                  {c.label}
                </div>
                <div
                  className={`mt-1 text-sm ${
                    c.tone === "good"
                      ? "text-forge-green"
                      : c.tone === "warn"
                      ? "text-forge-amber"
                      : c.tone === "bad"
                      ? "text-forge-ruby"
                      : "text-cream-100"
                  }`}
                >
                  {c.value}
                </div>
              </div>
            ))}
          </div>
        )}

        {msg.suggestions && (
          <div className="flex flex-wrap gap-2 pt-1">
            {msg.suggestions.map((s) => (
              <button
                key={s}
                onClick={() => onSuggest(s)}
                className="rounded-full border border-gold-400/20 bg-obsidian-800/60 px-3 py-1 text-[11px] text-cream-200 hover:border-gold-400/50 hover:text-cream-50"
              >
                {s}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function ContextRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between border-b border-gold-400/5 pb-1.5">
      <span className="text-obsidian-200">{label}</span>
      <span className="text-cream-100">{value}</span>
    </div>
  );
}
