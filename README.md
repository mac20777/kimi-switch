# kimi-switch

一键切换 [Kimi Code CLI](https://www.kimi.com/code/docs/en/) 账号的小工具（macOS / Linux，Bash + Python3，无第三方依赖）。

适合同时持有多个 Kimi 会员账号、想在 CLI 里轮换使用额度的人。

## 功能

- **一键换号·热切换**：`ks` 在两个账号间互切（凭证文件 + api_key 快照原子替换）；CLI 每次请求都重读凭证文件，**运行中的会话下一条消息即生效，无需重启**
- **自动选号启动**：`ks go` 查询各账号余量，自动切到剩余最多的账号再启动 kimi
- **自动化换号**：`ks rotate` 无交互切到仍有额度的最佳其他账号，不启动新会话、不改模型偏好
- **偏好保持**：每次 `ks go` 启动前自动套用偏好到 config.toml（默认 YOLO 模式 + K3 模型 + max 思考），解决 CLI 每次打开都要重选的问题；用 `ks prefs` 查看 / 修改
- **项目目录记忆**：`ks go` 自动记录用过的项目目录；`ks dirs` 列出最近项目及各自上次的会话标题，`ks go <编号>` 跳回项目并接着上次的对话聊（会话历史按项目目录存放，找到项目 = 找到聊天记录）
- **用量总览**：`ks usage` 并排查看所有账号的 5 小时滚动窗口、每周额度、加油包
- **账号身份**：save 时自动记录昵称和手机号，`ls` 里一眼分清谁是谁
- **状态栏集成**：在 Kimi Code 底部常驻显示"当前账号 · 本周剩余 · 5h 剩余"（纯 cat 预渲染文件，零进程启动）
- **token 自维护**：access token 过期自动刷新并写回快照；`synclive` 把 CLI 运行时轮转过的最新凭证自动回同步到快照，快照不会悄悄失效
- **防墓碑校验**：`use` 切换前校验快照的 refresh token，已失效则拒绝装入（失效凭证被 CLI 刷新失败后会变成空 token 墓碑）

## 安装

```bash
cp kimi-switch ~/.local/bin/kimi-switch
chmod +x ~/.local/bin/kimi-switch
ln -sf ~/.local/bin/kimi-switch ~/.local/bin/ks   # 缩写，以后敲 ks 即可
```

确保 `~/.local/bin` 在 `PATH` 里。

## 首次设置（只做一次）

1. 在 kimi 里 `/login` 登录账号 A，然后运行 `ks save A`
2. 在 kimi 里 `/login` 换成账号 B，再运行 `ks save B`
3. 以后敲 `ks` 互切，或用 `ks go` 代替 `kimi` 启动（自动选号 + 套用偏好）

## 命令

| 命令 | 作用 |
| --- | --- |
| `ks` | 一键互换（两个账号时）；多账号弹出编号菜单 |
| `ks go` | 自动选号 + 套用偏好并启动 kimi（当前目录开新会话） |
| `ks go <编号>` | 跳回最近项目并接着上次的对话聊（`ks go last` = 上一个项目；加 `new` 开新会话） |
| `ks dirs` | 最近项目列表，附各项目上次的会话标题和时间 |
| `ks dir <编号>` | 只打印项目路径，配合 `cd "$(ks dir 2)"` |
| `ks prefs` | 查看偏好；`ks prefs model/permission/effort <值>` 修改 |
| `ks usage` | 查看所有账号用量（5 小时窗口 / 每周额度 / 加油包） |
| `ks ls` | 列出所有账号（含昵称），`*` = 当前生效 |
| `ks current` | 显示当前账号名 |
| `ks use <名字>` | 切换到指定账号（热切 + 前置校验） |
| `ks rotate` | 无交互切到仍有额度的最佳其他账号；无可用账号时返回非零状态 |
| `ks synclive` | 把 live 里 CLI 刷新过的最新凭证回同步到当前账号快照（`use`/`usage`/`go` 已自动做） |
| `ks save <名字>` | 把当前登录态存为快照 |
| `ks rm <名字>` | 删除快照 |
| `ks statusline` | 状态栏输出（见下文） |
| `ks help` | 查看帮助 |

（所有命令用全名 `kimi-switch` 也一样生效。）

## 状态栏

在 `~/.kimi-code/tui.toml` 里加：

```toml
[status_line]
command = "/Users/<你>/.local/bin/kimi-switch statusline"
```

效果：`B(用户5586) · 周剩100/100 · 5h剩100/100`。

状态栏直接 `cat` 预渲染文件（`.statusline.txt`），零进程启动、远低于 300ms 预算、不发网络请求；内容由 `usage` / `go` / 切换命令自动刷新。

## 注意

- 切换对**正在运行**的 kimi 会话即时生效（已对 0.39 源码核实：CLI 每次请求都重读凭证文件），无需重启
- 聊天记录存在本地 `~/.kimi-code/sessions/`，不按账号区分，切换后不丢也不变；切换后会提示 `kimi --session <id>` 恢复当前目录上次的对话
- 快照保存在 `~/.kimi-code/accounts/`（目录 700 / 文件 600），不会打印密钥
- 如果设置了 `KIMI_CODE_HOME` 环境变量，工具会跟着走

## License

MIT
