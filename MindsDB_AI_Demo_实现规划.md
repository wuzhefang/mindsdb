# MindsDB AI Demo 实现规划

## 项目概述

本项目旨在使用MindsDB展示两个核心AI能力：
1. **AI Table（AI表）能力**：将AI模型抽象为虚拟表，通过SQL查询获得AI推理结果
2. **Chat to Data（对话数据）能力**：通过自然语言与数据对话，进行智能数据查询和分析

## 技术方案

### AI模型选择
- 使用阿里云百炼在线模型（通义千问等）替代OpenAI
- 通过修改base_url参数来兼容阿里云百炼API

### 数据源配置
- 使用MindsDB内置示例数据库（MySQL/PostgreSQL）
- 准备典型业务场景数据（如销售数据、用户评论等）

## 实现步骤

### 第一阶段：环境准备和基础配置

#### 1.1 MindsDB环境准备
```bash
# 设置环境变量
export MINDSDB_APIS="http,mysql,postgres,mongodb,mcp,a2a"
export MINDSDB_A2A_ENABLED=true
export MINDSDB_A2A_HOST="0.0.0.0"
export MINDSDB_A2A_PORT="47338"
export MINDSDB_HOST="localhost"
export MINDSDB_PORT="47334"
export MINDSDB_PROJECT_NAME="mindsdb"
export MINDSDB_STORAGE_DIR=./mindsdb_storage
export MINDSDB_LOG_LEVEL=INFO
export MINDSDB_CONSOLE_LOG_LEVEL=INFO

# 启动MindsDB
python -m mindsdb --api http,mysql,postgres,mongodb,mcp,a2a
```

或者创建启动脚本 `start_demo.sh`:
```bash
#!/bin/bash
export MINDSDB_APIS="http,mysql,postgres,mongodb,mcp,a2a"
export MINDSDB_STORAGE_DIR=./mindsdb_storage
export MINDSDB_LOG_LEVEL=DEBUG  # 设置为DEBUG便于调试
python -m mindsdb --api http,mysql,postgres,mongodb,mcp,a2a
```

#### 1.2 获取阿里云百炼API密钥
- 注册阿里云账号：https://www.aliyun.com/
- 开通百炼服务：https://dashscope.aliyun.com/
- 获取API Key：控制台 -> API-KEY管理 -> 创建新的API-KEY
- 记录API密钥格式：`sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
- 访问地址：`https://dashscope-intl.aliyuncs.com/compatible-mode/v1`

#### 1.3 验证基础连接
访问 http://localhost:47334 或使用SQL客户端连接：
```sql
-- 测试MindsDB基础功能
SHOW DATABASES;
SHOW ML_ENGINES;

-- 检查MindsDB版本和状态
SELECT version();
SELECT * FROM information_schema.databases;
```

### 第二阶段：配置阿里云百炼AI引擎

#### 2.1 创建支持阿里云百炼的AI引擎
```sql
-- 创建兼容阿里云百炼的OpenAI引擎
CREATE ML_ENGINE dashscope_engine
FROM openai
USING
    openai_api_key = 'sk-your-dashscope-api-key',  -- 替换为您的DashScope API Key
    openai_api_base = 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1';
```

#### 2.2 验证AI引擎配置
```sql
-- 查看已创建的ML引擎
SHOW ML_ENGINES;

-- 验证引擎状态
DESCRIBE ML_ENGINE dashscope_engine;
```

#### 2.3 详细的模型配置和调试指南

**常见问题和解决方案：**

1. **API密钥验证失败**
```sql
-- 如果创建引擎失败，检查错误信息
SHOW ERRORS;

-- 重新创建引擎时先删除旧的
DROP ML_ENGINE IF EXISTS dashscope_engine;

-- 确保API密钥格式正确
CREATE ML_ENGINE dashscope_engine
FROM openai
USING
    openai_api_key = 'sk-your-actual-api-key-here',
    openai_api_base = 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1';
```

