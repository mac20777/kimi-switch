# kimi-switch

一键切换 [Kimi Code CLI](https://www.kimi.com/code/docs/en/) 账号的小工具（macOS / Linux，Bash + Python3，无第三方依赖）。

适合同时持有多个 Kimi 会员账号、想在 CLI 里轮换使用额度的人。

## 功能

- **一键换号**：`kimi-switch` 在两个账号间互切（凭证文件 + api_key 快照替换）
- **自动选号启动**：`kimi-switch go` 查询各账号余量，自动切到剩余最多的账号再启动 kimi
- **用量总览**：`kimi-switch usage` 并排查看所有账号的 5 小时滚动窗口、每周额度、加油包
- **账号身份**：save 时自动记录昵称和手机号，`ls` 里一眼分清谁是谁
- **状态栏集成**：在 Kimi Code 底部常驻显示"当前账号 · 本周剩余 · 5h 剩余"
- **token 自维护**：access token 过期自动用 refresh token 刷新并写回快照

## 安装

```bash
cp kimi-switch ~/.local/bin/kimi-switch
chmod +x ~/.local/bin/kimi-switch
```

确保 `~/.local/bin` 在 `PATH` 里。

## 首次设置（只做一次）

1. 在 kimi 里 `/login` 登录账号 A，然后运行 `kimi-switch save A`
2. 在 kimi 里 `/login` 换成账号 B，再运行 `kimi-switch save B`
3. 以后敲 `kimi-switch` 互切，或用 `kimi-switch go` 代替 `kimi` 启动（自动选余量多的号）

## 命令

| 命令 | 作用 |
| --- | --- |
| `kimi-switch` | 一键互换（两个账号时）；多账号弹出编号菜单 |
| `kimi-switch go` | 自动切到余量最多的账号并启动 kimi |
| `kimi-switch usage` | 查看所有账号用量（5 小时窗口 / 每周额度 / 加油包） |
| `kimi-switch ls` | 列出所有账号（含昵称），`*` = 当前生效 |
| `kimi-switch current` | 显示当前账号名 |
| `kimi-switch use <名字>` | 切换到指定账号 |
| `kimi-switch save <名字>` | 把当前登录态存为快照 |
| `kimi-switch rm <名字>` | 删除快照 |
| `kimi-switch statusline` | 状态栏输出（见下文） |
| `kimi-switch help` | 查看帮助 |

## 状态栏

在 `~/.kimi-code/tui.toml` 里加：

```toml
[status_line]
command = "/Users/<你>/.local/bin/kimi-switch statusline"
```

效果：`B(用户5586) · 周剩100/100 · 5h剩100/100`。

状态栏只读本地缓存（300ms 预算内，不发网络请求）；缓存由 `usage` / `go` 命令刷新。

## 注意

- 切换对**正在运行**的 kimi 会话不生效（凭证只在进程启动时读一次），重开新会话才是新账号
- 聊天记录存在本地 `~/.kimi-code/sessions/`，不按账号区分，切换后不丢也不变；切换后会提示 `kimi --session <id>` 恢复当前目录上次的对话
- 快照保存在 `~/.kimi-code/accounts/`（目录 700 / 文件 600），不会打印密钥
- 如果设置了 `KIMI_CODE_HOME` 环境变量，工具会跟着走

## License

MIT
