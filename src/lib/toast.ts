// Tiny app-wide toast bus. Call toast("…") from any client component;
// the <Toaster/> in the app layout renders it.
export function toast(message: string) {
  if (typeof window !== "undefined") {
    window.dispatchEvent(new CustomEvent("forge-toast", { detail: message }));
  }
}
