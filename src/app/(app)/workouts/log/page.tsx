"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { SectionTitle } from "@/components/ui/SectionTitle";
import { todaysWorkout } from "@/lib/mock/workouts";
import { useForge } from "@/lib/store";
import { toast } from "@/lib/toast";

type LoggedSet = { reps: string; weight: string; rpe: string; done: boolean };

export default function LogPage() {
  const [sets, setSets] = useState<Record<number, LoggedSet[]>>(() => {
    const seed: Record<number, LoggedSet[]> = {};
    todaysWorkout.exercises.forEach((_, i) => {
      seed[i] = [
        { reps: "", weight: "", rpe: "", done: false },
        { reps: "", weight: "", rpe: "", done: false },
        { reps: "", weight: "", rpe: "", done: false },
      ];
    });
    return seed;
  });
  const [restSec, setRestSec] = useState(0);
  const [restActive, setRestActive] = useState(false);
  const [startedAt] = useState(() => Date.now());
  const forge = useForge();
  const router = useRouter();

  function finishSession() {
    const done = Object.values(sets).flat().filter((s) => s.done);
    if (done.length === 0) {
      toast("Log at least one set before finishing");
      return;
    }
    const volumeKg = Math.round(
      done.reduce((sum, s) => sum + (parseFloat(s.weight) || 0) * (parseInt(s.reps) || 0), 0)
    );
    const durationMin = Math.max(1, Math.round((Date.now() - startedAt) / 60000));
    forge.addSession({
      name: todaysWorkout.name,
      date: "Today",
      durationMin,
      volumeKg,
      sets: done.length,
    });
    forge.addXp(180);
    toast(`Session saved · ${done.length} sets · ${volumeKg.toLocaleString()} lb volume · +180 XP`);
    router.push("/workouts");
  }

  function updateSet(exIdx: number, setIdx: number, field: keyof LoggedSet, value: any) {
    setSets((s) => ({
      ...s,
      [exIdx]: s[exIdx].map((x, i) => (i === setIdx ? { ...x, [field]: value } : x)),
    }));
  }

  function completeSet(exIdx: number, setIdx: number) {
    updateSet(exIdx, setIdx, "done", true);
    setRestSec(150);
    setRestActive(true);
    const interval = setInterval(() => {
      setRestSec((r) => {
        if (r <= 1) {
          clearInterval(interval);
          setRestActive(false);
          return 0;
        }
        return r - 1;
      });
    }, 1000);
  }

  const totalSets = Object.values(sets).flat().length;
  const completedSets = Object.values(sets).flat().filter((s) => s.done).length;

  return (
    <div className="space-y-6">
      <SectionTitle
        eyebrow="Train · Logger"
        title={todaysWorkout.name}
        subtitle={`${todaysWorkout.exercises.length} exercises · ~${todaysWorkout.durationMin} min · ${completedSets}/${totalSets} sets`}
        right={
          <button className="btn-gold shrink-0 whitespace-nowrap" onClick={finishSession}>
            Finish →
          </button>
        }
      />

      {/* Rest timer overlay */}
      {restActive && (
        <div className="card card-gold sticky top-20 z-20 flex items-center justify-between gap-3 p-4">
          <div>
            <div className="text-[10px] uppercase tracking-[0.18em] text-gold-300">Rest</div>
            <div className="stat-num text-2xl text-gold-grad">
              {Math.floor(restSec / 60)}:{String(restSec % 60).padStart(2, "0")}
            </div>
          </div>
          <div className="text-[11px] text-obsidian-200">
            Suggested 2:30 for compound · 1:00 for accessory
          </div>
          <button onClick={() => setRestActive(false)} className="btn-ghost text-xs">
            Skip
          </button>
        </div>
      )}

      <div className="space-y-3">
        {todaysWorkout.exercises.map((ex, exIdx) => (
          <div key={exIdx} className="card p-5">
            <div className="mb-3 flex flex-wrap items-baseline justify-between gap-2">
              <div>
                <div className="flex items-center gap-3">
                  <span className="grid h-6 w-6 place-items-center rounded-full border border-gold-400/30 bg-obsidian-900 text-[11px] text-gold-300">
                    {exIdx + 1}
                  </span>
                  <h3 className="text-base text-cream-50">{ex.name}</h3>
                </div>
                <div className="mt-1 ml-9 text-[12px] text-obsidian-200">{ex.prescription}</div>
              </div>
              <button className="btn-quiet text-xs" onClick={() => toast(`Swapped ${ex.name} for the closest knee-safe alternative`)}>Swap</button>
            </div>

            <div className="overflow-hidden rounded-md border border-gold-400/8">
              <div className="grid grid-cols-[40px,1fr,1fr,1fr,60px] bg-obsidian-900/60 px-3 py-2 text-[10px] uppercase tracking-[0.18em] text-obsidian-200">
                <span>#</span>
                <span>Weight</span>
                <span>Reps</span>
                <span>RPE</span>
                <span></span>
              </div>
              {sets[exIdx].map((s, setIdx) => (
                <div
                  key={setIdx}
                  className={`grid grid-cols-[40px,1fr,1fr,1fr,60px] items-center gap-2 px-3 py-2 ${
                    s.done ? "bg-forge-green/5" : "bg-obsidian-800/30"
                  }`}
                >
                  <span className="text-sm text-cream-200">{setIdx + 1}</span>
                  <input
                    value={s.weight}
                    onChange={(e) => updateSet(exIdx, setIdx, "weight", e.target.value)}
                    placeholder="lb"
                    className="input !py-1.5 !text-sm"
                  />
                  <input
                    value={s.reps}
                    onChange={(e) => updateSet(exIdx, setIdx, "reps", e.target.value)}
                    placeholder="reps"
                    className="input !py-1.5 !text-sm"
                  />
                  <input
                    value={s.rpe}
                    onChange={(e) => updateSet(exIdx, setIdx, "rpe", e.target.value)}
                    placeholder="rpe"
                    className="input !py-1.5 !text-sm"
                  />
                  <button
                    onClick={() => completeSet(exIdx, setIdx)}
                    className={
                      s.done
                        ? "rounded-md bg-forge-green/15 px-2 py-1 text-[11px] text-forge-green"
                        : "rounded-md border border-gold-400/30 bg-gold-400/5 px-2 py-1 text-[11px] text-gold-200 hover:bg-gold-400/15"
                    }
                  >
                    {s.done ? "✓" : "Log"}
                  </button>
                </div>
              ))}
            </div>

            <button
              onClick={() =>
                setSets((s) => ({
                  ...s,
                  [exIdx]: [...s[exIdx], { reps: "", weight: "", rpe: "", done: false }],
                }))
              }
              className="mt-2 text-[11px] text-gold-300 hover:text-gold-200"
            >
              + Add set
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}
