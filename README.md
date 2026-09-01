# kimi-switch

一键切换 [Kimi Code CLI](https://www.kimi.com/code/docs/en/) 账号的小工具（macOS / Linux，纯 Bash，零依赖）。

## 原理

Kimi Code 的登录态保存在 `~/.kimi-code/credentials/kimi-code.json`，`config.toml` 里还有一行 `api_key`。
kimi-switch 把这两样按账号名做快照、来回替换。快照保存在 `~/.kimi-code/accounts/`（权限 600），不会打印密钥。

## 安装

```bash
cp kimi-switch ~/.local/bin/kimi-switch
chmod +x ~/.local/bin/kimi-switch
```

确保 `~/.local/bin` 在 `PATH` 里。

## 首次设置（只做一次）

1. 在 kimi 里 `/login` 登录账号 A，然后运行 `kimi-switch save A`
2. 在 kimi 里 `/login` 换成账号 B，再运行 `kimi-switch save B`
3. 以后敲 `kimi-switch` 即可一键互换

## 命令

| 命令 | 作用 |
| --- | --- |
| `kimi-switch` | 一键互换（只存了两个账号时）；多账号弹出编号菜单 |
| `kimi-switch ls` | 列出所有账号，`*` = 当前生效 |
| `kimi-switch current` | 显示当前账号名 |
| `kimi-switch use <名字>` | 切换到指定账号 |
| `kimi-switch save <名字>` | 把当前登录态存为快照 |
| `kimi-switch rm <名字>` | 删除快照 |
| `kimi-switch help` | 查看帮助 |

## 注意

- 切换对**正在运行**的 kimi 会话不生效，重开新会话才是新账号
- 验证是否切换成功：新会话里 `/usage` 看额度归属
- 如果设置了 `KIMI_CODE_HOME` 环境变量，工具会跟着走

## License

MIT
