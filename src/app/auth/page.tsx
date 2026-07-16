"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { signIn, signUp, sendReset } from "@/lib/auth";

type Mode = "signin" | "signup" | "reset";

export default function AuthPage() {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>("signin");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setNotice(null);
    const result =
      mode === "signin"
        ? await signIn(email, password)
        : mode === "signup"
          ? await signUp(email, password, name)
          : await sendReset(email);
    setBusy(false);
    if (!result.ok) {
      setError(result.error);
    } else if ("notice" in result) {
      setNotice(result.notice);
      if (mode === "reset") setMode("signin");
    } else {
      router.push("/dashboard");
    }
  }

  const title =
    mode === "signin" ? "Welcome back" : mode === "signup" ? "Create your account" : "Reset password";

  return (
    <main className="min-h-screen bg-forge flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        <Link href="/" className="block text-center mb-8 font-display text-2xl text-cream-100">
          FORGE
        </Link>
        <div className="card p-8">
          <h1 className="font-display text-2xl text-cream-100 mb-1">{title}</h1>
          <p className="text-xs text-cream-100/50 mb-6">
            {mode === "signup"
              ? "14 days free. No card required."
              : mode === "reset"
                ? "We'll email you a reset link."
                : "Sign in to The Forge."}
          </p>

          <form onSubmit={submit} className="space-y-4">
            {mode === "signup" && (
              <Field label="Name" type="text" value={name} onChange={setName} autoComplete="name" />
            )}
            <Field label="Email" type="email" value={email} onChange={setEmail} autoComplete="email" />
            {mode !== "reset" && (
              <Field
                label="Password"
                type="password"
                value={password}
                onChange={setPassword}
                autoComplete={mode === "signup" ? "new-password" : "current-password"}
              />
            )}

            {error && <p className="text-xs text-red-400">{error}</p>}
            {notice && <p className="text-xs text-gold-300">{notice}</p>}

            <button type="submit" disabled={busy} className="btn-gold w-full disabled:opacity-60">
              {busy
                ? "One moment…"
                : mode === "signin"
                  ? "Sign in"
                  : mode === "signup"
                    ? "Begin"
                    : "Send reset link"}
            </button>
          </form>

          <div className="mt-6 flex items-center justify-between text-xs text-cream-100/60">
            {mode === "signin" ? (
              <>
                <button className="hover:text-gold-200" onClick={() => setMode("signup")}>
                  Create an account
                </button>
                <button className="hover:text-gold-200" onClick={() => setMode("reset")}>
                  Forgot password?
                </button>
              </>
            ) : (
              <button className="hover:text-gold-200" onClick={() => setMode("signin")}>
                ← Back to sign in
              </button>
            )}
          </div>
        </div>

        <p className="text-center text-[11px] text-cream-100/40 mt-6">
          Just exploring?{" "}
          <Link href="/dashboard" className="text-gold-300 hover:text-gold-200">
            View the live demo
          </Link>{" "}
          — no account needed.
        </p>
      </div>
    </main>
  );
}

function Field(props: {
  label: string;
  type: string;
  value: string;
  onChange: (v: string) => void;
  autoComplete: string;
}) {
  return (
    <label className="block">
      <span className="block text-[10px] font-semibold tracking-[0.14em] uppercase text-cream-100/50 mb-1.5">
        {props.label}
      </span>
      <input
        type={props.type}
        value={props.value}
        required
        autoComplete={props.autoComplete}
        onChange={(e) => props.onChange(e.target.value)}
        className="w-full rounded-xl bg-black/40 border border-white/10 px-4 py-3 text-sm text-cream-100 outline-none focus:border-gold-400/60"
      />
    </label>
  );
}
