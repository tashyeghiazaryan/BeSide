import { motion } from "motion/react";
import { ChevronLeft, Bell } from "lucide-react";

export interface NotificationItem {
  id: string;
  title: string;
  subtitle?: string;
  timeLabel: string;
  read: boolean;
}

interface NotificationsScreenProps {
  onBack: () => void;
  /** Optional feed; defaults to sample items for preview */
  items?: NotificationItem[];
}

const DEFAULT_ITEMS: NotificationItem[] = [
  { id: "1", title: "Alex reacted to your mood", timeLabel: "2h ago", read: false },
  { id: "2", title: "Upcoming: Our Anniversary", subtitle: "In 5 days", timeLabel: "Yesterday", read: false },
  { id: "3", title: "New love note is waiting", timeLabel: "2d ago", read: true },
];

export function NotificationsScreen({ onBack, items = DEFAULT_ITEMS }: NotificationsScreenProps) {
  return (
    <motion.div
      className="fixed inset-0 z-[40] flex justify-center bg-[#f2ede4]"
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", stiffness: 320, damping: 32 }}
    >
      <div className="flex h-full w-full max-w-md flex-col shadow-[inset_1px_0_0_rgba(0,0,0,0.04)]">
      <header
        className="flex shrink-0 items-center gap-1 border-b border-black/[0.06] px-2 pb-3"
        style={{ paddingTop: "max(0.75rem, env(safe-area-inset-top))" }}
      >
        <button
          type="button"
          onClick={onBack}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-black/55 transition hover:bg-black/[0.05] active:scale-95"
          aria-label="Back"
        >
          <ChevronLeft className="h-6 w-6" strokeWidth={1.75} />
        </button>
        <h1 className="flex-1 pr-11 text-center text-[1.05rem] text-black/75" style={{ fontWeight: 300, letterSpacing: "0.03em" }}>
          Notifications
        </h1>
      </header>

      <div
        className="min-h-0 flex-1 overflow-y-auto px-4 py-4"
        style={{ paddingBottom: "max(1.5rem, env(safe-area-inset-bottom))" }}
      >
        {items.length === 0 ? (
          <div className="flex flex-col items-center justify-center gap-3 px-6 py-20 text-center">
            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-black/[0.04] text-black/25">
              <Bell className="h-7 w-7" strokeWidth={1.5} />
            </div>
            <p className="text-[15px] text-black/45" style={{ fontWeight: 300 }}>
              No notifications yet
            </p>
          </div>
        ) : (
          <ul className="flex flex-col gap-2">
            {items.map((n) => (
              <li key={n.id}>
                <button
                  type="button"
                  className="w-full rounded-xl border border-black/[0.06] bg-white/60 px-3.5 py-3 text-left transition active:scale-[0.99]"
                  style={{
                    boxShadow: n.read ? "none" : "0 0 0 1px rgba(251,191,36,0.25)",
                  }}
                >
                  <div className="flex items-start justify-between gap-2">
                    <p className="text-[14px] leading-snug text-gray-800" style={{ fontWeight: n.read ? 400 : 600 }}>
                      {n.title}
                    </p>
                    <span className="shrink-0 text-[11px] text-black/35" style={{ fontWeight: 300 }}>
                      {n.timeLabel}
                    </span>
                  </div>
                  {n.subtitle ? (
                    <p className="mt-1 text-[12px] text-black/40" style={{ fontWeight: 300 }}>
                      {n.subtitle}
                    </p>
                  ) : null}
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
      </div>
    </motion.div>
  );
}
