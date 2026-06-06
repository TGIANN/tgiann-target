// Applies the accent ("green") theme colour, mirroring tgiann-core's setGreenColor so
// tgiann-target follows the same live colour changes (tgiann-lumihud:setLumiHudColor).
const root = document.documentElement;

export interface ThemeColorData {
  background: string;
  color: string;
}

function hexToRgb(hex: string): { r: number; g: number; b: number } {
  const v = parseInt(hex.slice(1), 16);
  return { r: (v >> 16) & 255, g: (v >> 8) & 255, b: v & 255 };
}

function rgbToHex(r: number, g: number, b: number): string {
  return "#" + ((1 << 24) | (r << 16) | (g << 8) | b).toString(16).slice(1);
}

function mixColors(color1: string, color2: string, weight: number): string {
  const c1 = hexToRgb(color1);
  const c2 = hexToRgb(color2);
  return rgbToHex(
    Math.round(c1.r * weight + c2.r * (1 - weight)),
    Math.round(c1.g * weight + c2.g * (1 - weight)),
    Math.round(c1.b * weight + c2.b * (1 - weight)),
  );
}

function hexWithOpacity(hex: string, opacity: number): string {
  const alpha = Math.round(opacity * 255)
    .toString(16)
    .padStart(2, "0");
  return hex + alpha;
}

export function setThemeColor(data: ThemeColorData): void {
  if (!data?.background) return;

  const green = data.background;
  root.style.setProperty("--green", green);
  root.style.setProperty("--green-hover", mixColors(green, "#000000", 0.8));
  root.style.setProperty("--green-opacity-20", hexWithOpacity(green, 0.2));
  if (data.color) root.style.setProperty("--green-text", data.color);
}
