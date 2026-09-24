import { useMemo, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { moods, needsByMood, type MoodType } from "./moods";
import { Clock, Calendar, Heart } from "lucide-react";

// Mock data for partner's current mood
const partnerMood = moods.find((m) => m.id === "stressed")!;
const partnerWish = "Just listen without judging.";
const partnerTimestamp = new Date(Date.now() - 45 * 60 * 1000);

const MAX_DAY_MOODS = 15;

// Reactions mapped to mood+wish combos
const reactionsMap: Record<string, string[]> = {
  calm: [
    "🫖 Make them a warm cup of tea",
    "🤫 Give them quiet space nearby",
    "📖 Suggest reading together tonight",
    "🌿 Send a calming playlist",
  ],
  joy: [
    "🎉 Plan a surprise mini-date tonight",
    "💌 Send a sweet voice message",
    "🎶 Share a song that reminds you of them",
    "🍦 Bring home their favorite treat",
  ],
  love: [
    "💐 Write them a little love note",
    "📵 Suggest a phone-free evening",
    "🕯️ Set up a cozy atmosphere at home",
    "💬 Tell them what you love about them",
  ],
  sad: [
    "🤗 Give them a long, warm hug",
    "🎬 Suggest watching their comfort movie",
    "🍫 Bring their favorite comfort food",
    "💬 Ask how you can help today",
  ],
  exhausted: [
    "🍽️ Handle dinner tonight",
    "🛁 Run a warm bath for them",
    "📱 Don't expect quick replies today",
    "🧹 Take over chores without asking",
  ],
  stressed: [
    "👂 Listen without trying to fix things",
    "🧘 Suggest a short breathing exercise together",
    "🚶 Offer a calming walk outside",
    "💆 Give them a shoulder massage",
  ],
};

// Mock mood history — each day can have multiple moods
interface DayMoodEntry {
  mood: MoodType;
  wish: string;
  time: string;
}

const moodById = (id: string) => moods.find((m) => m.id === id)!;

const wishFor = (id: string, index = 0) => {
  const list = needsByMood[id] ?? ["…"];
  return list[index % list.length];
};

const formatTime = (date: Date) =>
  date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });

const formatDate = (date: Date) =>
  date.toLocaleDateString([], { month: "short", day: "numeric" });

/** Past days (Mon–Sat). Today is built separately and always ends with the current partner mood. */
const pastWeekDays: { day: string; entries: DayMoodEntry[] }[] = [
  {
    day: "Mon",
    entries: [
      { mood: moodById("calm"), wish: wishFor("calm", 0), time: "9:30 AM" },
      { mood: moodById("stressed"), wish: wishFor("stressed", 0), time: "6:15 PM" },
    ],
  },
  {
    day: "Tue",
    entries: [{ mood: moodById("stressed"), wish: wishFor("stressed", 2), time: "11:00 AM" }],
  },
  {
    day: "Wed",
    entries: [
      { mood: moodById("sad"), wish: wishFor("sad", 0), time: "8:45 AM" },
      { mood: moodById("calm"), wish: wishFor("calm", 2), time: "3:20 PM" },
      { mood: moodById("stressed"), wish: wishFor("stressed", 0), time: "6:00 PM" },
      { mood: moodById("love"), wish: wishFor("love", 2), time: "9:00 PM" },
    ],
  },
  {
    day: "Thu",
    entries: [{ mood: moodById("calm"), wish: wishFor("calm", 1), time: "10:00 AM" }],
  },
  {
    day: "Fri",
    entries: [{ mood: moodById("love"), wish: wishFor("love", 0), time: "7:30 PM" }],
  },
  {
    day: "Sat",
    entries: [
      { mood: moodById("joy"), wish: wishFor("joy", 2), time: "12:00 PM" },
      { mood: moodById("joy"), wish: wishFor("joy", 1), time: "5:45 PM" },
    ],
  },
];

/** Earlier mood check-ins today (before the latest). Last slot is always the current hero mood. */
const todayEarlierEntries: DayMoodEntry[] = [
  { mood: moodById("calm"), wish: wishFor("calm", 0), time: "8:15 AM" },
  { mood: moodById("joy"), wish: wishFor("joy", 2), time: "10:40 AM" },
  { mood: moodById("love"), wish: wishFor("love", 2), time: "12:20 PM" },
  { mood: moodById("sad"), wish: wishFor("sad", 2), time: "2:05 PM" },
  { mood: moodById("exhausted"), wish: wishFor("exhausted", 1), time: "4:10 PM" },
];

