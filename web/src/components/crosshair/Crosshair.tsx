import "../../css/crosshair.css";
import { AnimatePresence, motion } from "framer-motion";
import { useNuiEvent } from "fivem-nui-react";
import { useState } from "react";

function Crosshair() {
  const [visible, setVisible] = useState(false);

  // Sent only on transition by the client (one message to show, one to hide).
  useNuiEvent<boolean>("setCrosshair", (show) => {
    setVisible(!!show);
  });

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          className="target_crosshair"
          initial={{ opacity: 0, scale: 0.4 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.4 }}
          transition={{ duration: 0.12 }}
        />
      )}
    </AnimatePresence>
  );
}

export default Crosshair;
