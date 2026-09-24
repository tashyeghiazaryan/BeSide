import { useState, useRef, useEffect, useCallback, type KeyboardEvent, type ReactNode, type ChangeEvent } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Heart, ArrowRight, RotateCcw, Check, Mail, Sparkle, Camera, User, ChevronLeft } from "lucide-react";

type AuthStep = "email" | "otp" | "onboarding";
const STEP_ORDER: AuthStep[] = ["email", "otp", "onboarding"];

interface AuthScreenProps {
  onAuthenticated: () => void;
}
function EmailStep({
  onNext,
}: {
  onNext: (email: string) => void;
}) {
  const [email, setEmail] = useState("");
  const [emailError, setEmailError] = useState("");
  const [termsError, setTermsError] = useState("");
  const [loading, setLoading] = useState(false);
  const [termsAccepted, setTermsAccepted] = useState(false);

  const isValidEmail = (v: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.trim());
  const canSubmit = termsAccepted && !loading;

  const handleSubmit = () => {
    const trimmed = email.trim();
    let nextEmailError = "";
    let nextTermsError = "";

    if (!trimmed) {
      nextEmailError = "Email is required";
    } else if (!isValidEmail(trimmed)) {
      nextEmailError = "Enter a valid email address";
    }

    if (!termsAccepted) {
      nextTermsError = "You must accept the terms to continue";
    }

    setEmailError(nextEmailError);
    setTermsError(nextTermsError);

    if (nextEmailError || nextTermsError) return;

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      onNext(trimmed);
    }, 1100);
  };

  return (
    <motion.div
      key="email-step"
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -24 }}
      transition={{ duration: 0.38, ease: [0.25, 0.46, 0.45, 0.94] }}
    >
      <p
        className="text-[10px] uppercase tracking-[0.12em] mb-5"
        style={{ color: "rgba(0,0,0,0.28)", fontWeight: 400 }}
      >
        Email address
      </p>

      <div className="relative mb-3">
        <Mail
          className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4"
          style={{ color: "rgba(0,0,0,0.3)" }}
        />
        <input
          type="email"
          placeholder="your@email.com"
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            if (emailError) setEmailError("");
          }}
          onKeyDown={(e) => e.key === "Enter" && handleSubmit()}
          autoFocus
          className="w-full pl-11 pr-4 py-3.5 rounded-2xl text-sm outline-none transition-all duration-200"
          style={{
            background: email ? "rgba(255,255,255,0.9)" : "rgba(0,0,0,0.04)",
            border: emailError
              ? "1px solid rgba(251,113,133,0.6)"
              : email
              ? "1px solid #2d2d44"
              : "1px solid rgba(0,0,0,0.06)",
            color: "rgba(0,0,0,0.8)",
            fontWeight: 300,
            letterSpacing: "0.01em",
            caretColor: "#2d2d44",
          }}
        />
      </div>

      <AnimatePresence>
        {emailError && (
          <motion.p
            key="email-error"
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            className="text-xs mb-3 pl-1"
            style={{ color: "#fb7185", fontWeight: 300 }}
          >
            {emailError}
          </motion.p>
        )}
      </AnimatePresence>

      <p className="text-xs mb-5 pl-1" style={{ color: "rgba(0,0,0,0.28)", fontWeight: 300 }}>
        {"We'll send a 6-digit code to verify your account"}
      </p>

      <label className="mb-2 flex cursor-pointer items-start gap-3 select-none">
        <span className="relative mt-0.5 flex h-4 w-4 shrink-0 items-center justify-center">
          <input
            type="checkbox"
            checked={termsAccepted}
            onChange={(e) => {
              setTermsAccepted(e.target.checked);
              if (termsError) setTermsError("");
            }}
            className="absolute inset-0 z-10 cursor-pointer opacity-0"
            aria-label="Agree to the Terms of Service and Privacy Policy"
          />
          <span
            className="flex h-4 w-4 items-center justify-center rounded-[5px] border transition-all duration-200"
            style={{
              background: termsAccepted
                ? "linear-gradient(135deg, #1a1a2e, #2d2d44)"
                : "rgba(255,255,255,0.85)",
              borderColor: termsError
                ? "rgba(251,113,133,0.7)"
                : termsAccepted
                ? "rgba(45,45,68,0.9)"
                : "rgba(0,0,0,0.18)",
              boxShadow: termsAccepted
                ? "0 1px 4px rgba(26,26,46,0.2)"
                : "inset 0 1px 0 rgba(255,255,255,0.8)",
            }}
          >
            {termsAccepted && <Check className="h-2.5 w-2.5 text-white" strokeWidth={3} />}
          </span>
        </span>
        <span
          className="text-[10px] leading-relaxed"
          style={{ color: "rgba(0,0,0,0.35)", fontWeight: 300 }}
        >
          I agree to the{" "}
          <span style={{ color: "rgba(0,0,0,0.5)", fontWeight: 400 }}>Terms of Service</span>
          {" "}and{" "}
          <span style={{ color: "rgba(0,0,0,0.5)", fontWeight: 400 }}>Privacy Policy</span>
        </span>
      </label>

      <AnimatePresence>
        {termsError && (
          <motion.p
            key="terms-error"
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            className="text-xs mb-4 pl-1"
            style={{ color: "#fb7185", fontWeight: 300 }}
          >
            {termsError}
          </motion.p>
        )}
      </AnimatePresence>

      {!termsError && <div className="mb-2" />}

      <motion.button
        type="button"
        onClick={handleSubmit}
        disabled={loading}
        className="w-full py-4 rounded-2xl flex items-center justify-center gap-2.5 relative overflow-hidden transition-opacity duration-200"
        style={{
          background: canSubmit
            ? "linear-gradient(135deg, #1a1a2e, #2d2d44)"
            : "rgba(0,0,0,0.08)",
          color: canSubmit ? "rgba(255,255,255,0.92)" : "rgba(0,0,0,0.3)",
          fontWeight: 300,
          letterSpacing: "0.04em",
          fontSize: "0.875rem",
          cursor: loading ? "not-allowed" : "pointer",
        }}
        whileTap={loading ? {} : { scale: 0.985 }}
        transition={{ duration: 0.15 }}
      >
        {loading ? (
          <motion.div
            className="w-5 h-5 rounded-full border-2 border-white/30 border-t-white/80"
            animate={{ rotate: 360 }}
            transition={{ duration: 0.8, repeat: Infinity, ease: "linear" }}
          />
        ) : (
          <>
            <span>Send verification code</span>
            <ArrowRight className="w-4 h-4 opacity-70" />
          </>
        )}
      </motion.button>
    </motion.div>
  );
}