const buildTodayEntries = (
  currentMood: MoodType,
  currentWish: string,
  currentTime: Date,
): DayMoodEntry[] => {
  const latest: DayMoodEntry = {
    mood: currentMood,
    wish: currentWish,
    time: formatTime(currentTime),
  };
  const earlier = todayEarlierEntries.slice(0, Math.max(0, MAX_DAY_MOODS - 1));
  return [...earlier, latest].slice(-MAX_DAY_MOODS);
};

const getMoodFeeling = (mood: MoodType): string => {
  const map: Record<string, string> = {
    calm: "calm and balanced",
    joy: "joyful",
    love: "loving and connected",
    sad: "sad and vulnerable",
    exhausted: "exhausted",
    stressed: "stressed",
  };
  return map[mood.id] || mood.label.toLowerCase();
};

interface PartnerScreenProps {
  /** When false, shows locked invite modal over a blurred preview. */
  isPaired?: boolean;
  inviteCode?: string;
  onInvite?: () => void;
  onCopyCode?: () => void;
  onJoin?: (code: string) => void;
  onSendReaction?: (emoji: string) => void;
  sentReaction?: string | null;
}

type PairModalStep = "choose" | "invite" | "join";

export function PartnerScreen({
  isPaired = false,
  inviteCode = "BESIDE-4K2M",
  onInvite,
  onCopyCode,
  onJoin,
  onSendReaction,
  sentReaction,
}: PartnerScreenProps) {
  const [expandedDay, setExpandedDay] = useState<string | null>(null);
  const [showReactionPicker, setShowReactionPicker] = useState(false);
  const [justSentReaction, setJustSentReaction] = useState(false);
  const [codeCopied, setCodeCopied] = useState(false);
  const [pairStep, setPairStep] = useState<PairModalStep>("choose");
  const [joinCode, setJoinCode] = useState("");

  const reactionEmojis = ["❤️", "🤗", "😊", "👏", "💪", "🔥", "😍", "💐"];

  const moodHistoryData = useMemo(
    () => [
      ...pastWeekDays,
      {
        day: "Today",
        entries: buildTodayEntries(partnerMood, partnerWish, partnerTimestamp),
      },
    ],
    [],
  );

  const handleSendReaction = (emoji: string) => {
    onSendReaction?.(emoji);
    setShowReactionPicker(false);
    setJustSentReaction(true);
    setTimeout(() => setJustSentReaction(false), 2000);
  };

  const handleCopyCode = () => {
    onCopyCode?.();
    if (typeof navigator !== "undefined" && navigator.clipboard?.writeText) {
      void navigator.clipboard.writeText(inviteCode);
    }
    setCodeCopied(true);
    setTimeout(() => setCodeCopied(false), 1800);
  };

  const reactions = reactionsMap[partnerMood.id] || reactionsMap.joy;

  const expandedDayData = moodHistoryData.find((d) => d.day === expandedDay) ?? null;

  const handleDayTap = (day: string, entries: DayMoodEntry[]) => {
    if (!isPaired || entries.length === 0) return;
    setExpandedDay(expandedDay === day ? null : day);
  };

  return (
    <>
      <style>{`
        .mood-day-scroll {
          scrollbar-width: thin;
          scrollbar-color: rgba(0, 0, 0, 0.14) rgba(255, 255, 255, 0.55);
        }
        .mood-day-scroll::-webkit-scrollbar {
          width: 4px;
        }
        .mood-day-scroll::-webkit-scrollbar-track {
          background: rgba(255, 255, 255, 0.45);
          border-radius: 999px;
        }
        .mood-day-scroll::-webkit-scrollbar-thumb {
          background: rgba(0, 0, 0, 0.14);
          border-radius: 999px;
        }
        .mood-day-scroll::-webkit-scrollbar-thumb:hover {
          background: rgba(0, 0, 0, 0.22);
        }
      `}</style>
      <div
        className={isPaired ? undefined : "pointer-events-none select-none"}
        style={
          isPaired
            ? undefined
            : {
                filter: "blur(5px)",
                opacity: 0.72,
                transform: "scale(1.02)",
                transformOrigin: "center top",
              }
        }
        aria-hidden={!isPaired}
      >
      {/* Ambient blurs — mood-colored */}
      <motion.div
        className="absolute top-0 -left-24 w-[28rem] h-[28rem] rounded-full blur-[160px]"
        style={{ background: partnerMood.gradient }}
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 0.22, scale: 1 }}
        transition={{ duration: 1.4 }}
      />
      <motion.div
        className="absolute bottom-32 -right-20 w-96 h-96 rounded-full blur-[140px]"
        style={{ background: partnerMood.gradient }}
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 0.16, scale: 1 }}
        transition={{ duration: 1.4, delay: 0.3 }}
      />
      <motion.div
        className="absolute top-1/3 left-1/2 -translate-x-1/2 w-60 h-60 rounded-full blur-[120px]"
        style={{ background: partnerMood.gradient }}
        initial={{ opacity: 0 }}
        animate={{ opacity: 0.08 }}
        transition={{ duration: 1.6, delay: 0.5 }}
      />

      <div className="relative z-10 min-h-screen flex flex-col pb-24 max-w-md mx-auto">
        <div className="h-12 shrink-0" />

        <div className="flex-1 overflow-y-auto px-5">
          {/* Header */}
          <motion.h1
            className="text-black/70 text-center mb-2"
            style={{ fontWeight: 200, letterSpacing: "0.03em" }}
            initial={{ opacity: 0, y: -16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7 }}
          >
            Your partner's mood
          </motion.h1>

          {/* Feeling description */}
          <motion.p
            className="text-center mb-6"
            style={{
              fontWeight: 300,
              color: `${partnerMood.color}cc`,
              letterSpacing: "0.01em",
            }}
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.15 }}
          >
            Alex feels {getMoodFeeling(partnerMood)} today
          </motion.p>

          {/* ====== MAIN MOOD CARD — HERO ====== */}
          <motion.div
            className="relative w-full rounded-[1.75rem] overflow-hidden backdrop-blur-3xl border"
            style={{
              background: `linear-gradient(155deg, ${partnerMood.color}20, ${partnerMood.color}0a 40%, rgba(255,255,255,0.55) 100%)`,
              borderColor: `${partnerMood.color}35`,
              boxShadow: `0 16px 56px ${partnerMood.color}20, 0 6px 24px rgba(0,0,0,0.06), inset 0 1px 0 rgba(255,255,255,0.6)`,
            }}
            initial={{ opacity: 0, y: 24, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.7, delay: 0.2, type: "spring", stiffness: 200, damping: 24 }}
          >
            {/* Accent strip top */}
            <div
              className="h-[3px] w-full"
              style={{
                background: `linear-gradient(90deg, ${partnerMood.color}80, ${partnerMood.color}40, ${partnerMood.color}10, transparent)`,
              }}
            />

            {/* Inner glow overlay */}
            <div
              className="absolute inset-0 pointer-events-none"
              style={{
                background: `radial-gradient(ellipse at 20% 30%, ${partnerMood.color}12 0%, transparent 60%)`,
              }}
            />

            <div className="relative px-5 pt-5 pb-5">
              <div className="flex items-start gap-4">
                <div className="relative shrink-0">
                  {/* Outer glow pulse */}
                  <motion.div
                    className="absolute inset-[-10px] rounded-full blur-xl"
                    style={{ background: partnerMood.gradient }}
                    animate={{
                      opacity: [0.35, 0.6, 0.35],
                      scale: [1, 1.2, 1],
                    }}
                    transition={{
                      duration: 3.5,
                      repeat: Infinity,
                      ease: "easeInOut",
                    }}
                  />

                  {/* Sphere */}
                  <motion.div
                    className="relative w-[4.5rem] h-[4.5rem] rounded-full overflow-hidden backdrop-blur-xl"
                    style={{
                      background: `linear-gradient(135deg, ${partnerMood.color}95, ${partnerMood.color}55)`,
                      border: "2.5px solid rgba(255,255,255,0.75)",
                      boxShadow: `0 0 28px ${partnerMood.color}45, 0 8px 28px rgba(0,0,0,0.1)`,
                    }}
                    animate={{ scale: [1, 1.05, 1] }}
                    transition={{
                      duration: 4.5,
                      repeat: Infinity,
                      ease: "easeInOut",
                    }}
                  >
                    <motion.div
                      className="absolute inset-0"
                      style={{
                        background: partnerMood.gradient,
                        opacity: 0.55,
                        filter: "blur(20px)",
                      }}
                      animate={{
                        y: ["-12%", "12%"],
                        rotate: [0, 180, 360],
                      }}
                      transition={{
                        duration: 9,
                        repeat: Infinity,
                        ease: "easeInOut",
                      }}
                    />
                    <div className="absolute inset-0 bg-gradient-to-br from-white/50 via-white/15 to-transparent rounded-full" />
                    <div className="absolute inset-0 flex items-center justify-center">
                      {(() => {
                        const Icon = partnerMood.icon;
                        return <Icon className="w-8 h-8 text-white/95 drop-shadow-lg" />;
                      })()}
                    </div>
                  </motion.div>
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0 pt-1">
                  <p className="text-gray-800" style={{ fontWeight: 400 }}>
                    {partnerMood.name}
                  </p>
                  <p
                    className="text-gray-500 text-sm mt-1.5 leading-relaxed"
                    style={{ fontWeight: 300 }}
                  >
                    "{partnerWish}"
                  </p>
                  <div className="flex items-center gap-1.5 mt-3 text-gray-400">
                    <Clock className="w-3 h-3" />
                    <span className="text-[0.65rem]" style={{ fontWeight: 300 }}>
                      {formatDate(partnerTimestamp)} at {formatTime(partnerTimestamp)}
                    </span>
                  </div>
                </div>
              </div>

              {/* Send a reaction section */}
              <div
                className="mt-4 pt-3.5"
                style={{ borderTop: `1px solid ${partnerMood.color}10` }}
              >
                <AnimatePresence mode="wait">
                  {justSentReaction && sentReaction ? (
                    <motion.div
                      key="sent"
                      className="flex items-center justify-center gap-2 py-1"
                      initial={{ opacity: 0, scale: 0.85 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0 }}
                      transition={{ type: "spring", stiffness: 300, damping: 20 }}
                    >
                      <motion.span
                        className="text-xl"
                        initial={{ scale: 0, rotate: -180 }}
                        animate={{ scale: 1, rotate: 0 }}
                        transition={{ type: "spring", stiffness: 400, damping: 12 }}
                      >
                        {sentReaction}
                      </motion.span>
                      <span className="text-xs text-gray-400" style={{ fontWeight: 300 }}>
                        Reaction sent!
                      </span>
                    </motion.div>
                  ) : showReactionPicker ? (
                    <motion.div
                      key="picker"
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: 8 }}
                      transition={{ duration: 0.25 }}
                    >
                      <p
                        className="text-[10px] text-gray-400 text-center mb-2.5"
                        style={{ fontWeight: 300 }}
                      >
                        React to Alex's mood
                      </p>
                      <div className="flex items-center justify-center gap-2 flex-wrap">
                        {reactionEmojis.map((emoji, i) => (
                          <motion.button
                            key={emoji}
                            onClick={() => handleSendReaction(emoji)}
                            className="w-9 h-9 rounded-full flex items-center justify-center"
                            style={{
                              background: `linear-gradient(135deg, ${partnerMood.color}12, ${partnerMood.color}06)`,
                              border: `1px solid ${partnerMood.color}15`,
                            }}
                            initial={{ opacity: 0, scale: 0.5 }}
                            animate={{ opacity: 1, scale: 1 }}
                            transition={{ delay: i * 0.03, type: "spring", stiffness: 400, damping: 15 }}
                            whileTap={{ scale: 0.8 }}
                            whileHover={{ scale: 1.15 }}
                          >
                            <span className="text-base">{emoji}</span>
                          </motion.button>
                        ))}
                      </div>
                      <motion.button
                        className="w-full mt-2.5 text-[10px] text-gray-300 text-center py-1"
                        style={{ fontWeight: 300 }}
                        onClick={() => setShowReactionPicker(false)}
                        whileTap={{ scale: 0.98 }}
                      >
                        Cancel
                      </motion.button>
                    </motion.div>
                  ) : (
                    <motion.button
                      key="button"
                      className="w-full flex items-center justify-center gap-2 py-1.5 rounded-xl"
                      style={{
                        background: `linear-gradient(135deg, ${partnerMood.color}12, ${partnerMood.color}06)`,
                        border: `1px solid ${partnerMood.color}15`,
                      }}
                      onClick={() => setShowReactionPicker(true)}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      whileTap={{ scale: 0.97 }}
                    >
                      {sentReaction ? (
                        <span className="text-sm">{sentReaction}</span>
                      ) : (
                        <Heart className="w-3.5 h-3.5 text-gray-400" />
                      )}
                      <span
                        className="text-xs text-gray-500"
                        style={{ fontWeight: 300 }}
                      >
                        {sentReaction ? "Change reaction" : "Send a reaction"}
                      </span>
                    </motion.button>
                  )}
                </AnimatePresence>
              </div>
            </div>

            <div
              className="h-[1px] w-full"
              style={{
                background: `linear-gradient(90deg, transparent, ${partnerMood.color}15, transparent)`,
              }}
            />
          </motion.div>

          {/* Spacer */}
          <div className="h-8" />

          {/* Reactions hint */}
          <motion.p
            className="text-black/25 text-xs tracking-widest uppercase mb-3 ml-1"
            style={{ fontWeight: 300 }}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
          >
            Small ways to show you care
          </motion.p>

          {/* Care suggestion cards — display only */}
          <div className="space-y-2.5">
            {reactions.map((reaction, index) => (
              <motion.div
                key={reaction}
                className="w-full px-5 py-3.5 rounded-2xl backdrop-blur-2xl border text-left"
                style={{
                  background:
                    "linear-gradient(135deg, rgba(255,255,255,0.5) 0%, rgba(255,255,255,0.25) 100%)",
                  borderColor: "rgba(255,255,255,0.5)",
                  boxShadow: "0 4px 16px rgba(0,0,0,0.04)",
                }}
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.55 + index * 0.08, duration: 0.4 }}
              >
                <span
                  className="text-sm"
                  style={{ fontWeight: 300, color: "#666" }}
                >
                  {reaction}
                </span>
              </motion.div>
            ))}
          </div>

          {/* Spacer */}
          <div className="h-7" />

          {/* ====== MOOD HISTORY — WEEK with expandable days ====== */}
          <motion.div
            className="relative z-10 w-full overflow-visible rounded-2xl backdrop-blur-2xl border border-white/60 shadow-xl px-5 py-4"
            style={{
              background:
                "linear-gradient(135deg, rgba(255,255,255,0.55) 0%, rgba(255,255,255,0.35) 50%, rgba(255,255,255,0.25) 100%)",
            }}
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.75, duration: 0.5 }}
          >
            <div className="flex items-center gap-2 mb-3.5">
              <Calendar className="w-3.5 h-3.5 text-gray-400" />
              <p
                className="text-black/25 text-xs tracking-widest uppercase"
                style={{ fontWeight: 300 }}
              >
                Mood this week
              </p>
            </div>

            <div className="relative overflow-visible">
              {/* Day detail modal — opens upward above the week row */}
              <AnimatePresence>
                {expandedDayData && (
                  <motion.div
                    key={expandedDayData.day}
                    className="absolute bottom-full left-1/2 z-30 mb-2 w-[11.5rem] rounded-xl border border-white/70 shadow-xl backdrop-blur-2xl overflow-hidden"
                    style={{
                      background:
                        "linear-gradient(155deg, rgba(255,255,255,0.96) 0%, rgba(255,255,255,0.88) 100%)",
                      boxShadow: "0 8px 24px rgba(0,0,0,0.1)",
                    }}
                    initial={{ opacity: 0, y: 8, scale: 0.96, x: "-50%" }}
                    animate={{ opacity: 1, y: 0, scale: 1, x: "-50%" }}
                    exit={{ opacity: 0, y: 6, scale: 0.96, x: "-50%" }}
                    transition={{ duration: 0.2, ease: "easeOut" }}
                  >
                    <div className="px-2.5 pt-2 pb-1 flex items-center justify-between">
                      <p className="text-[10px] text-gray-500" style={{ fontWeight: 500 }}>
                        {expandedDayData.day === "Today" ? "Today" : expandedDayData.day}
                      </p>
                      <button
                        type="button"
                        className="text-[9px] text-gray-400 px-1"
                        style={{ fontWeight: 300 }}
                        onClick={() => setExpandedDay(null)}
                      >
                        Close
                      </button>
                    </div>
                    <div
                      className={`mood-day-scroll px-2 pb-2 space-y-1.5 ${
                        expandedDayData.entries.length >= 4 ? "max-h-[7.25rem] overflow-y-auto" : ""
                      }`}
                    >
                      {expandedDayData.entries.slice(0, MAX_DAY_MOODS).map((entry, eIdx) => {
                        const EIcon = entry.mood.icon;
                        return (
                          <div
                            key={eIdx}
                            className="flex items-center gap-2 rounded-lg px-2 py-1.5"
                            style={{
                              background: `linear-gradient(135deg, ${entry.mood.color}14, ${entry.mood.color}08)`,
                            }}
                          >
                            <div
                              className="w-5 h-5 rounded-full shrink-0 flex items-center justify-center"
                              style={{
                                background: `linear-gradient(135deg, ${entry.mood.color}90, ${entry.mood.color}55)`,
                              }}
                            >
                              <EIcon className="w-2.5 h-2.5 text-white/95" />
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="text-[11px] text-gray-800 truncate" style={{ fontWeight: 500 }}>
                                {entry.mood.label}
                              </p>
                              <p className="text-[9px] text-gray-400" style={{ fontWeight: 300 }}>
                                {entry.time}
                              </p>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>

              <div className="flex items-start justify-between">
                {moodHistoryData.map(({ day, entries }, index) => {
                  const isToday = day === "Today";
                  const lastMood = entries.length > 0 ? entries[entries.length - 1].mood : null;
                  const isExpanded = expandedDay === day;
                  const hasMultiple = entries.length > 1;
                  const moodCount = Math.min(entries.length, MAX_DAY_MOODS);

                  const maxEntries = Math.max(...moodHistoryData.map((d) => d.entries.length), 1);
                  const intensity = entries.length > 0 ? 0.35 + 0.65 * (entries.length / maxEntries) : 0;
                  const sphereAlphaHigh = Math.round(intensity * 255).toString(16).padStart(2, "0");
                  const sphereAlphaLow = Math.round(intensity * 180).toString(16).padStart(2, "0");
                  const glowBaseOpacity = 0.15 + 0.45 * intensity;
                  const glowPeakOpacity = 0.3 + 0.5 * intensity;
                  const iconOpacity = 0.5 + 0.5 * intensity;

                  return (
                    <div key={day} className="flex flex-col items-center">
                      <motion.button
                        type="button"
                        className="flex flex-col items-center gap-1.5"
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ delay: 0.85 + index * 0.06 }}
                        onClick={() => handleDayTap(day, entries)}
                      >
                        {lastMood ? (
                          <div className="relative">
                            <motion.div
                              className="absolute inset-[-3px] rounded-full blur-sm"
                              style={{ background: lastMood.gradient }}
                              animate={{ opacity: [glowBaseOpacity, glowPeakOpacity, glowBaseOpacity] }}
                              transition={{
                                duration: 3,
                                repeat: Infinity,
                                delay: index * 0.3,
                              }}
                            />
                            <div
                              className="relative w-8 h-8 rounded-full overflow-hidden shadow-md"
                              style={{
                                background: `linear-gradient(135deg, ${lastMood.color}${sphereAlphaHigh}, ${lastMood.color}${sphereAlphaLow})`,
                                border: isExpanded
                                  ? `2px solid ${lastMood.color}80`
                                  : "1.5px solid rgba(255,255,255,0.5)",
                              }}
                            >
                              <div
                                className="absolute inset-0 bg-gradient-to-br from-white/40 via-white/10 to-transparent"
                                style={{ opacity: 0.4 + 0.6 * intensity }}
                              />
                              <div className="absolute inset-0 flex items-center justify-center">
                                {(() => {
                                  const Icon = lastMood.icon;
                                  return (
                                    <Icon
                                      className="w-3.5 h-3.5 drop-shadow"
                                      style={{ color: `rgba(255,255,255,${iconOpacity})` }}
                                    />
                                  );
                                })()}
                              </div>
                            </div>

                            {hasMultiple && (
                              <div
                                className="absolute -top-0.5 -right-0.5 w-3 h-3 rounded-full flex items-center justify-center"
                                style={{
                                  background: "rgba(255,255,255,0.9)",
                                  border: "1px solid rgba(0,0,0,0.08)",
                                  boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
                                }}
                              >
                                <span className="text-[6px] text-gray-500" style={{ fontWeight: 600 }}>
                                  {moodCount}
                                </span>
                              </div>
                            )}
                          </div>
                        ) : (
                          <div
                            className="w-8 h-8 rounded-full border-2 border-dashed flex items-center justify-center"
                            style={{ borderColor: "rgba(0,0,0,0.1)" }}
                          >
                            <span className="text-[8px] text-gray-300">?</span>
                          </div>
                        )}
                        <span
                          className={`text-[9px] ${
                            isToday ? "text-gray-500" : "text-gray-300"
                          }`}
                          style={{ fontWeight: isToday ? 500 : 300 }}
                        >
                          {isToday ? "Today" : day}
                        </span>
                      </motion.button>
                    </div>
                  );
                })}
              </div>
            </div>
          </motion.div>

          <div className="h-6" />
        </div>
      </div>
      </div>

      {/* Locked invite modal — cannot dismiss until partner is connected */}
      <AnimatePresence>
        {!isPaired && (
          <motion.div
            className="absolute inset-0 z-50 flex items-center justify-center px-5"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.35 }}
          >
            {/* Dim veil — not clickable to close */}
            <div
              className="absolute inset-0"
              style={{
                background:
                  "linear-gradient(180deg, rgba(250,250,250,0.15) 0%, rgba(26,26,46,0.28) 45%, rgba(26,26,46,0.38) 100%)",
              }}
              aria-hidden
            />

            <motion.div
              role="dialog"
              aria-modal="true"
              aria-labelledby="partner-invite-title"
              className="relative z-10 w-full max-w-[19.5rem] rounded-[1.5rem] overflow-hidden border border-white/70"
              style={{
                background:
                  "linear-gradient(155deg, rgba(255,255,255,0.96) 0%, rgba(255,255,255,0.88) 100%)",
                boxShadow: "0 20px 56px rgba(26,26,46,0.22), 0 4px 16px rgba(0,0,0,0.06)",
              }}
              initial={{ opacity: 0, y: 18, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 12, scale: 0.97 }}
              transition={{ duration: 0.4, type: "spring", stiffness: 280, damping: 24 }}
              onClick={(e) => e.stopPropagation()}
            >
              <div
                className="h-[3px] w-full"
                style={{
                  background: "linear-gradient(90deg, #E8BED3, #D7C8E2, #C9D6EE, transparent)",
                }}
              />

              <div className="px-5 pt-5 pb-5">
                <p
                  className="text-center text-black/25 text-[10px] tracking-[0.22em] uppercase mb-2"
                  style={{ fontWeight: 300 }}
                >
                  Partner
                </p>
                <h2
                  id="partner-invite-title"
                  className="text-center text-black/80 text-[1.35rem] leading-snug mb-2"
                  style={{ fontWeight: 200, letterSpacing: "0.02em" }}
                >
                  {pairStep === "invite"
                    ? "Share your code"
                    : pairStep === "join"
                      ? "Enter their code"
                      : (
                        <>
                          You’re in.
                          <br />
                          Invite them next.
                        </>
                      )}
                </h2>
                <p
                  className="text-center text-[13px] text-gray-500 leading-relaxed mb-5"
                  style={{ fontWeight: 300 }}
                >
                  {pairStep === "invite"
                    ? "Send this code to your partner so they can join you."
                    : pairStep === "join"
                      ? "Type the invite code they shared with you."
                      : "One tap closer to knowing how they really feel."}
                </p>

                {pairStep === "choose" && (
                  <>
                    <div className="flex items-center justify-center gap-4 mb-5">
                      <div
                        className="w-11 h-11 rounded-full flex items-center justify-center"
                        style={{
                          background: "linear-gradient(135deg, rgba(26,26,46,0.92), rgba(45,45,68,0.88))",
                          boxShadow: "0 6px 18px rgba(26,26,46,0.18)",
                          border: "2px solid rgba(255,255,255,0.55)",
                        }}
                      >
                        <span className="text-white/90 text-[11px]" style={{ fontWeight: 400 }}>
                          You
                        </span>
                      </div>
                      <div className="w-5 h-px bg-black/10" />
                      <div
                        className="w-11 h-11 rounded-full border-2 border-dashed flex items-center justify-center"
                        style={{
                          borderColor: "rgba(26,26,46,0.18)",
                          background: "rgba(255,255,255,0.5)",
                        }}
                      >
                        <span className="text-[10px] text-gray-400" style={{ fontWeight: 300 }}>
                          ?
                        </span>
                      </div>
                    </div>

                    <motion.button
                      type="button"
                      onClick={() => {
                        setPairStep("invite");
                        onInvite?.();
                      }}
                      className="w-full py-3 rounded-2xl text-sm tracking-wide"
                      style={{
                        fontWeight: 500,
                        background: "linear-gradient(135deg, #1a1a2e, #2d2d44)",
                        color: "rgba(255,255,255,0.92)",
                        boxShadow: "0 8px 24px rgba(26,26,46,0.22)",
                      }}
                      whileTap={{ scale: 0.98 }}
                    >
                      Invite the partner
                    </motion.button>

                    <motion.button
                      type="button"
                      onClick={() => setPairStep("join")}
                      className="w-full mt-2.5 py-3 rounded-2xl text-sm tracking-wide"
                      style={{
                        fontWeight: 500,
                        background: "rgba(26,26,46,0.05)",
                        color: "rgba(26,26,46,0.78)",
                        border: "1px solid rgba(26,26,46,0.1)",
                      }}
                      whileTap={{ scale: 0.98 }}
                    >
                      Join the partner
                    </motion.button>

                    <p
                      className="text-center text-[10px] text-gray-400 mt-4 leading-relaxed"
                      style={{ fontWeight: 300 }}
                    >
                      Connect a partner to unlock this screen.
                    </p>
                  </>
                )}

                {pairStep === "invite" && (
                  <AnimatePresence mode="wait">
                    <motion.div
                      key="invite"
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -6 }}
                      transition={{ duration: 0.22 }}
                    >
                      <div
                        className="rounded-2xl px-3.5 py-3.5 flex items-center justify-between gap-3"
                        style={{
                          background: "rgba(26,26,46,0.04)",
                          border: "1px solid rgba(26,26,46,0.06)",
                        }}
                      >
                        <div className="min-w-0">
                          <p
                            className="text-[9px] text-gray-400 tracking-wider uppercase mb-0.5"
                            style={{ fontWeight: 300 }}
                          >
                            Your invite code
                          </p>
                          <p
                            className="text-[15px] text-gray-800 tracking-[0.12em] truncate"
                            style={{ fontWeight: 500 }}
                          >
                            {inviteCode}
                          </p>
                        </div>
                        <button
                          type="button"
                          onClick={handleCopyCode}
                          className="shrink-0 px-2.5 py-1.5 rounded-xl text-[11px] text-gray-600"
                          style={{
                            fontWeight: 400,
                            background: "rgba(255,255,255,0.8)",
                            border: "1px solid rgba(26,26,46,0.08)",
                          }}
                        >
                          {codeCopied ? "Copied" : "Copy"}
                        </button>
                      </div>

                      <button
                        type="button"
                        onClick={() => setPairStep("choose")}
                        className="w-full mt-3 text-[11px] text-gray-400 py-1.5"
                        style={{ fontWeight: 300 }}
                      >
                        Back
                      </button>
                    </motion.div>
                  </AnimatePresence>
                )}

                {pairStep === "join" && (
                  <AnimatePresence mode="wait">
                    <motion.div
                      key="join"
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -6 }}
                      transition={{ duration: 0.22 }}
                    >
                      <label className="block">
                        <span
                          className="text-[9px] text-gray-400 tracking-wider uppercase mb-1.5 block"
                          style={{ fontWeight: 300 }}
                        >
                          Invite code
                        </span>
                        <input
                          type="text"
                          value={joinCode}
                          onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
                          placeholder="BESIDE-····"
                          autoCapitalize="characters"
                          autoCorrect="off"
                          spellCheck={false}
                          className="w-full rounded-2xl px-3.5 py-3 text-[14px] text-gray-800 tracking-[0.1em] outline-none"
                          style={{
                            fontWeight: 500,
                            background: "rgba(26,26,46,0.04)",
                            border: "1px solid rgba(26,26,46,0.1)",
                          }}
                        />
                      </label>

                      <motion.button
                        type="button"
                        disabled={!joinCode.trim()}
                        onClick={() => onJoin?.(joinCode.trim())}
                        className="w-full mt-3 py-3 rounded-2xl text-sm tracking-wide disabled:opacity-40"
                        style={{
                          fontWeight: 500,
                          background: "linear-gradient(135deg, #1a1a2e, #2d2d44)",
                          color: "rgba(255,255,255,0.92)",
                          boxShadow: "0 8px 24px rgba(26,26,46,0.22)",
                        }}
                        whileTap={{ scale: joinCode.trim() ? 0.98 : 1 }}
                      >
                        Connect
                      </motion.button>

                      <button
                        type="button"
                        onClick={() => {
                          setPairStep("choose");
                          setJoinCode("");
                        }}
                        className="w-full mt-2 text-[11px] text-gray-400 py-1.5"
                        style={{ fontWeight: 300 }}
                      >
                        Back
                      </button>
                    </motion.div>
                  </AnimatePresence>
                )}
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
