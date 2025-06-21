#!/bin/bash

# 设置环境变量
export MINDSDB_APIS="http,mysql,postgres,mongodb,mcp,a2a"
export MINDSDB_A2A_ENABLED=true
export MINDSDB_A2A_HOST="0.0.0.0"
export MINDSDB_A2A_PORT="47338"
export MINDSDB_HOST="localhost"
export MINDSDB_PORT="47334"
export MINDSDB_PROJECT_NAME="mindsdb"
export MINDSDB_AGENT_NAME="my_agent"
# 存储目录
export MINDSDB_STORAGE_DIR=./mindsdb_storage
# 日志级别
export MINDSDB_LOG_LEVEL=INFO
export MINDSDB_CONSOLE_LOG_LEVEL=INFO
# export MINDSDB_FILE_LOG_LEVEL=DEBUG

# 启动MindsDB
python -m mindsdb --api http,mysql,postgres,mongodb,mcp,a2a