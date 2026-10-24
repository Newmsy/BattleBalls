// The Fuse tab's header band: the lab wall with the reactor ring and tubes
// pushed right, so the screen title sits on the calm left.
import lab from "./fuse_chamber.mjs";
export const size = [720, 220];
export const dir = "game/ui/fuse_art";
export default () => lab({ band: true });