2. **支持的模型名称**
阿里云百炼支持的模型（通过OpenAI兼容接口）：
- `qwen-turbo`: 通义千问Turbo版本
- `qwen-plus`: 通义千问Plus版本  
- `qwen-max`: 通义千问Max版本
- `qwen-max-longcontext`: 长上下文版本

3. **模型参数配置**
```sql
-- 创建模型时的重要参数
CREATE MODEL test_model
PREDICT response
USING
    engine = 'dashscope_engine',
    model_name = 'qwen-turbo',           -- 选择合适的模型
    temperature = 0.7,                   -- 控制输出随机性 (0-1)
    max_tokens = 2000,                   -- 最大输出长度
    prompt_template = '{{input_text}}';  -- 提示词模板
```

4. **调试步骤**
```sql
-- 步骤1: 检查引擎状态
SELECT * FROM information_schema.ml_engines WHERE name = 'dashscope_engine';

-- 步骤2: 创建简单测试模型
CREATE MODEL simple_test
PREDICT response
USING
    engine = 'dashscope_engine',
    model_name = 'qwen-turbo',
    prompt_template = '请回答：{{question}}';

-- 步骤3: 检查模型状态
DESCRIBE simple_test;

-- 步骤4: 简单测试
SELECT response FROM simple_test WHERE question = '你好';
```

5. **错误排查**
```sql
-- 查看模型训练状态
SELECT * FROM models WHERE name = 'your_model_name';

-- 查看详细错误信息
SELECT * FROM logs WHERE error IS NOT NULL ORDER BY created_at DESC LIMIT 10;

-- 重新训练失败的模型
RETRAIN your_model_name;
```

### 第三阶段：数据源准备

#### 3.1 连接示例数据库
```sql
-- 连接MindsDB公共示例数据库
CREATE DATABASE demo_db
WITH ENGINE = 'mysql',
PARAMETERS = {
    "user": "user",
    "password": "MindsDBUser123!",
    "host": "samples.mindsdb.com",
    "port": "3306",
    "database": "public"
};
```

#### 3.2 准备演示数据表
- 用户评论数据表（用于情感分析）
- 销售数据表（用于预测分析）
- 问答数据表（用于智能问答）

```sql
-- 查看可用的演示数据
SHOW TABLES FROM demo_db;

-- 预览数据
SELECT * FROM demo_db.amazon_reviews LIMIT 5;
SELECT * FROM demo_db.home_rentals LIMIT 5;
SELECT * FROM demo_db.questions LIMIT 5;
```

### 第四阶段：AI Table功能实现 - 销量预测演示

#### 4.1 创建销量预测AI表

**步骤1：准备销量数据**
```sql
-- 查看可用的销量相关数据
SELECT * FROM demo_db.ecommerce_data LIMIT 5;
-- 或者
SELECT * FROM demo_db.sales_data LIMIT 5;
```

**步骤2：创建销量预测模型**
```sql
-- 创建销量预测AI表
CREATE MODEL sales_predictor
PREDICT predicted_sales
USING
    engine = 'dashscope_engine',
    model_name = 'qwen-turbo',
    temperature = 0.3,  -- 降低随机性，提高预测准确性
    max_tokens = 500,
    prompt_template = '基于以下历史销量数据，预测下个月的销量：

历史数据：
- 产品类别：{{category}}
- 月份：{{month}}
- 历史销量：{{historical_sales}}
- 价格：{{price}}
- 促销活动：{{promotion}}
- 季节因素：{{season}}

请分析这些因素并预测下个月的销量数字，只返回预测的销量数值：';
```

**步骤3：模型状态检查和调试**
```sql
-- 检查模型创建状态
DESCRIBE sales_predictor;

-- 查看模型详细信息
SELECT * FROM models WHERE name = 'sales_predictor';

-- 如果状态不是complete，等待或检查错误
SELECT status, error FROM models WHERE name = 'sales_predictor';
```