const DEMO_VALID_OTP = "123456";
const DEMO_EXPIRED_OTP = "999999";
const OTP_MAX_ATTEMPTS = 3;

function OtpStep({
  email,
  onVerified,
  onBack,
}: {
  email: string;
  onVerified: () => void;
  onBack: () => void;
}) {
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [resent, setResent] = useState(false);
  const [failedAttempts, setFailedAttempts] = useState(0);
  const [locked, setLocked] = useState(false);
  const inputRef = useRef<HTMLInputElement | null>(null);

  const isComplete = code.length === 6;
  const canSubmit = isComplete && !loading && !locked;

  const verify = useCallback(
    (value: string) => {
      if (value.length !== 6 || loading) return;
      if (locked) {
        setError("Too many failed attempts. Try again in 15 minutes");
        return;
      }

      setLoading(true);
      setTimeout(() => {
        setLoading(false);

        if (value === DEMO_EXPIRED_OTP) {
          setError("Code expired. Please request a new one");
          return;
        }

        if (value === DEMO_VALID_OTP) {
          setError("");
          onVerified();
          return;
        }

        setFailedAttempts((prev) => {
          const next = prev + 1;
          if (next >= OTP_MAX_ATTEMPTS) {
            setLocked(true);
            setError("Too many failed attempts. Try again in 15 minutes");
          } else {
            setError("Invalid code.");
          }
          return next;
        });
      }, 900);
    },
    [locked, loading, onVerified],
  );

  const handleChange = (value: string) => {
    const next = value.slice(0, 6);
    setCode(next);
    if (error && !locked) setError("");
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter" && canSubmit) verify(code);
  };

  const handleResend = () => {
    if (locked) return;
    setResent(true);
    setCode("");
    setError("");
    setFailedAttempts(0);
    inputRef.current?.focus();
    setTimeout(() => setResent(false), 3000);
  };

  const maskedEmail = email.replace(/(.{2}).+(@.+)/, "$1•••$2");

  return (
    <motion.div
      key="otp-step"
      initial={{ opacity: 0, x: 24 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: 20 }}
      transition={{ duration: 0.38, ease: [0.25, 0.46, 0.45, 0.94] }}
    >
      <p
        className="text-[10px] uppercase tracking-[0.12em] mb-2"
        style={{ color: "rgba(0,0,0,0.28)", fontWeight: 400 }}
      >
        Check your email
      </p>
      <p className="text-sm mb-1" style={{ color: "rgba(0,0,0,0.55)", fontWeight: 300 }}>
        We sent a verification code to{" "}
        <span style={{ color: "rgba(0,0,0,0.7)" }}>{maskedEmail}</span>
      </p>
      <p
        className="text-[11px] uppercase tracking-[0.1em] mt-5 mb-3"
        style={{ color: "rgba(0,0,0,0.3)", fontWeight: 400 }}
      >
        Enter the 6-digit code
      </p>

      <div className="mb-3">
        <input
          ref={inputRef}
          type="text"
          inputMode="text"
          maxLength={6}
          value={code}
          onChange={(e) => handleChange(e.target.value)}
          onKeyDown={handleKeyDown}
          autoFocus
          disabled={locked}
          placeholder="••••••"
          className="w-full text-center rounded-2xl outline-none transition-all duration-200 text-lg placeholder-gray-300 disabled:opacity-60"
          style={{
            height: "3.25rem",
            background: code ? "rgba(255,255,255,0.9)" : "rgba(0,0,0,0.04)",
            border: error
              ? "1px solid rgba(251,113,133,0.6)"
              : code
              ? "1px solid #2d2d44"
              : "1px solid rgba(0,0,0,0.07)",
            color: "rgba(0,0,0,0.8)",
            fontWeight: 300,
            letterSpacing: "0.5em",
            caretColor: "#2d2d44",
          }}
        />
      </div>

      <AnimatePresence>
        {error && (
          <motion.p
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            className="text-xs mb-3 pl-1"
            style={{ color: "#fb7185", fontWeight: 300 }}
          >
            {error}
          </motion.p>
        )}
      </AnimatePresence>

      <div className="flex items-center justify-between mb-6 px-0.5">
        <AnimatePresence mode="wait">
          {resent ? (
            <motion.span
              key="resent"
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="text-xs flex items-center gap-1.5"
              style={{ color: "#4ade80", fontWeight: 300 }}
            >
              <Check className="w-3.5 h-3.5" /> Code resent
            </motion.span>
          ) : (
            <motion.span
              key="resend-btn"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="text-xs flex items-center gap-1.5"
              style={{ color: "rgba(0,0,0,0.35)", fontWeight: 300 }}
            >
              Didn&apos;t get the code?{" "}
              <button
                onClick={handleResend}
                disabled={locked}
                className="inline-flex items-center gap-0.5 text-[10px] disabled:opacity-40"
                style={{ color: "rgba(0,0,0,0.75)", fontWeight: 500 }}
              >
                <RotateCcw className="w-2.5 h-2.5" /> Resend
              </button>
            </motion.span>
          )}
        </AnimatePresence>
      </div>

      <motion.button
        onClick={() => verify(code)}
        disabled={!canSubmit}
        className="w-full py-4 rounded-2xl flex items-center justify-center gap-2.5 transition-opacity duration-200"
        style={{
          background: canSubmit
            ? "linear-gradient(135deg, #1a1a2e, #2d2d44)"
            : "rgba(0,0,0,0.08)",
          color: canSubmit ? "rgba(255,255,255,0.92)" : "rgba(0,0,0,0.3)",
          fontWeight: 300,
          letterSpacing: "0.04em",
          fontSize: "0.875rem",
          cursor: canSubmit ? "pointer" : "not-allowed",
        }}
        whileTap={canSubmit ? { scale: 0.985 } : {}}
        transition={{ duration: 0.15 }}
      >
        {loading ? (
          <motion.div
            className="w-5 h-5 rounded-full border-2 border-white/30 border-t-white/80"
            animate={{ rotate: 360 }}
            transition={{ duration: 0.8, repeat: Infinity, ease: "linear" }}
          />
        ) : (
          <>
            <span>Continue</span>
            <ArrowRight className="w-4 h-4 opacity-70" />
          </>
        )}
      </motion.button>
    </motion.div>
  );
}

