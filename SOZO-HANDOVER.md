# Sozo on the TV: handover

State as of 2026-11-06. Sozo is a third-party streaming app (`professorDeveloper/sozo-tv`); its webOS
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
| `webos-native-relabel` | [#45](https://github.com/professorDeveloper/sozo-tv/pull/45) | Loopback relay service so the native player plays vidapi; stacked on #42 |
| `tv-build` (local only) | – | All four merged; this is what the TV runs (`2d11f92a`) |

Open question in #45 to @professorDeveloper: fix vidapi's content type in the backend relay from #36
(`/api/contents/media-segment`) instead of on the device. If he says yes: the backend must accept vidapi's
rotating hosts, relay playlists as well as segments (webOS native has no playlist hook, unlike AVPlayer in
#36) and carry all video bandwidth. Then #45 shrinks to a URL rewrite or closes; #42/#43 stay.

PR bodies follow the `mattpocock-skills:pr` template (Summary, Evidence, Merge Danger), titles `webOS: ...`,
no AI credit. Pushing workflow-touching history needs a token with the `workflow` scope; Claude does not
handle tokens, Captain runs pushes/PR creation himself.

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
  ES5 for webOS 4's Node. `ares-package` always prints a Node-version notice for services; `package.js`
  whitelists exactly that line.
- **Subtitles** are fetched and drawn by the app (`renderCue`), so the offset works with native and hls.js.
- **UniFi:** content-filter category FAMILY (and/or ADVERTISEMENT) blocked `uzbeklar.biz`, `strem.io`
  (vidapi subtitles) and `paste.pics` (sportstv posters). All three were added to the allow lists of both
  `Default` filters and both `LGwebOSTV_privacy*` filters on 2026-11-06. Block symptom: DNS answers
  `2001:db8:1000::fa` / `203.0.113.250`, then `ERR_CERT_AUTHORITY_INVALID` with a UniFi CA cert.
  Controller: `https://192.168.1.100:8443` (the UniFi MCP was disconnected; the logged-in Chrome session works).
- The LG emulator (VirtualBox, x86, last version webOS 6) is no use here; the simulator runs web apps only
  and cannot run the relay service.

## Open

- **Screensaver test:** leave Sozo idle on Home (LG screensaver should appear) and play a vidapi film ~10 min
  without input (it should not). Not done yet.
- Follow up on PR review for #42-#45; drafts of any replies go to Captain, he posts.
- Untested: webOS 4-6, Developer Mode `ares-install`, relay across app suspend/resume, sportstv on the TV.
- Both GitHub tokens used on 2026-11-06 appeared in a chat transcript and must be revoked.
