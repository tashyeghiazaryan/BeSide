import { motion, AnimatePresence, useMotionValue, animate, type PanInfo } from "motion/react";
import {
  Calendar,
  Heart,
  Gift,
  Sparkles,
  X,
  ChevronLeft,
  ChevronRight,
  ChevronDown,
  Share2,
  Plus,
  Check,
  Image,
  Mail,
  Bell,
  Clock,
  Waves,
  Pencil,
  History,
  Send,
} from "lucide-react";
import {
  createElement,
  useState,
  useRef,
  useEffect,
  useMemo,
  useCallback,
  type ChangeEvent,
  type CSSProperties,
} from "react";

interface ImportantDate {
  id: string;
  title: string;
  date: Date;
  icon: typeof Calendar;
  color: string;
  gradient: string;
}

interface SharedMemory {
  id: string;
  title: string;
  dateTime: Date;
  description?: string;
  mood: string;
  photoUrl?: string;
  likes: number;
  likedByMe: boolean;
  /** True when created via “Add a memory” — shown in the gallery page. */
  addedByUser: boolean;
}

/** Fulfilled wishlist item — gifts completed for each other. */
interface CompletedWish {
  id: string;
  title: string;
  completedAt: Date;
  /** `for_me` — partner fulfilled your wish; `for_partner` — you fulfilled theirs. */
  direction: "for_me" | "for_partner";
}

/** Wishlist entry — photo + short caption. */
interface WishlistItem {
  id: string;
  caption: string;
  photoUrl: string;
}

const DEFAULT_PARTNER_WISHLIST: WishlistItem[] = [
  {
    id: "pw-1",
    caption: "Cozy knit sweater",
    photoUrl: "https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400&h=400&fit=crop",
  },
  {
    id: "pw-2",
    caption: "Pour-over coffee kit",
    photoUrl: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&h=400&fit=crop",
  },
  {
    id: "pw-3",
    caption: "Concert tickets",
    photoUrl: "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400&h=400&fit=crop",
  },
];

function normalizeWishlistSeed(raw: Array<string | WishlistItem>): WishlistItem[] {
  return raw.map((item, i) => {
    if (typeof item === "string") {
      return { id: `wish-seed-${i}`, caption: item, photoUrl: "" };
    }
    return {
      id: item.id || `wish-seed-${i}`,
      caption: item.caption,
      photoUrl: item.photoUrl || "",
    };
  });
}

export type PairMood = "calm" | "joy" | "love" | "sad" | "exhausted" | "stressed";

/** Viewer-relative: what you sent vs what your partner left for you. */
type LoveNoteDirection = "incoming" | "outgoing";

/** How a note was (or is) meant to open. New notes use `instant` only. */
export type LoveNoteTriggerKind = "instant" | "time" | "mood" | "away";

export type LoveNoteStatus = "waiting" | "unlocked" | "read";

export interface LoveNote {
  id: string;
  body: string;
  createdAt: Date;
  direction: LoveNoteDirection;
  triggerKind: LoveNoteTriggerKind;
  /** For `time` — when the note unlocks (sender-only detail on outgoing). */
  opensAt?: Date;
  /** For `mood` — which mood unlocks the note. */
  targetMood?: PairMood;
  /** For `away` — days without opening the app. */
  inactivityDays?: 1 | 3 | 7;
  /** Incoming: sealed → can read → read. Outgoing: traveling → they opened → they read. */
  status: LoveNoteStatus;
  readAt?: Date;
  partnerReadAt?: Date;
  /** Incoming unlocked — hero tile + banner until dismissed or read. */
  moodUnlockHighlight?: boolean;
}

const MAX_WAITING_LOVE_NOTES = 5;
const LOVE_NOTE_BODY_MAX_LEN = 100;

/** Demo partner note when host doesn't pass `loveNotesSeed`. */
const DEFAULT_LOVE_NOTES_SEED: LoveNote[] = [
  {
    id: "ln-demo-incoming-1",
    body: "Hey you — just thinking of you. Hope this makes you smile today.",
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    direction: "incoming",
    triggerKind: "instant",
    status: "unlocked",
    moodUnlockHighlight: true,
  },
];

/** Latin letters, digits, common punctuation/symbols, spaces — plus emoji / ZWJ sequences. */
function isAllowedLoveNoteChar(ch: string): boolean {
  const code = ch.codePointAt(0);
  if (code == null) return false;
  if (code >= 0x20 && code <= 0x7e) return true;
  if (code === 0x200d || code === 0xfe0f || code === 0x20e3) return true;
  if (code >= 0x2600 && code <= 0x27bf) return true;
  if (code >= 0x1f1e6 && code <= 0x1f1ff) return true;
  if (code >= 0x1f300 && code <= 0x1faff) return true;
  if (code >= 0x1f3fb && code <= 0x1f3ff) return true;
  return false;
}

function loveNoteBodyLength(body: string): number {
  return Array.from(body).length;
}

function sanitizeLoveNoteBody(raw: string): string {
  let out = "";
  for (const ch of raw) {
    if (!isAllowedLoveNoteChar(ch)) continue;
    if (loveNoteBodyLength(out) >= LOVE_NOTE_BODY_MAX_LEN) break;
    out += ch;
  }
  return out;
}

const PAIR_MOOD_LABEL: Record<PairMood, string> = {
  calm: "Calm",
  joy: "Joyful",
  love: "Loving",
  sad: "Sad",
  exhausted: "Exhausted",
  stressed: "Stressed",
};

/** Legacy seeds (pre–Love Note v2). */
type LegacyLoveNoteCondition = "specific_time" | "when_sad" | "when_exhausted" | "when_need_support" | "after_quiet";

function normalizeLoveNoteFromSeed(raw: unknown): LoveNote {
  const r = raw as Record<string, unknown>;
  if (r.triggerKind && (r.status === "waiting" || r.status === "unlocked" || r.status === "read")) {
    const n = raw as LoveNote;
    return {
      ...n,
      createdAt: n.createdAt instanceof Date ? n.createdAt : new Date(String(n.createdAt)),
      opensAt: n.opensAt ? (n.opensAt instanceof Date ? n.opensAt : new Date(String(n.opensAt))) : undefined,
      readAt: n.readAt ? (n.readAt instanceof Date ? n.readAt : new Date(String(n.readAt))) : undefined,
      partnerReadAt: n.partnerReadAt
        ? n.partnerReadAt instanceof Date
          ? n.partnerReadAt
          : new Date(String(n.partnerReadAt))
        : undefined,
    };
  }
  const condition = r.condition as LegacyLoveNoteCondition | undefined;
  let triggerKind: LoveNoteTriggerKind = "mood";
  let targetMood: PairMood | undefined = "sad";
  let inactivityDays: 1 | 3 | 7 | undefined;
  let opensAt: Date | undefined;
  if (condition === "specific_time") {
    triggerKind = "time";
    targetMood = undefined;
    if (r.opensAt) opensAt = r.opensAt instanceof Date ? r.opensAt : new Date(String(r.opensAt));
  } else if (condition === "after_quiet") {
    triggerKind = "away";
    targetMood = undefined;
    inactivityDays = 1;
  } else if (condition === "when_exhausted") targetMood = "exhausted";
  else if (condition === "when_need_support") targetMood = "stressed";
  else targetMood = "sad";
  const legacyStatus = r.status as string | undefined;
  let status: LoveNoteStatus = "waiting";
  if (legacyStatus === "read") status = "read";
  else if (legacyStatus === "delivered") status = "unlocked";
  return {
    id: String(r.id),
    body: String(r.body),
    direction: r.direction as LoveNoteDirection,
    createdAt: r.createdAt instanceof Date ? r.createdAt : new Date(String(r.createdAt)),
    triggerKind,
    opensAt,
    targetMood,
    inactivityDays,
    status,
    readAt: r.readAt ? (r.readAt instanceof Date ? r.readAt : new Date(String(r.readAt))) : undefined,
    partnerReadAt: r.partnerReadAt
      ? r.partnerReadAt instanceof Date
        ? r.partnerReadAt
        : new Date(String(r.partnerReadAt))
      : undefined,
    moodUnlockHighlight: Boolean(r.moodUnlockHighlight),
  };
}

function littleSurprisesLine(count: number): string {
  if (count <= 0) return "";
  if (count === 1) return "1 little surprise tucked away";
  return `${count} little surprises tucked away`;
}

function loveNoteBodyPreview(body: string, max = 52): string {
  const t = body.trim().replace(/\s+/g, " ");
  if (t.length <= max) return t;
  return `${t.slice(0, max).trim()}…`;
}

function loveNoteIncomingVagueTriggerLine(note: LoveNote): string {
  if (note.triggerKind === "instant") return "A note for you";
  if (note.triggerKind === "time") return "Opens on a set date";
  if (note.triggerKind === "mood") return "Opens when they feel a certain way";
  return "Opens after you've been away";
}

function loveNoteIncomingUnlockedLine(note: LoveNote): string {
  if (note.triggerKind === "instant") return "Ready to open";
  if (note.triggerKind === "mood") return "Unlocked — you seemed to need it";
  if (note.triggerKind === "time") return "Unlocked — left for this moment";
  return "Unlocked — someone missed you";
}

function loveNoteOutgoingOpensLine(note: LoveNote): string {
  if (note.triggerKind === "instant") {
    if (note.status === "read") return "They’ve opened it";
    if (note.status === "unlocked") return "Delivered";
    return "On its way";
  }
  if (note.triggerKind === "time" && note.opensAt) {
    return `Opens ${note.opensAt.toLocaleDateString("en-US", { month: "short", day: "numeric" })}`;
  }
  if (note.triggerKind === "time") return "Opens at a set time";
  if (note.triggerKind === "mood" && note.targetMood) {
    return `Opens when ${PAIR_MOOD_LABEL[note.targetMood].toLowerCase()}`;
  }
  if (note.triggerKind === "away" && note.inactivityDays) {
    return `Opens after ${note.inactivityDays} day${note.inactivityDays > 1 ? "s" : ""} away`;
  }
  if (note.triggerKind === "away") return "Opens after they've been away";
  return "Opens when the moment is right";
}

function formatRelativeLoveSent(createdAt: Date): string {
  const now = Date.now();
  const d = createdAt.getTime();
  const days = Math.floor((now - d) / (86400 * 1000));
  if (days <= 0) return "Sent today";
  if (days === 1) return "Sent yesterday";
  if (days < 7) return `Sent ${days} days ago`;
  return `Sent ${createdAt.toLocaleDateString("en-US", { month: "short", day: "numeric" })}`;
}

