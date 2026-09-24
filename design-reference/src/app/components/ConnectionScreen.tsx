import { useState, useEffect, useCallback, useRef, type PointerEventHandler } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Heart, Sparkle, Check, ArrowRight, ChevronLeft } from "lucide-react";

const TODAYS_ACTIVITY = {
  id: "todays-activity",
  userTask: "Send a short voice note: one thing you appreciated about your partner today, even if it was tiny.",
  partnerTask: "Write one sentence you'd like to hear more often from them—keep it kind and specific.",
  closedHint: "Today’s activity is ready — open it when you’re both free to share.",
  pendingMessage: "This task will be counted as complete after your partner approves it",
} as const;

type PendingPartnerAnswer = {
  id: string;
  partnerName: string;
  preview: string;
  submittedAt: string;
};

const SAMPLE_PENDING_ANSWERS: PendingPartnerAnswer[] = [
  {
    id: "pa-1",
    partnerName: "Alex",
    preview: "I'd love to hear “I'm proud of you” more often — especially on hard days.",
    submittedAt: "Today · 10:24",
  },
  {
    id: "pa-2",
    partnerName: "Alex",
    preview: "A simple “thank you for being here” would mean a lot after long evenings.",
    submittedAt: "Today · 14:02",
  },
];

const activeCtaStyle = {
  background: "linear-gradient(135deg, #1a1a2e, #2d2d44)",
  color: "rgba(255,255,255,0.92)",
  fontWeight: 300 as const,
  letterSpacing: "0.04em",
  fontSize: "0.875rem",
};

const glassCardStyle = {
  background: "linear-gradient(145deg, rgba(255,255,255,0.95), rgba(255,255,255,0.82))",
  backdropFilter: "blur(36px)",
  boxShadow: "0 12px 40px rgba(80,70,120,0.08), 0 2px 8px rgba(0,0,0,0.04)",
} as const;

const softPinkCtaStyle = {
  background: "linear-gradient(135deg, #fdf2f8, #fbcfe8)",
  color: "rgba(26,26,46,0.78)",
  fontWeight: 400 as const,
  letterSpacing: "0.03em",
  fontSize: "0.875rem",
  boxShadow: "0 2px 12px rgba(251,207,232,0.35)",
};

function BesideLogoMark({ size = 28 }: { size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 64 64"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-label="beside logo"
    >
      <defs>
        <linearGradient id="activityBesideBg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#C2CEE9" />
          <stop offset="100%" stopColor="#E8BEC9" />
        </linearGradient>
      </defs>
      <rect width="64" height="64" rx="17" fill="url(#activityBesideBg)" />
      <rect x="0" y="0" width="64" height="28" rx="17" fill="white" fillOpacity="0.13" />
      <path
        d="M13,14 C13,10 17,10 17,10 L21,10 Q46,10 46,22 Q46,34 31,34 Q50,34 50,44 Q50,56 21,56 L17,56 C17,56 13,56 13,52 Z"
        fill="white"
        fillOpacity="0.95"
      />
    </svg>
  );
}