**常见状态说明：**
- `training`: 模型正在创建中
- `complete`: 模型创建完成，可以使用
- `error`: 创建失败，检查错误信息

**步骤4：模型功能验证**
```sql
-- 简单功能测试
SELECT predicted_sales 
FROM sales_predictor 
WHERE category = '电子产品'
  AND month = '2024-01'
  AND historical_sales = '1000,1200,900,1100,1300'
  AND price = '299'
  AND promotion = '无'
  AND season = '冬季';
```

#### 4.2 模型使用最佳实践

**参数优化建议：**
```sql
-- 创建优化版本的模型
CREATE MODEL sales_predictor_v2
PREDICT predicted_sales
USING
    engine = 'dashscope_engine',
    model_name = 'qwen-plus',  -- 使用更强大的模型
    temperature = 0.1,         -- 更低的随机性
    max_tokens = 200,          -- 限制输出长度
    prompt_template = '你是一个专业的销量预测分析师。

根据以下数据进行销量预测：
产品：{{category}}
历史5个月销量：{{historical_sales}}
当前价格：{{price}}元
促销情况：{{promotion}}

请给出下个月预测销量（只返回数字）：';
```

**错误处理：**
```sql
-- 如果模型创建失败，先删除再重建
DROP MODEL IF EXISTS sales_predictor;

-- 检查引擎是否正常
SELECT * FROM information_schema.ml_engines WHERE name = 'dashscope_engine';

-- 重新创建模型
CREATE MODEL sales_predictor
PREDICT predicted_sales
USING
    engine = 'dashscope_engine',
    model_name = 'qwen-turbo',
    prompt_template = '预测销量：{{input_data}}';
```

### 第五阶段：AI Table功能演示 - 销量预测实例

#### 5.1 单条销量预测演示
```sql
-- 单产品销量预测
SELECT 
    category,
    historical_sales,
    price,
    predicted_sales
FROM sales_predictor 
WHERE category = '智能手机'
  AND historical_sales = '1500,1800,1200,1600,2000'
  AND price = '3999'
  AND promotion = '买一送一'
  AND season = '春季';

-- 验证预测结果的合理性
SELECT 
    '输入参数' as type,
    'iPhone 14' as product,
    '过去5个月: 1500,1800,1200,1600,2000' as data
UNION
SELECT 
    '预测结果',
    predicted_sales,
    '基于历史趋势和促销活动的预测'
FROM sales_predictor 
WHERE category = 'iPhone 14'
  AND historical_sales = '1500,1800,1200,1600,2000'
  AND price = '6999'
  AND promotion = '无促销'
  AND season = '夏季';
```

#### 5.2 批量销量预测演示

**创建测试数据表：**
```sql
-- 创建测试用的产品数据
CREATE TABLE product_forecast_input AS (
    SELECT * FROM (
        VALUES 
        ('电视', '500,600,450,550,700', '2999', '双十一促销', '秋季'),
        ('笔记本电脑', '300,350,280,320,400', '8999', '无促销', '秋季'),
        ('智能音箱', '800,900,750,850,1000', '399', '限时折扣', '秋季'),
        ('平板电脑', '200,250,180,220,280', '2499', '买二送一', '秋季'),
        ('智能手表', '400,450,380,420,500', '1999', '新品发布', '秋季')
    ) AS t(category, historical_sales, price, promotion, season)
);
```

**批量预测：**
```sql
-- 批量销量预测
SELECT 
    input.category as 产品类别,
    input.historical_sales as 历史销量,
    input.price as 当前价格,
    input.promotion as 促销活动,
    output.predicted_sales as 预测销量
FROM product_forecast_input AS input
JOIN sales_predictor AS output
LIMIT 10;
```

#### 5.3 预测结果分析和验证

