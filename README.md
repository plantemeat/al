# al — persistent command aliases for bash / zsh

```bash
al set sh12 ssh server12        # 之后敲 sh12 就是 ssh server12（参数会透传：sh12 -p 2222）
al set -t 7d logs 'tail -f /data/reth.log | grep -i error'   # 7 天后自动过期
al unset sh12                   # 删除
al show                         # 列出全部：状态 / 最近使用 / 过期时间 / 命令
al clean --unused 90d           # 清理过期的 + 90 天没用过的
```

- 纯 shell，零依赖（只需 `awk sort date`），Linux / macOS，bash / zsh 都能用
- `set/unset` 当前终端立即生效，不用重开
- 每天首次开终端时自动静默清理过期别名
- 数据是一个 TSV：`~/.al/aliases.tsv`，可直接编辑 / 备份 / 同步

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/plantemeat/al/main/install.sh | bash
exec $SHELL
```

国内服务器访问 GitHub 慢：

```bash
curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/plantemeat/al/main/install.sh \
  | AL_RAW_BASE=https://ghfast.top/https://raw.githubusercontent.com/plantemeat/al/main bash
```

完全离线（内网机器）：

```bash
scp -r al/ server12:/tmp/al && ssh server12 'bash /tmp/al/install.sh'
```

安装只做两件事：文件放到 `~/.al/`，在 `~/.bashrc` / `~/.zshrc` 末尾追加一个 `# >>> al >>>` 块。

## 命令

| 命令 | 说明 |
|---|---|
| `al set [-t TTL] [-f] NAME [as] CMD...` | 新增/覆盖。TTL：`30m 12h 7d 2w`；`-f` 允许覆盖 PATH 里已有命令 |
| `al unset NAME...` | 删除（别名 `rm`） |
| `al show [关键字]` | 列表；`expired` 红色，`stale`（≥30 天未用）黄色 |
| `al clean [--unused DUR] [-n]` | 清理过期/久未使用；`-n` 只预览 |
| `al export` / `al import [FILE\|-]` | 导出/导入，便于多机同步 |
| `al update` | 从安装源升级 |

同步到另一台机器：

```bash
al export | ssh server12 '~/.al/bin/al import -'
```

## 卸载

```bash
curl -fsSL https://raw.githubusercontent.com/plantemeat/al/main/install.sh | bash -s -- --uninstall
# 保留 aliases.tsv；加 --purge 连数据一起删
```

## 安全约束

- 名字只允许 `[A-Za-z0-9_-]`，且不能是 `cd set unset alias rm ssh sudo ...` 等保留字
- 默认拒绝覆盖 PATH 里已存在的命令（如 `grep`），需 `-f`
- 命令以 `eval` 执行，等同于你自己敲；不要导入来路不明的 TSV

## 配置

| 变量 | 默认 | 说明 |
|---|---|---|
| `AL_HOME` | `~/.al` | 安装/数据目录 |
| `AL_STALE_DAYS` | `30` | `show` 中标记 stale 的阈值 |

## 开发

```bash
bash tests/run.sh    # 在临时 HOME 中对 bash + zsh 跑全量用例
```

MIT License
