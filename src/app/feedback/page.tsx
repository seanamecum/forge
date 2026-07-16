"use client";

import { useState } from "react";
import Link from "next/link";
import { submitFeedback } from "@/lib/feedback";

export default function FeedbackPage() {
  const [message, setMessage] = useState("");
  const [email, setEmail] = useState("");
  const [busy, setBusy] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const ok = await submitFeedback(message.trim(), email.trim() || null);
    setBusy(false);
    if (ok) setSent(true);
    else setError("Couldn't send — check your connection and try again.");
  }

  return (
    <main className="min-h-screen bg-forge flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <Link href="/" className="block text-center mb-8 font-display text-2xl text-cream-100">
          FORGE
        </Link>
        <div className="card p-8">
          {sent ? (
            <div className="text-center py-6">
              <h1 className="font-display text-2xl text-cream-100 mb-2">Received</h1>
              <p className="text-xs text-cream-100/50 mb-6">
                Every note gets read. Thank you for making Forge better.
              </p>
              <Link href="/" className="btn-gold inline-block">
                Back to Forge
              </Link>
            </div>
          ) : (
            <>
              <h1 className="font-display text-2xl text-cream-100 mb-1">Send feedback</h1>
              <p className="text-xs text-cream-100/50 mb-6">
                What&apos;s broken, confusing, or missing? Raw and unfiltered helps most — it goes
                straight to the founder.
              </p>
              <form onSubmit={submit} className="space-y-4">
                <textarea
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  rows={5}
                  required
                  minLength={3}
                  maxLength={4000}
                  placeholder="Tell us what you think…"
                  className="w-full rounded-xl bg-black/30 border border-white/10 px-4 py-3 text-sm text-cream-100 placeholder:text-cream-100/30 focus:outline-none focus:border-gold-300/60"
                />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Email (optional — for a reply)"
                  className="w-full rounded-xl bg-black/30 border border-white/10 px-4 py-3 text-sm text-cream-100 placeholder:text-cream-100/30 focus:outline-none focus:border-gold-300/60"
                />
                {error && <p className="text-xs text-red-400">{error}</p>}
                <button
                  type="submit"
                  disabled={busy || message.trim().length < 3}
                  className="btn-gold w-full disabled:opacity-60"
                >
                  {busy ? "Sending…" : "Send feedback"}
                </button>
              </form>
            </>
          )}
        </div>
        <p className="text-center text-[11px] text-cream-100/40 mt-6">
          Prefer email?{" "}
          <a href="mailto:seana.mecum@gmail.com" className="text-gold-300 hover:text-gold-200">
            Write to the founder directly
          </a>
          .
        </p>
      </div>
    </main>
  );
}