**预测准确性分析：**
```sql
-- 分析预测趋势
SELECT 
    category,
    CAST(SUBSTRING_INDEX(historical_sales, ',', -1) AS DECIMAL) as 上月销量,
    predicted_sales as 预测销量,
    CASE 
        WHEN predicted_sales > CAST(SUBSTRING_INDEX(historical_sales, ',', -1) AS DECIMAL) 
        THEN '增长'
        ELSE '下降'
    END as 趋势
FROM sales_predictor
WHERE category IN ('电视', '笔记本电脑', '智能音箱');
```

**调试和优化提示：**
1. **如果预测结果异常：**
   - 检查prompt_template是否清晰
   - 调整temperature参数（0.1-0.5）
   - 确保输入数据格式正确

2. **提高预测准确性：**
   - 增加更多历史数据维度
   - 优化提示词，增加具体的分析要求
   - 使用更强大的模型（qwen-plus或qwen-max）

3. **处理异常输出：**
   ```sql
   -- 检查模型输出是否为数字
   SELECT 
       predicted_sales,
       CASE 
           WHEN predicted_sales REGEXP '^[0-9]+$' THEN '数字'
           ELSE '非数字，需要优化提示词'
       END as 输出类型
   FROM sales_predictor
   WHERE category = '测试产品';
   ```

### 第六阶段：Chat to Data功能实现

#### 6.1 创建对话式数据分析AI表
```sql
-- 创建数据分析助手
CREATE MODEL data_chat_assistant
PREDICT analysis_result
USING
    engine = 'dashscope_engine',
    model_name = 'qwen-turbo',
    prompt_template = '作为数据分析专家，请基于以下数据回答用户问题：

数据信息：{{data_context}}
用户问题：{{user_question}}

请提供准确的分析和洞察：';
```

#### 6.2 创建SQL生成AI表
```sql
-- 创建SQL生成助手
CREATE MODEL sql_generator
PREDICT sql_query
USING
    engine = 'dashscope_engine',
    model_name = 'qwen-turbo',
    prompt_template = '基于以下表结构和用户需求，生成相应的SQL查询：

表结构：{{table_schema}}
用户需求：{{user_request}}

生成的SQL查询：';
```

### 第七阶段：Chat to Data功能演示

#### 7.1 自然语言数据查询
```sql
-- 通过自然语言查询数据统计
SELECT sql_query 
FROM sql_generator 
WHERE table_schema = 'home_rentals(rental_price, location, sqft, bedrooms, bathrooms)' 
AND user_request = '显示每个地区的平均租金价格，按价格降序排列';
```

#### 7.2 对话式数据分析
```sql
-- 对话式分析房租数据
SELECT analysis_result 
FROM data_chat_assistant 
WHERE data_context = '房屋租赁数据包含价格、位置、面积、卧室数量等信息' 
AND user_question = '哪些因素对租金价格影响最大？';

-- 对话式分析用户评论
SELECT analysis_result 
FROM data_chat_assistant 
WHERE data_context = '用户评论数据包含产品评价、评分、购买时间等信息' 
AND user_question = '用户满意度的主要影响因素是什么？';
```

### 第八阶段：高级功能展示

#### 8.1 实时数据处理流水线
```sql
-- 创建自动化作业：定期分析新评论
CREATE JOB sentiment_analysis_job AS (
    INSERT INTO sentiment_results (
        SELECT 
            input.review,
            input.product_name,
            output.sentiment,
            NOW() as analysis_date
        FROM demo_db.amazon_reviews AS input
        JOIN sentiment_analyzer AS output
        WHERE input.created_at >= CURRENT_DATE
    )
) 
EVERY 1 hour;
```

#### 8.2 多模态AI功能
```sql
-- 如果支持，可以添加图像分析等功能
CREATE MODEL image_analyzer
PREDICT description
USING
    engine = 'dashscope_engine',
    model_name = 'qwen-vl-chat',  -- 多模态模型
    mode = 'image',
    prompt_template = '请描述这张图片的内容：';
```

### 第九阶段：演示脚本和用户界面

