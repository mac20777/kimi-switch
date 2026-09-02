# ROADMAP

按"价值 / 成本"分档，已实现的勾掉。

## 已实现

- [x] 账号快照保存 / 一键互换（凭证 + api_key），缩写命令 `ks`
- [x] 用量总览：5 小时滚动窗口、每周额度、加油包（`ks usage`）
- [x] 启动时自动选号：`ks go` 切到余量最多的账号再启动 kimi
- [x] 偏好保持：`ks go` 启动前自动套用默认模型 / 权限模式 / 思考强度到 config.toml（`ks prefs` 管理）
- [x] 项目目录记忆：`ks dirs` 最近项目 + 各自上次会话标题；`ks go <编号>` 跳回并恢复上次会话（会话历史按项目目录存放）
- [x] 账号身份：save 时记录昵称 / 手机号，`ls` 里直接显示
- [x] 状态栏集成：tui.toml status_line.command 显示当前账号和余量（读本地缓存，不走网络）
- [x] token 自动刷新并写回快照（防止 refresh token 轮转失效）
- [x] 切换后提示 `kimi --session <id>` 恢复当前目录上次的对话
- [x] 热切换：核实 CLI 每次请求都重读凭证文件，切换对运行中的会话即时生效；原子写入（tmp+rename）防止被读到半截文件
- [x] 快照自愈：`synclive` 把 CLI 运行时轮转过的最新凭证回同步到快照（`use`/`usage`/`go` 入口自动执行）
- [x] 切换前置校验 `freshen`：refresh token 已死的快照拒绝装入 live（失效凭证会被 CLI 刷新失败后写成空 token 墓碑）
- [x] 状态栏预渲染：`statusline` 变成纯 cat 本地文件，杜绝 300ms 超时回退内置布局造成的闪烁

## 第二档：防翻车

- [ ] 额度告警：定时检查，当前账号 5h 窗口用量超 80% 时弹系统通知（launchd/cron）
- [ ] `kimi-switch doctor`：校验每个快照的 refresh token 是否有效、文件权限、config.toml 完整性
- [ ] 用量历史：每次查询追加 CSV，观察消耗节奏、预测额度见底时间

## 第三档：扩大边界

- [ ] 支持 Kimi 开放平台（api.moonshot.cn 按量 key）及其它 AI CLI 的账号切换
- [ ] 快照改存 macOS Keychain（目前是 0600 明文文件）
- [ ] Linux 适配验证（macOS 与 Windows Git Bash 已验证）
