import { useState, useCallback, useMemo } from "react";
import { motion, AnimatePresence } from "motion/react";
import { moods, needsByMood, type MoodType } from "./components/MoodSphere";
import {
  Send,
  Check,
  Clock,
  UserRound,
  Users,
  Heart,
  Sparkle,
  MoreHorizontal,
  Calendar,
  Gift,
  Plus,
  ChevronDown,
  X,
} from "lucide-react";

import { PartnerScreen } from "./components/PartnerScreen";
import { ConnectionScreen } from "./components/ConnectionScreen";
import { UsScreen } from "./components/UsScreen";
import { AuthScreen } from "./components/AuthScreen";
import { MoreScreen } from "./components/MoreScreen";

interface SharedMood {
  mood: MoodType;
  wish: string;
  timestamp: Date;
}

function triggerHaptic() {
  if (navigator.vibrate) {
    navigator.vibrate([12, 30, 12]);
  }
}

// Хелпер: получить короткое название дня недели
const DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

function getDayLabel(date: Date): string {
  return DAY_NAMES[date.getDay()];
}

function formatTimeShort(date: Date): string {
  return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

// Генерируем начальные mock-данные за прошедшие дни недели
function generateInitialHistory(): SharedMood[] {
  const now = new Date();
  const history: SharedMood[] = [];

  // Seed-данные: пары [daysAgo, moodId, wish, hour, minute]
  const seeds: [number, string, string, number, number][] = [
    [6, "joy", "Let's celebrate small wins together.", 8, 0],
    [5, "calm", "Let's just sit together in silence.", 10, 15],
    [5, "love", "Let's just talk about us.", 20, 30],
    [4, "stressed", "I need a few minutes to calm down.", 14, 0],
    [3, "sad", "I want hugs.", 9, 0],
    [3, "calm", "I'm feeling grounded — I can help you.", 17, 0],
    [2, "joy", "Go for a walk or a run together.", 7, 0],
    [2, "love", "Let's have a date / time without phones.", 19, 45],
    [2, "calm", "Let's do something calm together.", 22, 30],
    [1, "exhausted", "Don't be upset if I stay quiet.", 11, 0],
  ];

  for (const [daysAgo, moodId, wish, hour, minute] of seeds) {
    const d = new Date(now);
    d.setDate(d.getDate() - daysAgo);
    d.setHours(hour, minute, 0, 0);
    const mood = moods.find((m) => m.id === moodId);
    if (mood) {
      history.push({ mood, wish, timestamp: d });
    }
  }

  return history;
}

function App() {
  const [selectedMood, setSelectedMood] = useState<MoodType | null>(null);
  const [selectedWish, setSelectedWish] = useState<string | null>(null);
  const [moodHistory, setMoodHistory] = useState<SharedMood[]>(() => generateInitialHistory());
  const [isSending, setIsSending] = useState(false);
  const [justSent, setJustSent] = useState(false);
  const [activeTab, setActiveTab] = useState("me");
  const [favorites, setFavorites] = useState<string[]>([]);
  const [expandedMyDay, setExpandedMyDay] = useState<string | null>(null);

  // Reaction from partner (Alex) on Anna's mood
  const [partnerMoodReaction, setPartnerMoodReaction] = useState<string | null>(null);

  // Activity completion state (Connection screen)
  const [annaActivityDone, setAnnaActivityDone] = useState(false);
  const alexActivityDone = false; // mock: Alex hasn't completed yet

  // Wishlist state
  const [wishlist, setWishlist] = useState<string[]>([]);
  const [wishlistExpanded, setWishlistExpanded] = useState(false);
  const [wishlistAdding, setWishlistAdding] = useState(false);
  const [wishInput, setWishInput] = useState("");
  const [wishInputError, setWishInputError] = useState("");

  // Mock partner's wishlist (Alex's wishes — видимые Анне на экране Us)
  const [partnerWishlist] = useState<string[]>([
    "Dinner at an Italian restaurant",
    "A book about astronomy",
    "Weekend trip together",
  ]);

  const MAX_WISHES = 3;
  const MAX_WISH_LENGTH = 50;
  const WISH_PATTERN = /^[a-zA-Z0-9 .,!?'"&\-()]+$/;

  const handleAddWish = useCallback(() => {
    const trimmed = wishInput.trim();
    if (!trimmed) {
      setWishInputError("Please enter a wish");
      return;
    }
    if (trimmed.length > MAX_WISH_LENGTH) {
      setWishInputError(`Maximum ${MAX_WISH_LENGTH} characters`);
      return;
    }
    if (!WISH_PATTERN.test(trimmed)) {
      setWishInputError("Only latin letters, numbers and basic symbols");
      return;
    }
    if (wishlist.length >= MAX_WISHES) {
      setWishInputError(`Maximum ${MAX_WISHES} wishes`);
      return;
    }
    triggerHaptic();
    setWishlist((prev) => [...prev, trimmed]);
    setWishInput("");
    setWishInputError("");
    setWishlistAdding(false);
  }, [wishInput, wishlist.length]);

  const handleRemoveWish = useCallback((index: number) => {
    triggerHaptic();
    setWishlist((prev) => prev.filter((_, i) => i !== index));
  }, []);

  // Последний расшаренный mood (для панели "Your current mood")
  const sharedMood = moodHistory.length > 0 ? moodHistory[moodHistory.length - 1] : null;

  // Строим недельную историю из реальных данных
  const myMoodHistory = useMemo(() => {
    const now = new Date();
    const todayStart = new Date(now);
    todayStart.setHours(0, 0, 0, 0);

    // Создаём массив из 7 дней (6 дней назад ... сегодня)
    const days: { day: string; date: Date; entries: { mood: MoodType; wish: string; time: string }[] }[] = [];

    for (let i = 6; i >= 0; i--) {
      const d = new Date(todayStart);
      d.setDate(d.getDate() - i);
      days.push({
        day: getDayLabel(d),
        date: d,
        entries: [],
      });
    }

    // Распределяем записи из moodHistory по дням
    for (const entry of moodHistory) {
      const entryDate = new Date(entry.timestamp);
      entryDate.setHours(0, 0, 0, 0);

      for (const dayData of days) {
        if (entryDate.getTime() === dayData.date.getTime()) {
          dayData.entries.push({
            mood: entry.mood,
            wish: entry.wish,
            time: formatTimeShort(entry.timestamp),
          });
          break;
        }
      }
    }

    return days;
  }, [moodHistory]);

  const toggleFavorite = useCallback((reaction: string) => {
    setFavorites((prev) =>
      prev.includes(reaction)
        ? prev.filter((r) => r !== reaction)
        : [...prev, reaction]
    );
  }, []);

  const removeFavorite = useCallback((reaction: string) => {
    setFavorites((prev) => prev.filter((r) => r !== reaction));
  }, []);

  const isFirstTime = !sharedMood;
  const isReturningUser = !!sharedMood;

  const wishes = selectedMood ? needsByMood[selectedMood.id] || [] : [];

  const handleShare = useCallback(() => {
    if (!selectedMood || !selectedWish) return;
    triggerHaptic();
    setIsSending(true);
    setTimeout(() => {
      setMoodHistory((prev) => [...prev, {
        mood: selectedMood,
        wish: selectedWish,
        timestamp: new Date(),
      }]);
      setIsSending(false);
      setJustSent(true);
      setTimeout(() => {
        setJustSent(false);
        setSelectedMood(null);
        setSelectedWish(null);
      }, 2000);
    }, 1200);
  }, [selectedMood, selectedWish]);

  const handleMoodSelect = (mood: MoodType) => {
    if (selectedMood?.id === mood.id) {
      setSelectedMood(null);
      setSelectedWish(null);
    } else {
      setSelectedMood(mood);
      setSelectedWish(null);
    }
  };

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString([], { month: "short", day: "numeric" });
  };

  const getGreeting = () => {
    const hour = new Date().getHours();
    const name = "Anna";
    if (hour < 12) return `Good morning, ${name}`;
    if (hour < 17) return `Good afternoon, ${name}`;
    if (hour < 21) return `Good evening, ${name}`;
    return `Good night, ${name}`;
  };

  const navItems = [
    { id: "me", label: "Me", icon: UserRound },
    { id: "partner", label: "Partner", icon: Users },
    { id: "us", label: "Us", icon: Heart },
    { id: "connection", label: "Connection", icon: Sparkle },
    { id: "more", label: "More", icon: MoreHorizontal },
  ];

  return (
    <div
      className="min-h-screen bg-[#111112] overflow-auto"
      style={{
        display: "flex",
        alignItems: "flex-start",
        justifyContent: "center",
        gap: "2.5rem",
        padding: "3rem 3rem 4rem",
      }}
    >
      {/* Auth screen frame */}
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "0.625rem", flexShrink: 0 }}>
        <p style={{ fontSize: "0.6rem", textTransform: "uppercase", letterSpacing: "0.18em", color: "rgba(255,255,255,0.2)", fontWeight: 400, marginBottom: 2 }}>
          Auth screen
        </p>
        <div
          style={{
            width: 390,
            height: 844,
            borderRadius: 52,
            overflow: "hidden",
            flexShrink: 0,
            boxShadow: "0 40px 100px rgba(0,0,0,0.7), 0 0 0 1px rgba(255,255,255,0.07)",
          }}
        >
          <AuthScreen onAuthenticated={() => {}} />
        </div>
      </div>

      {/* Main app frame */}
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "0.625rem", flexShrink: 0 }}>
        <p style={{ fontSize: "0.6rem", textTransform: "uppercase", letterSpacing: "0.18em", color: "rgba(255,255,255,0.2)", fontWeight: 400, marginBottom: 2 }}>
          Main app
        </p>
        {/*
          transform: translateZ(0) creates a new containing block for position:fixed children,
          keeping the Liquid Glass nav bar inside this frame instead of the browser viewport.
        */}
        <div
          style={{
            width: 390,
            height: 844,
            borderRadius: 52,
            overflow: "hidden",
            flexShrink: 0,
            transform: "translateZ(0)",
            boxShadow: "0 40px 100px rgba(0,0,0,0.7), 0 0 0 1px rgba(255,255,255,0.07)",
          }}
        >
          <div className="[&::-webkit-scrollbar]:hidden" style={{ height: "100%", overflowY: "auto", overflowX: "hidden" }}>
            <div className="min-h-full relative overflow-hidden bg-gradient-to-br from-gray-50 via-white to-gray-100">
      {/* Colored ambient blurs matching selected mood — Me tab only */}
      {activeTab === "me" && (
        <>
          <AnimatePresence>
            {selectedMood && (
              <>
                <motion.div
                  key={`blur-tl-${selectedMood.id}`}
                  className="absolute top-0 left-0 w-96 h-96 rounded-full blur-[150px]"
                  style={{ background: selectedMood.gradient }}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 0.3, scale: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 1 }}
                />
                <motion.div
                  key={`blur-br-${selectedMood.id}`}
                  className="absolute bottom-0 right-0 w-96 h-96 rounded-full blur-[150px]"
                  style={{ background: selectedMood.gradient }}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 0.3, scale: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 1 }}
                />
              </>
            )}
          </AnimatePresence>

          {/* Default ambient blurs */}
          {!selectedMood && (
            <>
              <div className="absolute top-20 left-0 w-80 h-80 rounded-full blur-[120px] bg-green-300/20" />
              <div className="absolute bottom-20 right-0 w-80 h-80 rounded-full blur-[120px] bg-pink-300/20" />
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-60 h-60 rounded-full blur-[100px] bg-yellow-200/20" />
            </>
          )}
        </>
      )}

      {/* ===== Partner Screen ===== */}
      {activeTab === "partner" && (
        <PartnerScreen
          favorites={favorites}
          onToggleFavorite={toggleFavorite}
          onSendReaction={(emoji) => setPartnerMoodReaction(emoji)}
          sentReaction={partnerMoodReaction}
        />
      )}

      {/* ===== Connection Screen ===== */}
      {activeTab === "connection" && (
        <ConnectionScreen
          favorites={favorites}
          onRemoveFavorite={removeFavorite}
          activityCompleted={annaActivityDone}
          onCompleteActivity={() => setAnnaActivityDone(true)}
        />
      )}

      {/* ===== Us Screen ===== */}
      {activeTab === "us" && (
        <UsScreen
          partnerWishlist={partnerWishlist}
          annaMoodShared={!!sharedMood}
          alexMoodShared={true}
          annaReacted={!!partnerMoodReaction}
          alexReacted={false}
          annaActivityDone={annaActivityDone}
          alexActivityDone={alexActivityDone}
        />
      )}

      {/* ===== More Screen ===== */}
      {activeTab === "more" && (
        <MoreScreen
          displayName="Anna"
          partnerName="Alex"
          isPaired
          avatarInitial="A"
          onLogout={() => setActiveTab("me")}
        />
      )}

      {/* ===== Me Screen ===== */}
      {activeTab === "me" && (
        <div className="relative z-10 min-h-screen flex flex-col pb-24 max-w-md mx-auto">
          <div className="h-12 shrink-0" />

          <div className="flex-1 overflow-y-auto px-5">
            {/* Greeting header */}
            <motion.p
              className="text-black/35 text-center mb-1.5"
              style={{ fontWeight: 300, letterSpacing: "0.02em" }}
              initial={{ opacity: 0, y: -12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
            >
              {getGreeting()} ✨
            </motion.p>

            {/* Header */}
            <motion.h1
              className="text-black/70 text-center mb-6"
              style={{ fontWeight: 200, letterSpacing: "0.03em" }}
              initial={{ opacity: 0, y: -16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7 }}
            >
              How are you feeling?
            </motion.h1>

            {/* "Your current mood" label */}
            <motion.p
              className="text-center text-black/25 text-xs tracking-widest uppercase mb-2"
              style={{ fontWeight: 300 }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.2 }}
            >
              Your current mood
            </motion.p>

            {/* Current mood status panel */}
            <motion.div
              className="w-full rounded-2xl backdrop-blur-2xl border border-white/60 shadow-2xl px-5 py-4"
              style={{
                background:
                  "linear-gradient(135deg, rgba(255,255,255,0.6) 0%, rgba(255,255,255,0.4) 50%, rgba(255,255,255,0.3) 100%)",
              }}
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.15 }}
            >
              {sharedMood ? (
                <div className="flex items-start gap-3">
                  <div
                    className="w-10 h-10 rounded-full flex items-center justify-center shrink-0 backdrop-blur-sm border border-white/50 shadow-lg"
                    style={{
                      background: `linear-gradient(135deg, ${sharedMood.mood.color}60, ${sharedMood.mood.color}30)`,
                    }}
                  >
                    {(() => {
                      const Icon = sharedMood.mood.icon;
                      return (
                        <Icon className="w-5 h-5 text-white drop-shadow" />
                      );
                    })()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-gray-800 text-sm">
                      {sharedMood.mood.name}
                    </p>
                    <p className="text-gray-500 text-xs mt-0.5 line-clamp-2">
                      {sharedMood.wish}
                    </p>
                    <div className="flex items-center gap-1 mt-1.5 text-gray-400">
                      <Clock className="w-3 h-3" />
                      <span className="text-[0.65rem]">
                        {formatDate(sharedMood.timestamp)} at {formatTime(sharedMood.timestamp)}
                      </span>
                    </div>

                    {/* Partner's reaction */}
                    <AnimatePresence>
                      {partnerMoodReaction && (
                        <motion.div
                          className="flex items-center gap-1.5 mt-2 px-2.5 py-1 rounded-full w-fit"
                          style={{
                            background: `linear-gradient(135deg, ${sharedMood.mood.color}10, ${sharedMood.mood.color}05)`,
                            border: `1px solid ${sharedMood.mood.color}15`,
                          }}
                          initial={{ opacity: 0, scale: 0.8, y: -4 }}
                          animate={{ opacity: 1, scale: 1, y: 0 }}
                          exit={{ opacity: 0, scale: 0.8 }}
                          transition={{ type: "spring", stiffness: 400, damping: 20 }}
                        >
                          <motion.span
                            className="text-sm"
                            animate={{ scale: [1, 1.15, 1] }}
                            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
                          >
                            {partnerMoodReaction}
                          </motion.span>
                          <span
                            className="text-[10px] text-gray-400"
                            style={{ fontWeight: 300 }}
                          >
                            Alex reacted
                          </span>
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>
                </div>
              ) : (
                <p
                  className="text-gray-400 text-sm text-center py-1"
                  style={{ fontWeight: 300 }}
                >
                  Select your mood below to share it with your partner
                </p>
              )}
            </motion.div>

            {/* Spacer between panels */}
            <div className="h-8" />

            {/* Hint text above sphere panel */}
            <AnimatePresence>
              {isFirstTime && !selectedMood && (
                <motion.p
                  key="hint-first"
                  className="text-center text-black/25 text-xs mb-3"
                  style={{ fontWeight: 300 }}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.4 }}
                >
                  Tap to show how you're feeling.
                </motion.p>
              )}
              {isReturningUser && !selectedMood && (
                <motion.p
                  key="hint-returning"
                  className="text-center text-black/25 text-xs mb-3"
                  style={{ fontWeight: 300 }}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.4 }}
                >
                  Your partner would love to know how you're feeling
                </motion.p>
              )}
              {selectedMood && (
                <motion.p
                  key="hint-selected"
                  className="text-center text-black/30 text-xs mb-3"
                  style={{ fontWeight: 300 }}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.3 }}
                >
                  Tell your partner how you feel today.
                </motion.p>
              )}
            </AnimatePresence>

            {/* Glass container with mood spheres */}
            <motion.div
              className="w-full mb-5 rounded-[2rem] backdrop-blur-2xl border border-white/60 shadow-2xl p-6"
              style={{
                background:
                  "linear-gradient(135deg, rgba(255,255,255,0.6) 0%, rgba(255,255,255,0.4) 50%, rgba(255,255,255,0.3) 100%)",
              }}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.6, delay: 0.25 }}
            >
              <div className="grid grid-cols-3 gap-x-4 gap-y-5">
                {moods.map((mood, index) => {
                  const Icon = mood.icon;
                  const isSelected = selectedMood?.id === mood.id;
                  const hasSelection = selectedMood !== null;
                  const pulseDelay = index * 0.6;

                  return (
                    <motion.button
                      key={mood.id}
                      onClick={() => handleMoodSelect(mood)}
                      className="flex flex-col items-center"
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.3 + index * 0.08 }}
                      whileTap={{ scale: 0.92 }}
                    >
                      <div className="relative mb-2">
                        {/* Outer glow */}
                        <motion.div
                          className="absolute inset-[-8px] rounded-full blur-xl"
                          style={{ background: mood.gradient }}
                          animate={{
                            opacity: isSelected
                              ? [0.5, 0.8, 0.5]
                              : hasSelection
                              ? 0.12
                              : [0.25, 0.5, 0.25],
                            scale: isSelected
                              ? [1, 1.25, 1]
                              : hasSelection
                              ? 0.85
                              : [0.95, 1.12, 0.95],
                          }}
                          transition={{
                            duration: isSelected ? 2.5 : 5,
                            repeat: Infinity,
                            ease: "easeInOut",
                            delay: hasSelection ? 0 : pulseDelay,
                          }}
                        />

                        {/* Glass sphere */}
                        <motion.div
                          className="relative w-[4.5rem] h-[4.5rem] rounded-full overflow-hidden backdrop-blur-xl shadow-xl"
                          style={{
                            background: `linear-gradient(135deg, ${mood.color}90, ${mood.color}50)`,
                            border: isSelected
                              ? "3px solid rgba(255,255,255,0.85)"
                              : "1.5px solid rgba(255,255,255,0.4)",
                            boxShadow: isSelected
                              ? `0 0 24px ${mood.color}60, 0 8px 32px rgba(0,0,0,0.1)`
                              : "0 4px 16px rgba(0,0,0,0.08)",
                          }}
                          animate={
                            !hasSelection
                              ? { scale: [1, 1.05, 1] }
                              : isSelected
                              ? { scale: [1, 1.06, 1] }
                              : { scale: 0.88 }
                          }
                          transition={{
                            duration: 5,
                            repeat: Infinity,
                            ease: "easeInOut",
                            delay: hasSelection ? 0 : pulseDelay,
                          }}
                        >
                          {/* Animated smoke */}
                          <motion.div
                            className="absolute inset-0"
                            style={{
                              background: mood.gradient,
                              opacity:
                                hasSelection && !isSelected ? 0.3 : 0.6,
                              filter: "blur(20px)",
                            }}
                            animate={{
                              y:
                                mood.smokePattern === "falling"
                                  ? ["-12%", "12%"]
                                  : ["12%", "-12%"],
                              x:
                                mood.smokePattern === "chaotic"
                                  ? ["-6%", "6%", "-6%"]
                                  : ["0%", "3%", "0%"],
                              scale:
                                mood.smokePattern === "expanding"
                                  ? [0.92, 1.08, 0.92]
                                  : [1, 1.04, 1],
                              rotate:
                                mood.smokePattern === "swirling"
                                  ? [0, 180, 360]
                                  : [0, 4, 0],
                            }}
                            transition={{
                              duration:
                                mood.smokePattern === "chaotic" ? 3.5 : 9,
                              repeat: Infinity,
                              ease: "easeInOut",
                            }}
                          />

                          {/* Glass highlight */}
                          <div className="absolute inset-0 bg-gradient-to-br from-white/50 via-white/10 to-transparent rounded-full" />

                          {/* Dimming overlay */}
                          {hasSelection && !isSelected && (
                            <motion.div
                              className="absolute inset-0 rounded-full bg-white/30"
                              initial={{ opacity: 0 }}
                              animate={{ opacity: 1 }}
                              transition={{ duration: 0.4 }}
                            />
                          )}

                          {/* Icon */}
                          <div className="absolute inset-0 flex items-center justify-center">
                            <Icon
                              className={`w-8 h-8 drop-shadow-lg relative z-10 transition-all duration-500 ${
                                hasSelection && !isSelected
                                  ? "text-white/50"
                                  : "text-white/95"
                              }`}
                            />
                          </div>

                          {/* Selected white ring */}
                          {isSelected && (
                            <motion.div
                              className="absolute inset-[-1px] rounded-full border-[3px] border-white"
                              initial={{ scale: 0.8, opacity: 0 }}
                              animate={{ scale: 1, opacity: 1 }}
                              transition={{
                                duration: 0.35,
                                type: "spring",
                                stiffness: 300,
                              }}
                            />
                          )}
                        </motion.div>
                      </div>

                      {/* Label */}
                      <p
                        className={`text-center text-[0.6rem] leading-tight max-w-[5rem] transition-all duration-500 ${
                          isSelected
                            ? "text-gray-900"
                            : hasSelection
                            ? "text-gray-300"
                            : "text-gray-600"
                        }`}
                        style={{ fontWeight: isSelected ? 400 : 300 }}
                      >
                        {mood.name}
                      </p>
                    </motion.button>
                  );
                })}
              </div>
            </motion.div>

            {/* "Your wishes..." hint above wish cards */}
            <AnimatePresence>
              {selectedMood && !justSent && (
                <motion.p
                  key="wishes-hint"
                  className="text-black/25 text-xs mb-2 ml-1"
                  style={{ fontWeight: 300 }}
                  initial={{ opacity: 0, y: 6 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.3 }}
                >
                  Your wishes...
                </motion.p>
              )}
            </AnimatePresence>

            {/* Wish buttons */}
            <AnimatePresence mode="wait">
              {selectedMood && !justSent && (
                <motion.div
                  key={`wishes-${selectedMood.id}`}
                  className="w-full space-y-2.5"
                  initial={{ opacity: 0, y: 24 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: 16 }}
                  transition={{ duration: 0.45 }}
                >
                  {wishes.map((wish, index) => {
                    const isWishSelected = selectedWish === wish;
                    return (
                      <motion.button
                        key={wish}
                        onClick={() => setSelectedWish(wish)}
                        className="w-full px-5 py-3.5 rounded-2xl backdrop-blur-2xl border transition-all text-left"
                        style={{
                          background: isWishSelected
                            ? `linear-gradient(135deg, ${selectedMood.color}30, ${selectedMood.color}15)`
                            : "linear-gradient(135deg, rgba(255,255,255,0.5) 0%, rgba(255,255,255,0.25) 100%)",
                          borderColor: isWishSelected
                            ? `${selectedMood.color}50`
                            : "rgba(255,255,255,0.5)",
                          boxShadow: isWishSelected
                            ? `0 4px 20px ${selectedMood.color}20, 0 8px 32px rgba(0,0,0,0.06)`
                            : "0 4px 16px rgba(0,0,0,0.04)",
                        }}
                        initial={{ opacity: 0, y: 16 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: index * 0.08 }}
                        whileTap={{ scale: 0.98 }}
                      >
                        <p
                          className="text-sm"
                          style={{
                            fontWeight: isWishSelected ? 400 : 300,
                            color: isWishSelected ? "#333" : "#666",
                          }}
                        >
                          {wish}
                        </p>
                      </motion.button>
                    );
                  })}
                </motion.div>
              )}
            </AnimatePresence>

            {/* Share with partner button */}
            <AnimatePresence>
              {selectedWish && !isSending && !justSent && selectedMood && (
                <motion.button
                  className="mt-4 w-full px-6 py-4 rounded-2xl backdrop-blur-2xl shadow-xl flex items-center justify-center gap-3"
                  style={{
                    background: `linear-gradient(135deg, ${selectedMood.color}25, ${selectedMood.color}12, rgba(255,255,255,0.4))`,
                    border: `1.5px solid ${selectedMood.color}30`,
                    boxShadow: `0 8px 32px ${selectedMood.color}15, 0 4px 16px rgba(0,0,0,0.06)`,
                  }}
                  initial={{ opacity: 0, scale: 0.92, y: 10 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.92 }}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.96 }}
                  onClick={handleShare}
                >
                  <Send className="w-4 h-4 text-gray-700" />
                  <span className="text-gray-700 text-sm">
                    Share with partner
                  </span>
                </motion.button>
              )}
            </AnimatePresence>

            {/* Sending animation */}
            <AnimatePresence>
              {isSending && selectedMood && (
                <motion.div
                  className="mt-4 w-full px-6 py-4 rounded-2xl backdrop-blur-2xl shadow-lg flex items-center justify-center gap-3"
                  style={{
                    background: `linear-gradient(135deg, ${selectedMood.color}20, rgba(255,255,255,0.35))`,
                    border: `1.5px solid ${selectedMood.color}25`,
                  }}
                  initial={{ opacity: 1 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0, scale: 0.92 }}
                >
                  <motion.div className="flex items-center gap-1.5">
                    {[0, 0.15, 0.3].map((delay, i) => (
                      <motion.div
                        key={i}
                        className="w-1.5 h-1.5 rounded-full"
                        style={{ background: `${selectedMood.color}90` }}
                        animate={{
                          scale: [1, 1.6, 1],
                          opacity: [0.4, 1, 0.4],
                        }}
                        transition={{
                          duration: 0.7,
                          repeat: Infinity,
                          delay,
                        }}
                      />
                    ))}
                  </motion.div>
                  <span
                    className="text-gray-600 text-sm ml-1"
                    style={{ fontWeight: 300 }}
                  >
                    Sending...
                  </span>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Sent confirmation — warm lavender */}
            <AnimatePresence>
              {justSent && (
                <motion.div
                  className="mt-4 w-full px-6 py-4 rounded-2xl backdrop-blur-2xl shadow-xl flex items-center justify-center gap-3"
                  style={{
                    background:
                      "linear-gradient(135deg, rgba(200,180,220,0.45) 0%, rgba(220,190,200,0.35) 50%, rgba(255,255,255,0.3) 100%)",
                    border: "1.5px solid rgba(180,160,200,0.4)",
                  }}
                  initial={{ opacity: 0, scale: 0.85 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.92 }}
                  transition={{
                    type: "spring",
                    stiffness: 300,
                    damping: 22,
                  }}
                >
                  <motion.div
                    initial={{ scale: 0, rotate: -180 }}
                    animate={{ scale: 1, rotate: 0 }}
                    transition={{
                      type: "spring",
                      stiffness: 400,
                      damping: 15,
                    }}
                  >
                    <Check className="w-5 h-5 text-[#7b5ea7]" />
                  </motion.div>
                  <span
                    className="text-[#7b5ea7] text-sm"
                    style={{ fontWeight: 400 }}
                  >
                    Sent!
                  </span>
                </motion.div>
              )}
            </AnimatePresence>

            {/* ====== MY MOOD HISTORY — WEEK ====== */}
            <div className="h-7" />

            <motion.div
              className="w-full rounded-2xl backdrop-blur-2xl border border-white/60 shadow-xl px-5 py-4"
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
                  My mood this week
                </p>
              </div>

              <div className="flex items-start justify-between">
                {myMoodHistory.map(({ day, entries }, index) => {
                  const isToday = index === myMoodHistory.length - 1;
                  const lastMood = entries.length > 0 ? entries[entries.length - 1].mood : null;
                  const isExpanded = expandedMyDay === day;
                  const hasMultiple = entries.length > 1;

                  const maxEntries = Math.max(...myMoodHistory.map((d) => d.entries.length), 1);
                  const intensity = entries.length > 0 ? 0.35 + 0.65 * (entries.length / maxEntries) : 0;
                  const sphereAlphaHigh = Math.round(intensity * 255).toString(16).padStart(2, "0");
                  const sphereAlphaLow = Math.round(intensity * 180).toString(16).padStart(2, "0");
                  const glowBaseOpacity = 0.15 + 0.45 * intensity;
                  const glowPeakOpacity = 0.3 + 0.5 * intensity;
                  const iconOpacity = 0.5 + 0.5 * intensity;

                  return (
                    <div key={day} className="flex flex-col items-center relative">
                      <motion.button
                        className="flex flex-col items-center gap-1.5"
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ delay: 0.85 + index * 0.06 }}
                        onClick={() => {
                          if (entries.length === 0) return;
                          setExpandedMyDay(isExpanded ? null : day);
                        }}
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
                                  const MIcon = lastMood.icon;
                                  return (
                                    <MIcon
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
                                  {entries.length}
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

                      {/* Expanded dropdown */}
                      <AnimatePresence>
                        {isExpanded && entries.length > 0 && (
                          <motion.div
                            className="absolute top-full mt-2 z-20 rounded-xl backdrop-blur-2xl border border-white/60 shadow-xl overflow-hidden"
                            style={{
                              background:
                                "linear-gradient(135deg, rgba(255,255,255,0.85) 0%, rgba(255,255,255,0.7) 100%)",
                              minWidth: "140px",
                              left: "50%",
                              transform: "translateX(-50%)",
                            }}
                            initial={{ opacity: 0, y: -4, scale: 0.95 }}
                            animate={{ opacity: 1, y: 0, scale: 1 }}
                            exit={{ opacity: 0, y: -4, scale: 0.95 }}
                            transition={{ duration: 0.2 }}
                          >
                            <div className="p-2.5 space-y-2">
                              {entries.map((entry, eIdx) => {
                                const EIcon = entry.mood.icon;
                                return (
                                  <div key={eIdx} className="flex items-center gap-2">
                                    <div
                                      className="w-5 h-5 rounded-full shrink-0 flex items-center justify-center"
                                      style={{
                                        background: `linear-gradient(135deg, ${entry.mood.color}80, ${entry.mood.color}40)`,
                                      }}
                                    >
                                      <EIcon className="w-2.5 h-2.5 text-white/90" />
                                    </div>
                                    <div className="flex-1 min-w-0">
                                      <p className="text-[10px] text-gray-700 truncate" style={{ fontWeight: 400 }}>
                                        {entry.mood.name}
                                      </p>
                                      <p className="text-[8px] text-gray-400" style={{ fontWeight: 300 }}>
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
                    </div>
                  );
                })}
              </div>
            </motion.div>


            <div className="h-6" />
          </div>
        </div>
      )}

      {/* Bottom Tab Bar — Liquid Glass (iOS 26 style) */}
      <div className="fixed bottom-0 left-0 right-0 z-50 pointer-events-none">
        <div className="max-w-md mx-auto px-4 pb-[max(env(safe-area-inset-bottom,6px),6px)]">
          <div
            className="pointer-events-auto relative rounded-[22px] overflow-hidden"
            style={{
              background:
                "linear-gradient(135deg, rgba(255,255,255,0.55) 0%, rgba(255,255,255,0.3) 40%, rgba(255,255,255,0.2) 100%)",
              backdropFilter: "blur(50px) saturate(200%) brightness(1.05)",
              WebkitBackdropFilter: "blur(50px) saturate(200%) brightness(1.05)",
              boxShadow:
                "0 8px 40px rgba(0,0,0,0.08), 0 1.5px 8px rgba(0,0,0,0.04), inset 0 1.5px 0 rgba(255,255,255,0.7), inset 0 -0.5px 0 rgba(255,255,255,0.15)",
              border: "0.5px solid rgba(255,255,255,0.55)",
            }}
          >
            {/* Top specular highlight — liquid glass refraction */}
            <div
              className="absolute top-0 left-[10%] right-[10%] h-[1px] rounded-full"
              style={{
                background:
                  "linear-gradient(90deg, transparent, rgba(255,255,255,0.9) 30%, rgba(255,255,255,0.95) 50%, rgba(255,255,255,0.9) 70%, transparent)",
              }}
            />

            {/* Subtle internal gradient sheen */}
            <div
              className="absolute inset-0 rounded-[22px]"
              style={{
                background:
                  "linear-gradient(180deg, rgba(255,255,255,0.15) 0%, transparent 40%, rgba(255,255,255,0.05) 100%)",
                pointerEvents: "none",
              }}
            />

            <div className="relative flex items-center justify-around px-1 py-2">
              {navItems.map((item) => {
                const NavIcon = item.icon;
                const isActive = activeTab === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => setActiveTab(item.id)}
                    className="relative flex flex-col items-center py-1.5 px-3.5 rounded-2xl transition-all duration-300"
                  >
                    {/* Active indicator — glass bubble */}
                    {isActive && (
                      <motion.div
                        className="absolute inset-0 rounded-2xl"
                        style={{
                          background:
                            "linear-gradient(135deg, rgba(255,255,255,0.65) 0%, rgba(255,255,255,0.3) 50%, rgba(255,255,255,0.15) 100%)",
                          boxShadow:
                            "0 2px 12px rgba(0,0,0,0.06), inset 0 1px 0 rgba(255,255,255,0.8), inset 0 -0.5px 0 rgba(255,255,255,0.2)",
                          border: "0.5px solid rgba(255,255,255,0.6)",
                        }}
                        layoutId="liquidGlassTab"
                        transition={{
                          type: "spring",
                          stiffness: 400,
                          damping: 32,
                          mass: 0.8,
                        }}
                      />
                    )}
                    <NavIcon
                      className={`w-[21px] h-[21px] relative z-10 transition-all duration-300 ${
                        isActive
                          ? "text-gray-900"
                          : "text-gray-400/55"
                      }`}
                      strokeWidth={isActive ? 2 : 1.5}
                    />
                    <span
                      className={`text-[9.5px] mt-[2px] relative z-10 transition-all duration-300 tracking-[0.01em] ${
                        isActive
                          ? "text-gray-900"
                          : "text-gray-400/55"
                      }`}
                      style={{
                        fontWeight: isActive ? 600 : 400,
                      }}
                    >
                      {item.label}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;