function CtaButton({
  onClick,
  disabled = false,
  label,
  icon = <ArrowRight className="w-4 h-4 opacity-70" />,
}: {
  onClick: () => void;
  disabled?: boolean;
  label: string;
  icon?: ReactNode;
}) {
  return (
    <motion.button
      onClick={onClick}
      disabled={disabled}
      className="w-full py-4 rounded-2xl flex items-center justify-center gap-2.5 transition-opacity duration-200"
      style={{
        background: disabled ? "rgba(0,0,0,0.08)" : "linear-gradient(135deg, #1a1a2e, #2d2d44)",
        color: disabled ? "rgba(0,0,0,0.3)" : "rgba(255,255,255,0.92)",
        fontWeight: 300,
        letterSpacing: "0.04em",
        fontSize: "0.875rem",
        cursor: disabled ? "not-allowed" : "pointer",
      }}
      whileTap={disabled ? {} : { scale: 0.985 }}
      transition={{ duration: 0.15 }}
    >
      <span>{label}</span>
      {icon}
    </motion.button>
  );
}

function QuestionHeader({ title, subtitle }: { title: string; subtitle: string }) {
  return (
    <>
      <p className="text-base mb-1.5" style={{ color: "rgba(0,0,0,0.75)", fontWeight: 400 }}>
        {title}
      </p>
      <p className="text-sm" style={{ color: "rgba(0,0,0,0.45)", fontWeight: 300 }}>
        {subtitle}
      </p>
    </>
  );
}

function BackButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="flex items-center gap-0.5 text-xs -ml-1"
      style={{ color: "rgba(0,0,0,0.4)", fontWeight: 300 }}
    >
      <ChevronLeft className="w-4 h-4" /> Back
    </button>
  );
}

function SkipButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="text-xs -mr-1"
      style={{ color: "rgba(0,0,0,0.4)", fontWeight: 300 }}
    >
      Skip
    </button>
  );
}

const WHEEL_ITEM_H = 40;
const WHEEL_VISIBLE = 5;

function DateWheelColumn({
  options,
  value,
  onChange,
  pad = 2,
  fallbackIndex = 0,
}: {
  options: number[];
  value: number | null;
  onChange: (n: number) => void;
  pad?: number;
  fallbackIndex?: number;
}) {
  const listRef = useRef<HTMLDivElement | null>(null);
  const scrollEndTimer = useRef<number | null>(null);
  const suppressCommit = useRef(false);
  const padCount = Math.floor(WHEEL_VISIBLE / 2);

  useEffect(() => {
    const el = listRef.current;
    if (!el || options.length === 0) return;
    const idx =
      value != null && options.includes(value)
        ? options.indexOf(value)
        : Math.max(0, Math.min(options.length - 1, fallbackIndex));
    suppressCommit.current = true;
    el.scrollTop = idx * WHEEL_ITEM_H;
    const t = window.setTimeout(() => {
      suppressCommit.current = false;
    }, 120);
    return () => window.clearTimeout(t);
  }, [value, options, fallbackIndex]);

  const commitFromScroll = () => {
    if (suppressCommit.current) return;
    const el = listRef.current;
    if (!el) return;
    const idx = Math.round(el.scrollTop / WHEEL_ITEM_H);
    const clamped = Math.max(0, Math.min(options.length - 1, idx));
    const next = options[clamped];
    el.scrollTo({ top: clamped * WHEEL_ITEM_H, behavior: "smooth" });
    if (next != null) onChange(next);
  };

  return (
    <div className="relative h-[200px] flex-1 overflow-hidden">
      <div
        className="pointer-events-none absolute inset-x-1 top-1/2 z-10 h-10 -translate-y-1/2 rounded-xl"
        style={{
          background: "rgba(255,255,255,0.72)",
          border: "1px solid rgba(45,45,68,0.14)",
          boxShadow: "0 2px 10px rgba(26,26,46,0.06)",
        }}
      />
      <div
        className="pointer-events-none absolute inset-x-0 top-0 z-[5] h-16"
        style={{
          background: "linear-gradient(180deg, rgba(255,255,255,0.96), rgba(255,255,255,0))",
        }}
      />
      <div
        className="pointer-events-none absolute inset-x-0 bottom-0 z-[5] h-16"
        style={{
          background: "linear-gradient(0deg, rgba(255,255,255,0.96), rgba(255,255,255,0))",
        }}
      />
      <div
        ref={listRef}
        className="h-full overflow-y-auto overscroll-contain"
        style={{
          scrollSnapType: "y mandatory",
          WebkitOverflowScrolling: "touch",
        }}
        onScroll={() => {
          if (suppressCommit.current) return;
          if (scrollEndTimer.current) window.clearTimeout(scrollEndTimer.current);
          scrollEndTimer.current = window.setTimeout(commitFromScroll, 90);
        }}
      >
        <div style={{ height: padCount * WHEEL_ITEM_H }} />
        {options.map((n) => {
          const selected = value === n;
          return (
            <button
              key={n}
              type="button"
              className="flex w-full items-center justify-center"
              style={{
                height: WHEEL_ITEM_H,
                scrollSnapAlign: "center",
                color: selected ? "rgba(0,0,0,0.82)" : "rgba(0,0,0,0.28)",
                fontWeight: selected ? 500 : 300,
                fontSize: selected ? "1.05rem" : "0.9rem",
              }}
              onClick={() => {
                onChange(n);
                const idx = options.indexOf(n);
                suppressCommit.current = true;
                listRef.current?.scrollTo({ top: idx * WHEEL_ITEM_H, behavior: "smooth" });
                window.setTimeout(() => {
                  suppressCommit.current = false;
                }, 180);
              }}
            >
              {String(n).padStart(pad, "0")}
            </button>
          );
        })}
        <div style={{ height: padCount * WHEEL_ITEM_H }} />
      </div>
    </div>
  );
}

