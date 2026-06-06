import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "url";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  base: "./",
  build: {
    emptyOutDir: true,
    outDir: "build",
    chunkSizeWarningLimit: 1600,
    rollupOptions: {
      input: {
        // NUI page (menu + crosshair) and the in-game DUI widget (E prompt).
        main: fileURLToPath(new URL("./index.html", import.meta.url)),
        dui: fileURLToPath(new URL("./dui.html", import.meta.url)),
      },
    },
  },
});
