# Sozo on the TV: handover

State as of 2026-11-06, end of day: all review points answered, waiting on the dev. Sozo is a third-party streaming app (`professorDeveloper/sozo-tv`); its webOS
client arrived in upstream PR #41. This file is the pickup point for continuing work on it with this TV.
Read `~/git/personal/slopbro/TV-HANDOVER.md` first for TV access (SSH alias `tvtje`, CDP, root bridge).

## Where things are

| What | Where |
|---|---|
| Fork checkout | `~/git/personal/sozo-tv` (origin `ArnoldDeRuiter/sozo-tv`, remote `upstream` = `professorDeveloper/sozo-tv`) |
| Upstream base | `upstream/integrating-apple-tv`. #41 was merged there, not into `master` |
| webOS app | `webos/` in the fork; `webos/README.md` covers build, install, sources and tests |
| Installed app | `com.soplay.sozo.webos` in `/media/developer/apps/usr/palm/applications/` on the TV, plus the service `com.soplay.sozo.webos.service` in `.../services/` |
| Simulator notes | `~/git/personal/opencdi-docs/doc/webos-simulator.md` (webOS TV 25 Simulator, `sim-ipk` helper in `~/.local/bin`) |

Sozo is **not** managed by `ansible/site.yml`; installs are manual (below).

## Branches and PRs

All based on `upstream/integrating-apple-tv`, pushed to the fork, PRs open upstream (as ArnoldDeRuiter):

