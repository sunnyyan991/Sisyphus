# 诸神的差事 · Godot 版

《诸神的差事》的 Godot 4 实现。网页原型仍在仓库根目录，这里是同一套游戏的引擎版本。

## 打开与运行

1. 安装 [Godot 4.3](https://godotengine.org/download)（标准版即可，不需要 .NET）。
2. 在 Godot 项目管理器里导入 `godot/project.godot`。
3. 按 F5 运行，主场景是陶罐主界面 `scenes/menu.tscn`。

渲染器使用 Compatibility（OpenGL），这样网页导出和低端设备都能跑。

## 当前进度

| 内容 | 状态 |
|---|---|
| 陶罐主界面（选集、选章、进度痕迹、罐上人物吐槽） | 已完成 |
| 第一集《西西弗斯再来一次》（含行为回应：宙斯按你的打法点评、结尾用你的踹法） | 已完成 |
| 第二集《普罗米修斯，四种说法》 | 待移植，菜单里显示为"移植中" |
| 第三集《电车又来了》 | 待移植 |

## 结构

```
project.godot
scenes/            每个场景只挂一个脚本，界面在脚本里搭建
scripts/
  game.gd          全局单例 Game：配色、字体、剧集列表、存档、合成音效
  paint.gd         黑绘风格的绘图工具（线、肢体、椭圆、回纹、文字）
  episode_base.gd  每一集共用的框架：顶部数据栏、舞台、对话框、章节卡、结局卡、剧本执行器
  menu.gd          陶罐主界面
  episodes/
    sisyphus.gd    第一集
fonts/             思源宋体 / 思源黑体的子集（只含游戏用到的字）
tools/
  subset_fonts.py  重新生成字体子集
tests/             自动试玩脚本，用来回归测试和截图
```

### 加一集

1. 在 `scripts/episodes/` 新建脚本，`extends EpisodeBase`。
2. 实现这些钩子：`setup()`（标题、角色名）、`build_script()`（剧本步骤数组）、`build_hud()`、`reset_state()`、`custom_step()` / `custom_tap()` / `custom_update()`（本集玩法）、`draw_scene()`（画面）。
3. 在 `scenes/` 加一个挂这个脚本的场景，并在 `game.gd` 的 `EPISODES` 里填上 `scene` 路径。

剧本是一个字典数组，通用步骤有 `chapter`、`say`、`do`、`wait`、`end`，其余步骤交给本集的 `custom_step()` 处理。台词可以是字符串，也可以是 `Callable`，用来根据玩家行为返回不同的话。

## 字体

游戏只打包了用到的汉字，所以**新增台词后要重新生成字体子集**，否则新字会显示成方块：

```
pip install fonttools
python3 tools/subset_fonts.py <放着 NotoSerifSC[wght].ttf 和 NotoSansSC[wght].ttf 的目录>
```

完整字体可以从 [google/fonts](https://github.com/google/fonts) 的 `ofl/notoserifsc` 和 `ofl/notosanssc` 下载，采用 SIL Open Font License。

## 自动试玩

`tests/play_sisyphus.tscn` 会用指定打法把第一集从头玩到尾，打印宙斯的点评，并可以截图：

```
STYLE=late  godot --path . res://tests/play_sisyphus.tscn   # 每次都卡在山顶前一步
STYLE=early godot --path . res://tests/play_sisyphus.tscn   # 每次都踹得很早
STYLE=top   godot --path . res://tests/play_sisyphus.tscn   # 隔一轮放他登顶
SHOTS=/tmp/shots CH=3 godot --path . res://tests/play_sisyphus.tscn   # 从第三章开始并截图
```

## 网页导出

`export_presets.cfg` 里已经有一个 Web 预设，关闭了多线程，导出后可以直接放到 GitHub Pages（不需要额外的跨域响应头）。需要先在 Godot 编辑器里安装对应版本的导出模板。
