import { useEffect } from "react";
import { fetchNui, useNuiEvent } from "fivem-nui-react";
import Menu from "./components/menu/Menu";
import Crosshair from "./components/crosshair/Crosshair";
import { setThemeColor, ThemeColorData } from "./setTheme";

function App() {
  useEffect(() => {
    fetchNui("uiReady").catch(() => undefined);
  }, []);

  useNuiEvent<ThemeColorData>("setThemeColor", (data) => {
    setThemeColor(data);
  });

  return (
    <>
      <Crosshair />
      <Menu />
    </>
  );
}

export default App;