function formatLoveNoteSentAt(createdAt: Date): string {
  return createdAt.toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

function formatRelativeLoveRead(at: Date): string {
  const now = Date.now();
  const d = at.getTime();
  const days = Math.floor((now - d) / (86400 * 1000));
  if (days <= 0) return "Read today";
  if (days === 1) return "Read yesterday";
  if (days < 7) return `Read ${days} days ago`;
  return `Read ${at.toLocaleDateString("en-US", { month: "short", day: "numeric" })}`;
}

function loveNoteTriggerIconEl(kind: LoveNoteTriggerKind, className: string, style: CSSProperties) {
  const common = { className, strokeWidth: 2 as const, style, "aria-hidden": true as const };
  if (kind === "instant") return createElement(Mail, common);
  if (kind === "time") return createElement(Clock, common);
  if (kind === "mood") return createElement(Heart, common);
  return createElement(Waves, common);
}

function calculateTimeTogether(startDate: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - startDate.getTime();
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  const years = Math.floor(diffDays / 365);
  const months = Math.floor((diffDays % 365) / 30);
  const days = diffDays % 30;
  if (years > 0) {
    if (months > 0) return `together for ${years} year${years > 1 ? "s" : ""} and ${months} month${months > 1 ? "s" : ""}`;
    return `together for ${years} year${years > 1 ? "s" : ""}`;
  } else if (months > 0) {
    return `together for ${months} month${months > 1 ? "s" : ""}`;
  }
  return `together for ${days} day${days > 1 ? "s" : ""}`;
}

function getDaysUntil(date: Date): number {
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  const targetDate = new Date(date);
  targetDate.setHours(0, 0, 0, 0);
  return Math.floor((targetDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
}

function formatDate(date: Date): string {
  return date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

function formatShortDate(date: Date): string {
  return date.toLocaleDateString("en-GB", { day: "numeric", month: "short" });
}

function countdownLabel(daysUntil: number): string {
  if (daysUntil === 0) return "Today";
  if (daysUntil === 1) return "Tomorrow";
  if (daysUntil < 0) {
    const ago = Math.abs(daysUntil);
    if (ago === 1) return "Yesterday";
    return `${ago}d ago`;
  }
  return `in ${daysUntil} days`;
}

function buildCalendarDayCells(year: number, month: number): (number | null)[] {
  const first = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0).getDate();
  const startPad = (first.getDay() + 6) % 7;
  const cells: (number | null)[] = [];
  for (let i = 0; i < startPad; i++) cells.push(null);
  for (let d = 1; d <= lastDay; d++) cells.push(d);
  while (cells.length % 7 !== 0) cells.push(null);
  return cells;
}

function getNextAnnualOccurrence(date: Date): Date {
  const now = new Date();
  const normalizedNow = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  let candidate = new Date(now.getFullYear(), date.getMonth(), date.getDate());
  if (candidate < normalizedNow) candidate = new Date(now.getFullYear() + 1, date.getMonth(), date.getDate());
  return candidate;
}

/** Body / UI foreground ink (default black replacement on Us). */
const US_INK = "#26282B";
const US_INK_RGB = "38,40,43";

/** Expanded Shared Memories — swipe card deck on Us home. */
const MEMORY_CARD_WIDTH = 168;
const MEMORY_CARD_GAP = 12;
const MEMORY_SLIDE_WIDTH = MEMORY_CARD_WIDTH + MEMORY_CARD_GAP;
const MEMORY_CARD_PHOTO_HEIGHT = 118;
/** Primary label on pill / gradient CTAs — same as body emphasis elsewhere in the app */
const CTA_BUTTON_TEXT = `rgba(${US_INK_RGB},0.78)`;

/** Envelope icon on Us Love Note tile — disabled state */
const LOVE_NOTE_SEND_BTN_DISABLED = {
  bg: "rgba(255,248,240,0.08)",
  border: "1.5px solid rgba(255,248,240,0.28)",
  shadow: "none",
  icon: "rgba(255,248,240,0.45)",
} as const;

/**
 * Matte frosted glass — same visual language as Me / Partner mood tiles:
 * soft white translucency, blur, light rim, subtle inset highlight.
 */
const GLASS_MATTE = {
  border: "rgba(255,255,255,0.56)",
  surface: "linear-gradient(152deg, rgba(255,255,255,0.54) 0%, rgba(255,255,255,0.34) 46%, rgba(255,255,255,0.21) 100%)",
  shadow:
    `0 14px 44px rgba(15,23,42,0.075), 0 4px 14px rgba(${US_INK_RGB},0.04), inset 0 1px 0 rgba(255,255,255,0.8), inset 0 -1px 0 rgba(255,255,255,0.12)`,
} as const;

const GLASS_SHELL_CLASS = "relative overflow-hidden rounded-2xl border backdrop-blur-xl shadow-lg";

/**
 * Swipe cards inside Shared Memories — frostier and more lifted than the section shell
 * (even rim on all sides; photo sits in a clean frame above caption).
 */
const MEMORY_CARD_GLASS = {
  surface:
    "linear-gradient(168deg, rgba(255,255,255,0.9) 0%, rgba(255,255,255,0.72) 48%, rgba(248,250,252,0.78) 100%)",
  border: "1.5px solid rgba(255,255,255,0.85)",
  borderActive: "1.5px solid rgba(255,255,255,0.95)",
  shadowIdle: "0 4px 14px rgba(15,23,42,0.06), inset 0 1px 0 rgba(255,255,255,0.95)",
  shadowActive: "0 6px 18px rgba(15,23,42,0.08), inset 0 1px 0 rgba(255,255,255,0.95)",
} as const;

/** Shared Memories — matte frosted shell (same as `GLASS_MATTE`). */
const SHARED_MEMORIES_PANEL_SURFACE = GLASS_MATTE.surface;
/** Ambient wash on full-screen backdrop (warm butter under this section). */
const SHARED_MEMORIES_PANEL_RGB = "237,228,188";
const SHARED_MEMORY_CARD_SURFACE = "#F0EEE9";

/** Butter RGB tokens; solid fill kept for progress bar — Important Dates tile uses modal glass. */
const IMPORTANT_DATES_PANEL_RGB = "255,237,168";
const IMPORTANT_DATES_PANEL = {
  surface: "#FFEDA8",
  border: "rgba(255,255,255,0.65)",
  shadow: `0 10px 28px rgba(${IMPORTANT_DATES_PANEL_RGB},0.5), 0 2px 10px rgba(${US_INK_RGB},0.06)`,
} as const;
/** Long-term progress bar fill — Auth Continue navy with soft sheen. */
const US_CONTINUE_NAVY = "#1a1a2e";
const US_CONTINUE_NAVY_MID = "#2d2d44";
const US_LEVEL_PROGRESS_FILL = `linear-gradient(135deg, ${US_CONTINUE_NAVY}, ${US_CONTINUE_NAVY_MID}, #3d3d58, ${US_CONTINUE_NAVY_MID}, ${US_CONTINUE_NAVY})`;
const US_LEVEL_PROGRESS_GLOW = "rgba(26,26,46,0.28)";
/** Streak label under progress — plain orange (not a chip). */
const US_STREAK_LABEL_COLOR = "#EA580C";
/** Countdown pill — Important dates modal list + tile (muted frosted butter). */
const IMPORTANT_DATES_MODAL_COUNTDOWN_BADGE = {
  background: `linear-gradient(165deg, rgba(${IMPORTANT_DATES_PANEL_RGB},0.16) 0%, rgba(255,255,255,0.42) 100%)`,
  border: `1px solid rgba(${IMPORTANT_DATES_PANEL_RGB},0.22)`,
  shadow: `inset 0 1px 0 rgba(255,255,255,0.58), 0 1px 4px rgba(${US_INK_RGB},0.04)`,
  color: `rgba(${US_INK_RGB},0.46)`,
} as const;
const IMPORTANT_DATES_TEXT = US_INK;
const IMPORTANT_DATES_TEXT_SOFT = `rgba(${US_INK_RGB},0.55)`;
const IMPORTANT_DATES_TEXT_FAINT = `rgba(${US_INK_RGB},0.38)`;

/**
 * Modals + Important dates tile: frosted semi-transparent glass, warm butter wash
 * (progress bar still uses solid `#FFEDA8`).
 */
const IMPORTANT_DATES_MODAL_GLASS = {
  surface: `linear-gradient(168deg, rgba(255,255,255,0.5) 0%, rgba(255,252,242,0.44) 40%, rgba(255,244,218,0.38) 75%, rgba(255,255,255,0.34) 100%)`,
  border: "rgba(255,255,255,0.52)",
  shadow: `0 24px 56px rgba(15,23,42,0.09), 0 10px 28px rgba(${IMPORTANT_DATES_PANEL_RGB},0.14), inset 0 1px 0 rgba(255,255,255,0.78), inset 0 -1px 0 rgba(255,255,255,0.07)`,
  topHairline: `linear-gradient(90deg, rgba(${IMPORTANT_DATES_PANEL_RGB},0.45), rgba(255,248,224,0.28), transparent)`,
} as const;

const DATES_MODAL_INPUT_GLASS = {
  background: "rgba(255,255,255,0.42)",
  border: `1px solid rgba(${IMPORTANT_DATES_PANEL_RGB},0.22)`,
} as const;

/**
 * Important dates calendar modal — Auth-like frosted glass (white / soft navy ink),
 * keep translucent; navy Continue accents instead of butter yellow.
 */
const AUTH_DATES_CALENDAR_GLASS = {
  surface:
    "linear-gradient(155deg, rgba(255,255,255,0.88) 0%, rgba(255,255,255,0.72) 45%, rgba(248,250,252,0.68) 100%)",
  border: "rgba(255,255,255,0.72)",
  shadow: "0 24px 56px rgba(26,26,46,0.12), 0 8px 24px rgba(15,23,42,0.06), inset 0 1px 0 rgba(255,255,255,0.95)",
  topHairline: "linear-gradient(90deg, rgba(26,26,46,0.2), rgba(232,190,201,0.35), transparent)",
} as const;

const AUTH_DATES_CHROME = {
  background: "rgba(255,255,255,0.72)",
  border: "1px solid rgba(45,45,68,0.14)",
  shadow: "inset 0 1px 0 rgba(255,255,255,0.9), 0 2px 10px rgba(26,26,46,0.05)",
  icon: "rgba(26,26,46,0.55)",
} as const;

const AUTH_DATES_INPUT = {
  background: "rgba(255,255,255,0.9)",
  border: "1px solid rgba(45,45,68,0.12)",
} as const;

const AUTH_DATES_CTA = {
  background: "linear-gradient(135deg, #1a1a2e, #2d2d44)",
  color: "rgba(255,255,255,0.92)",
  shadow: "0 8px 24px rgba(26,26,46,0.22)",
} as const;

/** After saving a custom date — warm yellow glow on the Add button. */
const IMPORTANT_DATES_ADD_SUCCESS_BTN = {
  background: `linear-gradient(165deg, rgba(${IMPORTANT_DATES_PANEL_RGB},0.58) 0%, rgba(255,248,195,0.92) 100%)`,
  border: `1px solid rgba(${IMPORTANT_DATES_PANEL_RGB},0.48)`,
  shadow: `0 0 32px rgba(${IMPORTANT_DATES_PANEL_RGB},0.45), 0 6px 20px rgba(${IMPORTANT_DATES_PANEL_RGB},0.22), inset 0 1px 0 rgba(255,255,255,0.8)`,
  color: CTA_BUTTON_TEXT,
} as const;

/** Primary accent red on Us (progress accents, date tiles). */
const US_SAVVY_RED = "#FF555D";
const US_SAVVY_GRADIENT = "linear-gradient(135deg, #ffd4d6, #ff8a90, #FF555D, #e84850)";
/** For `rgba()` in themes — matches `US_SAVVY_RED` (#FF555D). */
const US_SAVVY_RGB = "255,85,93";
/** Avatar rings — soft translucent logo Rose. */
const US_AVATAR_ROSE_RGB = "232,190,201";
const US_AVATAR_GRADIENT = `linear-gradient(135deg, rgba(243,214,222,0.38), rgba(${US_AVATAR_ROSE_RGB},0.32), rgba(217,168,182,0.28))`;
const US_AVATAR_SURFACE = `rgba(${US_AVATAR_ROSE_RGB},0.18)`;

/** Love Note — soft pink surface; cream `#FFF8F0` type, strokes, mail control. */
const LOVE_NOTE_PANEL_CHROME = "#FFF8F0";
const LOVE_NOTE_CREAM_RGB = "255,248,240";
const LOVE_NOTE_PANEL = {
  surface: "#F8BBD0",
  border: "rgba(255,248,240,0.42)",
  shadow:
    "0 12px 36px rgba(200,100,140,0.18), 0 4px 16px rgba(248,187,208,0.35), inset 0 1px 0 rgba(255,255,255,0.45)",
  rowSurface: "rgba(255,248,240,0.18)",
  rowBorder: "rgba(255,248,240,0.38)",
  mailBtnEnabledBg: "rgba(255,248,240,0.24)",
} as const;

/** Love Notes tile when partner has left incoming surprises (slightly brighter pink). */
const LOVE_NOTE_PANEL_ACTIVE = {
  surface: "linear-gradient(165deg, #F8A0C4 0%, #F472A8 48%, #EC6FA5 100%)",
  border: "rgba(255,248,240,0.55)",
  shadow:
    "0 14px 40px rgba(220,80,130,0.35), 0 4px 18px rgba(248,120,168,0.45), inset 0 1px 0 rgba(255,255,255,0.55)",
  wash: "radial-gradient(ellipse 90% 70% at 15% 0%, rgba(255,255,255,0.35), transparent 55%)",
} as const;

/** For `rgba()` in Love Note glass — matches `#F8BBD0` family. */
const LOVE_NOTE_PANEL_RGB = "248,187,208";

/**
 * Expanded Love Notes strip — frosted semi-transparent glass with a soft pink wash
 * (same idea as `IMPORTANT_DATES_MODAL_GLASS`, butter → pink).
 */
const LOVE_NOTE_EXPANDED_GLASS = {
  surface: `linear-gradient(168deg, rgba(255,255,255,0.5) 0%, rgba(255,252,254,0.44) 40%, rgba(253,236,245,0.38) 75%, rgba(255,255,255,0.34) 100%)`,
  border: "rgba(255,255,255,0.52)",
  shadow: `0 24px 56px rgba(15,23,42,0.09), 0 10px 28px rgba(${LOVE_NOTE_PANEL_RGB},0.14), inset 0 1px 0 rgba(255,255,255,0.78), inset 0 -1px 0 rgba(255,255,255,0.07)`,
} as const;

/** Composer modal — frosted glass + soft pink wash and outer glow (“розовый свет”). */
const LOVE_NOTE_CREATE_MODAL_GLASS = {
  surface: `linear-gradient(168deg, rgba(255,254,255,0.68) 0%, rgba(255,250,253,0.52) 35%, rgba(253,236,246,0.42) 65%, rgba(255,252,254,0.55) 100%)`,
  border: `rgba(${LOVE_NOTE_PANEL_RGB},0.38)`,
  shadow: `inset 0 1px 0 rgba(255,255,255,0.88), inset 0 -1px 0 rgba(255,255,255,0.1), 0 24px 52px rgba(15,23,42,0.1), 0 12px 40px rgba(${LOVE_NOTE_PANEL_RGB},0.2), 0 0 72px rgba(236,72,153,0.22), 0 0 1px rgba(${LOVE_NOTE_PANEL_RGB},0.15)`,
} as const;

const LOVE_NOTE_CREATE_MODAL_PINK_WASH =
  `radial-gradient(ellipse 95% 60% at 50% -8%, rgba(${LOVE_NOTE_PANEL_RGB},0.28), transparent 55%), radial-gradient(ellipse 80% 50% at 80% 105%, rgba(244,114,182,0.14), transparent 52%)`;

const LOVE_NOTE_MODAL_FIELD = {
  background: "rgba(255,255,255,0.72)",
  border: `1px solid rgba(${US_INK_RGB},0.12)`,
} as const;

/** Inner list rows in expanded panel — lighter frost than solid `LOVE_NOTE_PANEL.surface`. */
const LOVE_NOTE_EXPANDED_ROW = {
  surface: `linear-gradient(165deg, rgba(255,255,255,0.34) 0%, rgba(255,250,252,0.22) 100%)`,
  border: `rgba(${LOVE_NOTE_PANEL_RGB},0.2)`,
} as const;

/** Long-term level ladder for the Us progress bar only (name / emoji / points goal per level) */
const US_LONG_TERM_LEVELS: readonly { level: number; name: string; emoji: string; pointsToNext: number }[] = [
  { level: 1, name: "First Spark", emoji: "✨", pointsToNext: 150 },
  { level: 2, name: "Curious Hearts", emoji: "💛", pointsToNext: 260 },
  { level: 3, name: "Getting Closer", emoji: "😊", pointsToNext: 370 },
  { level: 4, name: "Warm Connection", emoji: "☀️", pointsToNext: 480 },
  { level: 5, name: "Sweet Moments", emoji: "🍯", pointsToNext: 590 },
  { level: 6, name: "Building Trust", emoji: "🤝", pointsToNext: 700 },
  { level: 7, name: "Open Conversations", emoji: "💬", pointsToNext: 810 },
  { level: 8, name: "Emotional Sync", emoji: "💞", pointsToNext: 920 },
  { level: 9, name: "Deeper Feelings", emoji: "💓", pointsToNext: 1030 },
  { level: 10, name: "Safe Space", emoji: "🫶", pointsToNext: 1000 },
  { level: 11, name: "True Interest", emoji: "🌷", pointsToNext: 1100 },
  { level: 12, name: "Growing Bond", emoji: "🌱", pointsToNext: 1200 },
  { level: 13, name: "Daily Care", emoji: "☕", pointsToNext: 1400 },
  { level: 14, name: "Meaningful Talks", emoji: "🧠", pointsToNext: 1500 },
  { level: 15, name: "Honest Connection", emoji: "💎", pointsToNext: 1600 },
  { level: 16, name: "Strong Feelings", emoji: "❤️‍🔥", pointsToNext: 1700 },
  { level: 17, name: "Real Support", emoji: "🤗", pointsToNext: 1800 },
  { level: 18, name: "Understanding Each Other", emoji: "🧩", pointsToNext: 1900 },
  { level: 19, name: "Deep Connection", emoji: "💞", pointsToNext: 2000 },
  { level: 20, name: "Unbreakable Link", emoji: "🔗", pointsToNext: 2100 },
  { level: 21, name: "Shared World", emoji: "🌍", pointsToNext: 2200 },
  { level: 22, name: "True Partnership", emoji: "👫", pointsToNext: 2300 },
  { level: 23, name: "Soul Alignment", emoji: "🌙", pointsToNext: 2400 },
  { level: 24, name: "Deep Trust", emoji: "🔐", pointsToNext: 2500 },
  { level: 25, name: "Emotional Intimacy", emoji: "🫀", pointsToNext: 2600 },
  { level: 26, name: "Pure Love", emoji: "💖", pointsToNext: 2700 },
  { level: 27, name: "One Team", emoji: "🛡️", pointsToNext: 2800 },
  { level: 28, name: "Soulmates", emoji: "💍", pointsToNext: 3000 },
  { level: 29, name: "Lifelong Bond", emoji: "♾️", pointsToNext: 3200 },
  { level: 30, name: "Infinite Love", emoji: "🌌", pointsToNext: 0 },
];

type CoupleStatusTier = "harmonia" | "spark" | "anchor" | "storm";

const MOOD_ORDER: PairMood[] = ["calm", "joy", "love", "sad", "exhausted", "stressed"];

/** Spark couple status — warm butter yellow (matches progress + streak). */
const SPARK_STATUS_COLOR = "#FFEDA8";
const SPARK_STATUS_RGB = "255,237,168";
/** Readable label on light Spark chip / modal (butter accents stay `SPARK_STATUS_COLOR`). */
const SPARK_TITLE_TEXT_COLOR = "#3A3326";

/**
 * Frosted matte white — circular / pill controls across Us (not Love Note tile nor its expanded list).
 * Icons stay slightly dark for calm contrast on the pastel shell.
 */
const US_MATTE_CONTROL = {
  bg: "rgba(255,255,255,0.44)",
  border: `1px solid rgba(${US_INK_RGB},0.13)`,
  borderStrong: `1.5px solid rgba(${US_INK_RGB},0.15)`,
  shadow: `0 2px 16px rgba(${US_INK_RGB},0.06), inset 0 1px 0 rgba(255,255,255,0.82)`,
  icon: `rgba(${US_INK_RGB},0.56)`,
} as const;

/** Top-left notifications — same matte language as other chrome. */
const NOTIFICATIONS_BTN_BG = US_MATTE_CONTROL.bg;
const NOTIFICATIONS_BTN_BORDER = US_MATTE_CONTROL.borderStrong;
const NOTIFICATIONS_BTN_SHADOW = US_MATTE_CONTROL.shadow;
const NOTIFICATIONS_BTN_ICON = US_MATTE_CONTROL.icon;

/**
 * Connection status theme: per-tier accent + ambient; tile colors are independent.
 */
const STATUS_THEME: Record<
  CoupleStatusTier,
  {
    title: string;
    emoji: string;
    color: string;
    /** Title on chip / status modal when `color` is too light on pale UI (Spark). */
    titleTextColor?: string;
    ambientPrimary: string;
    ambientSecondary: string;
    ambientTertiary: string;
    /** Main screen pill CTAs (+ Add date, Leave a note, Add memory) */
    cta: { gradient: string; text: string; border: string; shadow: string };
  }
> = {
  harmonia: {
    title: "Harmonia",
    emoji: "💚",
    color: "#22c55e",
    ambientPrimary: "linear-gradient(135deg, #86efac, #22c55e)",
    ambientSecondary: "linear-gradient(135deg, #bbf7d0, #4ade80)",
    ambientTertiary: "linear-gradient(135deg, #d9f99d, #86efac)",
    cta: {
      gradient: "linear-gradient(135deg, #f0fdf4, #dcfce7, #bbf7d0)",
      text: CTA_BUTTON_TEXT,
      border: "1px solid rgba(34,197,94,0.22)",
      shadow: "0 2px 8px rgba(34,197,94,0.1)",
    },
  },
  spark: {
    title: "Spark",
    emoji: "",
    color: SPARK_STATUS_COLOR,
    titleTextColor: SPARK_TITLE_TEXT_COLOR,
    ambientPrimary: `linear-gradient(135deg, #fffefb, rgba(${SPARK_STATUS_RGB},0.2))`,
    ambientSecondary: `linear-gradient(135deg, #fff6e0, rgba(${SPARK_STATUS_RGB},0.22), rgba(${SPARK_STATUS_RGB},0.3))`,
    ambientTertiary: `linear-gradient(135deg, rgba(255, 246, 224, 0.96), rgba(${SPARK_STATUS_RGB},0.3))`,
    cta: {
      gradient: `linear-gradient(135deg, #ffffff, #fff8e8, rgba(${SPARK_STATUS_RGB},0.14))`,
      text: CTA_BUTTON_TEXT,
      border: `1px solid rgba(${SPARK_STATUS_RGB},0.34)`,
      shadow: `0 2px 10px rgba(${SPARK_STATUS_RGB},0.14)`,
    },
  },
  anchor: {
    title: "Anchor",
    emoji: "🤝",
    color: "#38bdf8",
    ambientPrimary: "linear-gradient(135deg, #bae6fd, #0ea5e9)",
    ambientSecondary: "linear-gradient(135deg, #e0f2fe, #38bdf8)",
    ambientTertiary: "linear-gradient(135deg, #7dd3fc, #0284c7)",
    cta: {
      gradient: "linear-gradient(135deg, #f8fafc, #f0f9ff, #e0f2fe)",
      text: CTA_BUTTON_TEXT,
      border: "1px solid rgba(56,189,248,0.22)",
      shadow: "0 2px 8px rgba(14,165,233,0.09)",
    },
  },
  storm: {
    title: "Storm",
    emoji: "☁️",
    color: "#3b82f6",
    ambientPrimary: "linear-gradient(135deg, #93c5fd, #2563eb)",
    ambientSecondary: "linear-gradient(135deg, #bfdbfe, #3b82f6)",
    ambientTertiary: "linear-gradient(135deg, #60a5fa, #1d4ed8)",
    cta: {
      gradient: "linear-gradient(135deg, #f8fafc, #eff6ff, #dbeafe)",
      text: CTA_BUTTON_TEXT,
      border: "1px solid rgba(59,130,246,0.2)",
      shadow: "0 2px 8px rgba(59,130,246,0.09)",
    },
  },
};

function sortedMoodPairKey(a: PairMood, b: PairMood): string {
  const ia = MOOD_ORDER.indexOf(a);
  const ib = MOOD_ORDER.indexOf(b);
  return ia <= ib ? `${a}|${b}` : `${b}|${a}`;
}

/** Resolved couple status from both partners' selected moods (order-independent). */
function getCoupleMoodStatus(partner1Mood: PairMood, partner2Mood: PairMood): {
  tier: CoupleStatusTier;
  message: string;
} {
  const key = sortedMoodPairKey(partner1Mood, partner2Mood);

  const messages: Record<string, { tier: CoupleStatusTier; message: string }> = {
    "calm|calm": { tier: "harmonia", message: "You are both in a calm state — there is stability and balance between you right now." },
    "joy|joy": { tier: "harmonia", message: "You are both on an upswing — there is a lot of energy and lightness between you." },
    "love|love": { tier: "harmonia", message: "There is a strong closeness between you right now — it’s a warm and meaningful moment." },
    "sad|sad": { tier: "harmonia", message: "You are both feeling vulnerable — this can bring you closer if you are gentle with each other." },
    "exhausted|exhausted": { tier: "harmonia", message: "You are both tired — it’s especially important right now to support each other rather than make demands." },
    "stressed|stressed": { tier: "harmonia", message: "You are both tense — it’s easy to hurt each other right now, so it’s wise to be more careful." },
    "calm|joy": { tier: "spark", message: "Calmness and energy complement you well — a pleasant balance." },
    "calm|love": { tier: "spark", message: "There is softness and warmth between you — a very harmonious state." },
    "joy|love": { tier: "spark", message: "Lots of joy and closeness — a strong and vibrant state between you." },
    "calm|sad": { tier: "anchor", message: "One of you is feeling vulnerable right now, while the other can provide a sense of support." },
    "calm|exhausted": { tier: "anchor", message: "There is calmness nearby that can help you get through fatigue." },
    "calm|stressed": { tier: "anchor", message: "One person’s calmness can help the other take a moment to breathe." },
    "joy|sad": { tier: "anchor", message: "You are in different moods — this is an opportunity to show care." },
    "joy|exhausted": { tier: "anchor", message: "One person has a lot of energy, but it’s important to be gentle with the other’s state." },
    "joy|stressed": { tier: "anchor", message: "One person’s lightness can help ease the other’s tension a bit." },
    "love|sad": { tier: "anchor", message: "There is vulnerability, but also closeness — a space for genuine support." },
    "love|exhausted": { tier: "anchor", message: "Even through fatigue, a warm connection remains between you." },
    "love|stressed": { tier: "anchor", message: "Despite the tension, there is a feeling between you that you can hold onto." },
    "sad|exhausted": { tier: "storm", message: "It might be difficult for both of you right now — it’s important not to shut each other out." },
    "sad|stressed": { tier: "storm", message: "Vulnerability and irritation — a difficult combination, where extra caution is especially important." },
    "exhausted|stressed": { tier: "storm", message: "Fatigue and tension can heighten conflict — it’s better to give each other some space." },
  };

  const row = messages[key];
  if (!row) {
    return {
      tier: "harmonia",
      message: "Your moods are updating — check back in a moment.",
    };
  }
  return { tier: row.tier, message: row.message };
}

function PartnerAvatarBubble({
  name,
  photoUrl,
  gradient,
}: {
  name: string;
  photoUrl?: string;
  gradient: string;
}) {
  const initial = name.trim().charAt(0).toUpperCase() || "?";
  return (
    <div
      className="relative h-[4.25rem] w-[4.25rem] shrink-0 overflow-hidden rounded-full"
      style={{
        border: `1px solid ${US_CONTINUE_NAVY_MID}`,
        boxShadow: "0 4px 14px rgba(38,40,43,0.1)",
        backgroundColor: US_AVATAR_SURFACE,
      }}
    >
      <div className="absolute inset-0" style={{ background: gradient }} aria-hidden />
      {photoUrl ? (
        <img
          src={photoUrl}
          alt=""
          className="absolute inset-0 z-[1] h-full w-full object-cover"
        />
      ) : (
        <div
          className="relative z-[1] flex h-full w-full items-center justify-center text-[1.35rem] font-light"
          style={{ color: "rgba(38,40,43,0.72)" }}
        >
          {initial}
        </div>
      )}
    </div>
  );
}

interface UsScreenProps {
  partnerWishlist?: Array<string | WishlistItem>;
  /** Current mood each partner picked (e.g. from Me / Partner flows). */
  partner1Mood?: PairMood;
  partner2Mood?: PairMood;
  isPremium?: boolean;
  relationshipStartDateInput?: Date;
  birthdayDate?: Date;
  specialDayDate?: Date;
  specialDayTitle?: string;
  customImportantDates?: Array<{ id?: string; title: string; date: Date }>;
  partner1AvatarUrl?: string;
  partner2AvatarUrl?: string;
  /** Daily Progress — same pairing flags as Connection screen. */
  annaMoodShared?: boolean;
  alexMoodShared?: boolean;
  annaReacted?: boolean;
  alexReacted?: boolean;
  annaActivityDone?: boolean;
  alexActivityDone?: boolean;
  /** Bell in the top-left — wire to navigation when the host app has a notifications route */
  onNotificationsPress?: () => void;
  /**
   * Photo for the default Shared memory “Evening on the rooftop” (`memory-1`).
   * Set from the host after the user picks/uploads an image (https URL or file path the WebView loads).
   */
  rooftopMemoryPhotoUrl?: string;
  /** Long-term level (1–30), points toward current level goal, daily streak — same model as Connection */
  connectionLongTermLevel?: number;
  connectionLongTermPoints?: number;
  connectionStreakDays?: number;
  /**
   * Seed Love Notes (`triggerKind`: instant | time | mood | away; `status`: waiting | unlocked | read; `direction`).
   * Legacy objects with `condition` / `delivered` are normalized automatically.
   */
  loveNotesSeed?: LoveNote[];
}

export function UsScreen({
  partnerWishlist = [],
  partner1Mood = "calm",
  partner2Mood = "joy",
  isPremium = true,
  relationshipStartDateInput = new Date(2022, 2, 14),
  birthdayDate = new Date(1998, 2, 18),
  specialDayDate = new Date(2022, 2, 13),
  specialDayTitle = "Our First Date",
  customImportantDates = [],
  partner1AvatarUrl,
  partner2AvatarUrl,
  annaMoodShared = true,
  alexMoodShared = true,
  annaReacted = true,
  alexReacted = false,
  annaActivityDone = false,
  alexActivityDone = false,
  onNotificationsPress,
  rooftopMemoryPhotoUrl,
  connectionLongTermLevel = 7,
  connectionLongTermPoints = 420,
  connectionStreakDays = 3,
  loveNotesSeed = [],
}: UsScreenProps) {
  const partner1Name = "Anna";
  const partner2Name = "Alex";
  const relationshipStartDate = relationshipStartDateInput;

  const tenDaysFromNow = new Date();
  tenDaysFromNow.setHours(0, 0, 0, 0);
  tenDaysFromNow.setDate(tenDaysFromNow.getDate() + 10);

  const baseImportantDates: ImportantDate[] = [
    {
      id: "next-soon",
      title: "Next date together",
      date: tenDaysFromNow,
      icon: Sparkles,
      color: US_SAVVY_RED,
      gradient: US_SAVVY_GRADIENT,
    },
    { id: "anniversary", title: "Our Anniversary", date: getNextAnnualOccurrence(relationshipStartDate), icon: Heart, color: "#FF555D", gradient: "linear-gradient(135deg, #FF555D, #ff8a90)" },
    { id: "birthday", title: `${partner2Name}'s Birthday`, date: getNextAnnualOccurrence(birthdayDate), icon: Gift, color: "#a78bfa", gradient: "linear-gradient(135deg, #a78bfa, #c4b5fd)" },
    {
      id: "special-day",
      title: specialDayTitle,
      date: getNextAnnualOccurrence(specialDayDate),
      icon: Sparkles,
      color: US_SAVVY_RED,
      gradient: US_SAVVY_GRADIENT,
    },
    { id: "valentines", title: "Valentine's Day", date: getNextAnnualOccurrence(new Date(2022, 1, 14)), icon: Heart, color: "#FF555D", gradient: "linear-gradient(135deg, #FF555D, #ff9ba0)" },
    { id: "new-year", title: "New Year", date: getNextAnnualOccurrence(new Date(2022, 0, 1)), icon: Sparkles, color: "#60a5fa", gradient: "linear-gradient(135deg, #60a5fa, #93c5fd)" },
  ];
  const [premiumAddedDates, setPremiumAddedDates] = useState<ImportantDate[]>(
    customImportantDates.map((item, idx) => ({
      id: item.id || `custom-${idx}`,
      title: item.title,
      date: item.date,
      icon: Calendar,
      color: "#22c55e",
      gradient: "linear-gradient(135deg, #22c55e, #86efac)",
    }))
  );
  const [newDateTitle, setNewDateTitle] = useState("");
  const [newDateValue, setNewDateValue] = useState("");
  /** Important dates modal: inline fields expand under the title; second tap on Add commits. */
  const [importantDatesInlineAddOpen, setImportantDatesInlineAddOpen] = useState(false);
  const [importantDatesAddSuccess, setImportantDatesAddSuccess] = useState(false);
  const importantDatesAddedTimerRef = useRef<number | null>(null);

  const timeTogether = calculateTimeTogether(relationshipStartDate);
  const coupleStatus = getCoupleMoodStatus(partner1Mood, partner2Mood);
  const statusTheme = STATUS_THEME[coupleStatus.tier];

  const longTermLevel = Math.min(30, Math.max(1, connectionLongTermLevel));
  const longTermPoints = connectionLongTermPoints;
  const longTermStreak = Math.max(0, connectionStreakDays);
  const longTermLvlRow = US_LONG_TERM_LEVELS[longTermLevel - 1];
  const longTermGoalPoints = longTermLvlRow.pointsToNext;
  const longTermProgressFrac =
    longTermGoalPoints > 0 ? Math.min(1, Math.max(0, longTermPoints / longTermGoalPoints)) : 1;

  const allImportantDates = [...baseImportantDates, ...premiumAddedDates];
  const upcomingDates = allImportantDates
    .filter((d) => getDaysUntil(d.date) >= 0)
    .sort((a, b) => getDaysUntil(a.date) - getDaysUntil(b.date))
    .slice(0, 10);

  /** Full list for the Important Dates list modal (no top-10 cap). */
  const importantDatesFullList = [...allImportantDates].sort(
    (a, b) => getDaysUntil(a.date) - getDaysUntil(b.date)
  );

  const nearestImportantDate = upcomingDates[0] ?? null;

  const [showImportantDatesList, setShowImportantDatesList] = useState(false);
  const [showImportantDatesCalendar, setShowImportantDatesCalendar] = useState(false);
  const [calendarViewMonth, setCalendarViewMonth] = useState(() => new Date());

  const [showWishlist, setShowWishlist] = useState(false);
  const [wishlistTab, setWishlistTab] = useState<"mine" | "partner">("mine");
  const [myWishlist, setMyWishlist] = useState<WishlistItem[]>([]);
  const [wishlistDraft, setWishlistDraft] = useState("");
  const [wishlistDraftPhotoUrl, setWishlistDraftPhotoUrl] = useState("");
  const [showAddWishModal, setShowAddWishModal] = useState(false);
  /** Mine Done is inactive until tapped once; second tap confirms. */
  const [doneArmedWishIndex, setDoneArmedWishIndex] = useState<number | null>(null);
  const [showWishlistHistory, setShowWishlistHistory] = useState(false);
  const [wishlistHistory, setWishlistHistory] = useState<CompletedWish[]>(() => {
    const now = new Date();
    return [
      {
        id: "wish-done-1",
        title: "Handmade candle set",
        completedAt: new Date(now.getFullYear(), now.getMonth(), Math.max(1, now.getDate() - 12), 18, 20),
        direction: "for_me",
      },
      {
        id: "wish-done-2",
        title: "Weekend hiking day",
        completedAt: new Date(now.getFullYear(), now.getMonth(), Math.max(1, now.getDate() - 5), 11, 0),
        direction: "for_partner",
      },
    ];
  });
  const [showAddMemoryModal, setShowAddMemoryModal] = useState(false);
  const [viewingMemoryId, setViewingMemoryId] = useState<string | null>(null);
  const memoryCarouselDraggedRef = useRef(false);
  const memoryDetailDragX = useMotionValue(0);
  const [showSharedMemoriesPage, setShowSharedMemoriesPage] = useState(false);
  const [memoryActiveIndex, setMemoryActiveIndex] = useState(0);
  const memoryDragX = useMotionValue(0);
  /** `all` or `YYYY-MM` month key for gallery date filter. */
  const [memoriesDateFilter, setMemoriesDateFilter] = useState<string>("all");
  const [sharedMemories, setSharedMemories] = useState<SharedMemory[]>(() => {
    const now = new Date();
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 12, 19, 30);
    return [
      {
        id: "memory-1",
        title: "Evening on the rooftop",
        dateTime: now,
        description: "You two enjoyed the sunset together",
        mood: "💛",
        photoUrl: rooftopMemoryPhotoUrl?.trim() ?? "",
        likes: 1,
        likedByMe: false,
        addedByUser: false,
      },
      {
        id: "memory-user-demo-1",
        title: "Morning coffee walk",
        dateTime: new Date(now.getFullYear(), now.getMonth(), Math.max(1, now.getDate() - 3), 9, 15),
        description: "Quiet streets and shared silence",
        mood: "☕",
        photoUrl: "",
        likes: 2,
        likedByMe: true,
        addedByUser: true,
      },
      {
        id: "memory-user-demo-2",
        title: "Rainy cinema night",
        dateTime: lastMonth,
        description: "Held hands through the credits",
        mood: "🎬",
        photoUrl: "",
        likes: 0,
        likedByMe: false,
        addedByUser: true,
      },
    ];
  });
  const [memoryTitle, setMemoryTitle] = useState("");
  const [memoryDateTime, setMemoryDateTime] = useState("");
  const [memoryDescription, setMemoryDescription] = useState("");
  const [memoryMood, setMemoryMood] = useState("💛");
  const [memoryPhotoUrl, setMemoryPhotoUrl] = useState("");
  const moodOptions = ["💛", "😊", "🥰", "✨", "🌙", "🔥", "💙"];

  useEffect(() => {
    if (rooftopMemoryPhotoUrl === undefined) return;
    const url = rooftopMemoryPhotoUrl.trim();
    setSharedMemories((prev) =>
      prev.map((m) => {
        if (m.id !== "memory-1") return m;
        const prevUrl = m.photoUrl;
        if (prevUrl?.startsWith("blob:")) URL.revokeObjectURL(prevUrl);
        return { ...m, photoUrl: url };
      })
    );
  }, [rooftopMemoryPhotoUrl]);

  const [loveNotes, setLoveNotes] = useState<LoveNote[]>(() => {
    const seed = loveNotesSeed.length > 0 ? loveNotesSeed : DEFAULT_LOVE_NOTES_SEED;
    return seed.map((n) => normalizeLoveNoteFromSeed(n));
  });
  const [showLoveNoteModal, setShowLoveNoteModal] = useState(false);
  const [loveNoteSentToast, setLoveNoteSentToast] = useState(false);
  const [loveNoteBody, setLoveNoteBody] = useState("");
  const [loveNoteOpening, setLoveNoteOpening] = useState<LoveNote | null>(null);
  const [showLoveNotesPage, setShowLoveNotesPage] = useState(false);
  const [dailyTipId, setDailyTipId] = useState<"mood" | "reaction" | "activity" | null>(null);
  const dailyTipRef = useRef<HTMLDivElement>(null);

  const resetLoveNoteComposer = () => {
    setLoveNoteBody("");
  };

  const openLoveNoteComposer = () => {
    resetLoveNoteComposer();
    setShowLoveNoteModal(true);
  };

  useEffect(() => {
    if (!showLoveNotesPage) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setShowLoveNotesPage(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [showLoveNotesPage]);

  useEffect(() => {
    if (!viewingMemoryId) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setViewingMemoryId(null);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [viewingMemoryId]);

  useEffect(() => {
    if (!showSharedMemoriesPage) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== "Escape") return;
      if (viewingMemoryId) {
        setViewingMemoryId(null);
        return;
      }
      setShowSharedMemoriesPage(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [showSharedMemoriesPage, viewingMemoryId]);

  useEffect(() => {
    if (sharedMemories.length === 0) {
      setMemoryActiveIndex(0);
      return;
    }
    setMemoryActiveIndex((prev) => Math.min(prev, sharedMemories.length - 1));
  }, [sharedMemories.length]);

  useEffect(() => {
    animate(memoryDragX, -memoryActiveIndex * MEMORY_SLIDE_WIDTH, {
      type: "spring",
      stiffness: 320,
      damping: 32,
    });
  }, [memoryActiveIndex, memoryDragX]);

  useEffect(() => {
    if (!showWishlist) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== "Escape") return;
      if (showAddWishModal) {
        setWishlistDraft("");
        setWishlistDraftPhotoUrl((prev) => {
          if (prev.startsWith("blob:")) URL.revokeObjectURL(prev);
          return "";
        });
        setShowAddWishModal(false);
        return;
      }
      if (showWishlistHistory) setShowWishlistHistory(false);
      else {
        setShowAddWishModal(false);
        setWishlistDraft("");
        setWishlistDraftPhotoUrl((prev) => {
          if (prev.startsWith("blob:")) URL.revokeObjectURL(prev);
          return "";
        });
        setShowWishlist(false);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [showWishlist, showWishlistHistory, showAddWishModal]);

  useEffect(() => {
    if (!dailyTipId) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setDailyTipId(null);
    };
    const onPointer = (e: PointerEvent) => {
      if (dailyTipRef.current && !dailyTipRef.current.contains(e.target as Node)) {
        setDailyTipId(null);
      }
    };
    window.addEventListener("keydown", onKey);
    window.addEventListener("pointerdown", onPointer);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("pointerdown", onPointer);
    };
  }, [dailyTipId]);

  const incomingWaitingLoveNotes = loveNotes.filter((n) => n.direction === "incoming" && n.status === "waiting");
  const incomingUnlockedLoveNotes = loveNotes.filter((n) => n.direction === "incoming" && n.status === "unlocked");
  const incomingReadLoveNotes = loveNotes.filter((n) => n.direction === "incoming" && n.status === "read");
  const outgoingWaitingLoveNotes = loveNotes.filter((n) => n.direction === "outgoing" && n.status === "waiting");
  const outgoingUnlockedLoveNotes = loveNotes.filter((n) => n.direction === "outgoing" && n.status === "unlocked");
  const outgoingReadLoveNotes = loveNotes.filter((n) => n.direction === "outgoing" && n.status === "read");

  const outgoingLoveNotesSorted = useMemo(
    () =>
      [...outgoingWaitingLoveNotes, ...outgoingUnlockedLoveNotes, ...outgoingReadLoveNotes].sort(
        (a, b) => b.createdAt.getTime() - a.createdAt.getTime()
      ),
    [outgoingWaitingLoveNotes, outgoingUnlockedLoveNotes, outgoingReadLoveNotes]
  );

  const incomingUnlockedSorted = [...incomingUnlockedLoveNotes].sort((a, b) => {
    const h = Number(b.moodUnlockHighlight) - Number(a.moodUnlockHighlight);
    if (h !== 0) return h;
    return b.createdAt.getTime() - a.createdAt.getTime();
  });

  const highlightedIncomingUnlocks = incomingUnlockedLoveNotes.filter((n) => n.moodUnlockHighlight);
  const unlockHeroCount = highlightedIncomingUnlocks.length;
  const firstUnlockHighlight = highlightedIncomingUnlocks[0];

  const canAddLoveNote = outgoingWaitingLoveNotes.length < MAX_WAITING_LOVE_NOTES;

  type LoveNotesTileKind = "empty" | "outgoing_only" | "incoming_waiting" | "unlocked_moment";
  const loveNotesTileKind: LoveNotesTileKind =
    unlockHeroCount > 0
      ? "unlocked_moment"
      : incomingWaitingLoveNotes.length > 0
        ? "incoming_waiting"
        : outgoingWaitingLoveNotes.length > 0
          ? "outgoing_only"
          : "empty";

  const loveNotesTileSurface =
    loveNotesTileKind === "incoming_waiting" ? LOVE_NOTE_PANEL_ACTIVE.surface : LOVE_NOTE_PANEL.surface;
  const loveNotesTileBorder =
    loveNotesTileKind === "incoming_waiting" ? LOVE_NOTE_PANEL_ACTIVE.border : LOVE_NOTE_PANEL.border;
  const loveNotesTileShadow =
    loveNotesTileKind === "incoming_waiting" ? LOVE_NOTE_PANEL_ACTIVE.shadow : LOVE_NOTE_PANEL.shadow;
  const loveNotesTileWash =
    loveNotesTileKind === "incoming_waiting"
      ? LOVE_NOTE_PANEL_ACTIVE.wash
      : `radial-gradient(ellipse 100% 80% at 20% 0%, rgba(255,255,255,0.2), transparent 55%)`;

  const dismissLoveNoteReader = (noteId: string, markIncomingRead: boolean) => {
    setLoveNotes((prev) =>
      prev.map((n) => {
        if (n.id !== noteId) return n;
        const cleared = { ...n, moodUnlockHighlight: false };
        if (markIncomingRead && n.direction === "incoming" && n.status === "unlocked") {
          return { ...cleared, status: "read" as const, readAt: new Date() };
        }
        return cleared;
      })
    );
    setLoveNoteOpening(null);
  };

  const handleSendLoveNote = () => {
    const trimmed = sanitizeLoveNoteBody(loveNoteBody.trim());
    if (!trimmed || !canAddLoveNote) return;

    const note: LoveNote = {
      id: `ln-${Date.now()}`,
      body: trimmed,
      createdAt: new Date(),
      direction: "outgoing",
      triggerKind: "instant",
      status: "waiting",
    };
    setLoveNotes((prev) => [note, ...prev]);
    setShowLoveNoteModal(false);
    resetLoveNoteComposer();
    setLoveNoteSentToast(true);
    window.setTimeout(() => setLoveNoteSentToast(false), 3200);
  };

  const closeImportantDatesList = () => {
    setShowImportantDatesList(false);
  };

  const closeImportantDatesCalendar = () => {
    setShowImportantDatesCalendar(false);
    if (importantDatesAddedTimerRef.current != null) {
      window.clearTimeout(importantDatesAddedTimerRef.current);
      importantDatesAddedTimerRef.current = null;
    }
    setImportantDatesInlineAddOpen(false);
    setImportantDatesAddSuccess(false);
    setNewDateTitle("");
    setNewDateValue("");
  };

  const openImportantDatesList = () => {
    setShowImportantDatesCalendar(false);
    setImportantDatesInlineAddOpen(false);
    setShowImportantDatesList(true);
  };

  const openImportantDatesCalendar = () => {
    setShowImportantDatesList(false);
    setCalendarViewMonth(new Date());
    setImportantDatesInlineAddOpen(true);
    setImportantDatesAddSuccess(false);
    setShowImportantDatesCalendar(true);
  };

  const dismissImportantDatesInlineAdd = () => {
    setImportantDatesInlineAddOpen(false);
    setNewDateTitle("");
    setNewDateValue("");
  };

  const handleImportantDatesAddButtonClick = () => {
    if (importantDatesAddSuccess) return;
    if (!importantDatesInlineAddOpen) {
      setImportantDatesInlineAddOpen(true);
      return;
    }
    const cleanTitle = newDateTitle.trim();
    if (!cleanTitle || !newDateValue) {
      return;
    }
    const parsedDate = new Date(`${newDateValue}T00:00:00`);
    setPremiumAddedDates((prev) => [
      ...prev,
      {
        id: `custom-${Date.now()}`,
        title: cleanTitle,
        date: parsedDate,
        icon: Calendar,
        color: "#22c55e",
        gradient: "linear-gradient(135deg, #22c55e, #86efac)",
      },
    ]);
    setNewDateTitle("");
    setNewDateValue("");
    setImportantDatesInlineAddOpen(false);
    setImportantDatesAddSuccess(true);
    if (importantDatesAddedTimerRef.current != null) window.clearTimeout(importantDatesAddedTimerRef.current);
    importantDatesAddedTimerRef.current = window.setTimeout(() => {
      setImportantDatesAddSuccess(false);
      importantDatesAddedTimerRef.current = null;
    }, 2600);
  };

  const handleShareMemory = async (memory: SharedMemory) => {
    const shareText = `${memory.mood} ${memory.title}\n${formatShortDate(memory.dateTime)}\n${memory.description || ""}`.trim();
    try {
      if (typeof navigator !== "undefined" && navigator.share) {
        await navigator.share({ title: "Shared Memory", text: shareText });
        return;
      }
      if (typeof navigator !== "undefined" && navigator.clipboard) {
        await navigator.clipboard.writeText(shareText);
      }
    } catch (_err) {
      // Ignore share/copy errors in preview environments.
    }
  };

  const handleMemoryDragEnd = (_: unknown, info: PanInfo) => {
    if (sharedMemories.length <= 1) return;
    const threshold = 48;
    let newIndex = memoryActiveIndex;
    if (info.offset.x > threshold && memoryActiveIndex > 0) newIndex = memoryActiveIndex - 1;
    if (info.offset.x < -threshold && memoryActiveIndex < sharedMemories.length - 1) {
      newIndex = memoryActiveIndex + 1;
    }
    setMemoryActiveIndex(newIndex);
  };

  const handleAddMemory = () => {
    const cleanTitle = memoryTitle.trim();
    if (!cleanTitle) return;
    const parsedDateTime = memoryDateTime ? new Date(memoryDateTime) : new Date();
    // Keep blob: URLs alive — they are owned by the new memory entry after save.
    const photo = memoryPhotoUrl.trim();
    setSharedMemories((prev) => [
      {
        id: `memory-${Date.now()}`,
        title: cleanTitle,
        dateTime: parsedDateTime,
        description: memoryDescription.trim(),
        mood: memoryMood,
        photoUrl: photo,
        likes: 0,
        likedByMe: false,
        addedByUser: true,
      },
      ...prev,
    ]);
    setShowAddMemoryModal(false);
    setShowSharedMemoriesPage(true);
    setMemoriesDateFilter("all");
    setMemoryTitle("");
    setMemoryDateTime("");
    setMemoryDescription("");
    setMemoryMood("💛");
    setMemoryPhotoUrl("");
  };

  const handleMemoryModalPhotoFile = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file?.type.startsWith("image/")) return;
    setMemoryPhotoUrl((prev) => {
      if (prev.startsWith("blob:")) URL.revokeObjectURL(prev);
      return URL.createObjectURL(file);
    });
  };

  const closeAddMemoryModal = () => {
    setMemoryPhotoUrl((prev) => {
      if (prev.startsWith("blob:")) URL.revokeObjectURL(prev);
      return prev.startsWith("blob:") ? "" : prev;
    });
    setShowAddMemoryModal(false);
  };

  const openMemoryDetail = (memoryId: string) => {
    memoryDetailDragX.set(0);
    setViewingMemoryId(memoryId);
    const idx = sharedMemories.findIndex((m) => m.id === memoryId);
    if (idx >= 0) setMemoryActiveIndex(idx);
  };

  const closeMemoryDetail = () => {
    setViewingMemoryId(null);
    memoryDetailDragX.set(0);
  };

  const goToAdjacentMemory = useCallback(
    (direction: 1 | -1) => {
      if (!viewingMemoryId) return false;
      const idx = sharedMemories.findIndex((m) => m.id === viewingMemoryId);
      if (idx < 0) return false;
      const nextIdx = idx + direction;
      if (nextIdx < 0 || nextIdx >= sharedMemories.length) return false;
      setViewingMemoryId(sharedMemories[nextIdx].id);
      setMemoryActiveIndex(nextIdx);
      return true;
    },
    [sharedMemories, viewingMemoryId]
  );

  const handleMemoryDetailDragEnd = (_: unknown, info: PanInfo) => {
    const offsetThreshold = 48;
    const velocityThreshold = 350;
    const goNext = info.offset.x < -offsetThreshold || info.velocity.x < -velocityThreshold;
    const goPrev = info.offset.x > offsetThreshold || info.velocity.x > velocityThreshold;

    if (goNext || goPrev) {
      const direction: 1 | -1 = goNext ? 1 : -1;
      const idx = viewingMemoryId
        ? sharedMemories.findIndex((m) => m.id === viewingMemoryId)
        : -1;
      const nextIdx = idx + direction;
      const canMove = idx >= 0 && nextIdx >= 0 && nextIdx < sharedMemories.length;

      if (canMove) {
        const exitX = direction === 1 ? -320 : 320;
        const enterX = direction === 1 ? 320 : -320;
        animate(memoryDetailDragX, exitX, {
          duration: 0.16,
          ease: "easeIn",
          onComplete: () => {
            goToAdjacentMemory(direction);
            memoryDetailDragX.set(enterX);
            animate(memoryDetailDragX, 0, { type: "spring", stiffness: 380, damping: 32 });
          },
        });
        return;
      }
    }

    animate(memoryDetailDragX, 0, { type: "spring", stiffness: 420, damping: 34 });
  };

  const partnerWishes: WishlistItem[] =
    partnerWishlist.length > 0 ? normalizeWishlistSeed(partnerWishlist) : DEFAULT_PARTNER_WISHLIST;

  const clearWishlistDraftPhoto = () => {
    setWishlistDraftPhotoUrl((prev) => {
      if (prev.startsWith("blob:")) URL.revokeObjectURL(prev);
      return "";
    });
  };

  const handleWishlistDraftPhotoFile = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file?.type.startsWith("image/")) return;
    setWishlistDraftPhotoUrl((prev) => {
      if (prev.startsWith("blob:")) URL.revokeObjectURL(prev);
      return URL.createObjectURL(file);
    });
  };

  const addMyWish = () => {
    const clean = wishlistDraft.trim().slice(0, 80);
    if (!clean) return;
    if (myWishlist.some((w) => w.caption.toLowerCase() === clean.toLowerCase())) {
      setWishlistDraft("");
      return;
    }
    const photoUrl = wishlistDraftPhotoUrl;
    setMyWishlist((prev) => [
      ...prev,
      {
        id: `wish-${Date.now()}`,
        caption: clean,
        photoUrl,
      },
    ]);
    setWishlistDraft("");
    setWishlistDraftPhotoUrl("");
    setShowAddWishModal(false);
  };

  const openAddWishModal = () => {
    setWishlistDraft("");
    clearWishlistDraftPhoto();
    setShowAddWishModal(true);
  };

  const closeAddWishModal = () => {
    setWishlistDraft("");
    clearWishlistDraftPhoto();
    setShowAddWishModal(false);
  };

  const closeWishlistPage = () => {
    closeAddWishModal();
    setShowWishlistHistory(false);
    setDoneArmedWishIndex(null);
    setShowWishlist(false);
  };

  const removeMyWish = (index: number) => {
    setMyWishlist((prev) => {
      const item = prev[index];
      if (item?.photoUrl.startsWith("blob:")) URL.revokeObjectURL(item.photoUrl);
      return prev.filter((_, i) => i !== index);
    });
    setDoneArmedWishIndex(null);
  };

  const completeMyWish = (index: number) => {
    const item = myWishlist[index];
    if (!item) return;
    setWishlistHistory((prev) => [
      {
        id: `wish-done-${Date.now()}`,
        title: item.caption,
        completedAt: new Date(),
        direction: "for_me",
      },
      ...prev,
    ]);
    removeMyWish(index);
  };

  const handleMineWishDone = (index: number) => {
    if (doneArmedWishIndex === index) {
      completeMyWish(index);
      return;
    }
    setDoneArmedWishIndex(index);
  };

  const openWishlist = (tab: "mine" | "partner" = "mine") => {
    setShowImportantDatesList(false);
    setShowImportantDatesCalendar(false);
    setWishlistTab(tab);
    setWishlistDraft("");
    clearWishlistDraftPhoto();
    setDoneArmedWishIndex(null);
    setShowWishlistHistory(false);
    setShowWishlist(true);
  };

  const formatWishHistoryDate = (date: Date) =>
    date.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });

  const dailyTasks = [
    {
      id: "mood" as const,
      short: "mood",
      label: "Share your mood & wish",
      why: "Lets your partner see how you feel today and what would help — so they can show up for you.",
      anna: annaMoodShared,
      alex: alexMoodShared,
    },
    {
      id: "reaction" as const,
      short: "partner",
      label: "Check partner's mood",
      why: "A quick look at their day builds care: react, acknowledge, and stay close even when you're apart.",
      anna: annaReacted,
      alex: alexReacted,
    },
    {
      id: "activity" as const,
      short: "prompt",
      label: "Complete a couples prompt",
      why: "A shared question or task turns the day into a moment together — small rituals that deepen connection.",
      anna: annaActivityDone,
      alex: alexActivityDone,
    },
  ];
  const dailyTip = dailyTasks.find((t) => t.id === dailyTipId) ?? null;
  const dailyDoneCount = dailyTasks.filter((t) => t.anna && t.alex).length;
  const dailyDoneFill =
    "linear-gradient(135deg, rgba(110,231,183,0.28), rgba(52,211,153,0.18))";
  const dailyDoneGlow = "rgba(52,211,153,0.12)";

  const userAddedMemories = useMemo(
    () =>
      [...sharedMemories]
        .filter((m) => m.addedByUser)
        .sort((a, b) => b.dateTime.getTime() - a.dateTime.getTime()),
    [sharedMemories]
  );

  const viewingMemory = useMemo(
    () => (viewingMemoryId ? sharedMemories.find((m) => m.id === viewingMemoryId) ?? null : null),
    [sharedMemories, viewingMemoryId]
  );

  const memoryMonthKey = (d: Date) =>
    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;

  const memoryMonthLabel = (key: string) => {
    const [y, m] = key.split("-").map(Number);
    return new Date(y, m - 1, 1).toLocaleDateString("en-US", { month: "short", year: "numeric" });
  };

  const memoriesDateFilterOptions = useMemo(() => {
    const keys = Array.from(new Set(userAddedMemories.map((m) => memoryMonthKey(m.dateTime))));
    keys.sort((a, b) => b.localeCompare(a));
    return keys;
  }, [userAddedMemories]);

  const filteredUserMemories = useMemo(() => {
    if (memoriesDateFilter === "all") return userAddedMemories;
    return userAddedMemories.filter((m) => memoryMonthKey(m.dateTime) === memoriesDateFilter);
  }, [userAddedMemories, memoriesDateFilter]);

  const calendarMonthYear = calendarViewMonth.getFullYear();
  const calendarMonthIndex = calendarViewMonth.getMonth();
  const calendarCells = buildCalendarDayCells(calendarMonthYear, calendarMonthIndex);
  /** User-added important dates only — green tint on the grid. */
  const calendarUserAddedDays = new Set(
    premiumAddedDates
      .filter((d) => d.date.getFullYear() === calendarMonthYear && d.date.getMonth() === calendarMonthIndex)
      .map((d) => d.date.getDate())
  );
  /** Shared memory gallery — day of each memory’s date in the visible month. */
  const calendarGalleryDays = new Set(
    sharedMemories
      .filter((m) => {
        const dt = m.dateTime;
        return dt.getFullYear() === calendarMonthYear && dt.getMonth() === calendarMonthIndex;
      })
      .map((m) => m.dateTime.getDate())
  );
  /** Important dates + gallery memories in this month (not top-10 limited). */
  const calendarMarkedDays = new Set<number>([
    ...allImportantDates
      .filter((d) => d.date.getFullYear() === calendarMonthYear && d.date.getMonth() === calendarMonthIndex)
      .map((d) => d.date.getDate()),
    ...calendarGalleryDays,
  ]);

  return (
    <div className="relative isolate min-h-screen bg-gradient-to-br from-gray-50 via-white to-gray-100">
      {/* Same ambient shell as AuthScreen */}
      <motion.div
        className="pointer-events-none fixed -top-24 -left-24 z-0 h-[28rem] w-[28rem] rounded-full blur-[130px]"
        style={{
          background: "linear-gradient(135deg, rgba(251,207,232,0.55), rgba(196,181,253,0.4))",
        }}
        animate={{ opacity: [0.45, 0.7, 0.45], scale: [0.9, 1.05, 0.9] }}
        transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
      />
      <motion.div
        className="pointer-events-none fixed -bottom-24 -right-24 z-0 h-96 w-96 rounded-full blur-[110px]"
        style={{
          background: "linear-gradient(135deg, rgba(167,243,208,0.35), rgba(147,197,253,0.45))",
        }}
        animate={{ opacity: [0.3, 0.55, 0.3], scale: [0.95, 1.08, 0.95] }}
        transition={{ duration: 7, repeat: Infinity, ease: "easeInOut", delay: 1.2 }}
      />

      <motion.button
        type="button"
        className="fixed z-[35] flex h-10 w-10 items-center justify-center rounded-full backdrop-blur-md"
        style={{
          top: "max(20px, calc(env(safe-area-inset-top) + 12px))",
          left: "max(14px, env(safe-area-inset-left))",
          background: NOTIFICATIONS_BTN_BG,
          border: NOTIFICATIONS_BTN_BORDER,
          boxShadow: NOTIFICATIONS_BTN_SHADOW,
        }}
        whileTap={{ scale: 0.88 }}
        whileHover={{ scale: 1.05 }}
        aria-label="Notifications"
        onClick={() => onNotificationsPress?.()}
      >
        <Bell className="h-[18px] w-[18px]" strokeWidth={2.25} style={{ color: NOTIFICATIONS_BTN_ICON }} fill="none" />
      </motion.button>

      <div className="relative z-10 mx-auto flex min-h-screen max-w-md flex-col pb-24">
        <div className="flex-1 overflow-y-auto">
          <div className="px-5">
            {/* Present — you two, then connection only (no lists in first screen). */}
            <section
              className="flex flex-col pb-0"
              aria-label="You and your connection"
              style={{ paddingTop: "max(3.5rem, calc(env(safe-area-inset-top) + 2.75rem))" }}
            >
              <motion.div
                key={coupleStatus.tier}
                className="flex min-h-[30vh] w-full flex-col justify-center px-2 text-center"
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ type: "spring", stiffness: 280, damping: 24, mass: 0.9 }}
              >
                <motion.h1
                  className="mb-0.5 text-[#26282B]/78"
                  style={{ fontWeight: 200, letterSpacing: "0.04em", fontSize: "1.35rem" }}
                  initial={{ opacity: 0, y: 6 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.06, duration: 0.4 }}
                >
                  {partner1Name} & {partner2Name}
                </motion.h1>
                <motion.p
                  className="mb-2 text-[#26282B]/38"
                  style={{ fontWeight: 300, letterSpacing: "0.02em", fontSize: "0.8125rem" }}
                  initial={{ opacity: 0, y: 4 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.1, duration: 0.35 }}
                >
                  {timeTogether}
                </motion.p>
                <motion.div
                  className="mt-4 mb-1 flex justify-center pl-2"
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.13, duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
                >
                  <div className="flex items-center justify-center -space-x-5">
                    <PartnerAvatarBubble
                      name={partner1Name}
                      photoUrl={partner1AvatarUrl}
                      gradient={US_AVATAR_GRADIENT}
                    />
                    <PartnerAvatarBubble
                      name={partner2Name}
                      photoUrl={partner2AvatarUrl}
                      gradient={US_AVATAR_GRADIENT}
                    />
                  </div>
                </motion.div>

                {/* Daily — thin “today” layer between couple hero and long-term bar */}
                <div
                  ref={dailyTipRef}
                  className="relative mt-3.5 flex w-full flex-col items-center"
                  role="list"
                  aria-label={`Daily progress ${dailyDoneCount} of ${dailyTasks.length} complete`}
                >
                  <div className="flex items-center justify-center gap-1.5">
                    {dailyTasks.map((task, i) => {
                      const bothDone = task.anna && task.alex;
                      const tipOpen = dailyTipId === task.id;
                      return (
                        <div key={task.id} className="flex items-center gap-1.5">
                          {i > 0 ? (
                            <span
                              className="select-none text-[10px] text-[#26282B]/22"
                              style={{ fontWeight: 300 }}
                              aria-hidden
                            >
                              ·
                            </span>
                          ) : null}
                          <motion.button
                            type="button"
                            role="listitem"
                            className="flex cursor-pointer touch-manipulation items-center gap-1 rounded-full py-0.5 pl-0.5 pr-1.5"
                            style={{
                              background: tipOpen ? "rgba(255,255,255,0.55)" : "transparent",
                              border: tipOpen
                                ? `1px solid rgba(${US_INK_RGB},0.14)`
                                : "1px solid transparent",
                            }}
                            initial={{ opacity: 0, y: 4 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: 0.2 + i * 0.05, duration: 0.28, ease: "easeOut" }}
                            whileTap={{ scale: 0.94 }}
                            aria-expanded={tipOpen}
                            aria-controls="daily-progress-tip"
                            aria-label={`${task.label}${bothDone ? ", done" : ", not done"}. Show explanation.`}
                            onClick={() => setDailyTipId((prev) => (prev === task.id ? null : task.id))}
                          >
                            <span
                              className="flex h-4 w-4 shrink-0 items-center justify-center rounded-full"
                              style={{
                                background: bothDone ? dailyDoneFill : "rgba(255,255,255,0.55)",
                                border: bothDone
                                  ? "1px solid rgba(52,211,153,0.28)"
                                  : `1px solid rgba(${US_INK_RGB},0.12)`,
                                boxShadow: bothDone
                                  ? `inset 0 1px 0 rgba(255,255,255,0.65), 0 1px 6px ${dailyDoneGlow}`
                                  : "inset 0 1px 0 rgba(255,255,255,0.7)",
                              }}
                            >
                              {bothDone ? (
                                <Check
                                  className="h-2 w-2"
                                  strokeWidth={2.75}
                                  style={{ color: "rgba(52,211,153,0.85)" }}
                                />
                              ) : null}
                            </span>
                            <span
                              className="text-[10px] lowercase tracking-wide text-[#26282B]/48"
                              style={{ fontWeight: tipOpen ? 500 : 300 }}
                            >
                              {task.short}
                            </span>
                          </motion.button>
                        </div>
                      );
                    })}
                  </div>

                  <AnimatePresence>
                    {dailyTip ? (
                      <motion.div
                        key={dailyTip.id}
                        id="daily-progress-tip"
                        role="tooltip"
                        className="absolute left-1/2 top-[calc(100%+0.45rem)] z-30 w-[min(16.5rem,calc(100vw-2.5rem))] -translate-x-1/2 rounded-2xl border px-3.5 py-3 text-left backdrop-blur-xl"
                        style={{
                          background: GLASS_MATTE.surface,
                          borderColor: GLASS_MATTE.border,
                          boxShadow: GLASS_MATTE.shadow,
                        }}
                        initial={{ opacity: 0, y: -4, scale: 0.96 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: -3, scale: 0.97 }}
                        transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
                      >
                        <p
                          className="text-[10px] uppercase tracking-[0.14em]"
                          style={{ fontWeight: 400, color: `rgba(${US_INK_RGB},0.4)` }}
                        >
                          Daily · {dailyTip.anna && dailyTip.alex ? "Done" : "To do"}
                        </p>
                        <p
                          className="mt-1 text-[13px] leading-snug"
                          style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.82)` }}
                        >
                          {dailyTip.label}
                        </p>
                        <p
                          className="mt-1.5 text-[12px] leading-relaxed"
                          style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.58)` }}
                        >
                          {dailyTip.why}
                        </p>
                      </motion.div>
                    ) : null}
                  </AnimatePresence>
                </div>

                <motion.div
                  className="relative mt-3.5 w-[calc(100%+1rem)] -mx-2"
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.19, duration: 0.4 }}
                >
                  <div className="mb-2 flex w-full items-center justify-between gap-2">
                    <span
                      className="min-w-0 flex-1 truncate text-left text-[13px] text-[#26282B]/68"
                      style={{ fontWeight: 500, letterSpacing: "0.02em" }}
                    >
                      {longTermLvlRow.name}
                    </span>
                    <span
                      className="shrink-0 text-right text-[11px] tracking-wide"
                      style={{ fontWeight: 600, color: US_STREAK_LABEL_COLOR, letterSpacing: "0.02em" }}
                      role="status"
                      aria-label={`Streak ${longTermStreak} ${longTermStreak === 1 ? "day" : "days"}`}
                    >
                      Streak · {longTermStreak} {longTermStreak === 1 ? "day" : "days"}
                    </span>
                  </div>
                  <div
                    className="relative h-2 w-full overflow-hidden rounded-full border bg-[#26282B]/[0.06]"
                    style={{ borderColor: "rgba(26,26,46,0.12)" }}
                    role="progressbar"
                    aria-valuemin={0}
                    aria-valuemax={100}
                    aria-valuenow={Math.round(longTermProgressFrac * 100)}
                    aria-label={`Level progress ${longTermPoints} of ${longTermGoalPoints || "max"} points`}
                  >
                    <motion.div
                      className="relative h-full overflow-hidden rounded-full"
                      style={{
                        background: US_LEVEL_PROGRESS_FILL,
                        backgroundSize: "220% 100%",
                        boxShadow: `inset 0 1px 0 rgba(255,255,255,0.2), 0 0 12px ${US_LEVEL_PROGRESS_GLOW}`,
                      }}
                      initial={{ width: "0%" }}
                      animate={{
                        width: `${longTermProgressFrac * 100}%`,
                        backgroundPosition: ["0% 50%", "100% 50%", "0% 50%"],
                      }}
                      transition={{
                        width: { delay: 0.28, duration: 0.85, ease: [0.22, 1, 0.36, 1] },
                        backgroundPosition: { duration: 3.4, repeat: Infinity, ease: "easeInOut" },
                      }}
                    >
                      <motion.div
                        className="pointer-events-none absolute inset-y-0 w-[55%]"
                        style={{
                          background:
                            "linear-gradient(90deg, transparent 0%, rgba(255,255,255,0.08) 35%, rgba(255,255,255,0.32) 50%, rgba(255,255,255,0.08) 65%, transparent 100%)",
                        }}
                        animate={{ x: ["-120%", "220%"] }}
                        transition={{ duration: 2.6, repeat: Infinity, ease: "easeInOut", repeatDelay: 0.8 }}
                        aria-hidden
                      />
                    </motion.div>
                  </div>
                  <div className="mt-1 flex w-full items-baseline justify-between tabular-nums">
                    <span className="text-[12px] text-[#26282B]/52" style={{ fontWeight: 600 }}>
                      {longTermPoints}
                    </span>
                    <span className="text-[12px] text-[#26282B]/38" style={{ fontWeight: 300 }}>
                      {longTermGoalPoints > 0 ? longTermGoalPoints : "—"}
                    </span>
                  </div>
                </motion.div>
              </motion.div>
            </section>

            <div className="mt-4 flex flex-col gap-6 pb-2">
              <div className="grid grid-cols-2 gap-2.5 items-stretch">
                <motion.div
                  className="relative min-h-[118px] cursor-pointer overflow-hidden rounded-2xl border text-left backdrop-blur-2xl"
                  style={{
                    background: IMPORTANT_DATES_MODAL_GLASS.surface,
                    borderColor: IMPORTANT_DATES_MODAL_GLASS.border,
                    boxShadow: IMPORTANT_DATES_MODAL_GLASS.shadow,
                  }}
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.45, delay: 0.2 }}
                  tabIndex={0}
                  aria-label="Open important dates list"
                  whileTap={{ scale: 0.98 }}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") {
                      e.preventDefault();
                      openImportantDatesList();
                    }
                  }}
                  onClick={openImportantDatesList}
                >
                  {nearestImportantDate ? (
                    <span
                      className="pointer-events-none absolute right-3 top-3 z-[2] inline-flex items-center justify-center whitespace-nowrap rounded-full px-2 py-0.5 text-center text-[9px] leading-tight tracking-wide backdrop-blur-sm"
                      style={{
                        background: IMPORTANT_DATES_MODAL_COUNTDOWN_BADGE.background,
                        border: IMPORTANT_DATES_MODAL_COUNTDOWN_BADGE.border,
                        boxShadow: IMPORTANT_DATES_MODAL_COUNTDOWN_BADGE.shadow,
                        fontWeight: 600,
                        color: IMPORTANT_DATES_MODAL_COUNTDOWN_BADGE.color,
                      }}
                    >
                      {countdownLabel(getDaysUntil(nearestImportantDate.date))}
                    </span>
                  ) : null}
                  <div className="pointer-events-none relative z-[2] flex h-full min-h-[118px] flex-col p-3 pb-11 pr-[5.5rem]">
                    <p
                      className="max-w-[58%] text-[9px] uppercase tracking-widest"
                      style={{ fontWeight: 300, color: IMPORTANT_DATES_TEXT_FAINT }}
                    >
                      Important Dates
                    </p>
                    {nearestImportantDate ? (
                      <>
                        <p
                          className="mt-2 break-words text-[14px] leading-snug"
                          style={{ fontWeight: 500, color: IMPORTANT_DATES_TEXT }}
                        >
                          {nearestImportantDate.title}
                        </p>
                        <p className="mt-1 text-[12px]" style={{ fontWeight: 300, color: IMPORTANT_DATES_TEXT_SOFT }}>
                          {formatShortDate(nearestImportantDate.date)}
                        </p>
                      </>
                    ) : (
                      <p className="mt-3 text-[12px] leading-snug" style={{ fontWeight: 300, color: IMPORTANT_DATES_TEXT_SOFT }}>
                        Tap to see all important dates
                      </p>
                    )}
                  </div>
                  <div className="absolute bottom-2 right-2 z-[10] flex items-center gap-1.5">
                    <motion.button
                      type="button"
                      className="flex h-9 w-9 shrink-0 cursor-pointer items-center justify-center rounded-full backdrop-blur-md"
                      style={{
                        background: US_MATTE_CONTROL.bg,
                        border: US_MATTE_CONTROL.borderStrong,
                        boxShadow: US_MATTE_CONTROL.shadow,
                      }}
                      aria-label="Wishlist"
                      whileTap={{ scale: 0.88 }}
                      whileHover={{ scale: 1.05 }}
                      onClick={(e) => {
                        e.stopPropagation();
                        openWishlist("mine");
                      }}
                    >
                      <Gift
                        className="pointer-events-none h-4 w-4"
                        strokeWidth={2}
                        style={{ color: US_MATTE_CONTROL.icon }}
                      />
                    </motion.button>
                    <motion.button
                      type="button"
                      className="flex h-9 w-9 shrink-0 cursor-pointer items-center justify-center rounded-full backdrop-blur-md"
                      style={{
                        background: US_MATTE_CONTROL.bg,
                        border: US_MATTE_CONTROL.borderStrong,
                        boxShadow: US_MATTE_CONTROL.shadow,
                      }}
                      aria-label="Open calendar to add a date"
                      whileTap={{ scale: 0.88 }}
                      whileHover={{ scale: 1.05 }}
                      onClick={(e) => {
                        e.stopPropagation();
                        openImportantDatesCalendar();
                      }}
                    >
                      <Plus
                        className="pointer-events-none h-4 w-4"
                        strokeWidth={2}
                        style={{ color: US_MATTE_CONTROL.icon }}
                      />
                    </motion.button>
                  </div>
                </motion.div>

                <motion.div
                  className={`${GLASS_SHELL_CLASS} relative h-[196px] shrink-0 cursor-pointer overflow-hidden text-left outline-none`}
                  style={{
                    background: loveNotesTileSurface,
                    borderColor: loveNotesTileBorder,
                    boxShadow: loveNotesTileShadow,
                  }}
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.45, delay: 0.26 }}
                  whileTap={{ scale: 0.98 }}
                  tabIndex={0}
                  aria-label="Open love notes"
                  onClick={() => setShowLoveNotesPage(true)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") {
                      e.preventDefault();
                      setShowLoveNotesPage(true);
                    }
                  }}
                >
                  <div className="pointer-events-none absolute inset-0" style={{ background: loveNotesTileWash }} />
                  {loveNotesTileKind === "outgoing_only" ? (
                    <span
                      className="pointer-events-none absolute right-3 top-3 z-[3] inline-flex items-center justify-center whitespace-nowrap rounded-full px-2.5 py-1 text-center text-[11px] leading-none tabular-nums backdrop-blur-sm"
                      style={{
                        fontWeight: 600,
                        color: LOVE_NOTE_PANEL_CHROME,
                        background: "rgba(255,255,255,0.36)",
                        border: `1px solid rgba(${LOVE_NOTE_CREAM_RGB},0.42)`,
                        boxShadow: "inset 0 1px 0 rgba(255,255,255,0.45), 0 2px 8px rgba(15,23,42,0.08)",
                      }}
                    >
                      {outgoingWaitingLoveNotes.length}/{MAX_WAITING_LOVE_NOTES} out
                    </span>
                  ) : null}
                  <div className="pointer-events-none relative z-[2] flex h-full flex-col overflow-hidden p-3 pb-11">
                    <div
                      className={`flex min-w-0 items-start justify-between gap-2 ${
                        loveNotesTileKind === "outgoing_only" ? "pr-[4.25rem]" : "pr-1"
                      }`}
                    >
                      <div className="flex min-w-0 items-center gap-1.5">
                        <p
                          className="whitespace-nowrap text-[9px] uppercase tracking-widest"
                          style={{ fontWeight: 300, color: `rgba(${LOVE_NOTE_CREAM_RGB},0.72)` }}
                        >
                          Love Notes
                        </p>
                      </div>
                      {loveNotesTileKind === "incoming_waiting" ? (
                        <span
                          className="shrink-0 rounded-full px-2 py-0.5 text-[13px] tabular-nums leading-none"
                          style={{
                            fontWeight: 600,
                            color: LOVE_NOTE_PANEL_CHROME,
                            background: "rgba(255,255,255,0.28)",
                            boxShadow: "inset 0 1px 0 rgba(255,255,255,0.35)",
                          }}
                        >
                          {incomingWaitingLoveNotes.length}
                        </span>
                      ) : null}
                    </div>

                    {loveNotesTileKind === "empty" ? (
                      <p
                        className="mt-2 pr-10 text-[14px] leading-snug hyphens-none"
                        style={{
                          fontWeight: 500,
                          color: "#ffffff",
                          wordBreak: "normal",
                          overflowWrap: "normal",
                        }}
                      >
                        Say something sweet —
                        <br />
                        it only takes a moment
                      </p>
                    ) : null}
                    {loveNotesTileKind === "incoming_waiting" ? (
                      <>
                        <p
                          className="mt-2 pr-10 text-[14px] leading-snug hyphens-none"
                          style={{
                            fontWeight: 500,
                            color: LOVE_NOTE_PANEL_CHROME,
                            wordBreak: "normal",
                            overflowWrap: "normal",
                          }}
                        >
                          {littleSurprisesLine(incomingWaitingLoveNotes.length)}
                        </p>
                        <p className="mt-1 pr-10 text-[12px] leading-snug" style={{ fontWeight: 300, color: `rgba(${LOVE_NOTE_CREAM_RGB},0.82)` }}>
                          Waiting for their moment
                        </p>
                      </>
                    ) : null}
                    {loveNotesTileKind === "unlocked_moment" ? (
                      <>
                        <p
                          className="mt-2 pr-10 text-[14px] leading-snug hyphens-none"
                          style={{
                            fontWeight: 700,
                            color: LOVE_NOTE_PANEL_CHROME,
                            wordBreak: "normal",
                            overflowWrap: "normal",
                          }}
                        >
                          {unlockHeroCount > 1 ? `${unlockHeroCount} new notes for you` : "New note for you"}
                        </p>
                        <p className="mt-1 pr-10 text-[12px] leading-snug" style={{ fontWeight: 300, color: `rgba(${LOVE_NOTE_CREAM_RGB},0.82)` }}>
                          Tap to open
                        </p>
                      </>
                    ) : null}
                    {loveNotesTileKind === "outgoing_only" ? (
                      <>
                        <p
                          className="mt-2 pr-10 text-[14px] leading-snug hyphens-none"
                          style={{
                            fontWeight: 500,
                            color: LOVE_NOTE_PANEL_CHROME,
                            wordBreak: "normal",
                            overflowWrap: "normal",
                          }}
                        >
                          Your words are on their way
                        </p>
                        <p className="mt-1 pr-10 text-[12px] leading-snug" style={{ fontWeight: 300, color: `rgba(${LOVE_NOTE_CREAM_RGB},0.82)` }}>
                          Waiting for them to open
                        </p>
                      </>
                    ) : null}
                  </div>
                  <div className="absolute bottom-2 right-2 z-[10]">
                    <motion.button
                      type="button"
                      aria-label={loveNotesTileKind === "empty" ? "Write a love note" : "Write another love note"}
                      className={`flex h-9 w-9 shrink-0 cursor-pointer items-center justify-center rounded-full backdrop-blur-md ${
                        loveNotesTileKind === "empty" ? "border border-dashed" : "border-[1.5px] border-solid"
                      }`}
                      style={
                        loveNotesTileKind === "empty"
                          ? {
                              borderColor: canAddLoveNote ? `rgba(${LOVE_NOTE_CREAM_RGB},0.55)` : "rgba(255,248,240,0.28)",
                              background: canAddLoveNote ? "rgba(255,255,255,0.14)" : LOVE_NOTE_SEND_BTN_DISABLED.bg,
                              boxShadow: "inset 0 1px 0 rgba(255,255,255,0.2)",
                            }
                          : {
                              background: canAddLoveNote ? LOVE_NOTE_PANEL.mailBtnEnabledBg : LOVE_NOTE_SEND_BTN_DISABLED.bg,
                              borderColor: canAddLoveNote ? LOVE_NOTE_PANEL_CHROME : LOVE_NOTE_SEND_BTN_DISABLED.border,
                              boxShadow: canAddLoveNote ? "none" : LOVE_NOTE_SEND_BTN_DISABLED.shadow,
                            }
                      }
                      whileTap={{ scale: canAddLoveNote ? 0.88 : 1 }}
                      whileHover={canAddLoveNote ? { scale: 1.05 } : undefined}
                      onClick={(e) => {
                        e.stopPropagation();
                        if (canAddLoveNote) openLoveNoteComposer();
                      }}
                    >
                      <Pencil
                        className="pointer-events-none h-4 w-4"
                        strokeWidth={2}
                        style={{
                          color: canAddLoveNote ? LOVE_NOTE_PANEL_CHROME : LOVE_NOTE_SEND_BTN_DISABLED.icon,
                        }}
                        aria-hidden
                      />
                    </motion.button>
                  </div>
                </motion.div>
              </div>

              {/* ====== SHARED MEMORIES ====== */}
              <motion.div
                className={`relative w-full ${GLASS_SHELL_CLASS}`}
                style={{
                  background: SHARED_MEMORIES_PANEL_SURFACE,
                  borderColor: GLASS_MATTE.border,
                  boxShadow: GLASS_MATTE.shadow,
                }}
                initial={{ opacity: 0, y: 14 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.52 }}
              >
                <motion.button
                  type="button"
                  aria-label="Add a memory"
                  className="absolute top-2 right-2 z-20 flex h-7 w-7 items-center justify-center rounded-full backdrop-blur-md"
                  style={{
                    background: US_MATTE_CONTROL.bg,
                    border: US_MATTE_CONTROL.borderStrong,
                    boxShadow: US_MATTE_CONTROL.shadow,
                  }}
                  whileTap={{ scale: 0.85 }}
                  whileHover={{ scale: 1.06 }}
                  onClick={() => setShowAddMemoryModal(true)}
                >
                  <Plus className="h-3.5 w-3.5" strokeWidth={2.5} style={{ color: US_MATTE_CONTROL.icon }} />
                </motion.button>
                <div className="pointer-events-none absolute inset-x-0 top-0 z-[1] h-px bg-white/60" />
                <div
                  className="pointer-events-none absolute inset-0"
                  style={{
                    background:
                      "radial-gradient(ellipse 95% 75% at 12% 18%, rgba(255,255,255,0.35), transparent 58%)",
                  }}
                />

                <div className="relative z-10 px-3 pb-3.5 pt-2.5">
                  <button
                    type="button"
                    className="flex w-full items-center gap-2 pr-8 text-left"
                    aria-label="Open Shared Memories gallery"
                    onClick={() => {
                      setMemoriesDateFilter("all");
                      setShowSharedMemoriesPage(true);
                    }}
                  >
                    <ChevronRight
                      className="h-4 w-4 shrink-0"
                      strokeWidth={2}
                      style={{ color: US_MATTE_CONTROL.icon }}
                      aria-hidden
                    />
                    <div className="min-w-0 flex-1">
                      <p
                        className="truncate text-xs uppercase tracking-widest"
                        style={{ fontWeight: 300, color: US_MATTE_CONTROL.icon }}
                      >
                        Shared Memories
                      </p>
                      <p className="mt-0.5 text-[11px] leading-snug" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.42)` }}>
                        Cherish the moments that matter to both of you.
                      </p>
                    </div>
                  </button>

                  {sharedMemories.length === 0 ? (
                    <p className="mt-4 px-1 pb-2 text-center text-[12px]" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.4)` }}>
                      Add your first shared moment
                    </p>
                  ) : (
                    <>
                      <div
                        className="mt-3 overflow-hidden"
                        style={{ padding: "10px 6px 8px" }}
                      >
                        <motion.div
                          className="flex cursor-grab active:cursor-grabbing"
                          style={{ x: memoryDragX, gap: MEMORY_CARD_GAP }}
                          drag="x"
                          dragConstraints={{
                            left: -Math.max(0, sharedMemories.length - 1) * MEMORY_SLIDE_WIDTH,
                            right: 0,
                          }}
                          dragElastic={0.08}
                          onDragStart={() => {
                            memoryCarouselDraggedRef.current = false;
                          }}
                          onDrag={(_, info) => {
                            if (Math.abs(info.offset.x) > 8) memoryCarouselDraggedRef.current = true;
                          }}
                          onDragEnd={handleMemoryDragEnd}
                        >
                          {sharedMemories.map((memory, cardIndex) => {
                            const isActive = cardIndex === memoryActiveIndex;
                            return (
                              <motion.div
                                key={memory.id}
                                role="button"
                                tabIndex={0}
                                aria-label={`Open memory ${memory.title}`}
                                className="relative flex shrink-0 cursor-pointer flex-col overflow-hidden rounded-[1.15rem]"
                                style={{
                                  width: MEMORY_CARD_WIDTH,
                                  background: MEMORY_CARD_GLASS.surface,
                                  border: isActive
                                    ? MEMORY_CARD_GLASS.borderActive
                                    : MEMORY_CARD_GLASS.border,
                                  boxShadow: isActive
                                    ? MEMORY_CARD_GLASS.shadowActive
                                    : MEMORY_CARD_GLASS.shadowIdle,
                                  boxSizing: "border-box",
                                }}
                                onClick={() => {
                                  if (memoryCarouselDraggedRef.current) return;
                                  openMemoryDetail(memory.id);
                                }}
                                onKeyDown={(e) => {
                                  if (e.key === "Enter" || e.key === " ") {
                                    e.preventDefault();
                                    openMemoryDetail(memory.id);
                                  }
                                }}
                              >
                                <div
                                  className="relative w-full shrink-0 overflow-hidden"
                                  style={{ height: MEMORY_CARD_PHOTO_HEIGHT }}
                                >
                                  {memory.photoUrl ? (
                                    <img
                                      src={memory.photoUrl}
                                      alt=""
                                      className="h-full w-full object-cover"
                                      draggable={false}
                                    />
                                  ) : (
                                    <div
                                      className="flex h-full w-full items-center justify-center"
                                      style={{
                                        background: `linear-gradient(155deg, rgba(255,255,255,0.55) 0%, ${statusTheme.color}22 55%, rgba(248,250,252,0.7) 100%)`,
                                      }}
                                    >
                                      <span className="text-[1.75rem] leading-none opacity-90" aria-hidden>
                                        {memory.mood}
                                      </span>
                                    </div>
                                  )}
                                  <motion.button
                                    type="button"
                                    aria-label={`Share ${memory.title}`}
                                    className="absolute right-2 top-2 z-10 flex h-7 w-7 items-center justify-center rounded-full backdrop-blur-md"
                                    style={{
                                      background: "rgba(255,255,255,0.72)",
                                      border: "1px solid rgba(255,255,255,0.85)",
                                      boxShadow: "0 2px 8px rgba(15,23,42,0.1)",
                                    }}
                                    whileTap={{ scale: 0.9 }}
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      handleShareMemory(memory);
                                    }}
                                  >
                                    <Share2
                                      className="h-3.5 w-3.5"
                                      strokeWidth={2}
                                      style={{ color: US_MATTE_CONTROL.icon }}
                                    />
                                  </motion.button>
                                </div>

                                <div className="flex min-h-[4.25rem] flex-col justify-center px-3 py-2.5">
                                  <div className="flex items-start gap-1.5">
                                    {memory.photoUrl ? (
                                      <span className="mt-0.5 shrink-0 text-[13px] leading-none" aria-hidden>
                                        {memory.mood}
                                      </span>
                                    ) : null}
                                    <p
                                      className="line-clamp-2 min-w-0 flex-1 text-[12.5px] leading-snug"
                                      style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.88)` }}
                                    >
                                      {memory.title}
                                    </p>
                                  </div>
                                  <p
                                    className="mt-1 text-[10px] leading-none"
                                    style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.4)` }}
                                  >
                                    {formatShortDate(memory.dateTime)}
                                  </p>
                                </div>
                              </motion.div>
                            );
                          })}
                        </motion.div>
                      </div>
                      {sharedMemories.length > 1 ? (
                        <div className="mt-3 flex items-center justify-center gap-1.5">
                          {sharedMemories.map((m, i) => {
                            const active = i === memoryActiveIndex;
                            return (
                              <button
                                key={m.id}
                                type="button"
                                className="rounded-full transition-all"
                                style={{
                                  width: active ? 16 : 6,
                                  height: 6,
                                  background: active ? US_CONTINUE_NAVY : "transparent",
                                  border: active
                                    ? `1.5px solid ${US_CONTINUE_NAVY}`
                                    : `1.5px solid ${US_CONTINUE_NAVY_MID}`,
                                  opacity: active ? 1 : 0.55,
                                  boxSizing: "border-box",
                                }}
                                aria-label={`Memory ${i + 1}`}
                                aria-current={active ? "true" : undefined}
                                onClick={() => setMemoryActiveIndex(i)}
                              />
                            );
                          })}
                        </div>
                      ) : null}
                    </>
                  )}
                </div>
              </motion.div>

              <div className="h-3" />
            </div>
          </div>
        </div>
      </div>

      {/* Add Memory Modal */}
      <AnimatePresence>
        {showAddMemoryModal && (
          <motion.div className="fixed inset-0 z-[63] flex items-center justify-center px-6" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.2 }}>
            <motion.div
              className="absolute inset-0"
              style={{ background: "rgba(38,40,43,0.25)", backdropFilter: "blur(8px)", WebkitBackdropFilter: "blur(8px)" }}
              onClick={closeAddMemoryModal}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            />
            <motion.div
              className="relative w-full max-w-sm overflow-hidden rounded-[1.6rem] border backdrop-blur-xl shadow-2xl"
              style={{
                background: GLASS_MATTE.surface,
                borderColor: GLASS_MATTE.border,
                boxShadow: GLASS_MATTE.shadow,
              }}
              initial={{ opacity: 0, scale: 0.92, y: 18 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.92, y: 18 }}
              transition={{ type: "spring", stiffness: 290, damping: 26 }}
            >
              <div className="pointer-events-none absolute inset-x-0 top-0 z-[1] h-px bg-white/65" />
              <div
                className="pointer-events-none absolute inset-0"
                style={{
                  background: `radial-gradient(ellipse 100% 60% at 50% 0%, ${statusTheme.color}10, transparent 55%)`,
                }}
              />
              <motion.button
                className="absolute top-4 right-4 z-20 rounded-full p-1.5 backdrop-blur-md"
                style={{
                  background: US_MATTE_CONTROL.bg,
                  border: US_MATTE_CONTROL.border,
                  boxShadow: US_MATTE_CONTROL.shadow,
                }}
                onClick={closeAddMemoryModal}
                whileTap={{ scale: 0.85 }}
              >
                <X className="h-4 w-4" strokeWidth={2} style={{ color: US_MATTE_CONTROL.icon }} />
              </motion.button>
              <div className="relative z-10 px-5 pt-5 pb-5">
                <p className="text-center text-[#26282B]/90 mb-1" style={{ fontWeight: 500 }}>Share a new memory</p>
                <p className="text-center text-[11px] text-[#26282B]/45 mb-4" style={{ fontWeight: 300 }}>
                  Capture your own moment, even if it is not a task.
                </p>
                <div className="space-y-2.5">
                  <input
                    value={memoryTitle}
                    onChange={(e) => setMemoryTitle(e.target.value)}
                    placeholder="Title"
                    className="w-full rounded-xl px-3 py-2.5 text-[13px] outline-none"
                    style={{ border: "1px solid rgba(38,40,43,0.08)", background: "rgba(255,255,255,0.85)" }}
                  />
                  <input
                    type="datetime-local"
                    value={memoryDateTime}
                    onChange={(e) => setMemoryDateTime(e.target.value)}
                    className="w-full rounded-xl px-3 py-2.5 text-[13px] outline-none"
                    style={{ border: "1px solid rgba(38,40,43,0.08)", background: "rgba(255,255,255,0.85)" }}
                  />
                  <textarea
                    value={memoryDescription}
                    onChange={(e) => setMemoryDescription(e.target.value)}
                    placeholder="Description (optional)"
                    className="w-full rounded-xl px-3 py-2.5 text-[13px] outline-none resize-none"
                    rows={3}
                    style={{ border: "1px solid rgba(38,40,43,0.08)", background: "rgba(255,255,255,0.85)" }}
                  />
                  <input
                    value={memoryPhotoUrl.startsWith("blob:") ? "" : memoryPhotoUrl}
                    onChange={(e) => {
                      const v = e.target.value;
                      setMemoryPhotoUrl((prev) => {
                        if (prev.startsWith("blob:")) URL.revokeObjectURL(prev);
                        return v;
                      });
                    }}
                    placeholder="Photo URL (optional)"
                    className="w-full rounded-xl px-3 py-2.5 text-[13px] outline-none"
                    style={{ border: "1px solid rgba(38,40,43,0.08)", background: "rgba(255,255,255,0.85)" }}
                  />
                  <label
                    className="flex w-full cursor-pointer flex-col items-center justify-center gap-1 rounded-xl border border-dashed border-[#26282B]/15 py-3"
                    style={{ background: "rgba(255,255,255,0.5)" }}
                  >
                    <Image className="h-4 w-4 text-[#26282B]/35" strokeWidth={2} aria-hidden />
                    <span className="text-[11px] text-[#26282B]/45" style={{ fontWeight: 500 }}>
                      {memoryPhotoUrl.startsWith("blob:") ? "Photo selected — add memory to attach" : "Upload photo from device"}
                    </span>
                    <input
                      type="file"
                      accept="image/*"
                      className="sr-only"
                      onChange={handleMemoryModalPhotoFile}
                    />
                  </label>
                  <div>
                    <p className="text-[11px] text-[#26282B]/55 mb-1.5" style={{ fontWeight: 400 }}>Mood</p>
                    <div className="flex flex-wrap gap-1.5">
                      {moodOptions.map((mood) => (
                        <motion.button
                          key={`memory-mood-${mood}`}
                          className="flex h-8 w-8 items-center justify-center rounded-full text-[16px] backdrop-blur-md"
                          style={{
                            background: memoryMood === mood ? "rgba(255,255,255,0.58)" : US_MATTE_CONTROL.bg,
                            border:
                              memoryMood === mood
                                ? `1px solid rgba(${US_INK_RGB},0.2)`
                                : US_MATTE_CONTROL.border,
                            boxShadow: memoryMood === mood ? US_MATTE_CONTROL.shadow : "none",
                          }}
                          whileTap={{ scale: 0.92 }}
                          onClick={() => setMemoryMood(mood)}
                        >
                          {mood}
                        </motion.button>
                      ))}
                    </div>
                  </div>
                </div>
                <motion.button
                  className="mt-4 w-full rounded-xl py-2.5 backdrop-blur-md"
                  style={{
                    background: US_MATTE_CONTROL.bg,
                    border: US_MATTE_CONTROL.border,
                    boxShadow: US_MATTE_CONTROL.shadow,
                    color: CTA_BUTTON_TEXT,
                    fontWeight: 600,
                  }}
                  whileTap={{ scale: 0.98 }}
                  onClick={handleAddMemory}
                >
                  Share a memory
                </motion.button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Memory detail — open from Shared Memories; swipe left → next */}
      <AnimatePresence>
        {viewingMemory ? (
          <motion.div
            className="fixed inset-0 z-[62] flex items-center justify-center px-5"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
          >
            <motion.div
              className="absolute inset-0"
              style={{
                background: "rgba(26,26,46,0.36)",
                backdropFilter: "blur(10px)",
                WebkitBackdropFilter: "blur(10px)",
              }}
              onClick={closeMemoryDetail}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            />
            <motion.div
              role="dialog"
              aria-modal="true"
              aria-label={viewingMemory.title}
              className="relative z-10 w-full max-w-sm cursor-grab overflow-hidden rounded-[1.5rem] border shadow-2xl backdrop-blur-2xl active:cursor-grabbing"
              style={{
                x: memoryDetailDragX,
                background: AUTH_DATES_CALENDAR_GLASS.surface,
                borderColor: AUTH_DATES_CALENDAR_GLASS.border,
                boxShadow: AUTH_DATES_CALENDAR_GLASS.shadow,
                touchAction: "none",
              }}
              initial={{ opacity: 0, scale: 0.94, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.94, y: 16 }}
              transition={{ type: "spring", stiffness: 300, damping: 28 }}
              drag="x"
              dragDirectionLock
              dragConstraints={{ left: -80, right: 80 }}
              dragElastic={0.35}
              onDragEnd={handleMemoryDetailDragEnd}
              onClick={(e) => e.stopPropagation()}
            >
              <div className="h-[3px] w-full" style={{ background: AUTH_DATES_CALENDAR_GLASS.topHairline }} />
              <motion.button
                type="button"
                className="absolute right-3.5 top-3.5 z-20 rounded-full p-1.5 backdrop-blur-md"
                style={{
                  background: AUTH_DATES_CHROME.background,
                  border: AUTH_DATES_CHROME.border,
                  boxShadow: AUTH_DATES_CHROME.shadow,
                }}
                onPointerDown={(e) => e.stopPropagation()}
                onClick={closeMemoryDetail}
                whileTap={{ scale: 0.85 }}
                aria-label="Close"
              >
                <X className="h-4 w-4" strokeWidth={2} style={{ color: AUTH_DATES_CHROME.icon }} />
              </motion.button>

              <AnimatePresence mode="wait" initial={false}>
                <motion.div
                  key={viewingMemory.id}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.15 }}
                >
                  <div className="relative">
                    {viewingMemory.photoUrl ? (
                      <div className="relative aspect-[4/3] w-full overflow-hidden bg-[rgba(26,26,46,0.06)]">
                        <img
                          src={viewingMemory.photoUrl}
                          alt=""
                          className="pointer-events-none h-full w-full select-none object-cover"
                          draggable={false}
                        />
                      </div>
                    ) : (
                      <div
                        className="flex aspect-[4/3] w-full items-center justify-center"
                        style={{
                          background: `linear-gradient(155deg, rgba(255,255,255,0.7) 0%, ${statusTheme.color}20 55%, rgba(248,250,252,0.85) 100%)`,
                        }}
                      >
                        <span className="text-[3rem] leading-none" aria-hidden>
                          {viewingMemory.mood}
                        </span>
                      </div>
                    )}
                  </div>

                  <div className="px-5 pb-5 pt-4">
                    <div className="flex items-start gap-2 pr-8">
                      {viewingMemory.photoUrl ? (
                        <span className="mt-0.5 shrink-0 text-[1.25rem] leading-none" aria-hidden>
                          {viewingMemory.mood}
                        </span>
                      ) : null}
                      <div className="min-w-0 flex-1">
                        <p className="text-[16px] leading-snug" style={{ fontWeight: 600, color: "rgba(26,26,46,0.92)" }}>
                          {viewingMemory.title}
                        </p>
                        <p className="mt-1 text-[12px]" style={{ fontWeight: 300, color: "rgba(26,26,46,0.48)" }}>
                          {formatShortDate(viewingMemory.dateTime)}
                        </p>
                      </div>
                    </div>

                    {viewingMemory.description ? (
                      <p
                        className="mt-3 text-[13px] leading-relaxed"
                        style={{ fontWeight: 300, color: "rgba(26,26,46,0.62)" }}
                      >
                        {viewingMemory.description}
                      </p>
                    ) : null}

                    <motion.button
                      type="button"
                      aria-label="Share memory"
                      className="mt-4 flex h-10 w-full items-center justify-center gap-1.5 rounded-xl"
                      style={{
                        background: AUTH_DATES_CTA.background,
                        color: AUTH_DATES_CTA.color,
                        boxShadow: AUTH_DATES_CTA.shadow,
                        border: "1px solid rgba(255,255,255,0.08)",
                      }}
                      whileTap={{ scale: 0.97 }}
                      onPointerDown={(e) => e.stopPropagation()}
                      onClick={() => handleShareMemory(viewingMemory)}
                    >
                      <Share2 className="h-4 w-4" strokeWidth={2} />
                      <span className="text-[12px]" style={{ fontWeight: 600 }}>
                        Share
                      </span>
                    </motion.button>
                  </div>
                </motion.div>
              </AnimatePresence>
            </motion.div>
          </motion.div>
        ) : null}
      </AnimatePresence>

      {/* Important dates — full list (Auth-styled glass) */}
      <AnimatePresence>
        {showImportantDatesList && (
          <motion.div
            className="fixed inset-0 z-50 flex items-center justify-center px-4 py-8"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
          >
            <motion.div
              className="absolute inset-0"
              style={{
                background:
                  "radial-gradient(ellipse 80% 60% at 20% 10%, rgba(251,207,232,0.22), transparent 55%), radial-gradient(ellipse 70% 50% at 90% 90%, rgba(196,181,253,0.18), transparent 50%), rgba(26,26,46,0.28)",
                backdropFilter: "blur(12px)",
                WebkitBackdropFilter: "blur(12px)",
              }}
              onClick={closeImportantDatesList}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            />
            <motion.div
              className="relative w-full max-w-sm max-h-[88vh] overflow-hidden rounded-[1.5rem] border shadow-2xl backdrop-blur-2xl"
              style={{
                background: AUTH_DATES_CALENDAR_GLASS.surface,
                borderColor: AUTH_DATES_CALENDAR_GLASS.border,
                boxShadow: AUTH_DATES_CALENDAR_GLASS.shadow,
              }}
              initial={{ opacity: 0, scale: 0.94, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.94, y: 16 }}
              transition={{ type: "spring", stiffness: 300, damping: 28 }}
            >
              <div className="h-[3px] w-full shrink-0" style={{ background: AUTH_DATES_CALENDAR_GLASS.topHairline }} />
              <motion.button
                type="button"
                className="absolute right-3.5 top-3.5 z-10 rounded-full p-1.5 backdrop-blur-md"
                style={{
                  background: AUTH_DATES_CHROME.background,
                  border: AUTH_DATES_CHROME.border,
                  boxShadow: AUTH_DATES_CHROME.shadow,
                }}
                onClick={closeImportantDatesList}
                whileTap={{ scale: 0.85 }}
                aria-label="Close"
              >
                <X className="h-4 w-4" strokeWidth={2} style={{ color: AUTH_DATES_CHROME.icon }} />
              </motion.button>
              <div className="flex max-h-[88vh] flex-col px-5 pb-5 pt-5">
                <p className="text-center text-[#1a1a2e]" style={{ fontWeight: 600 }}>
                  Important dates
                </p>
                <p className="mt-1 text-center text-[11px]" style={{ fontWeight: 300, color: "rgba(26,26,46,0.45)" }}>
                  All your moments together
                </p>
                <div
                  className="mt-4 min-h-0 flex-1 space-y-2 overflow-y-auto pr-0.5 [scrollbar-width:thin] [scrollbar-color:rgba(26,26,46,0.1)_transparent] [&::-webkit-scrollbar]:w-[3px] [&::-webkit-scrollbar-track]:bg-transparent [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-thumb]:bg-[rgba(26,26,46,0.1)]"
                >
                  {importantDatesFullList.length === 0 ? (
                    <p className="py-8 text-center text-[12px]" style={{ fontWeight: 300, color: "rgba(26,26,46,0.4)" }}>
                      No dates yet — tap + on the card to add one.
                    </p>
                  ) : (
                    importantDatesFullList.map((item) => {
                      const Icon = item.icon;
                      const du = getDaysUntil(item.date);
                      return (
                        <div
                          key={item.id}
                          className="flex items-center justify-between gap-2 rounded-xl border px-3 py-2.5 backdrop-blur-sm"
                          style={{
                            background:
                              "linear-gradient(155deg, rgba(255,255,255,0.82) 0%, rgba(255,255,255,0.58) 100%)",
                            borderColor: "rgba(45,45,68,0.1)",
                            boxShadow: "inset 0 1px 0 rgba(255,255,255,0.85), 0 2px 10px rgba(26,26,46,0.04)",
                          }}
                        >
                          <div className="flex min-w-0 flex-1 items-center gap-2">
                            <div
                              className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full"
                              style={{
                                background: `linear-gradient(135deg, ${item.color}55, ${item.color}30)`,
                                border: "1px solid rgba(255,255,255,0.65)",
                              }}
                            >
                              <Icon className="h-3.5 w-3.5 text-white/95" strokeWidth={2} />
                            </div>
                            <div className="min-w-0 flex-1">
                              <p className="truncate text-[13px]" style={{ fontWeight: 500, color: "#1a1a2e" }}>
                                {item.title}
                              </p>
                              <p className="text-[11px]" style={{ fontWeight: 300, color: "rgba(26,26,46,0.42)" }}>
                                {formatShortDate(item.date)}
                              </p>
                            </div>
                          </div>
                          <span
                            className="inline-flex shrink-0 items-center justify-center whitespace-nowrap rounded-full px-2 py-0.5 text-[9px] leading-tight tracking-wide backdrop-blur-sm"
                            style={{
                              background: "rgba(255,255,255,0.72)",
                              border: "1px solid rgba(45,45,68,0.12)",
                              boxShadow: "inset 0 1px 0 rgba(255,255,255,0.9)",
                              fontWeight: 600,
                              color: "rgba(26,26,46,0.62)",
                            }}
                          >
                            {countdownLabel(du)}
                          </span>
                        </div>
                      );
                    })
                  )}
                </div>
                <div className="mt-3 flex flex-col gap-2">
                  {partnerWishes.length > 0 ? (
                    <motion.button
                      type="button"
                      className="flex w-full items-center justify-center gap-2 rounded-xl py-2.5 backdrop-blur-md"
                      style={{
                        background: AUTH_DATES_CHROME.background,
                        border: AUTH_DATES_CHROME.border,
                        boxShadow: AUTH_DATES_CHROME.shadow,
                        color: "rgba(26,26,46,0.72)",
                        fontWeight: 600,
                      }}
                      whileTap={{ scale: 0.98 }}
                      onClick={() => {
                        closeImportantDatesList();
                        openWishlist("partner");
                      }}
                    >
                      <Gift className="h-4 w-4" strokeWidth={2} style={{ color: AUTH_DATES_CHROME.icon }} />
                      Wishlist ideas
                    </motion.button>
                  ) : null}
                  {isPremium ? (
                    <motion.button
                      type="button"
                      className="flex w-full items-center justify-center gap-2 rounded-xl py-3"
                      style={{
                        background: AUTH_DATES_CTA.background,
                        border: "1px solid rgba(255,255,255,0.08)",
                        boxShadow: AUTH_DATES_CTA.shadow,
                        color: AUTH_DATES_CTA.color,
                        fontWeight: 500,
                      }}
                      whileTap={{ scale: 0.98 }}
                      onClick={openImportantDatesCalendar}
                    >
                      <Plus className="h-4 w-4" strokeWidth={2.5} />
                      Add a date
                    </motion.button>
                  ) : null}
                </div>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Important dates — calendar (Auth-styled glass) */}
      <AnimatePresence>
        {showImportantDatesCalendar && (
          <motion.div
            className="fixed inset-0 z-50 flex items-center justify-center px-4 py-8"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
          >
            <motion.div
              className="absolute inset-0"
              style={{
                background:
                  "radial-gradient(ellipse 80% 60% at 20% 10%, rgba(251,207,232,0.22), transparent 55%), radial-gradient(ellipse 70% 50% at 90% 90%, rgba(196,181,253,0.18), transparent 50%), rgba(26,26,46,0.28)",
                backdropFilter: "blur(12px)",
                WebkitBackdropFilter: "blur(12px)",
              }}
              onClick={closeImportantDatesCalendar}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            />
            <motion.div
              className="relative w-full max-w-sm max-h-[88vh] overflow-y-auto rounded-[1.5rem] border shadow-2xl backdrop-blur-2xl"
              style={{
                background: AUTH_DATES_CALENDAR_GLASS.surface,
                borderColor: AUTH_DATES_CALENDAR_GLASS.border,
                boxShadow: AUTH_DATES_CALENDAR_GLASS.shadow,
              }}
              initial={{ opacity: 0, scale: 0.94, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.94, y: 16 }}
              transition={{ type: "spring", stiffness: 300, damping: 28 }}
            >
              <div className="h-[3px] w-full shrink-0" style={{ background: AUTH_DATES_CALENDAR_GLASS.topHairline }} />
              <motion.button
                type="button"
                className="absolute right-3.5 top-3.5 z-10 rounded-full p-1.5 backdrop-blur-md"
                style={{
                  background: AUTH_DATES_CHROME.background,
                  border: AUTH_DATES_CHROME.border,
                  boxShadow: AUTH_DATES_CHROME.shadow,
                }}
                onClick={closeImportantDatesCalendar}
                whileTap={{ scale: 0.85 }}
                aria-label="Close"
              >
                <X className="h-4 w-4" strokeWidth={2} style={{ color: AUTH_DATES_CHROME.icon }} />
              </motion.button>
              <div className="px-5 pb-5 pt-5">
                <p className="text-center text-[#1a1a2e]" style={{ fontWeight: 600 }}>
                  Add a date
                </p>
                <p className="mt-1 text-center text-[11px]" style={{ fontWeight: 300, color: "rgba(26,26,46,0.45)" }}>
                  Pick a day on the calendar
                </p>
                <div className="mt-3 w-full min-w-0">
                  <div className="mb-2 flex items-center justify-between gap-2">
                    <motion.button
                      type="button"
                      className="rounded-full p-2 backdrop-blur-md"
                      style={{
                        background: AUTH_DATES_CHROME.background,
                        border: AUTH_DATES_CHROME.border,
                        boxShadow: AUTH_DATES_CHROME.shadow,
                      }}
                      whileTap={{ scale: 0.92 }}
                      aria-label="Previous month"
                      onClick={() => setCalendarViewMonth(new Date(calendarMonthYear, calendarMonthIndex - 1, 1))}
                    >
                      <ChevronLeft className="h-4 w-4" strokeWidth={2} style={{ color: AUTH_DATES_CHROME.icon }} />
                    </motion.button>
                    <p
                      className="min-w-0 flex-1 truncate text-center text-[11px] capitalize"
                      style={{ fontWeight: 500, color: "rgba(26,26,46,0.88)" }}
                    >
                      {calendarViewMonth.toLocaleDateString("en-US", { month: "short", year: "numeric" })}
                    </p>
                    <motion.button
                      type="button"
                      className="rounded-full p-2 backdrop-blur-md"
                      style={{
                        background: AUTH_DATES_CHROME.background,
                        border: AUTH_DATES_CHROME.border,
                        boxShadow: AUTH_DATES_CHROME.shadow,
                      }}
                      whileTap={{ scale: 0.92 }}
                      aria-label="Next month"
                      onClick={() => setCalendarViewMonth(new Date(calendarMonthYear, calendarMonthIndex + 1, 1))}
                    >
                      <ChevronRight className="h-4 w-4" strokeWidth={2} style={{ color: AUTH_DATES_CHROME.icon }} />
                    </motion.button>
                  </div>
                  <div
                    className="grid w-full grid-cols-7 gap-1 text-center text-[8px] uppercase tracking-wide"
                    style={{ fontWeight: 500, color: "rgba(26,26,46,0.32)" }}
                  >
                    {["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"].map((d) => (
                      <span key={d} className="py-1">
                        {d}
                      </span>
                    ))}
                  </div>
                  <div className="mt-1.5 grid w-full grid-cols-7 gap-1">
                    {calendarCells.map((day, idx) => {
                      const isUserAdded = day !== null && calendarUserAddedDays.has(day);
                      const isGallery = day !== null && calendarGalleryDays.has(day);
                      const isMarked = day !== null && calendarMarkedDays.has(day);
                      const dayStr =
                        day !== null
                          ? `${calendarMonthYear}-${String(calendarMonthIndex + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`
                          : "";
                      const isSelected = day !== null && newDateValue === dayStr;
                      const tint = isSelected
                        ? {
                            color: "rgba(255,255,255,0.95)",
                            background: "linear-gradient(135deg, #1a1a2e, #2d2d44)",
                            boxShadow: "0 4px 12px rgba(26,26,46,0.25)",
                          }
                        : isUserAdded
                          ? {
                              color: "rgba(22,101,52,0.88)",
                              background: "rgba(34,197,94,0.22)",
                              boxShadow: "inset 0 0 0 1px rgba(34,197,94,0.3)",
                            }
                          : isGallery
                            ? {
                                color: "rgba(91,33,182,0.88)",
                                background: "rgba(167,139,250,0.2)",
                                boxShadow: "inset 0 0 0 1px rgba(139,92,246,0.32)",
                              }
                            : isMarked
                              ? {
                                  color: "rgba(26,26,46,0.72)",
                                  background: "rgba(232,190,201,0.35)",
                                }
                              : null;
                      return (
                        <button
                          key={`cal-${calendarMonthYear}-${calendarMonthIndex}-${idx}`}
                          type="button"
                          disabled={day === null}
                          className="flex aspect-square w-full min-w-0 items-center justify-center rounded-lg text-[10px] tabular-nums leading-none disabled:pointer-events-none"
                          style={{
                            fontWeight: isSelected || isMarked ? 600 : 400,
                            color: tint?.color ?? "rgba(26,26,46,0.32)",
                            background: tint?.background ?? "transparent",
                            boxShadow: tint?.boxShadow,
                          }}
                          onClick={() => {
                            if (day === null) return;
                            setNewDateValue(dayStr);
                            setImportantDatesInlineAddOpen(true);
                          }}
                        >
                          {day !== null ? day : ""}
                        </button>
                      );
                    })}
                  </div>
                </div>

                <AnimatePresence initial={false}>
                  {importantDatesInlineAddOpen ? (
                    <motion.div
                      key="inline-add-fields"
                      initial={{ opacity: 0, y: 6 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: 4 }}
                      transition={{ duration: 0.24, ease: [0.22, 1, 0.36, 1] }}
                      className="overflow-hidden"
                    >
                      <div className="relative space-y-2.5 pb-1 pt-3">
                        <p
                          className="text-center text-[10px]"
                          style={{ fontWeight: 400, color: "rgba(26,26,46,0.42)" }}
                        >
                          Name this date, then save
                        </p>
                        <input
                          value={newDateTitle}
                          onChange={(e) => setNewDateTitle(e.target.value)}
                          placeholder="Date title"
                          className="w-full rounded-xl px-3 py-2.5 text-[13px] outline-none backdrop-blur-sm"
                          style={{
                            border: AUTH_DATES_INPUT.border,
                            background: AUTH_DATES_INPUT.background,
                            boxShadow: "inset 0 1px 0 rgba(255,255,255,0.7)",
                            color: "#1a1a2e",
                          }}
                        />
                        <input
                          type="date"
                          value={newDateValue}
                          onChange={(e) => setNewDateValue(e.target.value)}
                          className="w-full rounded-xl px-3 py-2.5 text-[13px] outline-none backdrop-blur-sm"
                          style={{
                            border: AUTH_DATES_INPUT.border,
                            background: AUTH_DATES_INPUT.background,
                            boxShadow: "inset 0 1px 0 rgba(255,255,255,0.7)",
                            color: "#1a1a2e",
                          }}
                        />
                      </div>
                    </motion.div>
                  ) : null}
                </AnimatePresence>

                {isPremium ? (
                  <motion.button
                    type="button"
                    disabled={importantDatesAddSuccess}
                    className="mt-3 flex w-full items-center justify-center gap-2 rounded-xl py-3"
                    style={
                      importantDatesAddSuccess
                        ? {
                            background: IMPORTANT_DATES_ADD_SUCCESS_BTN.background,
                            border: IMPORTANT_DATES_ADD_SUCCESS_BTN.border,
                            boxShadow: IMPORTANT_DATES_ADD_SUCCESS_BTN.shadow,
                            color: IMPORTANT_DATES_ADD_SUCCESS_BTN.color,
                            fontWeight: 600,
                          }
                        : {
                            background: AUTH_DATES_CTA.background,
                            border: "1px solid rgba(255,255,255,0.08)",
                            boxShadow: AUTH_DATES_CTA.shadow,
                            color: AUTH_DATES_CTA.color,
                            fontWeight: 500,
                          }
                    }
                    animate={importantDatesAddSuccess ? { scale: [1, 1.02, 1] } : {}}
                    transition={{ duration: 0.45, ease: "easeOut" }}
                    whileTap={importantDatesAddSuccess ? undefined : { scale: 0.98 }}
                    onClick={handleImportantDatesAddButtonClick}
                  >
                    {importantDatesAddSuccess ? (
                      <Check className="h-4 w-4" strokeWidth={2.5} />
                    ) : (
                      <Plus className="h-4 w-4" strokeWidth={2.5} />
                    )}
                    {importantDatesAddSuccess ? "Added!" : "Save important date"}
                  </motion.button>
                ) : null}
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Love Note — write & send */}
      <AnimatePresence>
        {showLoveNoteModal && (
          <motion.div className="fixed inset-0 z-[62] flex items-center justify-center px-5" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.2 }}>
            <motion.div
              className="absolute inset-0"
              style={{
                background: `radial-gradient(ellipse 85% 70% at 50% 42%, rgba(${LOVE_NOTE_PANEL_RGB},0.14), transparent 55%), rgba(38,40,43,0.26)`,
                backdropFilter: "blur(8px)",
                WebkitBackdropFilter: "blur(8px)",
              }}
              onClick={() => {
                setShowLoveNoteModal(false);
                resetLoveNoteComposer();
              }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            />
            <motion.div
              className="relative w-full max-w-sm max-h-[90vh] overflow-y-auto overflow-x-hidden rounded-[1.6rem] border shadow-2xl backdrop-blur-2xl"
              style={{
                background: LOVE_NOTE_CREATE_MODAL_GLASS.surface,
                borderColor: LOVE_NOTE_CREATE_MODAL_GLASS.border,
                boxShadow: `${LOVE_NOTE_CREATE_MODAL_GLASS.shadow}, 0 20px 40px rgba(38,40,43,0.1)`,
              }}
              initial={{ opacity: 0, scale: 0.92, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.92, y: 20 }}
              transition={{ type: "spring", stiffness: 280, damping: 26 }}
            >
              <div
                className="pointer-events-none absolute inset-0 z-0 rounded-[1.6rem]"
                style={{ background: LOVE_NOTE_CREATE_MODAL_PINK_WASH }}
              />
              <motion.button
                className="absolute top-3.5 right-3.5 z-10 rounded-full p-1.5 backdrop-blur-md"
                style={{
                  background: US_MATTE_CONTROL.bg,
                  border: US_MATTE_CONTROL.border,
                  boxShadow: US_MATTE_CONTROL.shadow,
                }}
                onClick={() => {
                  setShowLoveNoteModal(false);
                  resetLoveNoteComposer();
                }}
                whileTap={{ scale: 0.85 }}
              >
                <X className="h-4 w-4" strokeWidth={2} style={{ color: US_MATTE_CONTROL.icon }} />
              </motion.button>
              <div className="relative z-[1] px-5 pb-5 pt-6">
                <p className="mb-4 text-center text-[15px]" style={{ fontWeight: 600, color: `rgba(${US_INK_RGB},0.88)` }}>
                  Write a note
                </p>

                <textarea
                  value={loveNoteBody}
                  onChange={(e) => setLoveNoteBody(sanitizeLoveNoteBody(e.target.value))}
                  placeholder="Something warm for them…"
                  rows={5}
                  maxLength={LOVE_NOTE_BODY_MAX_LEN}
                  autoFocus
                  className="mb-1.5 w-full resize-none rounded-xl px-3 py-2.5 text-[13px] outline-none"
                  style={{
                    border: LOVE_NOTE_MODAL_FIELD.border,
                    background: LOVE_NOTE_MODAL_FIELD.background,
                    color: "#26282B",
                  }}
                />
                <div className="mb-4 flex items-start justify-between gap-3">
                  <p className="min-w-0 flex-1 text-left text-[9px] leading-snug" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.4)` }}>
                    Latin letters, numbers, punctuation &amp; emoji — max {LOVE_NOTE_BODY_MAX_LEN} characters.
                  </p>
                  <p className="shrink-0 text-right text-[10px] tabular-nums" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.42)` }}>
                    {loveNoteBodyLength(loveNoteBody)}/{LOVE_NOTE_BODY_MAX_LEN}
                  </p>
                </div>
                <motion.button
                  type="button"
                  className="flex w-full items-center justify-center gap-2 rounded-xl py-3 backdrop-blur-md"
                  style={{
                    background: US_MATTE_CONTROL.bg,
                    border: US_MATTE_CONTROL.border,
                    boxShadow: US_MATTE_CONTROL.shadow,
                    color: CTA_BUTTON_TEXT,
                    fontWeight: 600,
                    opacity: loveNoteBody.trim() ? 1 : 0.55,
                  }}
                  whileTap={{ scale: loveNoteBody.trim() ? 0.98 : 1 }}
                  disabled={!loveNoteBody.trim()}
                  onClick={handleSendLoveNote}
                >
                  <Send className="h-4 w-4" strokeWidth={2} aria-hidden />
                  Send note
                </motion.button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>


      {/* Love Notes — full page */}
      <AnimatePresence>
        {showLoveNotesPage ? (
          <motion.div
            key="love-notes-page"
            className="fixed inset-0 z-[58] flex flex-col overflow-hidden"
            initial={{ opacity: 0, x: 28 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 24 }}
            transition={{ type: "spring", stiffness: 340, damping: 34 }}
          >
            <div
              className="pointer-events-none absolute inset-0"
              style={{
                background: [
                  "linear-gradient(180deg, #fdf2f8 0%, #faf5ff 32%, #f8fafc 68%, #f0fdf9 100%)",
                  "radial-gradient(ellipse 90% 55% at 12% -8%, rgba(248,187,208,0.35), transparent 55%)",
                  "radial-gradient(ellipse 70% 45% at 100% 20%, rgba(233,213,255,0.28), transparent 50%)",
                  "radial-gradient(ellipse 80% 50% at 50% 100%, rgba(255,255,255,0.65), transparent 55%)",
                ].join(", "),
              }}
            />
            <motion.div
              className="pointer-events-none absolute -left-20 -top-24 h-[22rem] w-[22rem] rounded-full blur-[110px]"
              style={{ background: "linear-gradient(135deg, rgba(251,207,232,0.55), rgba(196,181,253,0.35))" }}
              animate={{ opacity: [0.4, 0.65, 0.4], scale: [0.95, 1.06, 0.95] }}
              transition={{ duration: 7, repeat: Infinity, ease: "easeInOut" }}
              aria-hidden
            />
            <motion.div
              className="pointer-events-none absolute -bottom-24 -right-16 h-80 w-80 rounded-full blur-[100px]"
              style={{ background: "linear-gradient(135deg, rgba(253,236,245,0.55), rgba(167,243,208,0.22))" }}
              animate={{ opacity: [0.28, 0.5, 0.28], scale: [1, 1.08, 1] }}
              transition={{ duration: 8, repeat: Infinity, ease: "easeInOut", delay: 1.1 }}
              aria-hidden
            />

            <div
              className="relative z-10 mx-auto flex h-full w-full max-w-md flex-col"
              style={{ paddingTop: "max(3.5rem, calc(env(safe-area-inset-top) + 2.75rem))" }}
            >
              <div className="flex items-center gap-2 px-4 pb-2 pt-1">
                <motion.button
                  type="button"
                  className="flex h-10 w-10 items-center justify-center rounded-full backdrop-blur-md"
                  style={{
                    background: US_MATTE_CONTROL.bg,
                    border: US_MATTE_CONTROL.borderStrong,
                    boxShadow: US_MATTE_CONTROL.shadow,
                  }}
                  whileTap={{ scale: 0.9 }}
                  aria-label="Back to Us"
                  onClick={() => setShowLoveNotesPage(false)}
                >
                  <ChevronLeft className="h-5 w-5" strokeWidth={2} style={{ color: US_MATTE_CONTROL.icon }} />
                </motion.button>
                <div className="min-w-0 flex-1 text-center pr-10">
                  <p
                    className="text-[11px] uppercase tracking-[0.18em]"
                    style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.42)` }}
                  >
                    Love Notes
                  </p>
                  <p
                    className="mt-0.5 text-[15px] leading-snug hyphens-none"
                    style={{
                      fontWeight: 500,
                      color: `rgba(${US_INK_RGB},0.82)`,
                      wordBreak: "normal",
                      overflowWrap: "normal",
                    }}
                  >
                    Say something sweet — it only takes a moment
                  </p>
                </div>
              </div>

              <div
                className="min-h-0 flex-1 overflow-y-auto px-4 pb-8 pt-2"
                style={{ paddingBottom: "max(2rem, calc(env(safe-area-inset-bottom) + 1.25rem))" }}
              >
                <motion.section
                  className="relative mb-4 overflow-hidden rounded-[1.35rem] border backdrop-blur-2xl"
                  style={{
                    background: LOVE_NOTE_EXPANDED_GLASS.surface,
                    borderColor: LOVE_NOTE_EXPANDED_GLASS.border,
                    boxShadow: LOVE_NOTE_EXPANDED_GLASS.shadow,
                  }}
                  initial={{ opacity: 0, y: 14 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.12, duration: 0.4 }}
                  aria-label="Incoming notes"
                >
                  <div
                    className="pointer-events-none absolute inset-0"
                    style={{
                      background: `radial-gradient(ellipse 95% 70% at 10% 0%, rgba(${LOVE_NOTE_PANEL_RGB},0.16), transparent 55%)`,
                    }}
                  />
                  <div className="relative z-10 px-4 pb-4 pt-4">
                    <div className="mb-3 flex items-end justify-between gap-2">
                      <div>
                        <p className="text-[10px] uppercase tracking-[0.16em]" style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.42)` }}>
                          Incoming notes
                        </p>
                        <p className="mt-1 text-[13px]" style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.78)` }}>
                          Left for you
                        </p>
                      </div>
                      <span
                        className="rounded-full px-2.5 py-1 text-[10px] tabular-nums"
                        style={{
                          fontWeight: 600,
                          color: `rgba(${US_INK_RGB},0.55)`,
                          background: "rgba(255,255,255,0.45)",
                          border: `1px solid rgba(${LOVE_NOTE_PANEL_RGB},0.22)`,
                        }}
                      >
                        {incomingWaitingLoveNotes.length + incomingUnlockedSorted.length + incomingReadLoveNotes.length}
                      </span>
                    </div>

                    <div className="space-y-2.5">
                      {incomingWaitingLoveNotes.length === 0 &&
                      incomingUnlockedSorted.length === 0 &&
                      incomingReadLoveNotes.length === 0 ? (
                        <div
                          className="rounded-xl border px-3.5 py-5 text-center"
                          style={{
                            background: LOVE_NOTE_EXPANDED_ROW.surface,
                            borderColor: LOVE_NOTE_EXPANDED_ROW.border,
                          }}
                        >
                          <Mail className="mx-auto mb-2 h-5 w-5" strokeWidth={1.75} style={{ color: `rgba(${US_INK_RGB},0.28)` }} />
                          <p className="text-[12px] leading-snug" style={{ fontWeight: 400, color: `rgba(${US_INK_RGB},0.52)` }}>
                            No notes for you yet
                          </p>
                          <p className="mt-1 text-[10px] leading-snug" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.4)` }}>
                            When they write one, it will appear here.
                          </p>
                        </div>
                      ) : (
                        <>
                          {incomingUnlockedSorted.map((note, i) => {
                            const highlighted = Boolean(note.moodUnlockHighlight);
                            return (
                              <motion.button
                                key={note.id}
                                type="button"
                                className="relative w-full overflow-hidden rounded-xl border px-3.5 py-3 text-left backdrop-blur-md"
                                style={{
                                  background: highlighted
                                    ? `linear-gradient(165deg, rgba(255,255,255,0.55) 0%, rgba(253,236,245,0.38) 100%)`
                                    : LOVE_NOTE_EXPANDED_ROW.surface,
                                  borderColor: highlighted ? `rgba(${LOVE_NOTE_PANEL_RGB},0.38)` : LOVE_NOTE_EXPANDED_ROW.border,
                                  boxShadow: highlighted
                                    ? `inset 0 1px 0 rgba(255,255,255,0.6), 0 6px 18px rgba(${LOVE_NOTE_PANEL_RGB},0.16)`
                                    : "inset 0 1px 0 rgba(255,255,255,0.45)",
                                }}
                                initial={{ opacity: 0, y: 8 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ delay: 0.16 + i * 0.05 }}
                                whileTap={{ scale: 0.995 }}
                                onClick={() => setLoveNoteOpening(note)}
                              >
                                <div className="flex items-start gap-2.5">
                                  <div
                                    className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-full"
                                    style={{
                                      background: "rgba(255,255,255,0.55)",
                                      border: `1px solid rgba(${LOVE_NOTE_PANEL_RGB},0.25)`,
                                    }}
                                  >
                                    {loveNoteTriggerIconEl(note.triggerKind, "h-3.5 w-3.5", {
                                      color: `rgba(${US_INK_RGB},0.55)`,
                                    })}
                                  </div>
                                  <div className="min-w-0 flex-1 text-left">
                                    <p className="text-[12px] leading-snug" style={{ fontWeight: 700, color: `rgba(${US_INK_RGB},0.88)` }}>
                                      New note
                                    </p>
                                    <p className="mt-1 text-[11px] leading-snug italic" style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.62)` }}>
                                      &ldquo;{loveNoteBodyPreview(note.body, 15)}&rdquo;
                                    </p>
                                    <p className="mt-1 text-[10px]" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.42)` }}>
                                      {formatLoveNoteSentAt(note.createdAt)}
                                    </p>
                                  </div>
                                </div>
                              </motion.button>
                            );
                          })}
                          {incomingWaitingLoveNotes.map((note) => (
                            <div
                              key={note.id}
                              className="relative rounded-xl border px-3.5 py-3 backdrop-blur-md"
                              style={{
                                background: LOVE_NOTE_EXPANDED_ROW.surface,
                                borderColor: LOVE_NOTE_EXPANDED_ROW.border,
                              }}
                            >
                              <span
                                className="absolute right-2.5 top-2.5 rounded-full px-1.5 py-0.5 text-[8px] uppercase tracking-wide"
                                style={{
                                  fontWeight: 600,
                                  color: `rgba(${US_INK_RGB},0.48)`,
                                  background: "rgba(255,255,255,0.4)",
                                  border: `1px solid rgba(${US_INK_RGB},0.08)`,
                                }}
                              >
                                waiting
                              </span>
                              <div className="flex items-start gap-2.5 pr-14">
                                <div
                                  className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-full"
                                  style={{
                                    background: "rgba(255,255,255,0.45)",
                                    border: `1px solid rgba(${US_INK_RGB},0.08)`,
                                  }}
                                >
                                  {loveNoteTriggerIconEl(note.triggerKind, "h-3.5 w-3.5", {
                                    color: `rgba(${US_INK_RGB},0.45)`,
                                  })}
                                </div>
                                <div className="min-w-0 flex-1 text-left">
                                  <p className="text-[12px] leading-snug" style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.72)` }}>
                                    {loveNoteIncomingVagueTriggerLine(note)}
                                  </p>
                                  <p className="mt-1 text-[10px] leading-snug" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.45)` }}>
                                    A surprise is tucked away for you
                                  </p>
                                </div>
                              </div>
                            </div>
                          ))}
                          {incomingReadLoveNotes.map((note, i) => (
                            <motion.button
                              key={note.id}
                              type="button"
                              className="w-full rounded-xl border px-3.5 py-3 text-left opacity-95 backdrop-blur-md"
                              style={{
                                background: LOVE_NOTE_EXPANDED_ROW.surface,
                                borderColor: LOVE_NOTE_EXPANDED_ROW.border,
                              }}
                              initial={{ opacity: 0, y: 8 }}
                              animate={{ opacity: 0.95, y: 0 }}
                              transition={{ delay: 0.18 + i * 0.04 }}
                              whileTap={{ scale: 0.995 }}
                              onClick={() => setLoveNoteOpening(note)}
                            >
                              <div className="flex items-start gap-2.5">
                                <Check className="mt-0.5 h-4 w-4 shrink-0" strokeWidth={2} style={{ color: `rgba(${US_INK_RGB},0.38)` }} />
                                <div className="min-w-0 flex-1">
                                  <p className="text-[12px] leading-snug" style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.62)` }}>
                                    Seen
                                  </p>
                                  <p className="mt-1 text-[11px] leading-snug italic" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.45)` }}>
                                    &ldquo;{loveNoteBodyPreview(note.body, 15)}&rdquo;
                                  </p>
                                  <p className="mt-1 text-[10px]" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.4)` }}>
                                    {formatLoveNoteSentAt(note.createdAt)}
                                  </p>
                                </div>
                              </div>
                            </motion.button>
                          ))}
                        </>
                      )}
                    </div>
                  </div>
                </motion.section>

                <motion.section
                  className="relative mb-4 overflow-hidden rounded-[1.35rem] border backdrop-blur-2xl"
                  style={{
                    background: GLASS_MATTE.surface,
                    borderColor: GLASS_MATTE.border,
                    boxShadow: GLASS_MATTE.shadow,
                  }}
                  initial={{ opacity: 0, y: 14 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.2, duration: 0.4 }}
                  aria-label="Sent by you"
                >
                  <div
                    className="pointer-events-none absolute inset-0"
                    style={{
                      background: `radial-gradient(ellipse 90% 60% at 90% 0%, rgba(${LOVE_NOTE_PANEL_RGB},0.1), transparent 55%)`,
                    }}
                  />
                  <div className="relative z-10 px-4 pb-4 pt-4">
                    <div className="mb-3 flex items-end justify-between gap-2">
                      <div>
                        <p className="text-[10px] uppercase tracking-[0.16em]" style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.42)` }}>
                          Sent by you
                        </p>
                        <p className="mt-1 text-[13px]" style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.78)` }}>
                          On their way
                        </p>
                      </div>
                      <span
                        className="rounded-full px-2.5 py-1 text-[10px] tabular-nums"
                        style={{
                          fontWeight: 600,
                          color: IMPORTANT_DATES_MODAL_COUNTDOWN_BADGE.color,
                          background: IMPORTANT_DATES_MODAL_COUNTDOWN_BADGE.background,
                          border: IMPORTANT_DATES_MODAL_COUNTDOWN_BADGE.border,
                          boxShadow: IMPORTANT_DATES_MODAL_COUNTDOWN_BADGE.shadow,
                        }}
                      >
                        {outgoingWaitingLoveNotes.length}/{MAX_WAITING_LOVE_NOTES} waiting
                      </span>
                    </div>

                    {!canAddLoveNote ? (
                      <p
                        className="mb-3 rounded-lg px-2.5 py-2 text-left text-[10px] leading-snug"
                        style={{
                          fontWeight: 300,
                          color: `rgba(${US_INK_RGB},0.58)`,
                          background: LOVE_NOTE_EXPANDED_ROW.surface,
                          border: `1px solid ${LOVE_NOTE_EXPANDED_ROW.border}`,
                        }}
                      >
                        {MAX_WAITING_LOVE_NOTES} notes from you are already on their way. When one is opened, you can send another.
                      </p>
                    ) : null}

                    <div className="space-y-2.5">
                      {outgoingLoveNotesSorted.length === 0 ? (
                        <div
                          className="rounded-xl border px-3.5 py-5 text-center"
                          style={{
                            background: LOVE_NOTE_EXPANDED_ROW.surface,
                            borderColor: LOVE_NOTE_EXPANDED_ROW.border,
                          }}
                        >
                          <Pencil className="mx-auto mb-2 h-5 w-5" strokeWidth={1.75} style={{ color: `rgba(${US_INK_RGB},0.28)` }} />
                          <p className="text-[12px] leading-snug" style={{ fontWeight: 400, color: `rgba(${US_INK_RGB},0.52)` }}>
                            No notes yet — start with a little hello
                          </p>
                          <p className="mt-1 text-[10px] leading-snug" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.4)` }}>
                            A few warm words can make their day.
                          </p>
                        </div>
                      ) : (
                        outgoingLoveNotesSorted.map((note, i) => (
                          <motion.button
                            key={note.id}
                            type="button"
                            className="relative w-full rounded-xl border px-3.5 py-3 text-left backdrop-blur-md"
                            style={{
                              background: LOVE_NOTE_EXPANDED_ROW.surface,
                              borderColor: LOVE_NOTE_EXPANDED_ROW.border,
                            }}
                            initial={{ opacity: 0, y: 8 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: 0.22 + i * 0.04 }}
                            whileTap={{ scale: 0.995 }}
                            onClick={() => setLoveNoteOpening(note)}
                          >
                            <span
                              className="absolute right-2.5 top-2.5 rounded-full px-1.5 py-0.5 text-[8px] uppercase tracking-wide"
                              style={{
                                fontWeight: 600,
                                color:
                                  note.status === "read" ? `rgba(${US_INK_RGB},0.36)` : `rgba(${US_INK_RGB},0.5)`,
                                background: "rgba(255,255,255,0.4)",
                                border: `1px solid rgba(${US_INK_RGB},0.08)`,
                              }}
                            >
                              {note.status === "waiting" ? "waiting" : note.status === "unlocked" ? "delivered" : "read"}
                            </span>
                            <div className="flex items-start gap-2.5 pr-16">
                              <div
                                className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-full"
                                style={{
                                  background: "rgba(255,255,255,0.5)",
                                  border: `1px solid rgba(${US_INK_RGB},0.08)`,
                                }}
                              >
                                {note.status === "read" ? (
                                  <Check className="h-3.5 w-3.5" strokeWidth={2} style={{ color: `rgba(${US_INK_RGB},0.4)` }} />
                                ) : (
                                  loveNoteTriggerIconEl(note.triggerKind, "h-3.5 w-3.5", {
                                    color: `rgba(${US_INK_RGB},0.5)`,
                                  })
                                )}
                              </div>
                              <div className="min-w-0 flex-1">
                                <p className="text-[12px] leading-snug" style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.72)` }}>
                                  {loveNoteOutgoingOpensLine(note)}
                                </p>
                                <p className="mt-1 text-[11px] leading-snug italic" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.5)` }}>
                                  &ldquo;{loveNoteBodyPreview(note.body)}&rdquo;
                                </p>
                                <p className="mt-1 text-[10px]" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.4)` }}>
                                  {formatLoveNoteSentAt(note.createdAt)}
                                </p>
                              </div>
                            </div>
                          </motion.button>
                        ))
                      )}
                    </div>
                  </div>
                </motion.section>

                <motion.button
                  type="button"
                  className="flex w-full items-center justify-center gap-2 rounded-xl py-3.5"
                  style={{
                    fontWeight: 500,
                    color: canAddLoveNote ? AUTH_DATES_CTA.color : "rgba(0,0,0,0.3)",
                    background: canAddLoveNote
                      ? AUTH_DATES_CTA.background
                      : "rgba(0,0,0,0.08)",
                    border: canAddLoveNote
                      ? "1px solid rgba(255,255,255,0.08)"
                      : "1px solid rgba(0,0,0,0.06)",
                    boxShadow: canAddLoveNote ? AUTH_DATES_CTA.shadow : "none",
                    opacity: canAddLoveNote ? 1 : 0.7,
                  }}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: canAddLoveNote ? 1 : 0.7, y: 0 }}
                  transition={{ delay: 0.28, duration: 0.35 }}
                  whileTap={{ scale: canAddLoveNote ? 0.98 : 1 }}
                  disabled={!canAddLoveNote}
                  onClick={() => {
                    if (canAddLoveNote) openLoveNoteComposer();
                  }}
                >
                  {outgoingLoveNotesSorted.length === 0 ? "Write a note" : "Write another note"}
                </motion.button>
              </div>
            </div>
          </motion.div>
        ) : null}
      </AnimatePresence>

      {/* Shared Memories — gallery page (user-added moments) */}
      <AnimatePresence>
        {showSharedMemoriesPage ? (
          <motion.div
            key="shared-memories-page"
            className="fixed inset-0 z-[58] flex flex-col overflow-hidden"
            initial={{ opacity: 0, x: 28 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 24 }}
            transition={{ type: "spring", stiffness: 340, damping: 34 }}
          >
            <div
              className="pointer-events-none absolute inset-0"
              style={{
                background: [
                  "linear-gradient(180deg, #f8fafc 0%, #faf5ff 36%, #fdf2f8 72%, #f0fdf9 100%)",
                  "radial-gradient(ellipse 90% 55% at 88% -8%, rgba(196,181,253,0.28), transparent 55%)",
                  "radial-gradient(ellipse 70% 45% at 0% 30%, rgba(167,243,208,0.18), transparent 50%)",
                ].join(", "),
              }}
            />
            <motion.div
              className="pointer-events-none absolute -left-20 -top-24 h-[22rem] w-[22rem] rounded-full blur-[110px]"
              style={{ background: "linear-gradient(135deg, rgba(196,181,253,0.4), rgba(251,207,232,0.35))" }}
              animate={{ opacity: [0.35, 0.55, 0.35], scale: [0.95, 1.06, 0.95] }}
              transition={{ duration: 7, repeat: Infinity, ease: "easeInOut" }}
              aria-hidden
            />

            <div
              className="relative z-10 mx-auto flex h-full w-full max-w-md flex-col"
              style={{ paddingTop: "max(3.5rem, calc(env(safe-area-inset-top) + 2.75rem))" }}
            >
              <div className="flex items-center gap-2 px-4 pb-2 pt-1">
                <motion.button
                  type="button"
                  className="flex h-10 w-10 items-center justify-center rounded-full backdrop-blur-md"
                  style={{
                    background: US_MATTE_CONTROL.bg,
                    border: US_MATTE_CONTROL.borderStrong,
                    boxShadow: US_MATTE_CONTROL.shadow,
                  }}
                  whileTap={{ scale: 0.9 }}
                  aria-label="Back to Us"
                  onClick={() => setShowSharedMemoriesPage(false)}
                >
                  <ChevronLeft className="h-5 w-5" strokeWidth={2} style={{ color: US_MATTE_CONTROL.icon }} />
                </motion.button>
                <div className="min-w-0 flex-1 text-center">
                  <p
                    className="text-[11px] uppercase tracking-[0.18em]"
                    style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.42)` }}
                  >
                    Shared Memories
                  </p>
                  <p className="mt-0.5 text-[15px]" style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.82)` }}>
                    Moments you added
                  </p>
                </div>
                <motion.button
                  type="button"
                  className="flex h-10 w-10 items-center justify-center rounded-full backdrop-blur-md"
                  style={{
                    background: US_MATTE_CONTROL.bg,
                    border: US_MATTE_CONTROL.borderStrong,
                    boxShadow: US_MATTE_CONTROL.shadow,
                  }}
                  whileTap={{ scale: 0.9 }}
                  aria-label="Add a memory"
                  onClick={() => setShowAddMemoryModal(true)}
                >
                  <Plus className="h-4 w-4" strokeWidth={2.25} style={{ color: US_MATTE_CONTROL.icon }} />
                </motion.button>
              </div>

              <div className="px-4 pb-2">
                <div
                  className="flex gap-1.5 overflow-x-auto pb-1 [scrollbar-width:none] [&::-webkit-scrollbar]:h-0"
                  role="tablist"
                  aria-label="Filter memories by date"
                >
                  <motion.button
                    type="button"
                    role="tab"
                    aria-selected={memoriesDateFilter === "all"}
                    className="shrink-0 rounded-full px-3 py-1.5 text-[11px] backdrop-blur-md"
                    style={{
                      background:
                        memoriesDateFilter === "all" ? "rgba(255,255,255,0.72)" : US_MATTE_CONTROL.bg,
                      border:
                        memoriesDateFilter === "all"
                          ? `1.5px solid rgba(${US_INK_RGB},0.22)`
                          : US_MATTE_CONTROL.border,
                      boxShadow: US_MATTE_CONTROL.shadow,
                      color: `rgba(${US_INK_RGB},0.72)`,
                      fontWeight: memoriesDateFilter === "all" ? 500 : 400,
                    }}
                    whileTap={{ scale: 0.96 }}
                    onClick={() => setMemoriesDateFilter("all")}
                  >
                    All
                  </motion.button>
                  {memoriesDateFilterOptions.map((key) => {
                    const active = memoriesDateFilter === key;
                    return (
                      <motion.button
                        key={key}
                        type="button"
                        role="tab"
                        aria-selected={active}
                        className="shrink-0 rounded-full px-3 py-1.5 text-[11px] backdrop-blur-md"
                        style={{
                          background: active ? "rgba(255,255,255,0.72)" : US_MATTE_CONTROL.bg,
                          border: active
                            ? `1.5px solid rgba(${US_INK_RGB},0.22)`
                            : US_MATTE_CONTROL.border,
                          boxShadow: US_MATTE_CONTROL.shadow,
                          color: `rgba(${US_INK_RGB},0.72)`,
                          fontWeight: active ? 500 : 400,
                        }}
                        whileTap={{ scale: 0.96 }}
                        onClick={() => setMemoriesDateFilter(key)}
                      >
                        {memoryMonthLabel(key)}
                      </motion.button>
                    );
                  })}
                </div>
              </div>

              <div
                className="min-h-0 flex-1 overflow-y-auto px-4 pb-8 pt-1"
                style={{ paddingBottom: "max(2rem, calc(env(safe-area-inset-bottom) + 1.25rem))" }}
              >
                {filteredUserMemories.length === 0 ? (
                  <div className="flex flex-col items-center px-4 pt-16 text-center">
                    <p className="text-[14px]" style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.7)` }}>
                      {userAddedMemories.length === 0 ? "No moments yet" : "Nothing in this month"}
                    </p>
                    <p className="mt-1.5 max-w-[16rem] text-[12px] leading-relaxed" style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.45)` }}>
                      {userAddedMemories.length === 0
                        ? "Add a memory to start your gallery — photos and little stories you want to keep together."
                        : "Try another date filter or add a new memory."}
                    </p>
                    <motion.button
                      type="button"
                      className="mt-5 rounded-full px-5 py-2.5 text-[13px] backdrop-blur-md"
                      style={{
                        background: US_MATTE_CONTROL.bg,
                        border: US_MATTE_CONTROL.borderStrong,
                        boxShadow: US_MATTE_CONTROL.shadow,
                        color: `rgba(${US_INK_RGB},0.72)`,
                        fontWeight: 500,
                      }}
                      whileTap={{ scale: 0.97 }}
                      onClick={() => setShowAddMemoryModal(true)}
                    >
                      Add a memory
                    </motion.button>
                  </div>
                ) : (
                  <div className="grid grid-cols-2 gap-2.5">
                    {filteredUserMemories.map((memory, i) => (
                      <motion.article
                        key={memory.id}
                        role="button"
                        tabIndex={0}
                        aria-label={`Open memory ${memory.title}`}
                        className="relative cursor-pointer overflow-hidden rounded-2xl border backdrop-blur-xl"
                        style={{
                          background: memory.photoUrl ? undefined : SHARED_MEMORY_CARD_SURFACE,
                          borderColor: GLASS_MATTE.border,
                          boxShadow: GLASS_MATTE.shadow,
                          minHeight: 168,
                          ...(memory.photoUrl
                            ? {
                                backgroundImage: `url(${memory.photoUrl})`,
                                backgroundSize: "cover",
                                backgroundPosition: "center",
                              }
                            : {}),
                        }}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: Math.min(i * 0.04, 0.28), duration: 0.35 }}
                        onClick={() => openMemoryDetail(memory.id)}
                        onKeyDown={(e) => {
                          if (e.key === "Enter" || e.key === " ") {
                            e.preventDefault();
                            openMemoryDetail(memory.id);
                          }
                        }}
                      >
                        {memory.photoUrl ? (
                          <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-[#26282B]/65 via-[#26282B]/15 to-transparent" />
                        ) : (
                          <div
                            className="pointer-events-none absolute inset-0"
                            style={{
                              background:
                                "radial-gradient(ellipse 90% 80% at 30% 20%, rgba(38,40,43,0.04), transparent 60%)",
                            }}
                          />
                        )}
                        <div className="relative z-10 flex h-full min-h-[168px] flex-col justify-end p-3">
                          <span
                            className={`mb-1 text-base leading-none ${memory.photoUrl ? "drop-shadow" : ""}`}
                            aria-hidden
                          >
                            {memory.mood}
                          </span>
                          <p
                            className={`line-clamp-2 text-[13px] ${memory.photoUrl ? "text-white drop-shadow" : "text-[#26282B]"}`}
                            style={{ fontWeight: 500 }}
                          >
                            {memory.title}
                          </p>
                          <p
                            className={`mt-0.5 text-[10px] ${memory.photoUrl ? "text-white/80" : "text-[#26282B]/45"}`}
                            style={{ fontWeight: 300 }}
                          >
                            {formatShortDate(memory.dateTime)}
                          </p>
                          {memory.description ? (
                            <p
                              className={`mt-1 line-clamp-2 text-[11px] ${memory.photoUrl ? "text-white/75" : "text-[#26282B]/42"}`}
                              style={{ fontWeight: 300 }}
                            >
                              {memory.description}
                            </p>
                          ) : null}
                          <div className="mt-2 flex items-center gap-1">
                            <motion.button
                              type="button"
                              aria-label="Share memory"
                              className="flex h-7 w-7 items-center justify-center rounded-full backdrop-blur-md"
                              style={{
                                background: US_MATTE_CONTROL.bg,
                                border: US_MATTE_CONTROL.border,
                                boxShadow: US_MATTE_CONTROL.shadow,
                              }}
                              whileTap={{ scale: 0.9 }}
                              onClick={(e) => {
                                e.stopPropagation();
                                handleShareMemory(memory);
                              }}
                            >
                              <Share2 className="h-3.5 w-3.5" strokeWidth={2} style={{ color: US_MATTE_CONTROL.icon }} />
                            </motion.button>
                          </div>
                        </div>
                      </motion.article>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </motion.div>
        ) : null}
      </AnimatePresence>

      {/* Love Note — sent toast */}
      <AnimatePresence>
        {loveNoteSentToast && (
          <motion.div
            className="fixed bottom-28 left-1/2 z-[60] max-w-[min(340px,calc(100vw-2rem))] -translate-x-1/2 rounded-2xl px-4 py-3 shadow-xl"
            style={{
              background: LOVE_NOTE_PANEL.surface,
              border: `1px solid ${LOVE_NOTE_PANEL.border}`,
              boxShadow: LOVE_NOTE_PANEL.shadow,
              backdropFilter: "blur(12px)",
              WebkitBackdropFilter: "blur(12px)",
            }}
            initial={{ opacity: 0, y: 16, scale: 0.94 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 10, scale: 0.96 }}
            transition={{ type: "spring", stiffness: 380, damping: 28 }}
          >
            <p className="text-center text-[12px]" style={{ fontWeight: 500, color: LOVE_NOTE_PANEL_CHROME }}>
              💌 Your note is on its way
            </p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Love Note — opening (partner / preview) */}
      <AnimatePresence>
        {loveNoteOpening && (
          <motion.div className="fixed inset-0 z-[63] flex flex-col items-center justify-center px-6" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            <motion.div
              className="absolute inset-0 bg-[#26282B]/80"
              onClick={() => {
                dismissLoveNoteReader(
                  loveNoteOpening.id,
                  loveNoteOpening.direction === "incoming" && loveNoteOpening.status === "unlocked"
                );
              }}
            />
            <motion.div
              className="relative z-10 w-full max-w-sm rounded-2xl px-6 py-8 text-center"
              style={{
                background: "linear-gradient(165deg, rgba(30,27,40,0.95) 0%, rgba(20,18,28,0.98) 100%)",
                boxShadow: `0 0 60px rgba(${LOVE_NOTE_PANEL_RGB},0.45), 0 0 100px rgba(244,114,182,0.28), 0 0 1px rgba(${LOVE_NOTE_PANEL_RGB},0.35)`,
              }}
              initial={{ scale: 0.85, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              transition={{ type: "spring", stiffness: 260, damping: 24 }}
              onClick={(e) => e.stopPropagation()}
            >
              {loveNoteOpening.direction === "incoming" ? (
                <motion.p
                  className="text-[14px] text-white/95 leading-snug mb-5"
                  style={{ fontWeight: 600 }}
                  initial={{ opacity: 0, y: 6 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.08, duration: 0.4 }}
                >
                  A love note
                </motion.p>
              ) : null}
              <motion.div
                className="text-5xl mb-4"
                initial={{ scale: 0.5, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ delay: 0.15, type: "spring", stiffness: 200, damping: 14 }}
              >
                💌
              </motion.div>
              <motion.p
                className="text-[15px] text-white/95 leading-relaxed mb-3"
                style={{ fontWeight: 400 }}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.35, duration: 0.5 }}
              >
                {loveNoteOpening.body}
              </motion.p>
              {loveNoteOpening.direction === "incoming" ? (
                <p className="mb-6 text-[12px]" style={{ fontWeight: 500, color: "rgba(251,207,232,0.85)" }}>
                  — {partner2Name}
                </p>
              ) : (
                <p className="text-[10px] text-white/45 mb-6" style={{ fontWeight: 300 }}>
                  {loveNoteOpening.status === "waiting"
                    ? loveNoteOpening.triggerKind === "instant"
                      ? `On its way — ${partner2Name} will see it soon`
                      : `On its way — ${partner2Name} will see it when the moment is right`
                    : loveNoteOpening.status === "read"
                      ? "They’ve read what you sent"
                      : "They’ve received it — reading is up to them"}
                </p>
              )}
              <motion.button
                className="mt-2 rounded-full px-4 py-2 text-[11px] backdrop-blur-md"
                style={{
                  background: US_MATTE_CONTROL.bg,
                  border: US_MATTE_CONTROL.border,
                  boxShadow: US_MATTE_CONTROL.shadow,
                  color: CTA_BUTTON_TEXT,
                  fontWeight: 400,
                }}
                onClick={() => {
                  dismissLoveNoteReader(
                    loveNoteOpening.id,
                    loveNoteOpening.direction === "incoming" && loveNoteOpening.status === "unlocked"
                  );
                }}
                whileTap={{ scale: 0.98 }}
              >
                Close
              </motion.button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Wishlist — full page */}
      <AnimatePresence>
        {showWishlist ? (
          <motion.div
            key="wishlist-page"
            className="fixed inset-0 z-[58] flex flex-col overflow-hidden"
            initial={{ opacity: 0, x: 28 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 24 }}
            transition={{ type: "spring", stiffness: 340, damping: 34 }}
          >
            <div
              className="pointer-events-none absolute inset-0"
              style={{
                background: [
                  "linear-gradient(180deg, #faf5ff 0%, #fdf2f8 36%, #f8fafc 72%, #f0fdf9 100%)",
                  "radial-gradient(ellipse 90% 55% at 88% -8%, rgba(196,181,253,0.28), transparent 55%)",
                  "radial-gradient(ellipse 70% 45% at 0% 30%, rgba(251,207,232,0.22), transparent 50%)",
                ].join(", "),
              }}
            />
            <motion.div
              className="pointer-events-none absolute -right-20 -top-24 h-[22rem] w-[22rem] rounded-full blur-[110px]"
              style={{ background: "linear-gradient(135deg, rgba(196,181,253,0.4), rgba(251,207,232,0.35))" }}
              animate={{ opacity: [0.35, 0.55, 0.35], scale: [0.95, 1.06, 0.95] }}
              transition={{ duration: 7, repeat: Infinity, ease: "easeInOut" }}
              aria-hidden
            />

            <div
              className="relative z-10 mx-auto flex h-full w-full max-w-md flex-col"
              style={{ paddingTop: "max(3.5rem, calc(env(safe-area-inset-top) + 2.75rem))" }}
            >
              <div className="flex items-center gap-2 px-4 pb-2 pt-1">
                <motion.button
                  type="button"
                  className="flex h-10 w-10 items-center justify-center rounded-full backdrop-blur-md"
                  style={{
                    background: US_MATTE_CONTROL.bg,
                    border: US_MATTE_CONTROL.borderStrong,
                    boxShadow: US_MATTE_CONTROL.shadow,
                  }}
                  whileTap={{ scale: 0.9 }}
                  aria-label={showWishlistHistory ? "Back to wishlist" : "Back to Us"}
                  onClick={() => {
                    if (showWishlistHistory) {
                      setShowWishlistHistory(false);
                      setDoneArmedWishIndex(null);
                    } else {
                      closeWishlistPage();
                    }
                  }}
                >
                  <ChevronLeft className="h-5 w-5" strokeWidth={2} style={{ color: US_MATTE_CONTROL.icon }} />
                </motion.button>
                <div className="min-w-0 flex-1 text-center">
                  <p
                    className="text-[11px] uppercase tracking-[0.18em]"
                    style={{ fontWeight: 300, color: `rgba(${US_INK_RGB},0.42)` }}
                  >
                    {showWishlistHistory ? "Wish history" : "Wishlist"}
                  </p>
                  <p className="mt-0.5 text-[15px]" style={{ fontWeight: 500, color: `rgba(${US_INK_RGB},0.82)` }}>
                    {showWishlistHistory
                      ? `Gifts you and ${partner2Name} completed`
                      : `Your wishes and ${partner2Name}'s ideas`}
                  </p>
                </div>
                {!showWishlistHistory ? (
                  <motion.button
                    type="button"
                    className="flex h-10 w-10 items-center justify-center rounded-full backdrop-blur-md"
                    style={{
                      background: US_MATTE_CONTROL.bg,
                      border: US_MATTE_CONTROL.borderStrong,
                      boxShadow: US_MATTE_CONTROL.shadow,
                    }}
                    whileTap={{ scale: 0.9 }}
                    aria-label="Completed wishes history"
                    onClick={() => {
                      setShowWishlistHistory(true);
                      setDoneArmedWishIndex(null);
                    }}
                  >
                    <History className="h-5 w-5" strokeWidth={2} style={{ color: US_MATTE_CONTROL.icon }} />
                  </motion.button>
                ) : (
                  <div className="h-10 w-10 shrink-0" aria-hidden />
                )}
              </div>

              <div
                className="relative z-10 mx-auto flex min-h-0 w-full max-w-md flex-1 flex-col overflow-hidden px-4 pt-2"
                style={{ paddingBottom: "max(5.75rem, calc(env(safe-area-inset-bottom, 0px) + 5.25rem))" }}
              >
                {showWishlistHistory ? (
                  <div className="min-h-0 flex-1 space-y-2 overflow-y-auto pr-0.5 [scrollbar-width:thin] [scrollbar-color:rgba(26,26,46,0.1)_transparent] [&::-webkit-scrollbar]:w-[3px] [&::-webkit-scrollbar-track]:bg-transparent [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-thumb]:bg-[rgba(26,26,46,0.1)]">
                    {wishlistHistory.length === 0 ? (
                      <p className="py-10 text-center text-[12px]" style={{ fontWeight: 300, color: "rgba(26,26,46,0.4)" }}>
                        Completed wishes will show up here.
                      </p>
                    ) : (
                      wishlistHistory.map((item, i) => {
                        const forMe = item.direction === "for_me";
                        return (
                          <motion.div
                            key={item.id}
                            className="rounded-xl border px-3 py-2.5 backdrop-blur-sm"
                            style={{
                              background:
                                "linear-gradient(155deg, rgba(255,255,255,0.82) 0%, rgba(255,255,255,0.58) 100%)",
                              borderColor: "rgba(45,45,68,0.1)",
                              boxShadow:
                                "inset 0 1px 0 rgba(255,255,255,0.85), 0 2px 10px rgba(26,26,46,0.04)",
                            }}
                            initial={{ opacity: 0, x: -12 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: Math.min(i * 0.05, 0.25) }}
                          >
                            <div className="flex items-start gap-2.5">
                              <span
                                className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full"
                                style={{
                                  background: forMe ? "rgba(236,253,245,0.9)" : "rgba(253,242,248,0.9)",
                                  border: forMe
                                    ? "1px solid rgba(16,185,129,0.28)"
                                    : "1px solid rgba(251,113,133,0.22)",
                                }}
                              >
                                <Check
                                  className="h-3.5 w-3.5"
                                  strokeWidth={2.5}
                                  style={{ color: forMe ? "#047857" : "#be185d" }}
                                />
                              </span>
                              <div className="min-w-0 flex-1">
                                <p className="text-[13px]" style={{ fontWeight: 500, color: "rgba(26,26,46,0.88)" }}>
                                  {item.title}
                                </p>
                                <p className="mt-0.5 text-[11px]" style={{ fontWeight: 400, color: "rgba(26,26,46,0.5)" }}>
                                  {forMe
                                    ? `${partner2Name} fulfilled this for you`
                                    : `You fulfilled this for ${partner2Name}`}
                                </p>
                                <p className="mt-1 text-[10px]" style={{ fontWeight: 300, color: "rgba(26,26,46,0.38)" }}>
                                  {formatWishHistoryDate(item.completedAt)}
                                </p>
                              </div>
                            </div>
                          </motion.div>
                        );
                      })
                    )}
                  </div>
                ) : (
                  <>
                    <div
                      className="flex shrink-0 gap-1.5 rounded-full p-1"
                      style={{
                        background: "rgba(255,255,255,0.55)",
                        border: "1px solid rgba(45,45,68,0.1)",
                        boxShadow: "inset 0 1px 0 rgba(255,255,255,0.8)",
                      }}
                      role="tablist"
                      aria-label="Wishlist tabs"
                    >
                      {(
                        [
                          { id: "mine" as const, label: "Mine" },
                          { id: "partner" as const, label: partner2Name },
                        ] as const
                      ).map((tab) => {
                        const active = wishlistTab === tab.id;
                        return (
                          <motion.button
                            key={tab.id}
                            type="button"
                            role="tab"
                            aria-selected={active}
                            className="flex-1 rounded-full py-2.5 text-[12px]"
                            style={{
                              fontWeight: active ? 600 : 400,
                              color: active ? AUTH_DATES_CTA.color : "rgba(26,26,46,0.55)",
                              background: active ? AUTH_DATES_CTA.background : "transparent",
                              boxShadow: active ? AUTH_DATES_CTA.shadow : "none",
                            }}
                            whileTap={{ scale: 0.98 }}
                            onClick={() => {
                              setWishlistTab(tab.id);
                              setDoneArmedWishIndex(null);
                            }}
                          >
                            {tab.label}
                          </motion.button>
                        );
                      })}
                    </div>

                    <div className="mt-4 min-h-0 flex-1 space-y-2.5 overflow-y-auto pr-0.5 [scrollbar-width:thin] [scrollbar-color:rgba(26,26,46,0.1)_transparent] [&::-webkit-scrollbar]:w-[3px] [&::-webkit-scrollbar-track]:bg-transparent [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-thumb]:bg-[rgba(26,26,46,0.1)]">
                      {wishlistTab === "mine" ? (
                        myWishlist.length === 0 ? (
                          <p className="py-10 text-center text-[12px]" style={{ fontWeight: 300, color: "rgba(26,26,46,0.4)" }}>
                            Add a photo and caption — {partner2Name} will see it.
                          </p>
                        ) : (
                          myWishlist.map((wish, i) => (
                            <motion.div
                              key={wish.id}
                              className="overflow-hidden rounded-xl border backdrop-blur-sm"
                              style={{
                                background:
                                  "linear-gradient(155deg, rgba(255,255,255,0.82) 0%, rgba(255,255,255,0.58) 100%)",
                                borderColor: "rgba(45,45,68,0.1)",
                                boxShadow: "inset 0 1px 0 rgba(255,255,255,0.85), 0 2px 10px rgba(26,26,46,0.04)",
                              }}
                              initial={{ opacity: 0, x: -12 }}
                              animate={{ opacity: 1, x: 0 }}
                              transition={{ delay: Math.min(i * 0.05, 0.25) }}
                            >
                              <div className="flex items-center gap-3 p-2.5">
                                {wish.photoUrl ? (
                                  <div
                                    className="relative h-[72px] w-[72px] shrink-0 overflow-hidden rounded-lg"
                                    style={{
                                      background: "rgba(26,26,46,0.06)",
                                      border: "1px solid rgba(45,45,68,0.08)",
                                    }}
                                  >
                                    <img
                                      src={wish.photoUrl}
                                      alt=""
                                      className="h-full w-full object-cover"
                                    />
                                  </div>
                                ) : null}
                                <div className="min-w-0 flex-1 py-0.5">
                                  <p className="text-[13px] leading-snug" style={{ fontWeight: 500, color: "rgba(26,26,46,0.88)" }}>
                                    {wish.caption}
                                  </p>
                                </div>
                                <div className="flex shrink-0 items-center gap-1.5 self-center">
                                  <motion.button
                                    type="button"
                                    className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full"
                                    style={{
                                      background: AUTH_DATES_CHROME.background,
                                      border: AUTH_DATES_CHROME.border,
                                      boxShadow: AUTH_DATES_CHROME.shadow,
                                    }}
                                    whileTap={{ scale: 0.9 }}
                                    aria-label={`Remove ${wish.caption}`}
                                    onClick={() => removeMyWish(i)}
                                  >
                                    <X className="h-3.5 w-3.5" strokeWidth={2} style={{ color: AUTH_DATES_CHROME.icon }} />
                                  </motion.button>
                                  {(() => {
                                    const doneArmed = doneArmedWishIndex === i;
                                    return (
                                      <motion.button
                                        type="button"
                                        className="flex h-7 items-center gap-1 rounded-full px-2"
                                        style={
                                          doneArmed
                                            ? {
                                                background: "rgba(236,253,245,0.9)",
                                                border: "1px solid rgba(16,185,129,0.28)",
                                                boxShadow: "0 2px 8px rgba(16,185,129,0.12)",
                                              }
                                            : {
                                                background: AUTH_DATES_CHROME.background,
                                                border: AUTH_DATES_CHROME.border,
                                                boxShadow: AUTH_DATES_CHROME.shadow,
                                                opacity: 0.72,
                                              }
                                        }
                                        whileTap={{ scale: 0.9 }}
                                        aria-label={
                                          doneArmed
                                            ? `Confirm ${wish.caption} as done`
                                            : `Mark ${wish.caption} as done`
                                        }
                                        aria-pressed={doneArmed}
                                        onClick={() => handleMineWishDone(i)}
                                      >
                                        <Check
                                          className="h-3.5 w-3.5"
                                          strokeWidth={2.5}
                                          style={{ color: doneArmed ? "#047857" : AUTH_DATES_CHROME.icon }}
                                        />
                                        <span
                                          className="text-[10px]"
                                          style={{
                                            fontWeight: 600,
                                            color: doneArmed ? "#047857" : "rgba(26,26,46,0.45)",
                                          }}
                                        >
                                          {doneArmed ? "Confirm" : "Done"}
                                        </span>
                                      </motion.button>
                                    );
                                  })()}
                                </div>
                              </div>
                            </motion.div>
                          ))
                        )
                      ) : partnerWishes.length === 0 ? (
                        <p className="py-10 text-center text-[12px]" style={{ fontWeight: 300, color: "rgba(26,26,46,0.4)" }}>
                          {partner2Name} hasn&apos;t added wishes yet.
                        </p>
                      ) : (
                        partnerWishes.map((wish, i) => (
                          <motion.div
                            key={wish.id}
                            className="overflow-hidden rounded-xl border backdrop-blur-sm"
                            style={{
                              background:
                                "linear-gradient(155deg, rgba(255,255,255,0.82) 0%, rgba(255,255,255,0.58) 100%)",
                              borderColor: "rgba(45,45,68,0.1)",
                              boxShadow: "inset 0 1px 0 rgba(255,255,255,0.85), 0 2px 10px rgba(26,26,46,0.04)",
                            }}
                            initial={{ opacity: 0, x: -12 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: Math.min(i * 0.05, 0.25) }}
                          >
                              <div className="flex items-center gap-3 p-2.5">
                              {wish.photoUrl ? (
                                <div
                                  className="relative h-[72px] w-[72px] shrink-0 overflow-hidden rounded-lg"
                                  style={{
                                    background: "rgba(26,26,46,0.06)",
                                    border: "1px solid rgba(45,45,68,0.08)",
                                  }}
                                >
                                  <img
                                    src={wish.photoUrl}
                                    alt=""
                                    className="h-full w-full object-cover"
                                  />
                                </div>
                              ) : null}
                              <div className="min-w-0 flex-1 py-0.5">
                                <p className="text-[13px] leading-snug" style={{ fontWeight: 500, color: "rgba(26,26,46,0.88)" }}>
                                  {wish.caption}
                                </p>
                              </div>
                            </div>
                          </motion.div>
                        ))
                      )}
                    </div>

                    {wishlistTab === "mine" ? (
                      <motion.button
                        type="button"
                        className="mt-3 flex h-12 w-full shrink-0 items-center justify-center gap-2 rounded-xl"
                        style={{
                          background: AUTH_DATES_CTA.background,
                          color: AUTH_DATES_CTA.color,
                          boxShadow: AUTH_DATES_CTA.shadow,
                          border: "1px solid rgba(255,255,255,0.08)",
                          fontWeight: 600,
                        }}
                        whileTap={{ scale: 0.98 }}
                        onClick={openAddWishModal}
                      >
                        <Plus className="h-4 w-4" strokeWidth={2.5} />
                        <span className="text-[13px]">Add a wish</span>
                      </motion.button>
                    ) : null}
                  </>
                )}
              </div>
            </div>
          </motion.div>
        ) : null}
      </AnimatePresence>

      {/* Add wish modal */}
      <AnimatePresence>
        {showAddWishModal ? (
          <motion.div
            className="fixed inset-0 z-[62] flex items-center justify-center px-5"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
          >
            <motion.div
              className="absolute inset-0"
              style={{
                background: "rgba(26,26,46,0.32)",
                backdropFilter: "blur(10px)",
                WebkitBackdropFilter: "blur(10px)",
              }}
              onClick={closeAddWishModal}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            />
            <motion.div
              className="relative w-full max-w-sm overflow-hidden rounded-[1.5rem] border shadow-2xl backdrop-blur-2xl"
              style={{
                background: AUTH_DATES_CALENDAR_GLASS.surface,
                borderColor: AUTH_DATES_CALENDAR_GLASS.border,
                boxShadow: AUTH_DATES_CALENDAR_GLASS.shadow,
              }}
              initial={{ opacity: 0, scale: 0.94, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.94, y: 16 }}
              transition={{ type: "spring", stiffness: 300, damping: 28 }}
              onClick={(e) => e.stopPropagation()}
            >
              <div className="h-[3px] w-full" style={{ background: AUTH_DATES_CALENDAR_GLASS.topHairline }} />
              <motion.button
                type="button"
                className="absolute right-3.5 top-3.5 z-10 rounded-full p-1.5 backdrop-blur-md"
                style={{
                  background: AUTH_DATES_CHROME.background,
                  border: AUTH_DATES_CHROME.border,
                  boxShadow: AUTH_DATES_CHROME.shadow,
                }}
                onClick={closeAddWishModal}
                whileTap={{ scale: 0.85 }}
                aria-label="Close"
              >
                <X className="h-4 w-4" strokeWidth={2} style={{ color: AUTH_DATES_CHROME.icon }} />
              </motion.button>

              <div className="px-5 pb-5 pt-6">
                <p className="text-center text-[15px]" style={{ fontWeight: 600, color: "rgba(26,26,46,0.9)" }}>
                  Add a wish
                </p>
                <p className="mt-1 text-center text-[11px]" style={{ fontWeight: 300, color: "rgba(26,26,46,0.45)" }}>
                  Upload a photo and leave a short caption
                </p>

                <div className="relative mt-4">
                  <label
                    className="relative flex h-40 w-full cursor-pointer flex-col items-center justify-center overflow-hidden rounded-2xl border border-dashed"
                    style={{
                      borderColor: wishlistDraftPhotoUrl ? "rgba(45,45,68,0.12)" : "rgba(45,45,68,0.2)",
                      background: "rgba(255,255,255,0.65)",
                    }}
                  >
                    {wishlistDraftPhotoUrl ? (
                      <img
                        src={wishlistDraftPhotoUrl}
                        alt=""
                        className="absolute inset-0 h-full w-full object-cover"
                      />
                    ) : (
                      <>
                        <Image className="h-6 w-6" strokeWidth={1.75} style={{ color: "rgba(26,26,46,0.35)" }} />
                        <span className="mt-2 text-[12px]" style={{ fontWeight: 500, color: "rgba(26,26,46,0.48)" }}>
                          Upload photo
                        </span>
                      </>
                    )}
                    <input
                      type="file"
                      accept="image/*"
                      className="sr-only"
                      onChange={handleWishlistDraftPhotoFile}
                    />
                  </label>
                  {wishlistDraftPhotoUrl ? (
                    <motion.button
                      type="button"
                      className="absolute right-2 top-2 z-10 rounded-full p-1.5 backdrop-blur-md"
                      style={{
                        background: AUTH_DATES_CHROME.background,
                        border: AUTH_DATES_CHROME.border,
                        boxShadow: AUTH_DATES_CHROME.shadow,
                      }}
                      whileTap={{ scale: 0.85 }}
                      aria-label="Remove photo"
                      onClick={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        clearWishlistDraftPhoto();
                      }}
                    >
                      <X className="h-3.5 w-3.5" strokeWidth={2} style={{ color: AUTH_DATES_CHROME.icon }} />
                    </motion.button>
                  ) : null}
                </div>

                <input
                  value={wishlistDraft}
                  onChange={(e) => setWishlistDraft(e.target.value.slice(0, 80))}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") {
                      e.preventDefault();
                      addMyWish();
                    }
                  }}
                  placeholder="Write a caption…"
                  className="mt-3 w-full rounded-xl px-3 py-3 text-[13px] outline-none"
                  style={{
                    border: AUTH_DATES_INPUT.border,
                    background: AUTH_DATES_INPUT.background,
                    boxShadow: "inset 0 1px 0 rgba(255,255,255,0.7)",
                    color: "#1a1a2e",
                  }}
                  autoFocus
                />
                <p className="mt-1 text-right text-[10px]" style={{ fontWeight: 300, color: "rgba(26,26,46,0.38)" }}>
                  {wishlistDraft.length}/80
                </p>

                <motion.button
                  type="button"
                  className="mt-3 flex h-12 w-full items-center justify-center gap-2 rounded-xl"
                  style={{
                    background: wishlistDraft.trim() ? AUTH_DATES_CTA.background : "rgba(26,26,46,0.1)",
                    color: wishlistDraft.trim() ? AUTH_DATES_CTA.color : "rgba(26,26,46,0.4)",
                    boxShadow: wishlistDraft.trim() ? AUTH_DATES_CTA.shadow : "none",
                    border: "1px solid rgba(255,255,255,0.08)",
                    fontWeight: 600,
                  }}
                  whileTap={{ scale: wishlistDraft.trim() ? 0.98 : 1 }}
                  disabled={!wishlistDraft.trim()}
                  onClick={addMyWish}
                >
                  <Plus className="h-4 w-4" strokeWidth={2.5} />
                  Save wish
                </motion.button>
              </div>
            </motion.div>
          </motion.div>
        ) : null}
      </AnimatePresence>
    </div>
  );
}
