# Battle Balls

A mobile auto-battler: balls with abilities bounce around a square arena and
fight. Built with Godot 4.3 (GDScript, Compatibility renderer) so it runs in
mobile Safari as a web build and later ships to iOS / Google Play.

## Layout

| Path | What lives there |
|---|---|
| `sim/` | The deterministic fight simulation. Pure GDScript, no nodes or engine physics. Same config, same fight. |
| `meta/` | Progression outside a fight: the player profile (collection, fusion, energy, account level, campaign stars), campaign zones, drops. Pure logic, clock passed in. Saved in the SaveGame as `data.profile`. |
| `sim/critters/` | One file per critter: everything about it (see Adding a critter). |
| `game/` | The playable scene: menu, aim, fight rendering, result. Reads the sim and meta; never changes their rules. |
| `liveops/` | The live-ops schedule (`liveops.json`): seasons, Fight of the Day, Bracket of Legends. See its README. |
| `game/online/` | Offline-first online layer: Supabase guest accounts, local + cloud save, Ghost Arena lineups. |
| `supabase/` | Database migrations (tables, row-level security, RPCs). CI applies them to the live project from `main`. |
| `game/glow/` | Glow Gems, cosmetics, the shop's store layer and the Glow Pass. Render-only: never read by `sim/`. |
| `tests/` | Headless test suite: unit tests, determinism, golden replays. `tests/db/` tests the migrations on plain Postgres. |
| `tools/` | Headless utilities: `balance.gd` (win-rate matrix), `pve_difficulty.gd` (campaign stage win rates by player power), `boon_balance.gd` (Bounce Run boons), `boss_difficulty.gd` (farming boss win rates by player and boss power), `boss_matrix.gd` (every critter vs every boss and level, as CSV, with or without talents), `record_golden.gd`. `tools/sfx/make_sfx.py` renders every sound and `tools/music/remix_crypto.py` remixes "Crypto" by Kevin MacLeod (CC-BY 4.0, see CREDITS.md) into the victory music in `game/audio/` (it reuses the drum and synth voices in `tools/music/make_music.py`); `tools/music/loop_track.py` loops a finished song seamlessly, on the beat grid and time-stretched if asked (menu, fight and overtime tracks). |
| `smoke/` | Playwright smoke test that plays the web build in a phone-sized browser. |

## Commands

```sh
godot --headless --import                                   # once, after cloning
GODOT=godot tests/run.sh                                    # all tests
godot --headless --script res://tools/balance.gd -- --fights=200 --power-step [--arena=all] [--only=<id>]
godot --headless --script res://tools/record_golden.gd      # only for intended sim changes
godot --headless --script res://tools/spire_curve.gd        # The Spire's floor power curve
godot --headless --export-release "Web" build/web/index.html
cd smoke && npm ci && node smoke.mjs ../build/web
node screens.mjs ../build/web out-dir                       # every home screen, 2 phone sizes, normal + Larger text
EXTRA="&stars=3&today=2026-10-17" node screens.mjs ...      # extra URL params: a fully starred Zone 1, a given day
DATABASE_URL=postgresql://... tests/db/run.sh               # migrations + RLS tests on an empty Postgres
```

## Previews

CI builds every ready (non-draft) PR for the web and deploys it to Vercel
(project `battleballs`, token in the `VERCEL` repo secret). Each PR gets a
comment with its preview URL; `main` deploys to production. Smoke-test
screenshots are served at `<preview>/smoke/`.

URL params jump straight to a fight: `?p1=vampire&p2=laser&seed=42&aim=-450&auto=1&speed=2&arena=rink`
(`aim` is the launch angle in tenths of a degree, screen space, y down;
`arena` is an id from `sim/arenas.gd`).

