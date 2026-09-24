import { Heart, Leaf, Sparkles, Battery, Cloud, Zap } from "lucide-react";

export interface MoodType {
  id: string;
  name: string;
  label: string;
  color: string;
  gradient: string;
  icon: typeof Heart;
  smokePattern: string;
}

export const moods: MoodType[] = [
  {
    id: "calm",
    name: "Calm & Balanced",
    label: "Calm",
    color: "#98D8C8",
    gradient: "linear-gradient(135deg, #98D8C8, #B0E0E6, #F0F8FF)",
    icon: Leaf,
    smokePattern: "floating",
  },
  {
    id: "joy",
    name: "Joy & High Energy",
    label: "Joy",
    color: "#FFC447",
    gradient: "linear-gradient(135deg, #FFE9A8, #FFD56A, #FFC447, #FFB347)",
    icon: Sparkles,
    smokePattern: "swirling",
  },
  {
    id: "love",
    name: "Love & Connection",
    label: "Love",
    color: "#E53E3E",
    gradient: "linear-gradient(135deg, #FF1744, #E53E3E, #FF5252)",
    icon: Heart,
    smokePattern: "expanding",
  },
  {
    id: "sad",
    name: "Sad & Vulnerable",
    label: "Sad",
    color: "#4682B4",
    gradient: "linear-gradient(135deg, #708090, #4682B4, #5F9EA0)",
    icon: Cloud,
    smokePattern: "falling",
  },
  {
    id: "exhausted",
    name: "Exhausted & Low Battery",
    label: "Exhausted",
    color: "#B0C4DE",
    gradient: "linear-gradient(135deg, #DCDCDC, #B0C4DE, #D3D3D3)",
    icon: Battery,
    smokePattern: "falling",
  },
  {
    id: "stressed",
    name: "Stressed & Irritated",
    label: "Stressed",
    color: "#FF8C00",
    gradient: "linear-gradient(135deg, #FF6B00, #FF8C00, #FFA040)",
    icon: Zap,
    smokePattern: "chaotic",
  },
];

export const needsByMood: Record<string, string[]> = {
  calm: [
    "Let's just sit together in silence.",
    "I'm feeling grounded — I can help you with something.",
    "Let's do something calm together (read, puzzle, cook).",
  ],
  joy: [
    "Go for a walk or a run together.",
    "Share a funny story or meme.",
    "Let's celebrate small wins together.",
  ],
  love: [
    "Let's have a date / time without phones.",
    "I want to be intimate / have sex.",
    "Let's just talk about us.",
  ],
  sad: [
    "I want hugs.",
    "Let's change the scenery (walk/movie).",
    "I need a little support and words of love.",
  ],
  exhausted: [
    "Take care of the chores today.",
    "Don't be upset if I stay quiet.",
    "Make me tea / bring me something to eat.",
  ],
  stressed: [
    "I need a few minutes to calm down.",
    "Help me with small tasks while I relax.",
    "Just listen without judging.",
  ],
};