// Reacts like the "Enter the 6-digit code" field: dark contour + white fill when filled.
function fieldStyle(filled: boolean, hasError = false) {
  return {
    background: filled ? "rgba(255,255,255,0.9)" : "rgba(0,0,0,0.04)",
    border: hasError
      ? "1px solid rgba(251,113,133,0.6)"
      : filled
      ? "1px solid #2d2d44"
      : "1px solid rgba(0,0,0,0.06)",
    color: "rgba(0,0,0,0.8)",
    fontWeight: 300,
    letterSpacing: "0.01em",
    caretColor: "#2d2d44",
  } as const;
}

function validateOnboardingName(value: string): string {
  if (value.length === 0) return "Name is required";
  if (value.trim().length === 0) return "Please enter a valid name";

  const trimmed = value.trim();
  if (trimmed.length < 3) return "Name must be at least 3 characters long";
  if (trimmed.length > 15) return "Name cannot exceed 15 characters";
  if (/[\u0400-\u04FF]/.test(trimmed)) return "Please use Latin letters only";
  if (!/^[A-Za-z\- ]+$/.test(trimmed)) {
    return "Name can only contain letters, hyphens, and spaces";
  }
  return "";
}

function OnboardingStep({
  onDone,
  onPhaseChange,
  onPhotoPermissionPrompt,
}: {
  onDone: () => void;
  onPhaseChange?: (phase: number) => void;
  onPhotoPermissionPrompt?: (
    prompt: { onAllow: () => void; onDeny: () => void } | null
  ) => void;
}) {
  // phase: 0 = welcome, 1..4 = questions
  const [phase, setPhase] = useState(0);
  const [name, setName] = useState("");
  const [nameError, setNameError] = useState("");
  const [birthDay, setBirthDay] = useState("");
  const [birthMonth, setBirthMonth] = useState("");
  const [birthYear, setBirthYear] = useState("");
  const [birthdayError, setBirthdayError] = useState("");
  const [birthPickerOpen, setBirthPickerOpen] = useState(false);
  const [photo, setPhoto] = useState<string | null>(null);
  const [photoError, setPhotoError] = useState("");
  const [photoPermission, setPhotoPermission] = useState<"unknown" | "granted" | "denied">("unknown");
  const [gender, setGender] = useState<"male" | "female" | null>(null);
  const fileRef = useRef<HTMLInputElement | null>(null);

  const currentYear = new Date().getFullYear();
  const yearOptions = Array.from({ length: currentYear - 1950 + 1 }, (_, i) => currentYear - i);
  const monthOptions = Array.from({ length: 12 }, (_, i) => i + 1);
  const selectedMonth = birthMonth ? Number(birthMonth) : 1;
  const selectedYear = birthYear ? Number(birthYear) : currentYear - 18;
  const daysInSelectedMonth = new Date(selectedYear, selectedMonth, 0).getDate();
  const dayOptions = Array.from({ length: daysInSelectedMonth }, (_, i) => i + 1);

  useEffect(() => {
    onPhaseChange?.(phase);
  }, [phase, onPhaseChange]);

  useEffect(() => {
    return () => {
      onPhotoPermissionPrompt?.(null);
    };
  }, [onPhotoPermissionPrompt]);

  const handlePhoto = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setPhoto(URL.createObjectURL(file));
      setPhotoError("");
    }
    // Allow selecting the same file again later.
    e.target.value = "";
  };

  const openPhotoLibrary = () => {
    fileRef.current?.click();
  };

  const closePhotoPermissionPrompt = () => {
    onPhotoPermissionPrompt?.(null);
  };

  const requestPhotoAccess = () => {
    setPhotoError("");
    if (photoPermission === "granted") {
      openPhotoLibrary();
      return;
    }
    if (photoPermission === "denied") {
      setPhotoError("Allow access to your photos in Settings to choose a profile picture");
      return;
    }
    onPhotoPermissionPrompt?.({
      onAllow: () => {
        setPhotoPermission("granted");
        closePhotoPermissionPrompt();
        setPhotoError("");
        window.setTimeout(() => openPhotoLibrary(), 120);
      },
      onDeny: () => {
        setPhotoPermission("denied");
        closePhotoPermissionPrompt();
        setPhotoError("Allow access to your photos in Settings to choose a profile picture");
      },
    });
  };

  const handleNameContinue = () => {
    const err = validateOnboardingName(name);
    setNameError(err);
    if (!err) setPhase(2);
  };

  const hasAnyBirthPart =
    birthDay.length > 0 || birthMonth.length > 0 || birthYear.length > 0;

  const validateBirthday = (d: string, m: string, y: string): string => {
    if (!d || !m || !y) return "Please enter a complete date";

    const day = Number(d);
    const month = Number(m);
    const year = Number(y);
    if (!Number.isInteger(day) || !Number.isInteger(month) || !Number.isInteger(year)) {
      return "Enter a valid date";
    }

    if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1950) {
      return "Enter a valid date";
    }

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    if (year > now.getFullYear()) return "Enter a valid date";

    const date = new Date(year, month - 1, day);
    if (
      date.getFullYear() !== year ||
      date.getMonth() !== month - 1 ||
      date.getDate() !== day
    ) {
      return "Enter a valid date";
    }

    if (date > today) return "Enter a valid date";

    const turns18 = new Date(year + 18, month - 1, day);
    if (turns18 > today) {
      return "You must be at least 18 years old to register";
    }

    return "";
  };

  const handleBirthdayContinue = () => {
    const err = validateBirthday(birthDay, birthMonth, birthYear);
    setBirthdayError(err);
    if (!err) {
      setBirthPickerOpen(false);
      setPhase(3);
    }
  };

  const openBirthPicker = () => {
    if (birthdayError) setBirthdayError("");
    setBirthPickerOpen(true);
  };

  const setDayFromWheel = (n: number) => {
    if (birthdayError) setBirthdayError("");
    setBirthDay(String(n).padStart(2, "0"));
  };
  const setMonthFromWheel = (n: number) => {
    if (birthdayError) setBirthdayError("");
    setBirthMonth(String(n).padStart(2, "0"));
    const maxDay = new Date(selectedYear, n, 0).getDate();
    if (birthDay && Number(birthDay) > maxDay) {
      setBirthDay(String(maxDay).padStart(2, "0"));
    }
  };
  const setYearFromWheel = (n: number) => {
    if (birthdayError) setBirthdayError("");
    setBirthYear(String(n));
    const maxDay = new Date(n, selectedMonth, 0).getDate();
    if (birthDay && Number(birthDay) > maxDay) {
      setBirthDay(String(maxDay).padStart(2, "0"));
    }
  };

  const birthFieldStyle = (value: string) =>
    fieldStyle(value.length > 0, !!birthdayError);

  const stepMotion = {
    initial: { opacity: 0, x: 20 },
    animate: { opacity: 1, x: 0 },
    exit: { opacity: 0, x: -20 },
    transition: { duration: 0.35, ease: [0.25, 0.46, 0.45, 0.94] as const },
  };

  return (
    <AnimatePresence mode="wait">
      {phase === 0 && (
        <motion.div key="ob-welcome" {...stepMotion}>
          <p
            className="text-[10px] uppercase tracking-[0.12em] mb-2"
            style={{ color: "rgba(0,0,0,0.28)", fontWeight: 400 }}
          >
            Welcome to beside
          </p>
          <p className="text-sm mb-5" style={{ color: "rgba(0,0,0,0.55)", fontWeight: 300 }}>
            A small reason to connect every day.
          </p>

          <div className="space-y-3 mb-6">
            {[
              { icon: Heart, title: "Share your mood", text: "Let your partner know how you feel." },
              { icon: Check, title: "Daily rituals", text: "Small moments to stay connected." },
              { icon: Sparkle, title: "Grow together", text: "Build your shared journey, one day at a time." },
            ].map((f) => {
              const FIcon = f.icon;
              return (
                <div key={f.title} className="flex items-start gap-3">
                  <div
                    className="w-9 h-9 rounded-full flex items-center justify-center shrink-0 border border-white/60"
                    style={{
                      background: "linear-gradient(135deg, rgba(255,228,232,0.85), rgba(255,255,255,0.6))",
                    }}
                  >
                    <FIcon className="w-4 h-4 text-rose-400" />
                  </div>
                  <div>
                    <p className="text-sm" style={{ color: "rgba(0,0,0,0.7)", fontWeight: 400 }}>
                      {f.title}
                    </p>
                    <p className="text-xs" style={{ color: "rgba(0,0,0,0.4)", fontWeight: 300 }}>
                      {f.text}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>

          <CtaButton
            label="Let’s begin"
            icon={<ArrowRight className="w-4 h-4 opacity-70" />}
            onClick={() => setPhase(1)}
          />
        </motion.div>
      )}

      {/* Q1 — name */}
      {phase === 1 && (
        <motion.div key="ob-q1" className="flex flex-col flex-1 w-full" style={{ minHeight: 440 }} {...stepMotion}>
          <div className="h-6 mb-3" />
          <QuestionHeader
            title="What should we call you?"
            subtitle="Your name, so we can make this feel more personal."
          />
          <div className="flex-1 flex flex-col items-center justify-start gap-3 pt-6">
            <input
              type="text"
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                if (nameError) setNameError("");
              }}
              onKeyDown={(e) => {
                if (e.key === "Enter" && name.length > 0) handleNameContinue();
              }}
              placeholder="Your name"
              autoFocus
              className="w-full px-4 py-3.5 rounded-2xl text-sm outline-none text-center transition-all duration-200"
              style={fieldStyle(!!name.trim(), !!nameError)}
            />
            <AnimatePresence>
              {nameError && (
                <motion.p
                  key="name-error"
                  initial={{ opacity: 0, y: -4 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -4 }}
                  className="w-full text-xs text-center"
                  style={{ color: "#fb7185", fontWeight: 300 }}
                >
                  {nameError}
                </motion.p>
              )}
            </AnimatePresence>
          </div>
          <CtaButton
            label="Continue"
            onClick={handleNameContinue}
            disabled={name.length === 0}
          />
        </motion.div>
      )}

      {/* Q2 — birthday */}
      {phase === 2 && (
        <motion.div key="ob-q2" className="flex flex-col flex-1 w-full" style={{ minHeight: 440 }} {...stepMotion}>
          <div className="h-6 mb-3">
            <BackButton
              onClick={() => {
                setBirthPickerOpen(false);
                setPhase(1);
              }}
            />
          </div>
          <QuestionHeader
            title="When’s your birthday?"
            subtitle="We’ll keep it in mind for your special day."
          />
          <div className="flex-1 flex flex-col items-center justify-start gap-3 pt-6">
            <div className="flex w-full items-center justify-center gap-2">
              {(
                [
                  { key: "day", value: birthDay, placeholder: "dd", width: "4.5rem" },
                  { key: "month", value: birthMonth, placeholder: "mm", width: "4.5rem" },
                  { key: "year", value: birthYear, placeholder: "yyyy", width: "6rem" },
                ] as const
              ).map((field, i) => (
                <div key={field.key} className="flex items-center gap-2">
                  {i > 0 && (
                    <span className="text-sm" style={{ color: "rgba(0,0,0,0.25)", fontWeight: 300 }}>
                      /
                    </span>
                  )}
                  <button
                    type="button"
                    onClick={openBirthPicker}
                    className="rounded-2xl text-sm text-center transition-all duration-200"
                    style={{
                      ...birthFieldStyle(field.value),
                      width: field.width,
                      padding: "0.875rem 0.5rem",
                    }}
                    aria-label={field.key}
                  >
                    <span style={{ color: field.value ? "rgba(0,0,0,0.8)" : "rgba(0,0,0,0.28)" }}>
                      {field.value || field.placeholder}
                    </span>
                  </button>
                </div>
              ))}
            </div>

            <AnimatePresence>
              {birthPickerOpen && (
                <motion.div
                  key="birth-wheel"
                  initial={{ opacity: 0, y: 10, height: 0 }}
                  animate={{ opacity: 1, y: 0, height: "auto" }}
                  exit={{ opacity: 0, y: 8, height: 0 }}
                  transition={{ duration: 0.28, ease: [0.25, 0.46, 0.45, 0.94] }}
                  className="w-full overflow-hidden"
                >
                  <div
                    className="mt-2 rounded-[1.35rem] border px-2 py-3"
                    style={{
                      background:
                        "linear-gradient(155deg, rgba(255,255,255,0.92), rgba(255,255,255,0.72))",
                      borderColor: "rgba(255,255,255,0.7)",
                      boxShadow: "0 10px 28px rgba(15,23,42,0.06)",
                    }}
                  >
                    <div className="mb-2 flex items-center justify-between px-2">
                      <p
                        className="text-[10px] uppercase tracking-[0.12em]"
                        style={{ color: "rgba(0,0,0,0.28)", fontWeight: 400 }}
                      >
                        Scroll to choose
                      </p>
                      <button
                        type="button"
                        onClick={() => setBirthPickerOpen(false)}
                        className="text-[11px]"
                        style={{ color: "rgba(0,0,0,0.45)", fontWeight: 400 }}
                      >
                        Done
                      </button>
                    </div>
                    <div className="flex gap-1">
                      <DateWheelColumn
                        options={dayOptions}
                        value={birthDay ? Number(birthDay) : null}
                        onChange={setDayFromWheel}
                        fallbackIndex={0}
                      />
                      <DateWheelColumn
                        options={monthOptions}
                        value={birthMonth ? Number(birthMonth) : null}
                        onChange={setMonthFromWheel}
                        fallbackIndex={0}
                      />
                      <DateWheelColumn
                        options={yearOptions}
                        value={birthYear ? Number(birthYear) : null}
                        onChange={setYearFromWheel}
                        pad={4}
                        fallbackIndex={18}
                      />
                    </div>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            <AnimatePresence>
              {birthdayError && (
                <motion.p
                  key="birthday-error"
                  initial={{ opacity: 0, y: -4 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -4 }}
                  className="w-full text-xs text-center"
                  style={{ color: "#fb7185", fontWeight: 300 }}
                >
                  {birthdayError}
                </motion.p>
              )}
            </AnimatePresence>
          </div>
          <CtaButton
            label="Continue"
            onClick={handleBirthdayContinue}
            disabled={!hasAnyBirthPart}
          />
        </motion.div>
      )}

      {/* Q3 — photo */}
      {phase === 3 && (
        <motion.div key="ob-q3" className="flex flex-col flex-1 w-full" style={{ minHeight: 440 }} {...stepMotion}>
          <div className="mb-3 flex h-6 items-center justify-between">
            <BackButton onClick={() => setPhase(2)} />
            <SkipButton
              onClick={() => {
                setPhotoError("");
                closePhotoPermissionPrompt();
                setPhase(4);
              }}
            />
          </div>
          <QuestionHeader
            title="Add a photo"
            subtitle="Let your partner see you."
          />
          <div className="flex flex-1 flex-col items-center justify-start pt-6">
            <input
              ref={fileRef}
              type="file"
              accept="image/*"
              onChange={handlePhoto}
              className="hidden"
            />
            <button
              type="button"
              onClick={requestPhotoAccess}
              className="flex flex-col items-center justify-center gap-3"
            >
              {photo ? (
                <img
                  src={photo}
                  alt="Your photo"
                  className="h-28 w-28 rounded-full object-cover border border-white/70 shadow-md"
                />
              ) : (
                <div
                  className="flex h-28 w-28 items-center justify-center rounded-full border border-dashed"
                  style={{
                    background: "linear-gradient(135deg, rgba(194,206,233,0.55), rgba(232,190,201,0.55))",
                    borderColor: "rgba(0,0,0,0.15)",
                  }}
                >
                  <Camera className="h-8 w-8 text-white/90" />
                </div>
              )}
              <span className="text-xs" style={{ color: "rgba(0,0,0,0.4)", fontWeight: 300 }}>
                {photo ? "Tap to change photo" : "Tap to upload a photo"}
              </span>
            </button>

            <AnimatePresence>
              {photoError && (
                <motion.p
                  key="photo-error"
                  initial={{ opacity: 0, y: -4 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -4 }}
                  className="mt-4 max-w-[16rem] text-center text-xs leading-relaxed"
                  style={{ color: "#fb7185", fontWeight: 300 }}
                >
                  {photoError}
                </motion.p>
              )}
            </AnimatePresence>
          </div>
          <CtaButton label="Almost there" onClick={() => setPhase(4)} disabled={!photo} />
        </motion.div>
      )}

      {/* Q4 — gender */}
      {phase === 4 && (
        <motion.div key="ob-q4" className="flex flex-col flex-1 w-full" style={{ minHeight: 440 }} {...stepMotion}>
          <div className="h-6 mb-3">
            <BackButton onClick={() => setPhase(3)} />
          </div>
          <QuestionHeader title="Your gender" subtitle="This helps us personalize your experience." />
          <div className="flex-1 flex flex-col items-center justify-start gap-6 pt-6">
            <div className="grid grid-cols-2 gap-3 w-full">
              {(["male", "female"] as const).map((g) => {
                const active = gender === g;
                return (
                  <button
                    key={g}
                    onClick={() => setGender(g)}
                    className="flex flex-col items-center justify-center gap-2 py-5 rounded-2xl transition-all"
                    style={{
                      background: active ? "rgba(251,113,133,0.08)" : "rgba(0,0,0,0.04)",
                      border: active ? "1px solid rgba(251,113,133,0.4)" : "1px solid rgba(0,0,0,0.06)",
                    }}
                  >
                    <User className="w-5 h-5" style={{ color: active ? "#fb7185" : "rgba(0,0,0,0.35)" }} />
                    <span
                      className="text-sm capitalize"
                      style={{ color: active ? "rgba(0,0,0,0.75)" : "rgba(0,0,0,0.45)", fontWeight: active ? 400 : 300 }}
                    >
                      {g}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>
          <CtaButton
            label="That’s it!"
            icon={<Check className="w-4 h-4 opacity-80" />}
            onClick={onDone}
            disabled={!gender}
          />
        </motion.div>
      )}
    </AnimatePresence>
  );
}

export function AuthScreen({ onAuthenticated }: AuthScreenProps) {
  const [step, setStep] = useState<AuthStep>("email");
  const [email, setEmail] = useState("");
  const [onbPhase, setOnbPhase] = useState(0);
  const [photoPermissionPrompt, setPhotoPermissionPrompt] = useState<{
    onAllow: () => void;
    onDeny: () => void;
  } | null>(null);

  // Question mode: onboarding questions 1..4 — compact header, expanded card.
  const questionMode = step === "onboarding" && onbPhase >= 1;

  const handleEmailNext = (e: string) => {
    setEmail(e);
    setStep("otp");
  };

  return (
    <div className="h-full relative overflow-hidden bg-gradient-to-br from-gray-50 via-white to-gray-100 flex flex-col">
      <motion.div
        className="absolute -top-24 -left-24 w-[28rem] h-[28rem] rounded-full blur-[130px]"
        style={{
          background: "linear-gradient(135deg, rgba(251,207,232,0.55), rgba(196,181,253,0.4))",
        }}
        animate={{ opacity: [0.45, 0.7, 0.45], scale: [0.9, 1.05, 0.9] }}
      transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
      />
      <motion.div
        className="absolute -bottom-24 -right-24 w-96 h-96 rounded-full blur-[110px]"
        style={{
          background: "linear-gradient(135deg, rgba(167,243,208,0.35), rgba(147,197,253,0.45))",
        }}
        animate={{ opacity: [0.3, 0.55, 0.3], scale: [0.95, 1.08, 0.95] }}
        transition={{
          duration: 7,
          repeat: Infinity,
          ease: "easeInOut",
          delay: 1.2,
        }}
      />

      <div
        className={`flex flex-col items-center justify-center px-6 ${
          questionMode ? "pt-7 pb-2" : "pt-16 pb-6 flex-1"
        }`}
      >
        {!questionMode && (
          <motion.div
            initial={{ opacity: 0, scale: 0.85, y: 8 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            transition={{ duration: 0.7, ease: [0.25, 0.46, 0.45, 0.94] }}
          >
            <svg
              width="88"
              height="88"
              viewBox="0 0 64 64"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              aria-label="beside logo"
            >
              <defs>
                <linearGradient id="besideBg" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0%" stopColor="#C2CEE9" />
                  <stop offset="100%" stopColor="#E8BEC9" />
                </linearGradient>
                <filter id="besideSh" x="-20%" y="-20%" width="140%" height="140%">
                  <feDropShadow dx="0" dy="1.5" stdDeviation="2.5" floodColor="rgba(80,70,120,0.18)" />
                </filter>
              </defs>
              <rect width="64" height="64" rx="17" fill="url(#besideBg)" />
              <rect x="0" y="0" width="64" height="28" rx="17" fill="white" fillOpacity="0.13" />
              <path
                d="M13,14 C13,10 17,10 17,10 L21,10 Q46,10 46,22 Q46,34 31,34 Q50,34 50,44 Q50,56 21,56 L17,56 C17,56 13,56 13,52 Z"
                fill="white"
                fillOpacity="0.95"
                filter="url(#besideSh)"
              />
            </svg>
          </motion.div>
        )}

        <motion.div
          className={questionMode ? "flex items-center justify-center gap-2" : "text-center mt-2"}
          initial={{ opacity: 0, y: 14 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: questionMode ? 0 : 0.45, duration: 0.5 }}
        >
          {questionMode && (
            <svg
              width="28"
              height="28"
              viewBox="0 0 64 64"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              aria-label="beside logo"
            >
              <defs>
                <linearGradient id="besideBgSm" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0%" stopColor="#C2CEE9" />
                  <stop offset="100%" stopColor="#E8BEC9" />
                </linearGradient>
              </defs>
              <rect width="64" height="64" rx="17" fill="url(#besideBgSm)" />
              <rect x="0" y="0" width="64" height="28" rx="17" fill="white" fillOpacity="0.13" />
              <path
                d="M13,14 C13,10 17,10 17,10 L21,10 Q46,10 46,22 Q46,34 31,34 Q50,34 50,44 Q50,56 21,56 L17,56 C17,56 13,56 13,52 Z"
                fill="white"
                fillOpacity="0.95"
              />
            </svg>
          )}
          <h1
            className="text-gray-900"
            style={{
              fontWeight: 200,
              fontSize: questionMode ? "1.375rem" : "2rem",
              letterSpacing: "0.06em",
            }}
          >
            beside
          </h1>
          {!questionMode && (
            <p
              className="mt-1 text-[10px] tracking-[0.08em]"
              style={{ color: "rgba(0,0,0,0.25)", fontWeight: 400 }}
            >
              Just you two.
            </p>
          )}
        </motion.div>
      </div>

      <motion.div
        className={`px-5 ${questionMode ? "flex-1 flex flex-col pb-6 pt-2" : "pb-10"}`}
        initial={{ opacity: 0, y: 28 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.65, duration: 0.6, ease: [0.25, 0.46, 0.45, 0.94] }}
      >
        <AnimatePresence>
          {step === "email" && (
            <motion.p
              key="auth-intro"
              className="mx-auto mb-4 max-w-[18rem] text-center text-[13px] leading-relaxed"
              style={{
                color: "rgba(0,0,0,0.38)",
                fontWeight: 300,
                letterSpacing: "0.01em",
              }}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -6 }}
              transition={{ duration: 0.3 }}
            >
              Create your account and start your journey together.
            </motion.p>
          )}
        </AnimatePresence>

        <div
          className={`rounded-3xl border border-white/60 shadow-xl overflow-hidden ${
            questionMode ? "flex-1 flex flex-col" : ""
          }`}
          style={{
            background: "linear-gradient(145deg, rgba(255,255,255,0.88), rgba(255,255,255,0.68))",
            backdropFilter: "blur(36px)",
          }}
        >
          <div className={`p-6 ${questionMode ? "flex-1 flex flex-col" : ""}`}>
            <AnimatePresence mode="wait">
              {step === "email" && <EmailStep key="email" onNext={handleEmailNext} />}
              {step === "otp" && (
                <OtpStep
                  key="otp"
                  email={email}
                  onVerified={() => setStep("onboarding")}
                  onBack={() => setStep("email")}
                />
              )}
              {step === "onboarding" && (
                <OnboardingStep
                  key="onboarding"
                  onDone={onAuthenticated}
                  onPhaseChange={setOnbPhase}
                  onPhotoPermissionPrompt={setPhotoPermissionPrompt}
                />
              )}
            </AnimatePresence>
          </div>
        </div>

        <div
          className="relative flex items-center mt-5 p-1 rounded-2xl border border-white/60"
          style={{
            background: "linear-gradient(135deg, rgba(255,255,255,0.6), rgba(255,255,255,0.35))",
            backdropFilter: "blur(20px)",
          }}
        >
          {STEP_ORDER.map((s) => {
            const label = s === "email" ? "Account" : s === "otp" ? "Verify" : "Onboarding";
            const isActive = s === step;
            return (
              <button
                key={s}
                type="button"
                onClick={() => setStep(s)}
                className="relative flex-1 py-2.5 rounded-xl text-center"
                aria-label={`Go to ${label} step`}
              >
                {isActive && (
                  <motion.span
                    layoutId="authNavPill"
                    className="absolute inset-0 rounded-xl shadow-md"
                    style={{
                      background: "linear-gradient(135deg, #1a1a2e, #2d2d44)",
                    }}
                    transition={{ type: "spring", stiffness: 380, damping: 32 }}
                  />
                )}
                <span
                  className="relative z-10 text-xs"
                  style={{
                    color: isActive ? "rgba(255,255,255,0.95)" : "rgba(0,0,0,0.4)",
                    fontWeight: isActive ? 400 : 300,
                    letterSpacing: "0.02em",
                  }}
                >
                  {label}
                </span>
              </button>
            );
          })}
        </div>
      </motion.div>

      <AnimatePresence>
        {photoPermissionPrompt && (
          <motion.div
            key="photo-permission"
            className="absolute inset-0 z-50 flex items-center justify-center px-6"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <div
              className="absolute inset-0"
              style={{
                backdropFilter: "blur(16px)",
                WebkitBackdropFilter: "blur(16px)",
              }}
              aria-hidden
            />
            <motion.div
              role="dialog"
              aria-modal="true"
              aria-label="Photo library permission"
              className="relative w-full max-w-[19rem] overflow-hidden rounded-[1.35rem] border shadow-xl"
              style={{
                background: "linear-gradient(165deg, rgba(255,255,255,0.98), rgba(252,252,252,0.94))",
                borderColor: "rgba(255,255,255,0.7)",
              }}
              initial={{ opacity: 0, scale: 0.94, y: 12 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.96, y: 8 }}
              transition={{ type: "spring", stiffness: 360, damping: 28 }}
            >
              <div className="px-5 pb-2 pt-5 text-center">
                <p className="text-[15px]" style={{ color: "rgba(0,0,0,0.82)", fontWeight: 500 }}>
                  Allow photo access
                </p>
                <p
                  className="mt-2 text-[12px] leading-relaxed"
                  style={{ color: "rgba(0,0,0,0.45)", fontWeight: 300 }}
                >
                  beside needs access to your photo library so you can choose a profile picture.
                </p>
              </div>
              <div className="mt-3 grid grid-cols-2 border-t" style={{ borderColor: "rgba(0,0,0,0.06)" }}>
                <button
                  type="button"
                  onClick={photoPermissionPrompt.onDeny}
                  className="py-3.5 text-[13px]"
                  style={{
                    color: "rgba(0,0,0,0.45)",
                    fontWeight: 400,
                    borderRight: "1px solid rgba(0,0,0,0.06)",
                  }}
                >
                  Don&apos;t Allow
                </button>
                <button
                  type="button"
                  onClick={photoPermissionPrompt.onAllow}
                  className="py-3.5 text-[13px]"
                  style={{ color: "#fb7185", fontWeight: 500 }}
                >
                  Allow
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export default AuthScreen;
