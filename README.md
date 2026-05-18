# Claude Web API 单用户版

这是 Claude Web 的单用户服务端项目，适合个人在 Linux 服务器、轻量云主机、家用小机或 Termux 环境里自建 AI 聊天工作台。

项目使用 `FastAPI + SQLite + 原生前端`，默认把数据保存在本机 SQLite 数据库中，不依赖外部业务数据库。前端界面在 `static/index.html`，后端入口在 `app.py`。

## 主要功能

- 单用户本地聊天工作台
- OpenAI / Anthropic / 兼容接口直连
- 支持 Chat Completions、Anthropic Messages、OpenAI Responses 协议
- 流式输出、停止生成、重新回答、保留旧版本
- 图片上传、文本/代码文件上传、Responses 文件输入
- 多 API 接入商配置与默认接入商选择
- 系统提示词管理
- 会话创建、重命名、固定、删除、搜索、Markdown 导出
- 自主联网搜索，支持 Tavily 和 SerpAPI
- GitHub 链接在 Responses 协议下直接随 `input` 传给上游解析
- SQLite 本地持久化
- 健康检查、管理后台、部署脚本、启动脚本

## 服务端结构

```text
app.py                 FastAPI 路由、页面入口、聊天/上传/再生成接口
services.py            模型请求、Responses 请求、搜索、网页提取、视觉输入
db.py                  SQLite 表结构和数据访问
chat_utils.py          上下文拼接、token 粗估、图片历史处理
schemas.py             Pydantic 请求结构
config.py              默认模型、路径和上传限制
static/                前端页面和静态资源
scripts/smoke_test.py  部署后的基础冒烟测试
install.sh             安装运行环境
start-local.sh         启动本地服务
deploy-server.sh       服务器一键部署脚本
```

## 快速部署

### 方式一：从 GitHub 拉取单用户分支

```bash
git clone -b single-user https://github.com/ojcsdream/claude-web-api.git claude-web-single
cd claude-web-single
chmod +x deploy-server.sh
./deploy-server.sh
```

部署完成后访问：

```text
http://服务器IP:8000/
```

如果服务器有防火墙，请放行端口 `8000`。

### 方式二：手动启动

```bash
cd claude-web-single
./install.sh
./start-local.sh
```

默认监听：

```text
0.0.0.0:8000
```

健康检查：

```bash
curl http://127.0.0.1:8000/api/health
```

## 环境变量

可以在项目根目录创建 `.env`：

```bash
TAVILY_API_KEY="你的 Tavily key"
SERPAPI_API_KEY="你的 SerpAPI key"
NGROK_AUTHTOKEN="你的 ngrok token"
HOST="0.0.0.0"
PORT="8000"
```

说明：

- API 接入商 key 建议在网页设置里配置，不建议写死到代码。
- `.env`、`chat.db`、`uploads/`、`logs/` 默认不应提交到 Git。
- 没有 Tavily / SerpAPI 时，普通聊天仍可使用，只是后端自主搜索能力会下降。

## 一键部署脚本

`deploy-server.sh` 会执行：

1. 检查并安装 Python 运行环境
2. 创建或修复 `.venv`
3. 安装 `requirements.txt`
4. 编译检查核心 Python 文件
5. 启动服务
6. 调用 `/api/health` 做健康检查
7. 运行 `scripts/smoke_test.py`

常用参数：

```bash
PORT=8010 ./deploy-server.sh
START_PUBLIC=0 ./deploy-server.sh
```

## 生产建议

- 用 Nginx / Caddy 反向代理到 `127.0.0.1:8000`
- 通过 HTTPS 暴露服务
- 不要把 `.env`、数据库、上传文件、token 提交到仓库
- 如果暴露公网，建议增加访问控制或只放在可信网络内
- 定期备份 `chat.db`

## GitHub 分支说明

同一个仓库内有两个独立分支：

- `single-user`：单用户版，本项目
- `multi-user`：多用户版，包含登录、注册、用户隔离等能力
