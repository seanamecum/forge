"use client";

import { useState, useRef, useEffect } from "react";
import { coachReply, CoachMessage } from "@/lib/ai/coach";
import { user } from "@/lib/mock/user";

const QUICK_PROMPTS = [
  "What should I do today?",
  "Why am I tired?",
  "What should I eat?",
];

// Minimal coach: bubbles, three chips, one pill input. Nothing else.
export default function CoachPage() {
  const [messages, setMessages] = useState<CoachMessage[]>([
    {
      role: "coach",
      text: `Hi ${user.name.split(" ")[0]}. I see your full picture — sleep, HRV, today's workout, what you've eaten, the shoulder you've been rehabbing. Ask me anything.`,
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
    setMessages((m) => [...m, { role: "user", text: q }]);
    setInput("");
    setThinking(true);
    setTimeout(() => {
      setMessages((m) => [...m, coachReply(q)]);
      setThinking(false);
    }, 700);
  }

  return (
    <div className="mx-auto flex h-[calc(100dvh-140px)] max-w-2xl flex-col pb-4">
      {/* Messages */}
      <div className="flex-1 space-y-4 overflow-y-auto py-6">
        {messages.map((m, i) => (
          <Bubble key={i} msg={m} />
        ))}
        {thinking && (
          <div className="text-[12px] text-obsidian-200">Coach is thinking…</div>
        )}
        <div ref={endRef} />
      </div>

      {/* Chips — only before the conversation gets going */}
      {messages.length < 3 && (
        <div className="mb-3 flex flex-wrap gap-2">
          {QUICK_PROMPTS.map((q) => (
            <button
              key={q}
              onClick={() => send(q)}
              className="rounded-full border border-white/[0.06] px-4 py-2 text-[12px] text-cream-300 transition-colors hover:text-cream-100"
            >
              {q}
            </button>
          ))}
        </div>
      )}

      {/* Pill input */}
      <form
        onSubmit={(e) => {
          e.preventDefault();
          send(input);
        }}
        className="flex items-center gap-2 rounded-full border border-white/[0.06] bg-obsidian-900 py-1.5 pl-5 pr-1.5"
      >
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Ask the Coach…"
          className="flex-1 bg-transparent text-sm text-cream-100 placeholder-obsidian-300 outline-none"
        />
        <button
          type="submit"
          aria-label="Send"
          className="flex h-9 w-9 items-center justify-center rounded-full bg-gold-400 text-obsidian-950"
        >
          ↑
        </button>
      </form>

      <p className="mt-3 text-center text-[10px] text-obsidian-300">
        Educational guidance, not medical advice.
      </p>
    </div>
  );
}

function Bubble({ msg }: { msg: CoachMessage }) {
  if (msg.role === "user") {
    return (
      <div className="flex justify-end">
        <div className="max-w-[80%] rounded-2xl rounded-tr-md bg-gold-400/10 px-4 py-2.5 text-sm text-cream-100">
          {msg.text}
        </div>
      </div>
    );
  }
  return (
    <div className="flex justify-start">
      <div className="max-w-[85%] rounded-2xl rounded-tl-md border border-white/[0.06] bg-obsidian-800 px-4 py-3 text-sm leading-relaxed text-cream-100">
        {msg.text}
      </div>
    </div>
  );
}