| Branch | PR | What |
|---|---|---|
| `vidapi-hlsjs` | [#42](https://github.com/professorDeveloper/sozo-tv/pull/42) | vidapi `hlsjs: true`: native fails on its `text/html` segments, hls.js plays them |
| `hls-start-estimate` | [#43](https://github.com/professorDeveloper/sozo-tv/pull/43) | `abrEwmaDefaultEstimate: 5000000`: hls.js starts on the top level (800p) instead of 266p |
| `subtitle-offset` | [#44](https://github.com/professorDeveloper/sozo-tv/pull/44) | Subtitle timing chips `[−0.5 s] Timing: x [+0.5 s] [Reset]` in the panel header |
| `webos-native-relabel` | [#45](https://github.com/professorDeveloper/sozo-tv/pull/45) | Loopback relay service so the native player plays vidapi; stacked on #42. Head `93227436` (pushed) |
| `tv-build` (local only) | – | All four merged; this is what the TV runs (`046cb157`) |

### Review status

@professorDeveloper (first real-TV report for the webOS app): will merge #42, #43 and #44 once CI is green;
uz/ru strings in #44 approved. On #45 he chose the on-device relay over the backend, and asked for:

1. Test a Developer Mode `ares-install` and an older webOS. **Not possible here:** the TV is rooted, has no
   Developer Mode and Captain doesn't want it; no older webOS hardware. `ares-install` against root SSH uploads
   fine but the TV's sshd refuses its exec step (`Unable to exec`), so it is no stand-in. Offered instead:
   "tested on webOS 10.3 only". Possible partial check: run `test/relay.test.js` under old Node versions.
2. Limit who can use the relay. **Done** (`0b0eb1aa`, `3aea7589`): `relay` answers only when
   `message.sender === 'com.soplay.sozo.webos'` (shell `luna-send` gets `caller not allowed`), service is
   `public: false` (Sozo still reaches it, verified), upstreams must resolve to public addresses (checked in each
   connection's `lookup`, on every redirect hop).
3. Backpressure and redirect abort. **Done** (`0b0eb1aa`): media is piped after sniffing the first chunk; each
   redirect hop aborts its request; client close aborts the live hop.

Later rounds on #45 (all fixed, tested, and run on the TV):

4. A redirect to a non-http scheme crashed the relay (`ERR_INVALID_PROTOCOL` in the response callback).
   **Done** (`ffc565b1`): redirect targets go through `isUpstream`, `http.get` is wrapped in try/catch, both 502.
5. Non-Latin paths (`/файл.ts`) threw `ERR_UNESCAPED_CHARACTERS`. **Done** (`93227436`): non-ASCII path
   characters are percent-encoded before the request.
6. Expanded IPv6 (`0:0:0:0:0:0:0:1`, `0:0:0:0:0:ffff:7f00:1`) passed `isPublicAddress`. **Done** (`93227436`):
   IPv6 is normalised to eight groups first; IPv4-mapped, 6to4, Teredo and NAT64 forms are covered.

Each fix's test fails on the commit before it. CI upstream was green at 164/164 before the last two commits;
locally 166 unit / 100 browser. He also asked whether sportstv plays (yes, see Findings) and for the PR's
Evidence to be updated.

Current state: all four branches are pushed and match local. #45's description was replaced with updated
Evidence and Merge Danger. Captain posted the combined #45 reply and short confirmations on #42-#44 (browser
test counts and TV results, which upstream CI doesn't cover). The dev approved #42, #43 and #44 and said he'd
merge once CI is green; #45 waits on his response. Only #45's Developer Mode / older webOS request stays
unmet (not possible here, said so in the reply).

Next: when #42 merges, #45's diff shrinks to the relay commits; if GitHub reports a conflict, update the
branch and push. After merges, rebuild the TV install from upstream instead of `tv-build`.

Open question in #45 to @professorDeveloper: fix vidapi's content type in the backend relay from #36
(`/api/contents/media-segment`) instead of on the device. If he says yes: the backend must accept vidapi's
rotating hosts, relay playlists as well as segments (webOS native has no playlist hook, unlike AVPlayer in
#36) and carry all video bandwidth. Then #45 shrinks to a URL rewrite or closes; #42/#43 stay.

PR bodies follow the `mattpocock-skills:pr` template (Summary, Evidence, Merge Danger), titles `webOS: ...`,
no AI credit. Pushing workflow-touching history needs a token with the `workflow` scope; Claude does not
handle tokens, Captain runs pushes/comments himself with `~/.local/bin/sozo-gh` (below).

`sozo-gh` reads `GH_TOKEN`, stops unless it belongs to ArnoldDeRuiter, and works on `~/git/personal/sozo-tv`
(override with `SOZO_REPO`):

```sh
GH_TOKEN=<token> sozo-gh push <branch>...                            # push to the fork
GH_TOKEN=<token> sozo-gh comment <pr> <file.md> [<pr> <file.md>...]  # comment on upstream PRs
GH_TOKEN=<token> sozo-gh body <pr> <file.md>                         # replace a PR description
```

Keep reply files on a short path (e.g. `cd ~/sozo-replies` and relative names): a wrapped paste splits the
command line and nothing gets posted.

## Build, test, install

```sh
cd ~/git/personal/sozo-tv/webos
npm ci --ignore-scripts
npm test                                              # unit + ES5 + package checks (159 on tv-build)
SOZO_CHROMIUM=/usr/bin/google-chrome npm run test:browser   # 100 on tv-build; Playwright's own Chrome is not installed
npm run package                                       # dist/ipk/com.soplay.sozo.webos_1.0.0_all.ipk, app + service verified byte for byte
```

Install on the TV (`luna-send` prints nothing without a tty, so `ssh -tt`):

```sh
scp dist/ipk/com.soplay.sozo.webos_1.0.0_all.ipk tvtje:/tmp/sozo.ipk
ssh -tt tvtje 'luna-send -w 60000 -i luna://com.webos.appInstallService/dev/install "{\"id\":\"com.soplay.sozo.webos\",\"ipkUrl\":\"/tmp/sozo.ipk\",\"subscribe\":true}"; rm -f /tmp/sozo.ipk'
```

The last line reads `"state":"installed"`, then a harmless `install has been disconnected` when `-w` runs out.
Launch: `ssh -tt tvtje 'luna-send -n 1 luna://com.webos.applicationManager/launch "{\"id\":\"com.soplay.sozo.webos\"}"'`.

Live debugging: CDP is only reachable on the TV's loopback. Tunnel `ssh -N -L 19998:127.0.0.1:9998 tvtje`,
pick the target whose `description` is `com.soplay.sozo.webos` from `http://127.0.0.1:19998/json`, and use
a raw WebSocket client (handshake as in any app's `loginfill.py`). `window.Sozo` exposes `App`, `Player`,
`Playback`, `Nav`; `Sozo.App.relabel.ready()` shows whether the relay service answered.

## Findings worth keeping

- **TV:** webOS 10.3.1 = webOS TV 25, Chromium 120, Node 16.20 with global `webos-service`.
- **vidapi:** segments are real MPEG-TS sent as `text/html`. TV native: `MEDIA_ELEMENT_ERROR: Format error`
  in 0.9 s. Relabelled (`video/mp2t`, playlists `application/vnd.apple.mpegurl`): native plays, first frame
  ~1.0-1.7 s, settles on 1920x800. Segment host sends `Access-Control-Allow-Origin: *`.
- **Relay service:** loopback only, free port, per-run hex token; the app holds a subscription to keep it alive.
  Private, Sozo-only caller, public upstreams only (IPv6 normalised), non-ASCII paths percent-encoded, any URL
  `http.get` rejects answers 502 (tests: `test/relay.test.js`). ES5 for webOS 4's Node.
  `ares-package` always prints a Node-version notice for services; `package.js` whitelists exactly that line.
- **sportstv:** plays natively at 1920x1080 on the TV without the relay or hls.js (Setanta Sports 1 Eurasia via
  `stream.mcquack.net`, Futbol via `185.121.1.163:8083`, both plain HTTP). Live channels get their stream via
  the episode's `mediaRef` and `/api/contents/media`, not via `videoSources` from `/episodes`.
- **Subtitles** are fetched and drawn by the app (`renderCue`), so the offset works with native and hls.js.
- **UniFi:** content-filter category FAMILY (and/or ADVERTISEMENT) blocked `uzbeklar.biz`, `strem.io`
  (vidapi subtitles) and `paste.pics` (sportstv posters). All three were added to the allow lists of both
  `Default` filters and both `LGwebOSTV_privacy*` filters on 2026-11-06. Block symptom: DNS answers
  `2001:db8:1000::fa` / `203.0.113.250`, then `ERR_CERT_AUTHORITY_INVALID` with a UniFi CA cert.
  Controller: `https://192.168.1.100:8443` (the UniFi MCP was disconnected; the logged-in Chrome session works).
- The LG emulator (VirtualBox, x86, last version webOS 6) is no use here; the simulator runs web apps only
  and cannot run the relay service.

## Gotchas

- `pkill -f <pattern>` inside an `ssh tvtje '...'` one-liner matches its own command line and drops the session.
- Leaving a live channel: Back opens "Keep watching / Leave"; Leave is one Right then OK. Synthetic key events
  need `keyCode` set via `Object.defineProperty` (see `pressCode` in `webos/test/browser/harness.js`).
- `httpbin.org/redirect-to` refuses `ftp:` targets with its own 403, so it can't test a non-http redirect live.
- PR pushes need a token with `repo` and `workflow` scope (the base branch carries workflow changes the fork
  lacks). The push/PR scripts read `GH_TOKEN`; Captain runs them himself.

## Open

- **Screensaver test:** leave Sozo idle on Home (LG screensaver should appear) and play a vidapi film ~10 min
  without input (it should not). Not done yet.
- Follow up on PR review for #42-#45; drafts of any replies go to Captain, he posts.
- Untested: webOS 4-6, Developer Mode `ares-install`, relay across app suspend/resume.
- All three GitHub tokens used on 2026-11-06 appeared in a chat transcript and must be revoked.
