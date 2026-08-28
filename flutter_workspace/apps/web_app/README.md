# Shouyin Flutter Web

## Local development

From the repository root, run:

```sh
node flutter_workspace/tool/web_dev_runner.js
```

Then open <http://127.0.0.1:8183/>. The runner starts Flutter Debug on an
internal loopback port and exposes a single loopback origin that keeps the
original Vue development service paths:

- `/api/server` for the primary API;
- `/online/server` for synchronization HTTP calls;
- `/socket/server` for WebSocket traffic.

The runner also performs the same development cash-register terminal
authorization that the Vue registration screen provides. The terminal code is
read server-side from the existing Vue development configuration, substituted
only into the loopback `/term/auth` request, and is never added to Flutter
defines, browser JavaScript, or runner output. A failed authorization falls
back to the normal terminal-code form.

The insecure exception is compiled only into Flutter Debug when
`SHOUYIN_ALLOW_INSECURE_LOOPBACK=true`, accepts only `localhost`, `127.0.0.1`,
or `::1`, and still requires every endpoint to use the exact same origin and
port. Release builds continue to require HTTPS APIs and WSS on the deployment
origin.