#### 9.1 准备演示脚本
- 创建演示用的SQL查询集合
- 准备不同场景的数据样本
- 设计演示流程和解说词

#### 9.2 可选：Web界面开发
```python
# 使用MindsDB Python SDK创建简单的Web界面
import mindsdb_sdk

# 连接MindsDB
server = mindsdb_sdk.connect('http://localhost:47334')

# 创建简单的Streamlit应用展示功能
import streamlit as st

def demo_ai_table():
    st.title("AI Table 演示")
    user_input = st.text_input("输入要分析的文本：")
    if user_input:
        # 调用情感分析AI表
        result = server.query(f"SELECT sentiment FROM sentiment_analyzer WHERE review = '{user_input}'")
        st.write(f"情感分析结果：{result}")

def demo_chat_to_data():
    st.title("Chat to Data 演示")
    question = st.text_input("询问数据相关问题：")
    if question:
        # 调用数据分析AI表
        result = server.query(f"SELECT analysis_result FROM data_chat_assistant WHERE user_question = '{question}'")
        st.write(f"分析结果：{result}")
```

### 第十阶段：性能优化和最佳实践

#### 10.1 性能优化
- 配置合适的模型参数（temperature、max_tokens等）
- 实现查询结果缓存
- 优化批量处理性能

#### 10.2 错误处理和监控
```sql
-- 创建模型状态监控
SELECT * FROM models WHERE status != 'complete';

-- 查看模型性能指标
DESCRIBE sentiment_analyzer;
```

## 预期演示效果

### AI Table能力展示
1. **即时AI推理**：展示如何通过SQL查询直接获得AI推理结果
2. **批量数据处理**：演示大规模数据的AI分析能力
3. **多种AI任务**：展示情感分析、问答、摘要等不同AI能力

### Chat to Data能力展示
1. **自然语言查询**：用户可以用自然语言询问数据问题
2. **智能SQL生成**：根据需求自动生成SQL查询
3. **对话式分析**：提供数据洞察和业务建议

## 技术难点和解决方案

### 1. 阿里云百炼API兼容性
**解决方案**：通过设置`openai_api_base`参数指向阿里云百炼的兼容接口

### 2. 中文支持优化
**解决方案**：在prompt_template中使用中文指令，优化模型的中文理解能力

### 3. 响应速度优化
**解决方案**：
- 选择合适的模型规格
- 实现查询结果缓存
- 优化prompt设计

### 4. 数据安全和隐私
**解决方案**：
- 使用脱敏的演示数据
- 配置适当的访问控制
- 遵循数据使用规范

## 时间规划

- **第1天**：环境准备和基础配置（MindsDB安装、阿里云百炼API配置）
- **第2天**：AI引擎创建和调试（解决连接问题、API验证）
- **第3天**：数据源准备和连接（示例数据库、测试数据创建）
- **第4-5天**：AI Table功能实现（销量预测模型创建和调试）
- **第6天**：Chat to Data功能实现（简化版本）
- **第7天**：完整功能测试和优化
- **第8天**：演示脚本编写和界面准备
- **第9天**：演示彩排和问题修复
- **第10天**：正式演示

**每日具体目标：**
- 第1天：完成环境搭建，能够启动MindsDB并访问Web界面
- 第2天：成功创建阿里云百炼引擎，能够进行简单API调用
- 第3天：连接示例数据库，能够查询和预览数据
- 第4天：创建第一个销量预测模型，解决模型创建问题
- 第5天：完成模型调试，实现稳定的单条和批量预测
- 第6天：实现基础的自然语言数据查询功能
- 第7天：全面测试所有功能，修复发现的问题
- 第8天：准备演示材料和脚本
- 第9天：模拟演示，准备备用方案

## 预期成果

1. 完整的MindsDB AI功能演示系统
2. 展示AI Table和Chat to Data两大核心能力
3. 验证阿里云百炼模型在MindsDB中的应用效果
4. 为后续商业化应用提供技术验证