A first visit with no URL params plays the onboarding
(`game/onboarding.gd`; the design lives in the project's design/onboarding.md).
`?tutorial=1` replays it, `?tutorial=0` skips it.

Add `&clip=1` to make a "Save clip" video as soon as the fight ends.

## Finisher cam and clips

The finisher cam (`game/finisher_cam.gd`) slows and zooms into the knockout
blow. It is render-only: it plans from its own copy of the fight and only
changes playback speed and the camera. **Save clip** on the result screen
replays the fight in a 720x1280 "Who wins?" layout (`game/clip/`) and records
it in the browser (MP4 on iPhone Safari); browsers without MediaRecorder get
the same layout to screen-record. The export preset's `head_include` turns on
`preserveDrawingBuffer` and taps the game's audio so the page can record both.
`?sounds=1` opens the sound board: every sound with a play button.
`?dev=1` shows Settings > Testing (refill energy, free summons...) on that device from then on (`?dev=0` hides it); so does tapping the version line at the foot of Settings 7 times. Players never see it; debug runs from the editor always do.
`?pve=1-3&auto=1` plays campaign stage 1-3 on a fresh, unsaved profile.
`?demo=1` loads the filled-in sample profile (unsaved), for previews and the smoke test.

## Painted screens and living art

Paintings (Bounce Run events, banners, shop, the Home doors) are SVG scenes
in `tools/event_art/scenes/*.mjs`, rendered by `NODE_PATH=$(npm root -g) node
tools/event_art/render.mjs [name ...]` into PNGs (see the header of
`render.mjs`). To make part of a painting move, wrap it in
`<g data-layer="name" data-move="idle 4 0.7 0">`: the renderer writes the
picture without it plus a cut-out of it (and a blink frame when it has
`eye()` eyes), and `game/bounce_run/living_layers.gd`. In game,
`LivingArt.make(id, path)` (or `material_for()` + `animate()` on your own
Control, like `game/ui/home_painting.gd`) draws the layers back and moves each
one whole (bob, sway, breathe, idle), so the flat picture is never warped.
Glows and flickers are `LivingArt.SPECS` spots. At most 4 layers and 4 spots
per painting; a static part drawn over a moving one must be a still layer.
`tools/event_art/preview.gd` records a painting's idle for review.

## Icon and loading screen

All brand art is drawn in code in `tools/brand/designs.mjs` (Neon Critters
style) and rendered by `node tools/brand/render.mjs` (needs `smoke/`'s
Playwright and ImageMagick) into `game/brand/`:

- `icon.png` is the project icon: Godot turns it into the web favicon and the
  iPhone home-screen icon (`index.apple-touch-icon.png`).
- `splash.png` is the boot splash and the logo on the web loading screen,
  `game/web/shell.html` (the custom HTML shell with the progress bar and tips).
- `store/` holds the iOS and Android icon sizes (wired into the iOS and
  Android export presets), the Play Store 512 icon and feature graphic. It is
  excluded from the game pack.

designs.mjs also keeps the two runner-up icon options (`OPTIONS`); switch
`icon` to one of them and re-render to swap.

## Touch: scrolling and swipe back

`game/ui/touch_input.gd` handles touch for every screen before the GUI sees it
(added once by `TouchInput.ensure`). A drag past a small dead zone scrolls
the innermost `ScrollContainer` under the finger that can move that way, even
when it starts on a button or card, and the button is let go untapped; a
swipe in from the left edge runs the screen's Back. Screens say what Back
means with `TouchInput.set_back(self, func(): return <action or Callable()>)`;
the shell's is `Shell.back_action()` (close a sheet, or pop the screen stack).
New scroll areas need nothing extra: plain `ScrollContainer`s just work.

## Sound

All sounds are generated from recipes in `tools/sfx/make_sfx.py`
(`python3 tools/sfx/make_sfx.py`, needs numpy and ffmpeg) and the rendered
files are committed. `game/audio/sfx.gd` plays them from sim events only and
uses its own random generator, so sound can never change a fight.

Share links (`game/fight_link.gd`) need no server because fights are
deterministic: `?r=1.laser.vampire.11.-300.1066` replays one exact fight, and
`?c=1.laser.11.-300` challenges a friend to beat that ball and shot. Result
screens make both links (Share fight, Challenge friend).

## Daily Trick Shot

A daily called bank shot (`sim/trick_shot.gd`, `game/trick_shot.gd`): your
ball and a resting foe are placed, and you get three tries to find the launch
angle that banks off the called walls in order and then hits the foe. The
puzzle comes from the local date alone (#1 is 2026-10-14), so every device
gets the same one with no server. The generator tries setups until 4-12 of
the 360 whole-degree aims solve it; a test checks every day of the first year.
Progress and streaks are saved to `user://trick_shot.cfg`.

Open it from the menu's Trick Shot button or with
`?mode=trickshot` (`&day=12` for another day, `&aim=166&auto=1` to shoot at once).

Changing ball radius or speed, or adding playable balls, reshapes the
puzzles. That is fine; `tests/test_trick_shot.gd` only fails if days stop
being solvable or fair.

## Critter Plunge

A watch-only marble-run race in Versus (`sim/plunge.gd`, `sim/plunge_course.gd`,
`meta/critter_plunge.gd`, `meta/plunge_talents.gd`, `game/plunge.gd`,
`game/plunge_view.gd`, `game/ui/screens/plunge_screen.gd`). Your racer and 3, 5
or 7 CPU critters (all at your racer's tier) drop down one of 20 courses
(`PlungeCourse.COURSES`: a fixed run of sections, details varied by the seed,
each painted in one arena's art from `game/arena_art.gd`) built round its own
set piece: a gumball spiral, a honeycomb, swinging vines, drifting asteroids,
ice chutes, lava pipes, a pinball table with flippers and so on. Set pieces use
the arenas' moving parts (spinning, swinging and sliding bars, orbiting rocks,
thorns), wind bands, one-way portals, launch pads, curved ramps, icy ramps and
belts; open ones end on a ledge so the field gathers. Every course has one
hazard section (`PlungeCourse.HAZARDS`: gravity wells, lava, goo or sliding
bumpers) with a pickup (power core, heal or shield), carried on the arena's own
pieces so the fight view draws them. Races open on a course banner and a 3, 2,
1, GO! countdown (`game/plunge_intro.gd`).
The race is a MatchSim where every ball is its own team (`players` + `ffa`), so
critters race with their real abilities and the fight view draws them; gravity
and the course replace the arena walls, and a hard bounce off the course is a
wall bounce. Race rules on top: a hit staggers, aimed abilities go for the racer
ahead, charges are sideways swerves, stunned racers sink out of the way, and a
racer at 0 HP is knocked out and places last. Only `Plunge.RACERS` race (4 per
family, added in batches of one per family); `RACE_TWEAKS` scales a fight
number that doesn't fit a race and `RACE_HP` a racer's health. `HP_BY_FIELD`
and `HP_BY_TIER` keep knockouts near 1 in 10. Podium finishes win gold,
silver or bronze medals, spent on per-family race talents (1 gold = 2 silver =
4 bronze). `tools/plunge_stats.gd --races=600 --n=all --jobs=4 --check` prints
KO rate, race length, gate, critter and course numbers, and fails when a racer
wins outside 0.5-1.8x its fair share or a gate over 1.4x (too many races for
the test run: run it when racers or courses change). `?mode=plunge&seed=5&n=8` plays a practice
race (no rewards). Re-pin `tests/test_plunge.gd`'s golden race and bump
`Plunge.RACE_RULES` on intentional sim changes.

## Bounce Run

A daily roguelite (`sim/bounce_run.gd`, `sim/boons.gd`, `game/bounce_run.gd`;
design in the project's `design/bounce-run.md`). Draft 3 of 6 critters, pick 3
of 6 starting boons and a relic, then climb a 25-floor branching map (fights,
elites, events, shops, Charge Pads, a chest) to the Champion. A loss knocks
that critter out; lose all three and the run ends. Every run is a fresh map;
the day's best floor goes on the leaderboard and opens a chest the next day
(`meta/bounce_chest.gd`, a chest every 5 floors). Open it from the Daily board
or with `?mode=bouncerun`.

Both sides fight at `BounceRun.tier_at` (a tier every 5 floors) with the stats
of their rarity and tier (`sim/power.gd`), so your Legendary stays a
Legendary. Foes get rarer up the climb (`FOE_RARITY`), carry no boons, and
take the floor's edge (`FOE_POWER`) on top. Boons roll a seeded rarity: `id`
is Common, `id:rare` and `id:epic` scale its numbers, Legendary boons are
their own ids. The same boon can be taken again and stacks: the copies'
numbers add (`Boons.stacked`), Legendaries are one of a kind.

Boons are balanced by `tools/boon_balance.gd`: each one held at equal power
should win 52-62%. `--runs=400` (add `--greedy` for a player who drafts the
rarest critters) plays whole runs and reports where they end
(`--runs-from=K` splits the runs over processes). As of rules 13 a greedy
player clears about 24% of runs and a random one ends around floor 15.
## Ghost Arena (PvP)

Async PvP from design/pvp.md in the project files. `sim/relay.gd` runs a
lineup relay: each side brings 1-3 balls, legs are ordinary 1v1 MatchSim
fights, and a leg's winner stays in with the HP it has left (`hp` in the
MatchSim config). `game/pvp/ladder.gd` holds leagues, divisions and the
trophy rules per opponent card; `game/pvp/arena_ghosts.gd` generates the
labelled bot defences and the three daily opponent cards from fixed seeds.

Play tab -> Ghost Arena (`game/ui/screens/arena_screen.gd`) shows your league,
your trio (tap a slot to swap it) and the three cards; picking one opens
`game/ghost_arena.tscn`, which plays the relay: you aim each of your balls as
it first comes out, the ghost fires its saved shots. Trophies, your trio and
its last shots live in `user://ghost_arena.cfg` (`game/pvp/arena_store.gd`)
until the online ladder takes over trophies. An attack that is started but
not finished counts as a loss.

## Online backend (Supabase)

The game plays fully offline; the backend adds guest accounts, cloud save and
Ghost Arena (async PvP) storage. CI writes `backend_config.json` (URL + public
key) into the web build from repo secrets; without them the build is offline.

| Repo secret | What | Used by |
|---|---|---|
| `SUPABASE_URL` | `https://<ref>.supabase.co` | web build, migrations |
| `SUPABASE_ANON_KEY` | publishable (`sb_publishable_...`) or legacy anon key | web build (public by design) |
| `SUPABASE_ACCESS_TOKEN` | personal access token for the Supabase CLI | migrations only |
| `SUPABASE_DB_PASSWORD` | database password | migrations only |

- Never put a secret / `service_role` key in the game or a `SUPABASE_*` var the
  web job reads; CI refuses to build with one. All access control is
  row-level security plus `SECURITY DEFINER` functions in `supabase/migrations`.
- Schema changes are new migration files (never edit an applied one), with
  tests in `tests/db/`. They reach the live project when merged to `main`.
  Name a new file with a timestamp later than every migration on `main` (and
  never one already taken): `supabase db push` refuses to apply a file dated
  before the newest one already live, which stops every later migration too.
- `?offline=1` runs the web build without touching the backend.

### Accounts and cloud save

Everyone starts as a guest (an anonymous Supabase user). Tapping the level
badge opens **Account** (`game/online/account.gd`, `game/ui/screens/account_screen.gd`):
a guest saves their progress by email code, which links the email to the same
user id, so nothing moves. "Sign in instead" switches a device to an existing
account (the guest's local progress goes to a backup). Apple and Google
buttons appear on their own once those providers are switched on.

Cloud save (`game/online/save_game.gd`, `*_save_sync.sql`) is compare-and-swap:
the client sends the cloud revision its edits grew from, the server only
writes if that still matches and numbers revisions itself. Offline, changes
stay `dirty` on the device and go up on the next sync (boot, after fights,
when the app regains focus, every 60 s while dirty). When two devices
collide, the save with more progress (`SaveGame.progress`) wins and the other
is written to `user://save_backups` (newest 8 kept). Widen `progress` as more
of the game is saved (account level, critters).

The whole game is in the save: features that keep their own file
(`ghost_arena.cfg`, `spire.json`, `bounce_run.cfg`, `trick_shot.cfg`,
`this_week.cfg`, `legends.cfg`, `onboarding.cfg`; `SaveGame.MIRRORED`) ride
along as text in `data.files` and are written back when a cloud copy is
adopted. A new feature that saves anything either stores it in `save.data`
or adds its file to `MIRRORED`. The fight speed pick rides in
`data.settings`; other device settings (`settings.cfg`: sound,
accessibility, the Testing switches), the sign-in session and caches stay
on the device. A new device whose cloud copy already finished the
onboarding skips it as soon as the first sync lands. The game
checks for changes every 3 s and syncs right away, plus on launch, on
focus in/out and every 60 s while unsynced.

**Test mode** (`game/online/test_user.gd`, `ID := 1`): devices don't start
their own guest; they sign in to shared test account 1, so its save, Ghost
Arena trophies and league, friends and leaderboard entries are the same on
every device. CI's migrate job creates the account and gives it a fresh
random password on every deploy (`tools/supabase_auth_config.mjs`, using the
access token to read the project's server key in memory); the public
`test_login` RPC (`*_test_account.sql`) hands the login to the game, so it is
never in the repo. Anyone with the URL plays as that account, with a normal
player's rights only. If the account isn't there yet, devices carry on as
guests. The CI smoke test (an automated browser) always uses its own guests.
Set `ID := 0` to go back to one guest per device and real sign-in.

Auth settings live in code: CI's migrate job runs `tools/supabase_auth_config.mjs`
on every merge to `main` (guest linking, allowed return URLs, email codes) and
switches on Apple, Google and custom email when their secrets exist. The code
email templates go up with the `SMTP_*` secrets: Supabase's free built-in
mailer refuses custom templates, so until then its default emails carry a
sign-in link but no typed code:

| Repo secret | What |
|---|---|
| `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SERVICES_ID`, `APPLE_PRIVATE_KEY` (the .p8 text), `APPLE_BUNDLE_ID` | Sign in with Apple. The client secret Apple needs expires within 6 months, so CI makes a new one from the key each run. |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` | Google sign-in (web OAuth client). |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_SENDER` | Email from our own domain. Supabase's built-in email only reaches the project's team (a few an hour). |

**Before soft launch (iOS + Android):**
1. Custom email: a domain plus a sender such as Resend (free tier); add the `SMTP_*` secrets.
2. Apple, once the Apple Developer account exists: App ID with Sign in with
   Apple; a Services ID with domain `<ref>.supabase.co` and return URL
   `https://<ref>.supabase.co/auth/v1/callback`; a Sign in with Apple key
   (.p8, downloadable once); add the `APPLE_*` secrets. App Store rule 4.8:
   if Google sign-in is offered on iOS, Apple must be too.
3. Google (optional on the web, expected on Android): OAuth client with the
   same callback URL; add the `GOOGLE_*` secrets.
4. Store builds: the web build uses redirects; native iOS/Android builds need a
   sign-in plugin that passes Apple's/Google's id token to
   `/auth/v1/token?grant_type=id_token` (not built yet).

### Friends

`game/online/friends.gd` + `game/ui/screens/friends_screen.gd`, tables and
RPCs in `supabase/migrations/*_friends.sql`. Every player has an 8-character
friend code; invite links are `?f=<code>`, and signed-in players' replay and
challenge links carry `&f=<code>` so the receiver can add them. Friends can
rematch each other's saved Ghost Arena lineup (unranked, only a head-to-head
record moves), send one energy gift a day (2 energy; up to 10 gifts claimed a
day; the server sets the amount) and send **preset phrases only**, never free
text (Newms, 2026-10-14). `?demo=friends` shows sample friends with no server.

## Economy pacing

`meta/economy.gd` holds the economy numbers (summon odds, campaign drop
chance and zone drop pools, Summon Orb income) and the pacing targets from
design/pve.md section 6. `meta/economy_model.gd` plays simulated casual,
regular (~20 minutes a day) and heavy players through them, day by day, and
`tests/test_economy.gd` fails if the regular player's first fusion, T3, Rare
at T2, Legendary, T4 or T5 drifts out of its window.

```sh
godot --headless --script res://tools/economy_sim.gd -- --players=200 --as-built   # report, with the old numbers for comparison
godot --headless --script res://tools/economy_sim.gd -- --wishlist                 # players wishlist their top Rare+ critters
```

Changing drops, orb income, energy or the launch roster: re-run the report and
paste it in the PR.

## Analytics

`game/online/analytics.gd` queues anonymous play events (`Analytics.track(name, props)`)
and sends them in batches to `log_events()` as the signed-in guest. No names,
free text or device ids; players can turn it off in Settings (the gear) (which also
deletes what was sent), and browsers with Global Privacy Control or Do Not
Track start opted out. Smoke tests and debug builds are flagged as test
traffic. The owner's stats screen is `?stats#k=<dashboard key>` (`game/stats/`);
mint or revoke keys in the Supabase SQL editor (see the analytics migration).
`?stats&demo=1` shows it with sample numbers.

## Adding a critter

A critter is one file: `sim/critters/<id>.gd` (copy `sim/critters/_template.gd`).
It holds the name, rarity, role, stats, ability, T1-T5 ladder, look and voice.
`sim/critter_db.gd` finds every file, so the critter shows up in the fight sim,
the collection, summons, art, sound, the balance sim and the tests with no
other code.

- **Ability** = trigger + effect pairs from `sim/abilities.gd`, e.g.
  `{"on": "wall", "do": "beam"}`, with numbers in `params`. If the effect you
  need doesn't exist, add one `fx_<name>` method and its `EFFECTS` entry there.
- **Tiers** list the ladder text and any `params` that change at each tier.
  Keep text short (see `_template.gd`): T1 <= 60 chars, T2-T5 say only what
  changes ("Beam {^lamp_dps} → {lamp_dps}/sec"), and "now" is the one-line
  ability at that tier that cards, the fight HUD and Fuse show via
  `game/ui/ability_text.gd`. Numbers the sim grows with tier and rarity are
  `{param}` placeholders, filled with what the critter fights with
  (`CritterDb.fight_def`), so no screen shows a stale number. Rates are
  "/sec", never "/s". `CritterDb.validate` enforces the caps and units and
  checks the placeholders name params.
- **Look** comes from the kit in `game/ui/critter_art.gd`: a body style, a face
  and named features. A new feature is one branch in `_feature()`.
- **Status**: `planned` critters appear in the collection only; set `live` once
  the ability is built (BALANCE.md).
- `tests/test_critters.gd` checks every file; `CritterDb.validate` explains
  what's wrong.

## Damage rolls, crits, backstabs and gear

Every hit's damage is rolled within +-10% and can crit (5% base chance, x1.5),
from a roll stream seeded by the fight seed (`MatchSim.rolls`), so fights still
replay from the seed and the launch angles. A contact hit from behind (both
balls heading within 45 degrees of each other, the striker catching the other
up) is a backstab for x1.3. Damage events carry `crit` and `backstab` flags;
the arena shows gold CRIT pops and a BACKSTAB! call-out, with their own sounds.

Gear is known fight setup like tiers: `MatchSim` takes `gear: [g1, g2]` and
relays take `gear[side][slot]`, each a list of pieces or summed stat lines.
`sim/gear.gd` holds the stat lines (attack, health, defense, speed, crit
chance, crit damage, cooldown speed), the effect lines (thorns, mend,
lifesteal, ricochet, ward, revive: they set the same def keys as the Bounce
Run boons, plus `start_shield`), their 5-star values and caps, and the twelve
gear types over three slots (Shell, Core, and Charm from 3-star critters).
`balance.gd --gear` checks the lines stay worth about the same.

Gear merges like critters (design/gear.md): three of one type and tier make
one of the next tier, 1 to 5 stars, for coins (`Profile.merge_gear`,
`merge_all_gear`; costs in `meta/economy.gd`). A piece's stats come from its
type and tier alone, and every piece is worth the same power at a tier
(+1.75% at 1 star up to +5% at 5), so three 5-star pieces are the +15%
best-in-slot budget. Gear drops from the Anvil King (`meta/gear_vault.gd`, a
daily boss after the Zone 1 boss with a slot rotation by weekday), campaign
wins, Spire boss floors, the Glow Pass free track, the Bazaar, Bounce Run
chests and weekly quests. Campaign drops top out at 3 stars and are mostly 1-2
(`Economy.gear_tier`); no source drops 5 stars, which only come from merging.

## Collection battles: owned critters fight as owned

Every progression mode fights with the critters the player owns, at their
best tier and level and with the gear they wear: the campaign, Ghost Arena
(attack and the published defence) and the Spire. `sim/lineup.gd` is the one
place that turns a lineup slot `{critter, tier, level, gear}` into fight setup
(tier ability upgrades, the `sim/power.gd` multiplier, gear stat lines), with
everything clamped to the rules so a tampered ghost can't field a T9.
`Profile.slot_of(id)` gives an owned critter's slot. The slot is stored with
the fight (campaign config, `ArenaStore.pending.slots`, Spire picks), so it
still replays from setup, seed and launch angles.

Gear pieces in the save are `{uid, type, tier, on}`; `Profile.gear_piece`
fills in their name, slot, `stats` and `text` on load. Older pieces (a name
and a rarity) become the closest type, their rarity a tier
(`Profile.GEAR_TYPES`). The Power Rating counts each worn piece's worth from
its stat lines (`Gear.stats_power`), so the number matches what fights.

Practice modes stay open to every critter: Quick fight, share links and
friend challenges, Rival rematches, Trick Shot, Bounce Run's drafted cards
and Bracket picks. Arena Ghost bots grow with the ladder (T1 below 1200
trophies up to T5 from 4800; Bronze ghosts bring only Commons and Uncommons),
so ranked stays a fair climb once tiers count.

## Faction talent trees

Every critter belongs to one of nine factions (roster.md's theme families:
Fire, Frost, Nature, Sea, Tech, Spooky, Cosmic, Sweet, Toybox). Each faction
has one account-wide talent tree in `sim/talents.gd`: Core, faction and
Ability columns over four rows plus a capstone, 30 points max, rows opened by
points spent lower down. A critter only uses the rows its tier unlocks (T1 row
1 up to T5 for the capstone). Talents are conditional or faction flavour (first
seconds, after a wall bounce, below an HP line, burns, slows); flat stats stay
gear's. All of it is deterministic, so fights still replay.

The slot carries the tree as `talents: {node: rank}`; `Lineup.clean` and
`MatchSim` clean it against the critter's faction and tier, `Lineup.side` adds
Faction Bond (a capstone gets +2% power per other same-faction critter in a
relay team, up to two), and `Lineup.rating` counts +0.33% per active point.
Points come only from play (`Profile.add_xp` gives the critter's faction the
same Faction XP, and each of T2-T5 reached in the faction is a point); respecs
are free. The UI is Critters > Factions (`factions_screen.gd`,
`faction_screen.gd`).

```
godot --headless --script res://tools/talent_check.gd -- --fights=40 --per=4   # each faction's full tree vs bare
```

`Talents.STRENGTH` scales every node; the check wants each faction's full tree
to win 55-80% against the same critter bare (it landed 60-74%).

## Performance (phones, battery)

The web build draws a frame only when something on screen changed
(`OS.low_processor_usage_mode`, web only), and caps the canvas at 2x pixel
density (`export_presets.cfg` head include). Keep it that way:
- Anything that redraws every frame (`_process` + `queue_redraw`) must stop
  when hidden or off screen; one hidden redraw makes the whole screen redraw.
  Idle menu animations redraw at 20 fps (`game/ui/critter_icon.gd`).
- Godot 4.3 builds a fresh vertex buffer for every polygon, polyline and
  circle on every redraw. In fight and critter drawing use `game/dot.gd`:
  `Dot.circle` (textured quad), `Dot.poly` (batched triangles), `Dot.arc` and
  `Dot.pline` (short strokes as batched lines). Static art goes on a canvas
  item that isn't redrawn each frame (the arena floor layer in `arena_view.gd`).
- `?perf=1` logs a `PERF` line every 2s: frames drawn, fps, draw calls.

## Live fights (server)

Live Quick fights pair two players of similar power; the plan is
design/live-quick-fight.md in the project files. Nothing is switched on for
players yet. `server/live_server.gd` is the always-on referee: headless Godot
running `sim/`, speaking JSON over WebSockets. It pairs the queue, holds both
launch angles until both are in, and runs the fight itself; the phones replay
it from the same inputs (`sim/live_match.gd` builds the config for all three)
and report their end hash, so a desync or an edited client shows up.
`server/live_lobby.gd` has the rules without the networking (`tests/test_live_lobby.gd`).

```sh
LIVE_DEV=1 godot --headless --script res://server/live_server.gd     # local, any token signs in
godot --headless --script res://tools/live_bot.gd -- --name=a        # a pretend player (run two)
GODOT=godot tools/ci/live_e2e.sh                                     # both, as CI does
docker build -f server/Dockerfile -t battleballs-live .              # the image Azure will run
```

In the game, Quick fight's FIGHT! finds a live foe when Settings > Testing >
Live Quick fights is on (`Dev.LIVE_SERVER` in `game/dev.gd` is the Azure server), or for one
visit with `?live=ws://127.0.0.1:8080` (add `&auto=1` to queue and launch at
once). `game/online/live_client.gd` is the phone's side of the protocol; you can
be on sim side 1, so the arena, health bars and result follow `you_side`.
Smoke case 1c plays a live match between two browsers on a local server.

CI's `live_server` job builds and smoke-starts the image on every PR; on `main` it
pushes it to GitHub Packages (`ghcr.io/newmsy/battleballs-live`) and, once the
`AZURE_*` secrets exist, rolls it out to the Azure Container App `battleballs-live`
(one-time setup: design/azure-live-server-setup.md in the project files).

Players only meet on the same `sim_version` (`sim/sim_version.gd`, a hash of
`sim/`; exports carry it in `sim_version.txt`). The web build's `?probe=1` and
`tools/probe.gd` print a hash over a varied fight set; the smoke test fails if
they differ, which means something in `sim/` behaves differently per platform.

## Store apps (Google Play, App Store)

Device-specific things go through one provider per build
(`game/platform/platform.gd`, `Platform.get_current()`): `web_platform.gd`,
`android_platform.gd`, `ios_platform.gd`, and the base class (desktop and tests,
does nothing). It covers haptics (`haptic("hit")`, fight buzzes from sim events
in `fight_haptics.gd`, Settings > Vibration), sharing (clipboard until a share
plugin lands), safe areas (the shell keeps its top bar and tabs clear of the
notch and home bar), the store (`make_store`, see the shop section), and stubs
for local notifications and native Google / Apple sign-in. Screens never test
`OS.has_feature` for these themselves. Android's Back does what a left-edge
swipe does (`game/ui/touch_input.gd`); twice at Home leaves the game.

**Android.** `.github/workflows/android.yml` builds a signed `.aab` from main
(and from PRs that touch the Android build) with `tools/ci/export_android.sh`:
Godot 4.3's Gradle template, patched to target SDK 36 (Play's floor since
31 Aug 2026), plus the Google Play Billing plugin 3.3 in
`addons/GodotGooglePlayBilling` (Billing Library 9). Download it from the run's
Artifacts. Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`; with `PLAY_SERVICE_ACCOUNT_JSON` too, main uploads each
build to the internal testing track as a draft. Without the keystore it signs
with a throwaway key Play refuses. Package name `com.newms.battleballs`.
Godot 4.3's Android libraries are 4 KB-aligned; Play blocks updates without
16 KB page support from 1 Feb 2027, so the engine has to move to 4.5+ before then.

**iOS.** The `iOS` preset exports an Xcode project (bundle id as Android, team
id still empty). Needs a Mac with Xcode, the Apple developer account and the
InAppStore plugin from godot-ios-plugins in `ios/plugins/`.

## Rules for changes

- Fights must stay deterministic: no `randf()`, `Time`, engine physics or
  frame-rate-dependent logic in `sim/`. Use `sim/rng.gd`.
- Fights must also match across platforms (desktop, web, phones): no built-in
  `sin`/`cos`/`atan2`/`pow` or `Vector2.from_angle`/`rotated`/`angle`/`angle_to`
  in `sim/`, since each platform's maths library rounds them differently. Use
  `sim/dmath.gd`; `tests/test_determinism.gd` fails otherwise.
- If a change alters the outcome of a golden replay, re-record it with
  `tools/record_golden.gd` and say so in the PR as an intended balance change.
- Balance follows [BALANCE.md](BALANCE.md): power beats counters, no equal-power
  matchup over 65%, no hard counters. Balance is not checked in CI and never
  blocks a PR; it's tuned in batches with the on-demand `Balance audit` workflow.

## Merging

When every CI job passes on a PR that is **not a draft**, the `Auto-merge` job
squash-merges it and rebuilds `main`. Keep a PR in draft until its code review
is done; marking it ready re-runs CI and merges it once green.

Draft pushes run only the unit and database tests; the web build and smoke
test run once a PR is ready; `main` runs
the unit and database tests, then builds, deploys and migrates without
repeating the smoke test. Run the full checks locally before pushing (see
CLAUDE.md), and push a draft in a few larger steps rather than many small ones.

A ready PR's slow checks run side by side, and only where the diff can reach
them (`tools/ci/changes.sh`): the smoke test is split over 4 machines
(`SMOKE_SHARD=k/n node smoke.mjs`, each runs its share of the cases), and a PR
that only changes docs, notes or the headless balance tools skips the smoke
test.

Balance checks don't run in CI (Newms, 2026-10-15: as little friction as
possible from idea to testing). The `Balance audit` workflow (run it from
Actions > Balance audit > Run workflow) fights every pairing everywhere when
we do a balance tune; `tools/balance.gd` and `tools/boon_balance.gd` run
locally too (BALANCE.md, "What checks it").

## Cosmetics, the shop and the Glow Pass

Design: `design/monetisation.md`. Money never buys power: real money buys only
Glow Gems, the season's premium pass track and the Founder Pack; gems buy only
cosmetics and the pass. Every power reward sits on the pass's free track.

- `game/glow/catalog.gd` is all the data: cosmetics (hat, trail, hit spark, KO
  effect), bundles, store products. A new cosmetic is one entry there plus, if
  it needs a new look, one `style` branch in `cosmetic_art.gd`.
- Cosmetics are drawn by `arena_view.gd`, never passed to the sim, so fights
  still replay from angles + seed. The YOU/FOE rings, tags and HP badges are
  drawn last, over every cosmetic.
- `game/glow/store.gd` is the store interface; `Store.make()` picks the store:
  `apple_store.gd` (StoreKit, needs the godot-ios-plugins InAppStore plugin),
  `play_store.gd` (needs the GodotGooglePlayBilling plugin), the free fake
  store ("Test store") while Settings > Testing is on, and otherwise
  `no_store.gd`, which sells nothing: the web build hides gem packs and the
  paid pass. Real stores record each purchase with `record_purchase`
  (`supabase/migrations/*_purchases.sql`) before granting it and finish the
  transaction only after. Store product ids are the catalog ids. Receipts are
  stored but not yet verified with Apple / Google (needs store credentials).
- Pass levels come from play (fights, daily bounties, the weekly chest, Trick
  Shot); a new season in `liveops/liveops.json` starts a fresh pass.
- `tests/test_glow.gd` guards the rules: no power for money, fixed prices,
  cosmetics don't change a fight, rings draw last, colours stay clear of the
  team rings. `?screen=shop` and `?screen=pass` open the screens directly.
