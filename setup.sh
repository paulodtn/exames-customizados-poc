#!/bin/bash

# ============================================
# SETUP AUTOMÁTICO - EXAMES CUSTOMIZADOS POC
# ============================================

echo "🚀 Iniciando setup do projeto Exames Customizados..."
echo ""

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker primeiro."
    exit 1
fi

# Verificar se arquivo .env existe
if [ ! -f .env ]; then
    echo "📝 Criando arquivo .env..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "✅ Arquivo .env criado a partir do .env.example"
        echo "⚠️  Edite o arquivo .env se necessário (principalmente a senha do banco)"
    else
        echo "❌ Arquivo .env.example não encontrado. Criando .env padrão..."
        cat > .env << 'EOF'
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password123
POSTGRES_DB=exames_customizados_development
DB_HOST=db
DB_PORT=5432
RAILS_ENV=development
EOF
        echo "✅ Arquivo .env criado com configurações padrão"
    fi
    echo ""
fi

# Parar containers existentes (se houver)
echo "🛑 Parando containers existentes..."
docker compose down -v > /dev/null 2>&1

# Construir e iniciar containers
echo "🏗️  Construindo e iniciando containers..."
if docker compose up -d --build; then
    echo "✅ Containers iniciados com sucesso!"
else
    echo "❌ Erro ao iniciar containers. Verifique os logs:"
    docker compose logs
    exit 1
fi

# Aguardar banco estar pronto
echo "⏳ Aguardando banco de dados ficar pronto..."
sleep 5

# Verificar se containers estão rodando
if ! docker compose ps | grep -q "Up"; then
    echo "❌ Containers não estão rodando corretamente."
    docker compose logs
    exit 1
fi

# Criar estrutura do banco
echo "🗃️  Criando estrutura do banco de dados..."
if docker compose exec -T rails cat /app/db/schema.sql | docker compose exec -T db psql -U postgres -d exames_customizados_development; then
    echo "✅ Estrutura do banco criada!"
else
    echo "❌ Erro ao criar estrutura do banco."
    exit 1
fi

# Perguntar se quer popular com dados de exemplo
echo ""
read -p "🌱 Deseja popular o banco com dados de exemplo? (s/N): " populate

if [[ $populate =~ ^[Ss]$ ]]; then
    echo "🌱 Populando banco com dados de exemplo..."
    if docker compose exec -T rails cat /app/db/seed.sql | docker compose exec -T db psql -U postgres -d exames_customizados_development; then
        echo "✅ Dados de exemplo inseridos!"
    else
        echo "❌ Erro ao inserir dados de exemplo."
    fi
fi

# Verificar se aplicação está respondendo
echo ""
echo "🔍 Verificando se aplicação está funcionando..."
sleep 2

if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Aplicação está rodando!"
else
    echo "⚠️  Aplicação ainda está iniciando. Aguarde alguns segundos..."
fi

# Informações finais
echo ""
echo "🎉 SETUP CONCLUÍDO COM SUCESSO!"
echo ""
echo "📱 ACESSE A APLICAÇÃO:"
echo "   🏠 Página Principal:     http://localhost:3000"
echo "   ➕ Criar Exame:         http://localhost:3000/exames/new"
echo "   ✏️  Editar Exame:        http://localhost:3000/exames/:id/edit"
echo "   🔗 API REST:            http://localhost:3000/exames"
echo "   ❤️  Health Check:       http://localhost:3000/health"
echo ""
echo "🛠️  COMANDOS ÚTEIS:"
echo "   docker compose ps              # Status dos containers"
echo "   docker compose logs rails      # Logs da aplicação"
echo "   docker compose logs db         # Logs do banco"
echo "   docker compose down            # Parar tudo"
echo ""
echo "📚 Para mais informações, consulte o README_MASTER.md"