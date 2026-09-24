import { motion, AnimatePresence } from "motion/react";
import { X, Heart, Home, MessageCircle, Coffee, Users, Footprints, Clock, HandHeart, Volume2 } from "lucide-react";

interface Need {
  id: string;
  text: string;
  icon: typeof Heart;
}

interface NeedSelectorProps {
  isOpen: boolean;
  onClose: () => void;
  moodId: string;
  moodName: string;
  moodGradient: string;
  onSelectNeed: (need: Need) => void;
}

const needsByMood: Record<string, Need[]> = {
  love: [
    { id: "date", text: "Давай устроим свидание / время без телефонов", icon: Heart },
    { id: "intimacy", text: "Хочу заняться сексом / физической близостью", icon: Heart },
    { id: "talk", text: "Давай просто поболтаем о нас", icon: MessageCircle },
  ],
  calm: [
    { id: "silence", text: "Давай просто посидим рядом в тишине", icon: Home },
    { id: "help", text: "Я в ресурсе — могу помочь тебе с чем-то", icon: HandHeart },
    { id: "cozy", text: "Давай займемся чем-то спокойным (книга, пазл, готовка)", icon: Coffee },
  ],
  joy: [
    { id: "adventure", text: "Погнали куда-нибудь! (активный отдых)", icon: Footprints },
    { id: "social", text: "Давай позовем друзей или сотворим что-то безумное", icon: Users },
    { id: "share", text: "Хочу поделиться с тобой классными новостями", icon: MessageCircle },
  ],
  exhausted: [
    { id: "tasks", text: "Возьми на себя решение бытовых вопросов сегодня", icon: HandHeart },
    { id: "quiet", text: "Не обижайся, если я буду молчать", icon: Volume2 },
    { id: "care", text: "Сделай мне чай / принеси еды", icon: Coffee },
  ],
  sad: [
    { id: "hug", text: "Хочу обнимашек", icon: Heart },
    { id: "change", text: "Давай сменим обстановку (прогулка/кино)", icon: Footprints },
    { id: "support", text: "Мне нужно немного поддержки и слов любви", icon: MessageCircle },
  ],
  stressed: [
    { id: "timeout", text: "Дай мне 15 минут тишины", icon: Clock },
    { id: "listen", text: "Просто выслушай, не давая советов", icon: MessageCircle },
    { id: "household", text: "Помоги мне с бытовыми делами сегодня", icon: HandHeart },
  ],
};

export function NeedSelector({ isOpen, onClose, moodId, moodName, moodGradient, onSelectNeed }: NeedSelectorProps) {
  const needs = needsByMood[moodId] || [];

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-40"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />

          {/* Modal */}
          <motion.div
            className="fixed inset-x-4 top-1/2 -translate-y-1/2 z-50 max-w-md mx-auto"
            initial={{ opacity: 0, scale: 0.8, y: "-40%" }}
            animate={{ opacity: 1, scale: 1, y: "-50%" }}
            exit={{ opacity: 0, scale: 0.8, y: "-40%" }}
            transition={{ type: "spring", duration: 0.5 }}
          >
            {/* Frosted glass panel */}
            <div
              className="relative rounded-3xl overflow-hidden backdrop-blur-2xl border border-white/20 shadow-2xl"
              style={{
                background: "linear-gradient(135deg, rgba(255,255,255,0.1), rgba(255,255,255,0.05))",
              }}
            >
              {/* Colored gradient overlay */}
              <div
                className="absolute inset-0 opacity-20"
                style={{ background: moodGradient }}
              />

              {/* Content */}
              <div className="relative p-8">
                {/* Close button */}
                <button
                  onClick={onClose}
                  className="absolute top-4 right-4 p-2 rounded-full bg-white/10 hover:bg-white/20 transition-colors"
                >
                  <X className="w-5 h-5 text-white" />
                </button>

                {/* Header */}
                <motion.div
                  className="mb-6"
                  initial={{ y: -20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ delay: 0.1 }}
                >
                  <h2 className="text-white/90 mb-2">
                    {moodName}
                  </h2>
                  <p className="text-white/70 text-sm">
                    Что тебе сейчас нужно?
                  </p>
                </motion.div>

                {/* Needs list */}
                <div className="space-y-3">
                  {needs.map((need, index) => {
                    const Icon = need.icon;
                    return (
                      <motion.button
                        key={need.id}
                        onClick={() => {
                          onSelectNeed(need);
                          onClose();
                        }}
                        className="w-full p-4 rounded-2xl bg-white/10 hover:bg-white/20 border border-white/10 transition-all group text-left"
                        initial={{ x: -50, opacity: 0 }}
                        animate={{ x: 0, opacity: 1 }}
                        transition={{ delay: 0.1 + index * 0.1 }}
                        whileHover={{ scale: 1.02, x: 4 }}
                        whileTap={{ scale: 0.98 }}
                      >
                        <div className="flex items-start gap-3">
                          <div
                            className="mt-0.5 p-2 rounded-xl"
                            style={{
                              background: moodGradient,
                              opacity: 0.8,
                            }}
                          >
                            <Icon className="w-5 h-5 text-white" />
                          </div>
                          <p className="flex-1 text-white/90 text-sm leading-relaxed">
                            {need.text}
                          </p>
                        </div>
                      </motion.button>
                    );
                  })}
                </div>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
