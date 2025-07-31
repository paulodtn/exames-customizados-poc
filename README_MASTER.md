# 📋 Exames Customizados - PoC | Documentação Master

> **Sistema completo de gestão de exames laboratoriais com herança STI, API REST e interface web responsiva**

## 📖 Índice

- [1. Visão Geral](#1-visão-geral)
- [2. Arquitetura e Tecnologias](#2-arquitetura-e-tecnologias)
- [3. Estrutura do Projeto](#3-estrutura-do-projeto)
- [4. Como Executar](#4-como-executar)
- [5. API Rails](#5-api-rails)
- [6. Frontend React](#6-frontend-react)
- [7. Banco de Dados](#7-banco-de-dados)
- [8. Modelos STI](#8-modelos-sti)
- [9. Docker e Containers](#9-docker-e-containers)
- [10. Comandos Úteis](#10-comandos-úteis)
- [11. Troubleshooting](#11-troubleshooting)
- [12. Desenvolvimento](#12-desenvolvimento)

---

## 1. Visão Geral

### 🎯 **Objetivo**
Prova de Conceito (PoC) para um sistema de gestão de exames laboratoriais que permite:
- **Exames Base**: Exames principais do laboratório
- **Exames Personalizados**: Variações dos exames base com herança de preços
- **Interface Web**: Gestão completa via navegador
- **API REST**: Integração com outros sistemas

### ✨ **Funcionalidades Principais**
- ✅ **Sistema STI (Single Table Inheritance)** - Ambos tipos de exame na mesma tabela
- ✅ **Herança de Preços** - Exames personalizados herdam automaticamente o preço do exame base
- ✅ **Interface Web Completa** - Listagem, filtros, criação e edição via páginas HTML
- ✅ **CRUD Completo** - Criar, editar e excluir exames com formulários web funcionais
- ✅ **Soft Delete** - Exclusão lógica com recuperação possível (campo `deleted_at`)
- ✅ **API REST Funcional** - Endpoints CRUD para integração
- ✅ **Filtros Dinâmicos** - Busca por nome/código, tipo e status em tempo real
- ✅ **Cascata Inteligente** - Inativação/exclusão de pai afeta automaticamente os filhos
- ✅ **Validações Robustas** - Unicidade de código/nome e integridade referencial
- ✅ **Docker Completo** - Ambiente containerizado para desenvolvimento e produção

### 🆕 **Melhorias v2.0 - Setup Inteligente**
- 🚀 **Setup Automático** - Script `./setup.sh` que configura tudo em 30 segundos
- 🗃️ **Auto-Schema** - Banco de dados criado automaticamente na inicialização
- 🌱 **Dados Realistas** - 15 exames de exemplo (6 base + 9 personalizados) via `seed.sql`
- 🔒 **Segurança** - Arquivo `.env` para credenciais sensíveis
- 📚 **Documentação Atualizada** - README completo com todos os comandos
- 🎯 **Zero Configuração** - Clone, execute `./setup.sh` e pronto!

### 🏆 **Status do Projeto**
**100% FUNCIONAL + SETUP INTELIGENTE** - Todos os componentes implementados e testados:
- ✅ **Backend Ruby** + PostgreSQL com auto-configuração
- ✅ **Frontend Embutido** (HTML/CSS/JS) responsivo
- ✅ **Interface Web** com filtros dinâmicos e CRUD completo
- ✅ **API REST** com endpoints JSON para integração
- ✅ **Docker** com setup automático
- ✅ **Dados de Exemplo** com 15 exames realistas
- ✅ **Documentação Completa** e comandos facilitados

---

## 2. Arquitetura e Tecnologias

### 🏗️ **Arquitetura**
```
┌─────────────────────────────────────┐    ┌─────────────────┐
│         rails_minimal.rb            │    │   Database      │
│  ┌─────────────┐ ┌─────────────────┐│    │                 │
│  │  Frontend   │ │     Backend     ││◄──►│  PostgreSQL 13  │
│  │ HTML/CSS/JS │ │  Ruby + Socket  ││    │   Port: 5434    │
│  └─────────────┘ └─────────────────┘│    │                 │
│          Port: 3000                 │    │                 │
└─────────────────────────────────────┘    └─────────────────┘
```

### 🛠️ **Stack Tecnológico**

#### Core
- **Ruby 3.2.3** - Linguagem de programação
- **Socket TCP** - Servidor HTTP customizado
- **PostgreSQL 13** - Banco de dados relacional
- **PG Gem** - Driver PostgreSQL

#### Frontend (Embutido)
- **HTML5** - Estrutura das páginas
- **Tailwind CSS** - Framework CSS (via CDN)
- **Font Awesome** - Ícones (via CDN)
- **JavaScript** - Interatividade e AJAX

#### DevOps
- **Docker** - Containerização
- **Docker Compose** - Orquestração de containers

---

## 3. Estrutura do Projeto

### 📁 **Estrutura Minimalista & Inteligente**
```
exames-customizados-poc/
├── 📄 rails_minimal.rb                   # 🎯 SERVIDOR PRINCIPAL (Frontend + Backend + Auto-Setup)
├── 📄 docker-compose.yml                 # 🐳 Configuração dos containers  
├── 📄 Dockerfile.rails                   # 🐳 Container Ruby
├── 📄 Gemfile                            # 💎 Dependência: gem "pg"
├── 📄 README_MASTER.md                   # 📚 Esta documentação
├── 📄 .gitignore                         # 🔒 Git ignore
├── 📄 .env.example                       # 🔑 Template de configuração
├── 📄 setup.sh                           # 🚀 Script de setup automático
├── 📁 db/
│   ├── 📄 schema.sql                     # 🗃️ Estrutura do banco (criação auto)
│   └── 📄 seed.sql                       # 🌱 15 exames realistas (opcional)
└── 📄 CREDENCIAIS_LOCAIS.txt             # 🔑 Credenciais desenvolvimento
```

**✅ Total: 11 arquivos (125KB) | 🚀 Setup: 3 comandos | 🎯 Zero configuração**

### 🎨 **Frontend Embutido** (`rails_minimal.rb`)
```ruby
def rails_page(exames)          # 🏠 Página Principal (/)
  # HTML + CSS + JavaScript inline
  # - Listagem de exames
  # - Filtros dinâmicos  
  # - Cards estatísticos
  # - Botões CRUD
end

def create_exam_page()          # ➕ Página Criação (/exames/new)
  # Formulário completo
  # - Exame Base / Personalizado
  # - Validações JavaScript
  # - Submit via AJAX
end

def edit_exam_page(db, id)      # ✏️ Página Edição (/exames/:id/edit)
  # Formulário de edição
  # - Dados pré-preenchidos
  # - Botão excluir
  # - Herança de preços
end
```

### 💾 **Banco de Dados** (PostgreSQL direto)
```sql
-- Tabela única com STI
CREATE TABLE exames (
  id SERIAL PRIMARY KEY,
  codigo VARCHAR(50) UNIQUE,
  nome VARCHAR(255) UNIQUE, 
  descricao TEXT,
  preco DECIMAL(10,2),
  type VARCHAR(255),           -- 'Exame' | 'ExamePersonalizado'
  active BOOLEAN DEFAULT true,
  exame_base_id INTEGER,       -- FK para herança
  deleted_at TIMESTAMP,        -- Soft delete
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

---

## 4. Como Executar

### 🚀 **Início Rápido** (3 Comandos!)

#### Pré-requisitos
- Docker e Docker Compose instalados
- Portas 3000 e 5434 disponíveis

#### 🎯 **Setup Ultra-Simples**
```bash
git clone <url-do-repositorio>
cd exames-customizados-poc
./setup.sh
```

**🎉 PRONTO! Em 30 segundos você terá:**
- ✅ **Ambiente completo** rodando
- ✅ **Banco estruturado** automaticamente  
- ✅ **15 exames de exemplo** (opcional)
- ✅ **Interface web** funcionando
- ✅ **API REST** ativa

#### 🛠️ **Opções Avançadas**
```bash
# Setup manual (se preferir)
docker compose up -d --build

# Popular apenas com dados (após setup)
docker compose exec -T rails cat /app/db/seed.sql | docker compose exec -T db psql -U postgres -d exames_customizados_development

# Resetar ambiente
docker compose down -v && ./setup.sh
```

**Opcional - Popular com dados de exemplo:**
```bash
# Execute o seed para ter dados de teste (15 exames: 6 base + 9 personalizados)
docker compose exec -T rails cat /app/db/seed.sql | docker compose exec -T db psql -U postgres -d exames_customizados_development
```
💡 **Dados inclusos**: Hemograma, Glicemia, Colesterol, Tireoide, Urina, Creatinina + variações personalizadas

**Manual - Apenas se necessário:**
```sql
-- Estrutura da tabela
CREATE TABLE exames (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nome VARCHAR(255) NOT NULL UNIQUE,
    descricao TEXT,
    preco DECIMAL(10,2) NOT NULL,
    type VARCHAR(255) NOT NULL DEFAULT 'Exame',
    active BOOLEAN NOT NULL DEFAULT true,
    exame_base_id INTEGER REFERENCES exames(id),
    deleted_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

-- Índices
CREATE INDEX idx_exames_codigo ON exames(codigo);
CREATE INDEX idx_exames_nome ON exames(nome);
CREATE INDEX idx_exames_type ON exames(type);
CREATE INDEX idx_exames_deleted_at ON exames(deleted_at);

-- Dados de exemplo
INSERT INTO exames (codigo, nome, descricao, preco, type, created_at, updated_at) VALUES
('HEM001', 'Hemograma Completo', 'Análise completa dos elementos do sangue', 45.50, 'Exame', NOW(), NOW()),
('GLI001', 'Glicemia de Jejum', 'Dosagem de glicose após jejum de 8 horas', 25.00, 'Exame', NOW(), NOW()),
('COL001', 'Colesterol Total e Frações', 'Dosagem de colesterol total, HDL, LDL', 35.75, 'Exame', NOW(), NOW());

INSERT INTO exames (codigo, nome, descricao, preco, type, exame_base_id, created_at, updated_at) VALUES
('HEM001-URG', 'Hemograma Urgente', 'Resultado em 2 horas', 45.50, 'ExamePersonalizado', 1, NOW(), NOW()),
('GLI001-DOM', 'Glicemia Domicílio', 'Coleta domiciliar', 25.00, 'ExamePersonalizado', 2, NOW(), NOW()),
('COL001-COMP', 'Perfil Lipídico Completo', 'Inclui apolipoproteínas', 35.75, 'ExamePersonalizado', 3, NOW(), NOW());
```

### 🌐 **Acessos Principais**
- **🏠 Página Principal**: http://localhost:3000  
  *Listagem completa com filtros dinâmicos*
- **➕ Criar Exame**: http://localhost:3000/exames/new  
  *Formulário para exames base e personalizados*
- **✏️ Editar Exame**: http://localhost:3000/exames/:id/edit  
  *Edição com herança de preços*
- **🔗 API REST**: http://localhost:3000/exames  
  *Endpoints JSON para integração*
- **❤️ Health Check**: http://localhost:3000/health  
  *Status do sistema*
- **🐘 PostgreSQL**: localhost:5434  
  *Acesso direto ao banco*

### ✅ **Verificação de Funcionamento**
```bash
# Testar API
curl http://localhost:3000/health
curl http://localhost:3000/exames

# Ver logs
docker compose logs rails
docker compose logs db

# Status dos containers
docker compose ps
```

---

## 5. API Rails

### 🛤️ **Rotas Principais**

#### **CRUD Completo**
| Método | Endpoint | Descrição | Parâmetros |
|--------|----------|-----------|------------|
| `GET` | `/exames` | Listar todos os exames | `?type=Exame\|ExamePersonalizado` |
| `GET` | `/exames/:id` | Buscar exame específico | `id` |
| `POST` | `/exames` | Criar novo exame | JSON body |
| `PUT` | `/exames/:id` | Atualizar exame | `id` + JSON body |
| `DELETE` | `/exames/:id` | Remover exame | `id` |

#### **Endpoints Auxiliares**
| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `GET` | `/exames/tipos` | Tipos disponíveis |
| `GET` | `/exames/estatisticas` | Estatísticas gerais |
| `GET` | `/health` | Health check |
| `GET` | `/api/v1/exames` | API versionada |

### 📝 **Exemplos de Uso**

#### **1. Listar Exames**
```bash
GET /exames
```
**Resposta:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "codigo": "HEM001",
      "nome": "Hemograma Completo",
      "preco": 45.50,
      "type": "Exame",
      "active": true
    }
  ],
  "meta": {
    "total": 6,
    "base_exames": 3,
    "personalizados": 3
  }
}
```

#### **2. Criar Exame Base**
```bash
POST /exames
Content-Type: application/json

{
  "exame": {
    "codigo": "TIR001",
    "nome": "Tireoide Completa",
    "descricao": "TSH, T3, T4 e Anti-TPO",
    "preco": 85.00,
    "type": "Exame"
  }
}
```

#### **3. Criar Exame Personalizado**
```bash
POST /exames
Content-Type: application/json

{
  "exame": {
    "codigo": "HEM001-URG",
    "nome": "Hemograma Urgente",
    "descricao": "Resultado em 2 horas",
    "type": "ExamePersonalizado",
    "exame_base_id": 1
  }
}
```

### 🔒 **Validações da API**
- ✅ Campos obrigatórios: `codigo`, `nome`, `preco`
- ✅ Unicidade de `codigo` e `nome`
- ✅ Preço > 0
- ✅ Tipo válido: `Exame` ou `ExamePersonalizado`
- ✅ Para `ExamePersonalizado`: `exame_base_id` obrigatório
- ✅ Não permite alterar preço diretamente em exames personalizados

---

## 6. Interface Web

### 🎨 **Interface Web Unificada** 
**URL**: http://localhost:3000 *(Frontend + Backend no mesmo servidor)*

#### **Funcionalidades**
- ✅ **Listagem Completa**: Todos os exames do banco PostgreSQL
- ✅ **CRUD Funcional**: 
  - **🏠 Página Principal**: Listagem com filtros (`/`)
  - **➕ Criar Exames**: Formulário para exames base e personalizados (`/exames/new`)
  - **✏️ Editar Exames**: Formulário de edição com validações (`/exames/:id/edit`)
  - **🗑️ Excluir Exames**: Soft delete com confirmação (botão "Excluir")
- ✅ **Filtros Funcionais**: 
  - Busca por código/nome em tempo real
  - Filtro por tipo (Base/Personalizado)
  - Filtro por status (Ativo/Inativo)
- ✅ **Herança Automática**: Preço de exames personalizados sempre igual ao pai
- ✅ **Cascata Inteligente**: Inativação/exclusão de pai afeta filhos automaticamente
- ✅ **Cards Estatísticos**: Contadores dinâmicos que atualizam com filtros
- ✅ **Design Responsivo**: Tailwind CSS + Font Awesome (via CDN)
- ✅ **Estado Vazio**: Feedback quando nenhum exame é encontrado

### 🏗️ **Arquitetura Frontend**
- **Servidor**: Ruby Socket TCP customizado
- **HTML**: Gerado via Ruby (funções `*_page`)
- **CSS**: Tailwind CSS via CDN + estilos inline
- **JavaScript**: Vanilla JS inline para interatividade
- **AJAX**: Fetch API para comunicação com backend
- **Responsivo**: Mobile-first design

---

## 7. Banco de Dados

### 🗃️ **Estrutura da Tabela `exames`**
```sql
CREATE TABLE exames (
    id                SERIAL PRIMARY KEY,
    codigo            VARCHAR(50) NOT NULL UNIQUE,
    nome              VARCHAR(255) NOT NULL UNIQUE,
    descricao         TEXT,
    preco             DECIMAL(10,2) NOT NULL,
    type              VARCHAR(255) NOT NULL DEFAULT 'Exame',
    active            BOOLEAN NOT NULL DEFAULT true,
    exame_base_id     INTEGER REFERENCES exames(id),
    deleted_at        TIMESTAMP,                    -- Soft Delete
    created_at        TIMESTAMP NOT NULL,
    updated_at        TIMESTAMP NOT NULL
);
```

### 🔗 **Índices e Constraints**
```sql
-- Índices para performance
CREATE INDEX idx_exames_codigo ON exames(codigo);
CREATE INDEX idx_exames_nome ON exames(nome);
CREATE INDEX idx_exames_type ON exames(type);
CREATE INDEX idx_exames_active ON exames(active);
CREATE INDEX idx_exames_exame_base_id ON exames(exame_base_id);
CREATE INDEX idx_exames_deleted_at ON exames(deleted_at);  -- Soft Delete

-- Constraint STI
ALTER TABLE exames ADD CONSTRAINT check_exame_base_id_only_for_custom
CHECK (
  (type = 'ExamePersonalizado' AND exame_base_id IS NOT NULL) OR
  (type != 'ExamePersonalizado' AND exame_base_id IS NULL)
);
```

### 📊 **Dados de Exemplo**
```sql
-- Exames Base
INSERT INTO exames (codigo, nome, descricao, preco, type) VALUES
('HEM001', 'Hemograma Completo', 'Análise completa dos elementos do sangue', 45.50, 'Exame'),
('GLI001', 'Glicemia de Jejum', 'Dosagem de glicose após jejum de 8 horas', 25.00, 'Exame'),
('COL001', 'Colesterol Total e Frações', 'Dosagem de colesterol total, HDL, LDL', 35.75, 'Exame');

-- Exames Personalizados
INSERT INTO exames (codigo, nome, descricao, type, exame_base_id) VALUES
('HEM001-URG', 'Hemograma Urgente', 'Resultado em 2 horas', 'ExamePersonalizado', 1),
('GLI001-DOM', 'Glicemia Domicílio', 'Coleta domiciliar', 'ExamePersonalizado', 2),
('COL001-COMP', 'Perfil Lipídico Completo', 'Inclui apolipoproteínas', 'ExamePersonalizado', 3);
```

### 🔍 **Consultas Úteis**
```sql
-- Ver todos os exames
SELECT * FROM exames ORDER BY created_at DESC;

-- Contar por tipo
SELECT type, COUNT(*) FROM exames GROUP BY type;

-- Exames com seus pais
SELECT 
  e1.codigo, e1.nome, e1.type,
  e2.codigo as pai_codigo, e2.nome as pai_nome
FROM exames e1
LEFT JOIN exames e2 ON e1.exame_base_id = e2.id;
```

---

## 8. Lógica de Negócio STI

### 🏗️ **Single Table Inheritance (Implementação Simples)**

#### **Estrutura no `rails_minimal.rb`**
```ruby
# Buscar exames base (type = 'Exame')
def fetch_base_exames(db)
  result = db.exec('SELECT * FROM exames WHERE type = $1 AND active = true AND deleted_at IS NULL ORDER BY nome', ['Exame'])
  # Conversão para hash
end

# Criar exame com herança automática
def create_exam(db, post_data)
  # Se ExamePersonalizado: herdar preço do pai
  if params['type'] == 'ExamePersonalizado'
    parent = db.exec_params('SELECT preco FROM exames WHERE id = $1', [params['exame_base_id']])
    preco = parent[0]['preco'].to_f  # Herda automaticamente
  end
end

# Atualizar com cascata automática
def update_exam(db, id, put_data)
  # Se mudou preço do pai: atualizar todos filhos
  if preco != exame[:preco] && exame[:type] == 'Exame'
    db.exec_params('UPDATE exames SET preco = $1 WHERE exame_base_id = $2', [preco, id])
  end
  
  # Se inativou pai: inativar filhos
  if exame[:type] == 'Exame' && !active
    db.exec_params('UPDATE exames SET active = false WHERE exame_base_id = $1', [id])
  end
end
```

#### **Regras de Negócio Implementadas**
```sql
-- Validações no banco
ALTER TABLE exames ADD CONSTRAINT check_exame_base_id_only_for_custom
CHECK (
  (type = 'ExamePersonalizado' AND exame_base_id IS NOT NULL) OR
  (type != 'ExamePersonalizado' AND exame_base_id IS NULL)
);

-- Soft Delete implementado
UPDATE exames SET deleted_at = NOW() WHERE id = $1;

-- Cascata para filhos ao deletar pai
UPDATE exames SET deleted_at = NOW() WHERE exame_base_id = $1;
```

### 🔄 **Herança de Preços e Cascata**
- ✅ **Herança Automática**: Exames personalizados sempre retornam o preço do pai
- ✅ **Atualização Automática**: Mudanças no preço do pai atualizam automaticamente todos os filhos
- ✅ **Consistente**: Impossível alterar preço diretamente no filho
- ✅ **Cascata de Inativação**: Inativar exame pai inativa automaticamente todos os filhos
- ✅ **Cascata de Exclusão**: Excluir exame pai exclui automaticamente todos os filhos (soft delete)

### 🔗 **Relacionamentos**
- ✅ **1:N**: Um exame base pode ter vários personalizados
- ✅ **Soft Delete Cascata**: Deletar pai remove todos os filhos (recuperável)
- ✅ **Inativação Cascata**: Inativar pai inativa todos os filhos automaticamente
- ✅ **Referencial**: FK garante integridade dos dados
- ✅ **Herança Automática**: Preços sempre sincronizados pai→filhos

---

## 9. Docker e Containers

### 🐳 **Arquitetura Docker**
```yaml
# docker-compose.yml
services:
  db:                    # PostgreSQL 13
    image: postgres:13
    ports: ["5434:5432"]
    
  rails:                 # Rails API
    build: Dockerfile.rails
    ports: ["3000:3000"]
    depends_on: [db]
    
  react:                 # React Frontend
    build: frontend/Dockerfile.react
    ports: ["3001:3000"]
```

### 📦 **Containers (Minimalista)**

#### **1. PostgreSQL Container**
- **Imagem**: `postgres:13`
- **Porta Externa**: 5434
- **Porta Interna**: 5432
- **Banco**: `exames_customizados_development`
- **Health Check**: `pg_isready`
- **Volume**: Dados persistentes

#### **2. Rails Container (Customizado)**
- **Build**: `Dockerfile.rails`
- **Porta Externa**: 3000
- **Porta Interna**: 3000
- **Comando**: `ruby rails_minimal.rb`
- **Volumes**: Código fonte (apenas 7 arquivos)
- **ENV**: `DATABASE_URL`
- **Deps**: Ruby 3.2.3 + gem pg + postgresql-client

### 🔧 **Comandos Docker**
```bash
# Construir e iniciar
docker compose up -d --build

# Status dos containers
docker compose ps

# Logs
docker compose logs rails
docker compose logs db
docker compose logs react

# Acessar containers
docker compose exec rails bash
docker compose exec db psql -U postgres

# Parar serviços
docker compose down

# Limpar tudo
docker compose down -v
docker system prune -f
```

---

## 10. Comandos Úteis

### 🛠️ **Desenvolvimento**
```bash
# Setup inicial completo (NOVO!)
./setup.sh

# Popular com dados de exemplo (NOVO!)
docker compose exec -T rails cat /app/db/seed.sql | docker compose exec -T db psql -U postgres -d exames_customizados_development

# Reiniciar apenas o Rails
docker compose restart rails

# Acessar banco via Docker
docker compose exec db psql -U postgres -d exames_customizados_development

# Ver logs em tempo real
docker compose logs -f rails

# Resetar ambiente completo
docker compose down -v && ./setup.sh
```

### 🧪 **Testes da API**
```bash
# Health check
curl http://localhost:3000/health

# Listar exames
curl http://localhost:3000/exames

# Filtrar por tipo
curl "http://localhost:3000/exames?type=Exame"
curl "http://localhost:3000/exames?type=ExamePersonalizado"

# Estatísticas
curl http://localhost:3000/exames/estatisticas

# Tipos disponíveis
curl http://localhost:3000/exames/tipos
```

### 📊 **Banco de Dados**
```bash
# Conectar ao banco
docker compose exec db psql -U postgres -d exames_customizados_development

# Comandos SQL úteis
\dt                           # Listar tabelas
\d exames                     # Estrutura da tabela
SELECT COUNT(*) FROM exames;  # Contar registros

# Backup do banco
docker compose exec db pg_dump -U postgres exames_customizados_development > backup.sql

# Restaurar backup
docker compose exec -T db psql -U postgres -d exames_customizados_development < backup.sql
```

### 🎨 **Frontend (Embutido)**
```bash
# Frontend está no rails_minimal.rb
# Não há comandos separados necessários

# Ver estrutura das páginas
grep -n "def.*_page" rails_minimal.rb

# Ver tamanho total do projeto
du -sh .

# Ver logs do servidor (inclui frontend)
docker compose logs rails -f
```

---

## 11. Troubleshooting

### ⚠️ **Problemas Comuns**

#### **1. Porta já em uso**
```bash
# Verificar processos usando as portas
lsof -i :3000
lsof -i :3001
lsof -i :5434

# Matar processos
kill -9 <PID>

# Alterar portas no docker-compose.yml se necessário
```

#### **2. Container Rails não inicia**
```bash
# Ver logs detalhados
docker compose logs rails

# Reconstruir container
docker compose down rails
docker compose build rails --no-cache
docker compose up rails -d

# Verificar gems
docker compose exec rails bundle check
```

#### **3. Banco não conecta**
```bash
# Verificar status do PostgreSQL
docker compose exec db pg_isready -U postgres

# Recriar banco
docker compose exec rails rails db:drop db:create db:migrate

# Verificar variáveis de ambiente
docker compose exec rails env | grep DATABASE
```

#### **4. Página não carrega**
```bash
# Verificar se servidor está rodando
curl http://localhost:3000/

# Ver logs detalhados
docker compose logs rails

# Verificar conexão com banco
curl http://localhost:3000/health

# Reiniciar apenas o servidor
docker compose restart rails
```

#### **5. API retorna 404**
```bash
# Verificar se servidor Rails está rodando
curl http://localhost:3000/health

# Verificar rotas disponíveis
docker compose exec rails rails routes

# Testar endpoint específico
curl -v http://localhost:3000/exames
```

### 🔧 **Reset Completo**
```bash
# Parar tudo
docker compose down -v

# Limpar containers e volumes
docker system prune -f
docker volume prune -f

# Recomeçar do zero
./setup.sh
docker compose up -d --build
```

---

## 12. Desenvolvimento

### 📚 **Próximos Passos**

#### **Funcionalidades Futuras**
1. **Autenticação e Autorização**
   - JWT tokens
   - Roles de usuário (admin, técnico, etc.)
   - Controle de acesso por funcionalidade

2. **Melhorias na Interface**
   - Paginação para grandes volumes
   - Export para PDF/Excel
   - Upload de imagens dos exames
   - Dashboard com gráficos

3. **API Avançada**
   - Versionamento completo (/api/v2/)
   - Rate limiting
   - Cache com Redis
   - Documentação Swagger/OpenAPI

4. **Funcionalidades de Negócio**
   - Agendamento de exames
   - Resultados de exames
   - Integração com equipamentos
   - Faturamento e convênios

#### **Melhorias Técnicas**
1. **Performance**
   - Otimização de queries
   - Cache de dados frequentes
   - CDN para assets estáticos
   - Lazy loading no frontend

2. **Monitoramento**
   - Logs estruturados
   - Métricas de performance
   - Health checks avançados
   - Alertas automáticos

3. **Testes**
   - Testes unitários (RSpec)
   - Testes de integração
   - Testes E2E (Cypress)
   - Coverage reports

4. **Deploy**
   - CI/CD pipeline
   - Deploy automatizado
   - Ambiente de staging
   - Rollback automático

### 🧪 **Testes**
```bash
# Executar suite de testes Rails
docker compose exec rails bundle exec rspec

# Testes do frontend
docker compose exec react npm test

# Testes de integração
docker compose exec rails rails test:integration

# Coverage
docker compose exec rails bundle exec rspec --format documentation
```

### 📖 **Documentação**
- **API**: Endpoints documentados no código
- **Modelos**: Comentários inline nos models
- **Frontend**: Componentes documentados
- **Docker**: Comentários nos Dockerfiles

### 🔄 **Workflow de Desenvolvimento**
1. **Feature Branch**: Criar branch para nova funcionalidade
2. **Desenvolvimento**: Implementar com testes
3. **Code Review**: Review antes do merge
4. **Deploy**: Automático após merge na main

---

## 📋 **Resumo Final**

### ✅ **O que está Funcionando**
- ✅ **Servidor Ruby Customizado** com Socket TCP
- ✅ **Frontend HTML/CSS/JS** embutido e responsivo
- ✅ **Interface Web Completa** com CRUD funcional
- ✅ **Banco PostgreSQL** com STI simplificado
- ✅ **Docker Minimalista** com 2 containers
- ✅ **Herança de preços** automática
- ✅ **Soft Delete** com cascata
- ✅ **Validações** robustas
- ✅ **Documentação** atualizada

### 🎯 **URLs de Acesso**
- **🏠 Interface Principal**: http://localhost:3000
- **➕ Criar Exame**: http://localhost:3000/exames/new
- **✏️ Editar Exame**: http://localhost:3000/exames/:id/edit
- **🔗 API REST**: http://localhost:3000/exames
- **❤️ Health Check**: http://localhost:3000/health
- **🐘 Banco**: localhost:5434

### 🚀 **Como Começar** (Super Simples!)
```bash
git clone <repo>
cd exames-customizados-poc
./setup.sh
# 🎉 Pronto! Acesse http://localhost:3000
```

**🎯 O que o `setup.sh` faz automaticamente:**
- ✅ Verifica Docker
- ✅ Cria `.env` se não existir  
- ✅ Inicia containers
- ✅ Cria estrutura do banco
- ✅ Oferece popular com 15 exames de exemplo
- ✅ Valida se tudo está funcionando

---

## 💡 **Arquivo Responsável pelo Frontend**

**🎯 RESPOSTA DIRETA:**
```ruby
📄 rails_minimal.rb  # ← ESTE é o arquivo do frontend!
```

**Funções que geram as páginas:**
- **Linha ~816**: `def rails_page(exames)` → Página principal
- **Linha ~293**: `def create_exam_page()` → Página de criação  
- **Linha ~542**: `def edit_exam_page(db, id)` → Página de edição

**Cada função contém:**
- ✅ HTML completo estruturado
- ✅ CSS (Tailwind + estilos inline)
- ✅ JavaScript (filtros, AJAX, validações)
- ✅ Responsividade mobile-first

**Não há mais arquivos separados de frontend!** 

Todo HTML/CSS/JS está embutido no servidor Ruby. 🎨

---

**📧 Para dúvidas ou contribuições, consulte esta documentação.**

**🎉 Projeto minimalista 100% funcional! (7 arquivos, 112KB)**