/** Hub after Start on Today's Activity: Daily Task + partner answers awaiting approval. */
function TodaysActivityScreen({
  onClose,
  userTask = TODAYS_ACTIVITY.userTask,
  partnerTask = TODAYS_ACTIVITY.partnerTask,
}: {
  onClose: () => void;
  userTask?: string;
  partnerTask?: string;
}) {
  const [dailyPhase, setDailyPhase] = useState<"closed" | "open" | "waiting">("closed");
  const [pendingAnswers, setPendingAnswers] = useState(SAMPLE_PENDING_ANSWERS);

  const approveAnswer = (id: string) => {
    setPendingAnswers((prev) => prev.filter((a) => a.id !== id));
  };

  return (
    <motion.div
      className="fixed inset-0 z-[100] flex flex-col overflow-hidden bg-gradient-to-br from-gray-50 via-white to-gray-100"
      initial={{ opacity: 0, y: 18 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 12 }}
      transition={{ duration: 0.35, ease: [0.25, 0.46, 0.45, 0.94] }}
    >
      <motion.div
        className="pointer-events-none absolute -left-24 -top-24 h-[28rem] w-[28rem] rounded-full blur-[130px]"
        style={{ background: "linear-gradient(135deg, rgba(251,207,232,0.55), rgba(196,181,253,0.4))" }}
        animate={{ opacity: [0.45, 0.7, 0.45], scale: [0.9, 1.05, 0.9] }}
        transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
      />
      <motion.div
        className="pointer-events-none absolute -bottom-24 -right-24 h-96 w-96 rounded-full blur-[110px]"
        style={{ background: "linear-gradient(135deg, rgba(167,243,208,0.35), rgba(147,197,253,0.45))" }}
        animate={{ opacity: [0.3, 0.55, 0.3], scale: [0.95, 1.08, 0.95] }}
        transition={{ duration: 7, repeat: Infinity, ease: "easeInOut", delay: 1.2 }}
      />

      <div className="relative z-10 mx-auto flex h-full w-full max-w-md flex-col">
        <div className="relative flex shrink-0 items-center justify-center px-5 pb-2 pt-7">
          <button
            type="button"
            onClick={onClose}
            className="absolute left-5 flex items-center gap-0.5 text-xs"
            style={{ color: "rgba(0,0,0,0.4)", fontWeight: 300 }}
            aria-label="Back"
          >
            <ChevronLeft className="h-4 w-4" /> Back
          </button>

          <div className="flex items-center justify-center gap-2">
            <BesideLogoMark />
            <h1 className="text-gray-900" style={{ fontWeight: 200, fontSize: "1.375rem", letterSpacing: "0.06em" }}>
              beside
            </h1>
          </div>
        </div>

        <div className="flex min-h-0 flex-1 flex-col overflow-y-auto px-5 pb-8 pt-4 [scrollbar-width:none] [&::-webkit-scrollbar]:w-0">
          <p
            className="mb-4 text-center text-[11px] uppercase tracking-[0.16em]"
            style={{ color: "rgba(0,0,0,0.32)", fontWeight: 400 }}
          >
            {dailyPhase === "waiting" ? "One step closer together" : "Today's Activity"}
          </p>

          {/* Daily Task */}
          <section
            className="mb-4 overflow-hidden rounded-[1.75rem] border transition-[background,box-shadow,border-color] duration-300"
            style={{
              background: "linear-gradient(135deg, #1a1a2e, #2d2d44)",
              borderColor: "rgba(255,255,255,0.08)",
              boxShadow: "0 12px 40px rgba(26,26,46,0.28), 0 2px 8px rgba(0,0,0,0.08)",
            }}
          >
            <div className="px-5 pb-5 pt-5">
              <p
                className="mb-3 text-[10px] uppercase tracking-[0.14em]"
                style={{ color: "rgba(255,255,255,0.45)", fontWeight: 400 }}
              >
                Daily Task
              </p>

              <AnimatePresence mode="wait" initial={false}>
                {dailyPhase === "closed" ? (
                  <motion.div
                    key="closed"
                    initial={{ opacity: 0, y: 6 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -6 }}
                    transition={{ duration: 0.22 }}
                  >
                    <p
                      className="mb-5 text-[13px] leading-relaxed"
                      style={{ color: "rgba(255,255,255,0.58)", fontWeight: 400 }}
                    >
                      {TODAYS_ACTIVITY.closedHint}
                    </p>
                    <motion.button
                      type="button"
                      onClick={() => setDailyPhase("open")}
                      className="flex w-full touch-manipulation items-center justify-center gap-2.5 rounded-2xl py-3.5"
                      style={softPinkCtaStyle}
                      whileTap={{ scale: 0.985 }}
                      transition={{ duration: 0.15 }}
                    >
                      <span>Open your daily task</span>
                      <ArrowRight className="h-4 w-4 opacity-60" />
                    </motion.button>
                  </motion.div>
                ) : dailyPhase === "open" ? (
                  <motion.div
                    key="open"
                    initial={{ opacity: 0, y: 6 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -6 }}
                    transition={{ duration: 0.22 }}
                  >
                    <p
                      className="mb-1 text-[9px] uppercase tracking-[0.14em]"
                      style={{ color: "rgba(255,255,255,0.4)", fontWeight: 500 }}
                    >
                      You
                    </p>
                    <p
                      className="mb-4 text-[1.05rem] leading-snug"
                      style={{ color: "rgba(255,255,255,0.95)", fontWeight: 700 }}
                    >
                      {userTask}
                    </p>
                    <p
                      className="mb-1 text-[9px] uppercase tracking-[0.14em]"
                      style={{ color: "rgba(255,255,255,0.4)", fontWeight: 500 }}
                    >
                      Partner
                    </p>
                    <p
                      className="mb-5 text-[13px] leading-relaxed"
                      style={{ color: "rgba(255,255,255,0.58)", fontWeight: 400 }}
                    >
                      {partnerTask}
                    </p>
                    <motion.button
                      type="button"
                      onClick={() => setDailyPhase("waiting")}
                      className="flex w-full touch-manipulation items-center justify-center gap-2.5 rounded-2xl py-3.5"
                      style={softPinkCtaStyle}
                      whileTap={{ scale: 0.985 }}
                      transition={{ duration: 0.15 }}
                    >
                      <span>Mark as done</span>
                      <ArrowRight className="h-4 w-4 opacity-60" />
                    </motion.button>
                  </motion.div>
                ) : (
                  <motion.div
                    key="waiting"
                    initial={{ opacity: 0, y: 6 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -6 }}
                    transition={{ duration: 0.22 }}
                  >
                    <div
                      className="mb-3 flex h-10 w-10 items-center justify-center rounded-full"
                      style={{ background: "linear-gradient(135deg, rgba(253,242,248,0.95), rgba(251,207,232,0.85))" }}
                    >
                      <Heart className="h-5 w-5" fill="#fb7185" color="#fb7185" strokeWidth={1.5} />
                    </div>
                    <p
                      className="mb-1.5 text-[1.05rem] leading-snug"
                      style={{ color: "rgba(255,255,255,0.95)", fontWeight: 700 }}
                    >
                      Waiting for partner
                    </p>
                    <p
                      className="text-[13px] leading-relaxed"
                      style={{ color: "rgba(255,255,255,0.58)", fontWeight: 400 }}
                    >
                      {TODAYS_ACTIVITY.pendingMessage}
                    </p>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </section>

          {/* Partner answers to approve */}
          <section
            className="overflow-hidden rounded-[1.75rem] border border-white/60"
            style={glassCardStyle}
          >
            <div className="px-5 pb-5 pt-5">
              <div className="mb-3 flex items-center justify-between gap-2">
                <p
                  className="text-[10px] uppercase tracking-[0.14em]"
                  style={{ color: "rgba(0,0,0,0.3)", fontWeight: 400 }}
                >
                  Awaiting your approval
                </p>
                {pendingAnswers.length > 0 ? (
                  <span
                    className="rounded-full px-2 py-0.5 text-[10px]"
                    style={{
                      background: "rgba(251,113,133,0.12)",
                      color: "#fb7185",
                      fontWeight: 500,
                    }}
                  >
                    {pendingAnswers.length}
                  </span>
                ) : null}
              </div>
              <p className="mb-4 text-[13px] leading-relaxed text-[#86868B]" style={{ fontWeight: 400 }}>
                Answers from your partner for today — confirm to count them as done.
              </p>

              {pendingAnswers.length === 0 ? (
                <div
                  className="rounded-2xl px-3.5 py-4 text-center"
                  style={{ background: "rgba(0,0,0,0.03)" }}
                >
                  <p className="text-[13px] text-[#86868B]" style={{ fontWeight: 400 }}>
                    No answers waiting yet.
                  </p>
                </div>
              ) : (
                <div className="space-y-3">
                  {pendingAnswers.map((answer) => (
                    <div
                      key={answer.id}
                      className="rounded-2xl border border-black/[0.04] px-3.5 py-3.5"
                      style={{ background: "rgba(255,255,255,0.65)" }}
                    >
                      <div className="mb-1.5 flex items-center justify-between gap-2">
                        <p className="text-[13px] text-[#1D1D1F]" style={{ fontWeight: 500 }}>
                          {answer.partnerName}
                        </p>
                        <p className="text-[10px] text-[#86868B]" style={{ fontWeight: 300 }}>
                          {answer.submittedAt}
                        </p>
                      </div>
                      <p className="mb-3 text-[13px] leading-snug text-[#6E6E73]" style={{ fontWeight: 400 }}>
                        {answer.preview}
                      </p>
                      <motion.button
                        type="button"
                        onClick={() => approveAnswer(answer.id)}
                        className="flex w-full touch-manipulation items-center justify-center gap-1.5 rounded-2xl py-2.5 text-[13px]"
                        style={activeCtaStyle}
                        whileTap={{ scale: 0.985 }}
                      >
                        <Check className="h-3.5 w-3.5 opacity-80" strokeWidth={2.5} />
                        <span>Approve</span>
                      </motion.button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </section>
        </div>
      </div>
    </motion.div>
  );
}

/** One slide in the top fullscreen media carousel (photo / video later). */
export interface ConnectionCarouselSlide {
  id: string;
  /** Headline above the Start button. */
  title?: string;
  /** Supporting copy (shown under the title when no paired tasks). */
  body?: string;
  /** Today's Activity: your task (shown with Partner's). */
  userTask?: string;
  /** Today's Activity: partner's task (different from yours). */
  partnerTask?: string;
  /** Legacy single line; used if title/body/tasks are omitted. */
  description?: string;
  imageUrl?: string;
  videoUrl?: string;
  posterUrl?: string;
}

interface ConnectionScreenProps {
  /** @deprecated Kept for App compat — Connection is carousel-only now. */
  favorites?: string[];
  /** @deprecated Kept for App compat — Connection is carousel-only now. */
  onRemoveFavorite?: (reaction: string) => void;
  /** Media carousel (defaults to sample stills; swap for real uploads). */
  carouselSlides?: ConnectionCarouselSlide[];
  /** User tapped Start on the current slide. */
  onCarouselStart?: (index: number, slide: ConnectionCarouselSlide) => void;
  /** Auto-advance carousel (ms). 0 = off. */
  carouselAutoMs?: number;
}

/** Couple / closeness mood (not sports). Use `?w=&q=` Unsplash URLs — some `auto=format` / newer ids fail to load in apps. */
const DEFAULT_CAROUSEL_SLIDES: ConnectionCarouselSlide[] = [
  {
    id: "todays-activity",
    title: "Today's Activity",
    body: "Small relationship-building prompts—yours and your partner's are different, but they fit the same day.",
    userTask: "Send a short voice note: one thing you appreciated about your partner today, even if it was tiny.",
    partnerTask: "Write one sentence you'd like to hear more often from them—keep it kind and specific.",
    imageUrl: "https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=1280&q=80",
  },
  {
    id: "partner-quiz",
    title: "How well do you know your partner?",
    body: "Take a test now—playful questions to understand each other. One answers, the other guesses—or you both answer and compare at the end.",
    imageUrl: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=1280&q=80",
  },
  {
    id: "try-premium",
    title: "Try Premium!",
    body: "More daily questions, couple prompts, and rituals to grow your bond—unlock the full experience for both of you.",
    imageUrl: "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=1280&q=80",
  },
];

export function ConnectionScreen({
  carouselSlides = DEFAULT_CAROUSEL_SLIDES,
  onCarouselStart,
  carouselAutoMs = 8000,
}: ConnectionScreenProps) {
  const slides = carouselSlides.length > 0 ? carouselSlides : DEFAULT_CAROUSEL_SLIDES;
  const [carouselIndex, setCarouselIndex] = useState(0);
  const [showTodaysActivity, setShowTodaysActivity] = useState(false);
  const safeIndex = slides.length ? carouselIndex % slides.length : 0;
  const currentSlide = slides[safeIndex] ?? slides[0];

  const handleCarouselStart = useCallback(() => {
    onCarouselStart?.(safeIndex, currentSlide);
    if (currentSlide.id === TODAYS_ACTIVITY.id) {
      setShowTodaysActivity(true);
    }
  }, [onCarouselStart, safeIndex, currentSlide]);

  const goNext = useCallback(() => {
    setCarouselIndex((i) => (slides.length <= 1 ? 0 : (i + 1) % slides.length));
  }, [slides.length]);
  const goPrev = useCallback(() => {
    setCarouselIndex((i) => (slides.length <= 1 ? 0 : (i - 1 + slides.length) % slides.length));
  }, [slides.length]);

  const swipePointer = useRef<{ x: number; pointerId: number } | null>(null);
  const SWIPE_MIN_PX = 48;
  const onCarouselPointerDown = useCallback<PointerEventHandler<HTMLDivElement>>((e) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    swipePointer.current = { x: e.clientX, pointerId: e.pointerId };
  }, []);
  const onCarouselPointerUp = useCallback<PointerEventHandler<HTMLDivElement>>(
    (e) => {
      const start = swipePointer.current;
      if (!start || start.pointerId !== e.pointerId) return;
      swipePointer.current = null;
      if (slides.length <= 1) return;
      const dx = e.clientX - start.x;
      if (dx > SWIPE_MIN_PX) goPrev();
      else if (dx < -SWIPE_MIN_PX) goNext();
    },
    [slides.length, goPrev, goNext],
  );
  const onCarouselPointerCancel = useCallback(() => {
    swipePointer.current = null;
  }, []);

  useEffect(() => {
    if (showTodaysActivity || !carouselAutoMs || slides.length <= 1) return undefined;
    const t = window.setInterval(goNext, carouselAutoMs);
    return () => window.clearInterval(t);
  }, [carouselAutoMs, slides.length, goNext, showTodaysActivity]);

  return (
    <div className="fixed inset-0 z-0 flex justify-center bg-neutral-950">
      <div className="relative h-full w-full max-w-md overflow-hidden bg-neutral-950">
        <AnimatePresence>
          {showTodaysActivity ? (
            <TodaysActivityScreen
              key="todays-activity"
              onClose={() => setShowTodaysActivity(false)}
              userTask={currentSlide.userTask ?? TODAYS_ACTIVITY.userTask}
              partnerTask={currentSlide.partnerTask ?? TODAYS_ACTIVITY.partnerTask}
            />
          ) : null}
        </AnimatePresence>

        {/* Full-bleed media — stretches edge-to-edge under the tab bar */}
        <div
          className="absolute inset-0 touch-pan-x select-none"
          onPointerDown={onCarouselPointerDown}
          onPointerUp={onCarouselPointerUp}
          onPointerCancel={onCarouselPointerCancel}
          onPointerLeave={(e) => {
            if (swipePointer.current?.pointerId === e.pointerId) swipePointer.current = null;
          }}
        >
          <AnimatePresence mode="wait">
            <motion.div
              key={currentSlide.id}
              className="absolute inset-0"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.4 }}
            >
              {currentSlide.videoUrl ? (
                <video
                  className="absolute inset-0 h-full w-full object-cover"
                  src={currentSlide.videoUrl}
                  poster={currentSlide.posterUrl}
                  muted
                  playsInline
                  loop
                  autoPlay
                />
              ) : currentSlide.imageUrl ? (
                <img
                  key={`${currentSlide.id}-${currentSlide.imageUrl}`}
                  src={currentSlide.imageUrl}
                  alt=""
                  className="absolute inset-0 h-full w-full object-cover"
                  style={{ objectFit: "cover", objectPosition: "center" }}
                  draggable={false}
                  decoding="async"
                  sizes="100vw"
                />
              ) : (
                <div
                  className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-neutral-800 via-neutral-900 to-black text-sm text-white/35"
                  style={{ fontWeight: 300 }}
                >
                  Add photos or video
                </div>
              )}
              <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-black/55 via-black/20 to-black/50" />
            </motion.div>
          </AnimatePresence>

          <div className="pointer-events-none absolute left-0 right-0 top-0 z-10 flex justify-center pt-[max(0.5rem,env(safe-area-inset-top))]">
            <motion.div
              className="flex items-center gap-2 rounded-full border border-white/15 bg-black/30 px-3 py-1.5 backdrop-blur-md"
              initial={{ opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
            >
              <Sparkle className="h-3.5 w-3.5 text-white/75" />
              <span className="text-[10px] uppercase tracking-[0.18em] text-white/85" style={{ fontWeight: 300 }}>
                Connection
              </span>
            </motion.div>
          </div>

          {slides.length > 1 ? (
            <div className="absolute right-3 top-[max(2.75rem,env(safe-area-inset-top))] z-20 flex gap-1.5">
              {slides.map((s, i) => (
                <button
                  key={s.id}
                  type="button"
                  aria-label={`Slide ${i + 1}`}
                  onClick={() => setCarouselIndex(i)}
                  className={`h-1.5 rounded-full transition-all ${i === safeIndex ? "w-5 bg-white" : "w-1.5 bg-white/35"}`}
                />
              ))}
            </div>
          ) : null}

          <div className="absolute left-0 right-0 top-0 z-20 px-4 pt-[max(5.5rem,calc(env(safe-area-inset-top)+4.5rem))]">
            <div className="w-full max-w-[21rem] space-y-2.5 text-left">
              {currentSlide.title ? (
                <p className="text-[18px] leading-tight text-white drop-shadow-[0_1px_10px_rgba(0,0,0,0.75)]" style={{ fontWeight: 600 }}>
                  {currentSlide.title}
                </p>
              ) : null}
              {currentSlide.body ? (
                <p className="text-[14px] leading-snug text-white/88 drop-shadow-[0_1px_8px_rgba(0,0,0,0.65)]" style={{ fontWeight: 400 }}>
                  {currentSlide.body}
                </p>
              ) : null}
              {currentSlide.userTask != null && currentSlide.partnerTask != null ? (
                <div className="space-y-2.5 border-t border-white/15 pt-2.5">
                  <p className="text-[13px] leading-snug text-white/90 drop-shadow-[0_1px_6px_rgba(0,0,0,0.7)]" style={{ fontWeight: 400 }}>
                    <span className="mb-0.5 block text-[10px] uppercase tracking-[0.14em] text-white/55" style={{ fontWeight: 500 }}>
                      You
                    </span>
                    {currentSlide.userTask}
                  </p>
                  <p className="text-[13px] leading-snug text-white/90 drop-shadow-[0_1px_6px_rgba(0,0,0,0.7)]" style={{ fontWeight: 400 }}>
                    <span className="mb-0.5 block text-[10px] uppercase tracking-[0.14em] text-white/55" style={{ fontWeight: 500 }}>
                      Partner
                    </span>
                    {currentSlide.partnerTask}
                  </p>
                </div>
              ) : null}
              {!currentSlide.title && !currentSlide.body && !(currentSlide.userTask && currentSlide.partnerTask) && currentSlide.description ? (
                <p className="text-[14px] leading-snug text-white/92 drop-shadow-[0_1px_8px_rgba(0,0,0,0.65)]" style={{ fontWeight: 400 }}>
                  {currentSlide.description}
                </p>
              ) : null}
            </div>
          </div>

          <div className="pointer-events-none absolute inset-0 z-20 flex items-center justify-center px-4">
            <motion.button
              type="button"
              className="pointer-events-auto touch-manipulation rounded-full bg-white px-7 py-2.5 text-[14px] text-neutral-900 shadow-[0_4px_24px_rgba(0,0,0,0.35)]"
              style={{ fontWeight: 600 }}
              whileTap={{ scale: 0.97 }}
              onClick={handleCarouselStart}
            >
              {currentSlide.id === TODAYS_ACTIVITY.id ? "Open your task for today!" : "Start"}
            </motion.button>
          </div>
        </div>
      </div>
    </div>
  );
}
