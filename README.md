# MultiBot Chatless

## mod-playerbots-portable fork

A bot-control interface for **WoW 3.3.5a, build 12340** (Interface `30300`),
maintained for
[mod-playerbots-portable](https://github.com/Syntax555/mod-playerbots-portable).
This fork builds on
[Wishmaster117/MultiBot-Chatless](https://github.com/Wishmaster117/MultiBot-Chatless)
and uses the matching server's
[MultiBot Bridge](https://github.com/Syntax555/mod-multibot-bridge) for bot data
and validated actions.

## Install or update

1. Download
   [MultiBot-Chatless-latest.zip](https://github.com/Syntax555/MultiBot-Chatless/releases/latest/download/MultiBot-Chatless-latest.zip)
   from this fork's [Latest release](https://github.com/Syntax555/MultiBot-Chatless/releases/latest).
2. Close WoW completely. Back up the existing `Interface/AddOns/MultiBot/`
   folder, then replace it with the ZIP's `MultiBot/` folder. The resulting
   path must be `Interface/AddOns/MultiBot/MultiBot.toc`.
3. Keep `WTF/`, including account and character `SavedVariables`, to preserve
   settings. Enable MultiBot on the character-selection AddOns screen.
4. Use the matching
   [portable server](https://github.com/Syntax555/mod-playerbots-portable/releases/latest).
   For historical talents, also install its complete
   [EraTalents client pack](https://github.com/Syntax555/mod-playerbots-portable/blob/main/docs/era-talents.md#install-the-matching-client-files),
   including the matching MPQ.

Open the interface with `/mb`, `/mbot`, `/multibot` or its minimap button;
open settings with `/mbopt`. A repository source ZIP needs its containing
folder renamed to `MultiBot`; the Latest package already has the correct layout.

## Supported behavior

- Manage bot rosters, group controls, inventories, equipment, quests and other
  companion views through the bridge-backed interface. Available actions depend
  on server capabilities and permissions.
- Open historical bot talents through EraTalents. With the matching DragonUI
  talent module, the view appears in DragonUI; otherwise EraTalents uses the
  Blizzard inspect window. Controlled group altbots can spend their own earned
  talent points; other characters remain read-only. Normal inspect access and
  range still apply.
- Select **Automatic** or a manual combat profile for controlled altbots and
  active SelfBots. The matching server applies class strategies and checks
  suitable gear already in the bot's bags. Profile selection does not spend
  talent points or grant gear, abilities or gold. See
  [combat profiles](https://github.com/Syntax555/mod-playerbots-portable/blob/main/docs/combat-profiles.md).
- Buy merchant items for the selected altbot with its own gold: open that bot's
  inventory, select **Buy**, then click the merchant item. The bot must be able
  to interact with the vendor. Changing bots, leaving Buy mode or closing the
  inventory cancels pending purchase confirmations.
- Display bot money as gold, silver and copper, read the bridge's spellbook
  entries, preserve saved options and use the server's supported role strategies.

The addon uses structured bridge messages for many reads and actions; some
intentional Playerbots chat commands remain. Automatic legacy chat fallback is
disabled by default. This fork is intended for the matching server and bridge;
an unrelated bridge or server may lack features or apply different rules.
Historical trees require matching EraTalents files. The native-tree realm mode
keeps MultiBot's own talent window.

Source fixtures and the release workflow check selected behavior and Lua 5.1
syntax. They do not establish complete in-game coverage of every control or
addon combination. For errors, record the action, first Lua error, installed
`MultiBot/SOURCE_REVISION.txt`, server revision and enabled addons; see
[client diagnostics](https://github.com/Syntax555/mod-playerbots-portable/blob/main/docs/addons.md#blocked-interactions-and-lua-errors).

## Source and contributions

Work on this fork's `main` branch. Its
[Latest workflow](https://github.com/Syntax555/MultiBot-Chatless/blob/main/.github/workflows/latest.yml)
checks and packages the addon before replacing the rolling download. Update
from this fork to retain its server integrations. The server's
[dependency manifest](https://github.com/Syntax555/mod-playerbots-portable/blob/main/versions.lock.json)
records its exact tested fork commit and imported upstream revision; Latest may
be newer than that pin.

[Report a fork issue](https://github.com/Syntax555/MultiBot-Chatless/issues),
read [AGENTS.md](https://github.com/Syntax555/MultiBot-Chatless/blob/main/AGENTS.md)
and follow the server's
[contribution guide](https://github.com/Syntax555/mod-playerbots-portable/blob/main/CONTRIBUTING.md)
for integration changes. General upstream controls and technical documentation
are described in the
[imported upstream README](https://github.com/Wishmaster117/MultiBot-Chatless/blob/80148dff3f3a25a56d38dba0ecbd4f165b8c1d3f/README.md);
its downloads and server setup refer to the original project.

## Credits and license

The upstream README credits **Macx-Lio** for the original MultiBot module;
the addon TOC names **Nico Löbbert** as author. **Wishmaster117 (TheWarlock)**
maintains MultiBot Chatless, building on AzerothCore and Playerbots. Attribution for the selectively adapted **Jellypowered** bridge
work is preserved in the
[imported upstream roadmap](https://github.com/Wishmaster117/MultiBot-Chatless/blob/80148dff3f3a25a56d38dba0ecbd4f165b8c1d3f/docs/ROADMAP.md).

The repository includes the
[GNU General Public License version 3 text](https://github.com/Syntax555/MultiBot-Chatless/blob/main/LICENSE).
Bundled libraries retain their own license and copyright notices.
