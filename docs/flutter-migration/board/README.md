# Flutter 移植看板服务

改状态由写盘服务执行，不要只改浏览器 localStorage。

```bash
node docs/flutter-migration/board/server.js
```

打开 http://127.0.0.1:8791/

- 页面下拉状态 → `POST /api/status` → 立刻写 `tasks.json` 和 `docs/flutter-migration/BOARD.md`
- 代理人：`node docs/flutter-migration/board/sync-board.js --set S1.P1.T22=已编码·未确认`
- 验收「已确认」：页面确认框，或 `--set ID=已确认 --allow-confirm`
- 直接改 `BOARD.md` 后，服务会把状态同步回 JSON（约 250ms）
