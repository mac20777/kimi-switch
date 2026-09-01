# ROADMAP

按"价值 / 成本"分档，已实现的勾掉。

## 已实现

- [x] 账号快照保存 / 一键互换（凭证 + api_key），缩写命令 `ks`
- [x] 用量总览：5 小时滚动窗口、每周额度、加油包（`ks usage`）
- [x] 启动时自动选号：`ks go` 切到余量最多的账号再启动 kimi
- [x] 偏好保持：`ks go` 启动前自动套用默认模型 / 权限模式 / 思考强度到 config.toml（`ks prefs` 管理）
- [x] 账号身份：save 时记录昵称 / 手机号，`ls` 里直接显示
- [x] 状态栏集成：tui.toml status_line.command 显示当前账号和余量（读本地缓存，不走网络）
- [x] token 自动刷新并写回快照（防止 refresh token 轮转失效）
- [x] 切换后提示 `kimi --session <id>` 恢复当前目录上次的对话

## 第二档：防翻车

- [ ] 额度告警：定时检查，当前账号 5h 窗口用量超 80% 时弹系统通知（launchd/cron）
- [ ] `kimi-switch doctor`：校验每个快照的 refresh token 是否有效、文件权限、config.toml 完整性
- [ ] 用量历史：每次查询追加 CSV，观察消耗节奏、预测额度见底时间

## 第三档：扩大边界

- [ ] 支持 Kimi 开放平台（api.moonshot.cn 按量 key）及其它 AI CLI 的账号切换
- [ ] 快照改存 macOS Keychain（目前是 0600 明文文件）
- [ ] Linux 适配验证（目前只在 macOS 上测过）
