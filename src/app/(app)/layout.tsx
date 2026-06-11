import { Sidebar } from "@/components/layout/Sidebar";
import { TopBar } from "@/components/layout/TopBar";
import { BottomDock } from "@/components/layout/BottomDock";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-mesh">
      <Sidebar />
      <div className="lg:pl-64">
        <TopBar />
        <main className="px-4 pb-28 pt-6 sm:px-6 lg:px-10">
          <div className="fade-in mx-auto max-w-[1400px]">{children}</div>
        </main>
      </div>
      <BottomDock />
    </div>
  );
}
