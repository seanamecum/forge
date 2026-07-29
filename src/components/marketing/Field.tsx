"use client";

import { useId, type ReactNode } from "react";
import { HONEYPOT_FIELD } from "@/lib/marketing/rate-limit";

/**
 * Spam honeypot — visually hidden and off the tab order, so humans never see or
 * reach it, but bots that fill every field will populate it. The server drops
 * any submission where it's non-empty. Not display:none (some bots skip those).
 */
export function Honeypot({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <div
      aria-hidden="true"
      style={{ position: "absolute", left: "-9999px", top: "auto", width: 1, height: 1, overflow: "hidden" }}
    >
      <label htmlFor={HONEYPOT_FIELD}>Company website (leave this field blank)</label>
      <input
        id={HONEYPOT_FIELD}
        name={HONEYPOT_FIELD}
        type="text"
        tabIndex={-1}
        autoComplete="off"
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  );
}

export function Label({ htmlFor, children, required }: { htmlFor: string; children: ReactNode; required?: boolean }) {
  return (
    <label
      htmlFor={htmlFor}
      className="mb-1.5 block text-[11px] font-semibold uppercase tracking-[0.14em] text-obsidian-100"
    >
      {children}
      {required && <span className="ml-1 text-gold-300">*</span>}
    </label>
  );
}

function ErrorText({ id, error }: { id: string; error?: string }) {
  if (!error) return null;
  return (
    <p id={id} className="mt-1.5 text-xs text-forge-ruby" role="alert">
      {error}
    </p>
  );
}

export function TextField({
  label,
  value,
  onChange,
  error,
  required,
  type = "text",
  placeholder,
  autoComplete,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  error?: string;
  required?: boolean;
  type?: string;
  placeholder?: string;
  autoComplete?: string;
}) {
  const id = useId();
  return (
    <div>
      <Label htmlFor={id} required={required}>{label}</Label>
      <input
        id={id}
        type={type}
        className="input"
        value={value}
        placeholder={placeholder}
        autoComplete={autoComplete}
        aria-required={required}
        aria-invalid={!!error}
        aria-describedby={error ? `${id}-err` : undefined}
        onChange={(e) => onChange(e.target.value)}
      />
      <ErrorText id={`${id}-err`} error={error} />
    </div>
  );
}

export function SelectField({
  label,
  value,
  onChange,
  options,
  error,
  required,
  placeholder = "Select…",
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  options: readonly string[];
  error?: string;
  required?: boolean;
  placeholder?: string;
}) {
  const id = useId();
  return (
    <div>
      <Label htmlFor={id} required={required}>{label}</Label>
      <div className="relative">
        <select
          id={id}
          className="input appearance-none pr-9"
          value={value}
          aria-required={required}
          aria-invalid={!!error}
          aria-describedby={error ? `${id}-err` : undefined}
          onChange={(e) => onChange(e.target.value)}
        >
          <option value="" disabled>{placeholder}</option>
          {options.map((o) => (
            <option key={o} value={o}>{o}</option>
          ))}
        </select>
        <span className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-obsidian-200">▾</span>
      </div>
      <ErrorText id={`${id}-err`} error={error} />
    </div>
  );
}

export function TextArea({
  label,
  value,
  onChange,
  error,
  required,
  placeholder,
  rows = 4,
  maxLength,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  error?: string;
  required?: boolean;
  placeholder?: string;
  rows?: number;
  maxLength?: number;
}) {
  const id = useId();
  return (
    <div>
      <Label htmlFor={id} required={required}>{label}</Label>
      <textarea
        id={id}
        className="input resize-none"
        rows={rows}
        value={value}
        maxLength={maxLength}
        placeholder={placeholder}
        aria-required={required}
        aria-invalid={!!error}
        aria-describedby={error ? `${id}-err` : undefined}
        onChange={(e) => onChange(e.target.value)}
      />
      <ErrorText id={`${id}-err`} error={error} />
    </div>
  );
}

/** Multi-select chip group — used for "current apps". */
export function ChipGroup({
  label,
  options,
  selected,
  onToggle,
}: {
  label: string;
  options: readonly string[];
  selected: string[];
  onToggle: (v: string) => void;
}) {
  return (
    <fieldset>
      <legend className="mb-1.5 block text-[11px] font-semibold uppercase tracking-[0.14em] text-obsidian-100">
        {label}
      </legend>
      <div className="flex flex-wrap gap-2">
        {options.map((o) => {
          const on = selected.includes(o);
          return (
            <button
              key={o}
              type="button"
              aria-pressed={on}
              onClick={() => onToggle(o)}
              className={`rounded-full border px-3 py-1.5 text-xs font-medium transition ${
                on
                  ? "border-gold-400/60 bg-gold-400/10 text-gold-200"
                  : "border-white/10 bg-obsidian-850 text-obsidian-100 hover:border-gold-400/30 hover:text-cream-100"
              }`}
            >
              {o}
            </button>
          );
        })}
      </div>
    </fieldset>
  );
}

export function Checkbox({
  checked,
  onChange,
  children,
  error,
}: {
  checked: boolean;
  onChange: (v: boolean) => void;
  children: ReactNode;
  error?: string;
}) {
  const id = useId();
  return (
    <div>
      <label htmlFor={id} className="flex cursor-pointer items-start gap-3 text-sm text-cream-200">
        <input
          id={id}
          type="checkbox"
          checked={checked}
          aria-invalid={!!error}
          aria-describedby={error ? `${id}-err` : undefined}
          onChange={(e) => onChange(e.target.checked)}
          className="mt-0.5 h-4 w-4 shrink-0 cursor-pointer accent-gold-400"
        />
        <span>{children}</span>
      </label>
      <ErrorText id={`${id}-err`} error={error} />
    </div>
  );
}
