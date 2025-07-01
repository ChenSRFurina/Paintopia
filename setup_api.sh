#!/bin/bash

echo "🎨 Paintopia API 设置向导"
echo "=========================="
echo ""

# 检查是否已存在配置文件
if [ -f "paintopia/Config/config.plist" ]; then
    echo "⚠️  发现现有配置文件: paintopia/Config/config.plist"
    read -p "是否要覆盖现有配置? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ 取消设置"
        exit 1
    fi
fi

# 复制模板文件
if [ -f "paintopia/Config/config.template.plist" ]; then
    cp paintopia/Config/config.template.plist paintopia/Config/config.plist
    echo "✅ 已创建配置文件模板"
else
    echo "❌ 未找到配置文件模板"
    exit 1
fi

echo ""
echo "📝 请按以下步骤配置 OpenRouter API Key:"
echo ""
echo "1. 访问 https://openrouter.ai/ 注册账户"
echo "2. 在控制台创建 API key"
echo ""
echo "配置方式选择:"
echo "A) 使用 .env 文件（推荐）"
echo "B) 使用 config.plist 文件"
echo ""
read -p "请选择配置方式 (A/B): " -n 1 -r
echo

if [[ $REPLY =~ ^[Aa]$ ]]; then
    # 创建 .env 文件
    if [ -f ".env" ]; then
        echo "⚠️  发现现有 .env 文件"
        read -p "是否要覆盖? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ 取消设置"
            exit 1
        fi
    fi
    
    cp env.template .env
    echo "✅ 已创建 .env 文件"
    echo "📝 请编辑 .env 文件，将 'your_openrouter_api_key_here' 替换为你的实际 API key"
else
    # 使用 config.plist
    echo "📝 请编辑文件: paintopia/Config/config.plist"
    echo "将 'your_openrouter_api_key_here' 替换为你的实际 API key"
fi
echo ""
echo "💡 提示:"
echo "   - API key 通常以 'sk-' 开头"
echo "   - 配置文件已被添加到 .gitignore，不会被提交到版本控制"
echo "   - 也可以使用环境变量方式配置（参考 API_SETUP.md）"
echo ""
echo "🔧 其他配置方式请参考: API_SETUP.md" 