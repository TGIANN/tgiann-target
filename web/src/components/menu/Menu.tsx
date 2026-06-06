import "../../css/menu.css";
import { AnimatePresence, motion } from "framer-motion";
import { useNuiEvent, fetchNui } from "fivem-nui-react";
import { useEffect, useState } from "react";
import { MenuData, MenuOption } from "../../types";

function Menu() {
  const [visible, setVisible] = useState(false);
  const [options, setOptions] = useState<MenuOption[]>([]);

  useNuiEvent<MenuData>("openMenu", (data) => {
    setOptions(data.options || []);
    setVisible(true);
  });

  useNuiEvent("closeMenu", () => {
    setVisible(false);
  });

  const close = () => {
    setVisible(false);
    fetchNui("closeMenu").catch(() => undefined);
  };

  const onSelect = (option: MenuOption) => {
    fetchNui("select", option).catch(() => undefined);
  };

  // Right-click / ESC: go back one level if inside a sub-menu, otherwise close.
  const backOrClose = () => {
    const back = options.find((option) => option.builtin === "goback");
    if (back) {
      onSelect(back);
    } else {
      close();
    }
  };

  useEffect(() => {
    if (!visible) return;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape" || event.key === "Backspace") {
        backOrClose();
      }
    };

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [visible, options]);

  return (
    <AnimatePresence>
      {visible && (
        <div
          className="target_menu_overlay"
          onClick={close}
          onContextMenu={(event) => {
            event.preventDefault();
            backOrClose();
          }}
        >
          <motion.div
            className="target_menu"
            initial={{ opacity: 0, x: -12, scale: 0.96 }}
            animate={{ opacity: 1, x: 0, scale: 1 }}
            exit={{ opacity: 0, x: -12, scale: 0.96 }}
            transition={{ duration: 0.14, ease: "easeOut" }}
            onClick={(event) => event.stopPropagation()}
          >
            {options.map((option, index) => (
              <motion.div
                key={index}
                className={
                  "target_menu_option" +
                  (option.builtin === "goback" ? " target_menu_option_back" : "")
                }
                onClick={() => onSelect(option)}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.03, duration: 0.12 }}
              >
                <span className="target_menu_icon_box">
                  <i
                    className={option.icon}
                    style={option.iconColor ? { color: option.iconColor } : undefined}
                  ></i>
                </span>
                <span className="target_menu_label">{option.label}</span>
                {option.arrow && (
                  <i className="fa-solid fa-chevron-right target_menu_arrow"></i>
                )}
              </motion.div>
            ))}
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}

export default Menu;
