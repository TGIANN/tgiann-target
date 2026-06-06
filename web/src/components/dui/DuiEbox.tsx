import { motion, AnimatePresence } from "framer-motion";
import { useNuiEvent, fetchNui } from "fivem-nui-react";
import { useEffect, useState } from "react";
import { setThemeColor, ThemeColorData } from "../../setTheme";

interface EboxData {
  visible: boolean;
  key: string;
  label: string;
  holding: boolean;
  holdDuration: number;
}

// Rendered inside a fixed-size DUI texture that the client draws in-game with
// DrawSprite. The key box is anchored to the left of the canvas (the client aligns it
// onto the target); the label sits to its right.
function DuiEbox() {
  const [data, setData] = useState<EboxData>({
    visible: false,
    key: "E",
    label: "",
    holding: false,
    holdDuration: 600,
  });

  useNuiEvent<EboxData>("setEbox", (d) => setData(d));
  useNuiEvent<ThemeColorData>("setThemeColor", (d) => setThemeColor(d));

  useEffect(() => {
    fetchNui("eboxReady").catch(() => undefined);
  }, []);

  return (
    <div className="dui_ebox_root">
      <AnimatePresence>
        {data.visible && (
          <motion.div
            className="dui_ebox"
            initial={{ opacity: 0, scale: 0.6 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.6 }}
            transition={{ duration: 0.1 }}
          >
            <div className="dui_ebox_button">
              {data.key}
              <div className="dui_ebox_button_bottom"></div>

              <AnimatePresence>
                {data.holding && (
                  <svg
                    className="dui_ebox_progress"
                    viewBox="0 0 100 100"
                    preserveAspectRatio="none"
                  >
                    <motion.path
                      d="M 12 4 H 88 A 8 8 0 0 1 96 12 V 88 A 8 8 0 0 1 88 96 H 12 A 8 8 0 0 1 4 88 V 12 A 8 8 0 0 1 12 4 Z"
                      pathLength={100}
                      strokeDasharray="100"
                      initial={{ strokeDashoffset: 100, opacity: 1 }}
                      animate={{ strokeDashoffset: 0 }}
                      exit={{ opacity: 0 }}
                      transition={{
                        strokeDashoffset: {
                          duration: data.holdDuration / 1000,
                          ease: "linear",
                        },
                      }}
                    />
                  </svg>
                )}
              </AnimatePresence>
            </div>

            {data.label !== "" && <div className="dui_ebox_text">{data.label}</div>}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export default DuiEbox;