## 故障排除和常见问题

### 环境问题
**问题1：MindsDB启动失败**
```bash
# 检查Python版本（需要3.8+）
python --version

# 检查MindsDB安装
pip show mindsdb

# 重新安装MindsDB
pip install --upgrade mindsdb

# 清理缓存后重启
rm -rf ./mindsdb_storage
python -m mindsdb --api http,mysql,postgres
```

**问题2：端口占用**
```bash
# 检查端口占用
lsof -i :47334
netstat -tulpn | grep 47334

# 杀死占用进程
kill -9 <PID>

# 使用不同端口启动
export MINDSDB_PORT=47335
python -m mindsdb --api http --host 0.0.0.0 --port 47335
```

### API连接问题
**问题3：阿里云百炼API连接失败**
```sql
-- 检查API密钥格式
-- 正确格式：sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

-- 测试连接
CREATE ML_ENGINE test_engine
FROM openai
USING
    openai_api_key = 'your-key-here',
    openai_api_base = 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1';

-- 如果失败，检查错误信息
SHOW ERRORS;
```

**问题4：模型创建卡住**
```sql
-- 检查模型状态
SELECT name, status, error FROM models;

-- 删除卡住的模型
DROP MODEL IF EXISTS model_name;

-- 检查引擎状态
SELECT * FROM information_schema.ml_engines;

-- 重新创建引擎
DROP ML_ENGINE IF EXISTS dashscope_engine;
CREATE ML_ENGINE dashscope_engine FROM openai USING ...;
```

### 模型使用问题
**问题5：预测结果不合理**
```sql
-- 检查提示词模板
DESCRIBE sales_predictor;

-- 测试简化版本
CREATE MODEL simple_test
PREDICT result
USING
    engine = 'dashscope_engine',
    model_name = 'qwen-turbo',
    temperature = 0.1,
    prompt_template = '回答数字：{{input}}';

-- 测试基础功能
SELECT result FROM simple_test WHERE input = '1+1等于多少？';
```

**问题6：中文输出异常**
```sql
-- 优化中文提示词
CREATE MODEL chinese_model
PREDICT answer
USING
    engine = 'dashscope_engine',
    model_name = 'qwen-turbo',
    prompt_template = '请用中文回答，只返回结果：{{question}}';
```

### 性能优化
**问题7：响应速度慢**
- 使用`qwen-turbo`而不是`qwen-max`
- 降低`max_tokens`参数
- 设置合适的`temperature`（0.1-0.3）
- 简化prompt_template

**问题8：批量处理失败**
```sql
-- 分批处理大量数据
SELECT * FROM sales_predictor 
LIMIT 10;  -- 先处理小批量

-- 检查内存使用
SHOW PROCESSLIST;
```

### 应急备用方案
1. **如果阿里云百炼不可用**：
   - 准备OpenAI API密钥作为备用
   - 或使用本地Ollama模型

2. **如果网络问题**：
   - 准备离线演示数据
   - 使用预先录制的演示视频

3. **如果模型创建失败**：
   - 使用更简单的prompt
   - 降级到基础功能演示

## 注意事项

1. **安全性**：
   - 不要在代码中硬编码API密钥
   - 使用环境变量存储敏感信息
   - 演示后清理API密钥

2. **稳定性**：
   - 演示前充分测试所有功能
   - 准备多个备用方案
   - 监控API使用量和费用

3. **演示技巧**：
   - 准备预先验证过的演示数据
   - 备份工作正常的模型状态
   - 准备简化版本的演示流程

## 技术支持联系方式

- 阿里云百炼技术支持：https://help.aliyun.com/
- MindsDB社区：https://github.com/mindsdb/mindsdb
- 紧急联系：准备技术人员联系方式

---

*本文档将根据实际实现过程中遇到的问题进行动态更新和完善。请在实施过程中记录遇到的问题和解决方案，以便后续优化。* 