import type { ComponentType, ReactNode } from "react";
import {
  Camera,
  Crown,
  Users,
  Link2,
  Bell,
  Shield,
  HelpCircle,
  FileText,
  LogOut,
  ChevronRight,
  Sparkles,
} from "lucide-react";

export interface MoreScreenProps {
  /** Display name (you) */
  displayName?: string;
  /** Partner display name when paired */
  partnerName?: string;
  /** Whether the user is linked with a partner */
  isPaired?: boolean;
  /** Shown on avatar when no image */
  avatarInitial?: string;
  /** Optional avatar image URL */
  avatarUrl?: string;
  isPremium?: boolean;
  appVersion?: string;
  onEditProfile?: () => void;
  onChangeAvatar?: () => void;
  onPremium?: () => void;
  /** Invite code, deep link, or pair flow */
  onInviteOrPair?: () => void;
  onManagePair?: () => void;
  onNotifications?: () => void;
  onPrivacy?: () => void;
  onHelp?: () => void;
  onTerms?: () => void;
  onLogout?: () => void;
}

function Row({
  icon: Icon,
  label,
  hint,
  onClick,
  danger,
  trailing,
}: {
  icon: ComponentType<{ className?: string; strokeWidth?: number }>;
  label: string;
  hint?: string;
  onClick?: () => void;
  danger?: boolean;
  trailing?: ReactNode;
}) {
  const content = (
    <>
      <div
        className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ${
          danger ? "bg-red-500/[0.08]" : "bg-black/[0.04]"
        }`}
      >
        <Icon className={`h-[18px] w-[18px] ${danger ? "text-red-500/90" : "text-gray-600"}`} strokeWidth={1.75} />
      </div>
      <div className="min-w-0 flex-1 text-left">
        <p className={`text-[14px] ${danger ? "text-red-600" : "text-gray-800"}`} style={{ fontWeight: 600 }}>
          {label}
        </p>
        {hint ? (
          <p className="mt-0.5 text-[11px] text-gray-400" style={{ fontWeight: 300 }}>
            {hint}
          </p>
        ) : null}
      </div>
      {trailing ?? <ChevronRight className="h-4 w-4 shrink-0 text-gray-300" strokeWidth={2} />}
    </>
  );

  if (onClick) {
    return (
      <button
        type="button"
        onClick={onClick}
        className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition-colors hover:bg-black/[0.025] active:bg-black/[0.04] active:scale-[0.99]"
      >
        {content}
      </button>
    );
  }

  return <div className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5">{content}</div>;
}

function SectionTitle({ children }: { children: ReactNode }) {
  return (
    <p className="mb-2 mt-6 px-1 text-[10px] uppercase tracking-[0.16em] text-black/35 first:mt-0" style={{ fontWeight: 300 }}>
      {children}
    </p>
  );
}

function Card({ children }: { children: ReactNode }) {
  return (
    <div
      className="overflow-hidden rounded-2xl border border-black/[0.06] bg-white shadow-[0_2px_12px_rgba(0,0,0,0.04)]"
      style={{ boxShadow: "0 2px 12px rgba(0,0,0,0.04), 0 0 0 1px rgba(0,0,0,0.03)" }}
    >
      <div className="divide-y divide-black/[0.05]">{children}</div>
    </div>
  );
}

export function MoreScreen({
  displayName = "You",
  partnerName,
  isPaired = false,
  avatarInitial = "Y",
  avatarUrl,
  isPremium = false,
  appVersion = "1.0.0",
  onEditProfile,
  onChangeAvatar,
  onPremium,
  onInviteOrPair,
  onManagePair,
  onNotifications,
  onPrivacy,
  onHelp,
  onTerms,
  onLogout,
}: MoreScreenProps) {
  const initial = (avatarInitial && avatarInitial.length > 0 ? avatarInitial : "Y").slice(0, 1).toUpperCase();

  return (
    <div
      className="mx-auto flex min-h-dvh w-full max-w-md flex-col bg-[#fafafa] pb-24 text-gray-900 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:h-0 [&::-webkit-scrollbar]:w-0"
      style={{ minHeight: "100dvh" }}
    >
      <header className="shrink-0 px-4 pb-2 pt-[max(0.75rem,env(safe-area-inset-top))]">
        <div className="flex items-center gap-2">
          <Sparkles className="h-4 w-4 text-rose-400/80" strokeWidth={1.75} />
          <h1 className="text-[20px] tracking-tight text-gray-900" style={{ fontWeight: 600 }}>
            More
          </h1>
        </div>
        <p className="mt-1 text-[12px] text-gray-400" style={{ fontWeight: 300 }}>
          Profile, pair, and app settings
        </p>
      </header>

      <div className="flex min-h-0 flex-1 flex-col overflow-y-auto overscroll-contain px-4">
        {/* Profile */}
        <div className="mt-2 rounded-2xl border border-black/[0.06] bg-white p-4 shadow-sm">
          <div className="flex items-center gap-4">
            <button
              type="button"
              onClick={onChangeAvatar}
              className="relative shrink-0 rounded-full active:scale-[0.96]"
            >
              <div className="flex h-[72px] w-[72px] items-center justify-center overflow-hidden rounded-full bg-gradient-to-br from-rose-100 to-amber-50 ring-2 ring-white shadow-md">
                {avatarUrl ? (
                  <img src={avatarUrl} alt="" className="h-full w-full object-cover" />
                ) : (
                  <span className="text-[26px] text-rose-400/90" style={{ fontWeight: 500 }}>
                    {initial}
                  </span>
                )}
              </div>
              <div className="absolute -bottom-0.5 -right-0.5 flex h-7 w-7 items-center justify-center rounded-full border-2 border-white bg-gray-800 shadow">
                <Camera className="h-3.5 w-3.5 text-white" strokeWidth={2} />
              </div>
            </button>
            <div className="min-w-0 flex-1">
              <p className="truncate text-[17px] text-gray-900" style={{ fontWeight: 600 }}>
                {displayName}
              </p>
              <p className="mt-0.5 text-[12px] text-gray-400" style={{ fontWeight: 300 }}>
                {isPremium ? "Premium" : "Free plan"}
              </p>
              <button
                type="button"
                onClick={onEditProfile}
                className="mt-2 text-[12px] text-rose-500 active:opacity-70"
                style={{ fontWeight: 500 }}
              >
                Edit profile
              </button>
            </div>
          </div>
        </div>

        <SectionTitle>Pair</SectionTitle>
        <Card>
          {isPaired ? (
            <Row
              icon={Users}
              label={partnerName ? `With ${partnerName}` : "Partner connected"}
              hint="Manage invite, nickname, or unlink"
              onClick={onManagePair}
            />
          ) : (
            <Row
              icon={Link2}
              label="Connect with your partner"
              hint="Share a code or link to create your pair"
              onClick={onInviteOrPair}
            />
          )}
        </Card>

        <SectionTitle>Subscription</SectionTitle>
        <Card>
          <Row
            icon={Crown}
            label={isPremium ? "Premium active" : "Try Premium"}
            hint={isPremium ? "Manage billing and plan" : "More prompts, activities, and moments for two"}
            onClick={onPremium}
            trailing={
              isPremium ? (
                <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-medium text-amber-800">Active</span>
              ) : (
                <ChevronRight className="h-4 w-4 shrink-0 text-gray-300" strokeWidth={2} />
              )
            }
          />
        </Card>

        <SectionTitle>Preferences</SectionTitle>
        <Card>
          <Row icon={Bell} label="Notifications" hint="Reminders, partner activity, daily prompts" onClick={onNotifications} />
          <Row icon={Shield} label="Privacy & data" hint="Visibility, export, delete account" onClick={onPrivacy} />
        </Card>

        <SectionTitle>Support</SectionTitle>
        <Card>
          <Row icon={HelpCircle} label="Help & FAQ" onClick={onHelp} />
          <Row icon={FileText} label="Terms & privacy policy" onClick={onTerms} />
        </Card>

        <SectionTitle>Account</SectionTitle>
        <Card>
          <Row icon={LogOut} label="Log out" hint="Sign out on this device" onClick={onLogout} danger />
        </Card>

        <p className="py-8 text-center text-[10px] text-gray-300" style={{ fontWeight: 300 }}>
          BeSide · v{appVersion}
        </p>
      </div>
    </div>
  );
}
