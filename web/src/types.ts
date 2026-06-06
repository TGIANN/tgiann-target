export interface TargetData {
  /** Stable identifier for the target location ("entity" or "zone:<index>"). */
  id: string;
  /** Normalised (0..1) horizontal screen position. */
  x: number;
  /** Normalised (0..1) vertical screen position. */
  y: number;
  /** Whether this is the closest target. Active -> E box, otherwise -> ring. */
  active: boolean;
  /** Whether the interact key is currently held on the active target. */
  holding: boolean;
  /** Text shown in the label box next to the key (active target). */
  label: string;
}

export interface UpdateTargetsData {
  /** Focused target (0 or 1 entries); ambient markers are in-game sprites. */
  targets: TargetData[];
  /** The keyboard key the player presses to interact (e.g. "E"). */
  key: string;
  /** How long (ms) the key must be held; drives the border progress animation. */
  holdDuration: number;
}

export interface MenuOption {
  label: string;
  icon: string;
  /** Optional custom colour for the option's icon (from the option's iconColor). */
  iconColor?: string;
  /** True when selecting this option opens a sub-menu (shows a chevron). */
  arrow?: boolean;
  typeKey?: string;
  zoneIndex?: number;
  optionIndex?: number;
  builtin?: string;
}

export interface MenuData {
  /** Header title for the menu. */
  title?: string;
  options: MenuOption[];
  /** When true keep the previous title (sub-menu navigation). */
  keepPosition?: boolean;
}
