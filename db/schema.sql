-- ============================================
-- SCHEMA DO BANCO DE DADOS - EXAMES CUSTOMIZADOS
-- ============================================
-- Este arquivo cria automaticamente a estrutura do banco

-- Tabela principal com STI (Single Table Inheritance)
CREATE TABLE IF NOT EXISTS exames (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nome VARCHAR(255) NOT NULL UNIQUE,
    descricao TEXT,
    preco DECIMAL(10,2) NOT NULL,
    type VARCHAR(255) NOT NULL DEFAULT 'Exame',
    active BOOLEAN NOT NULL DEFAULT true,
    exame_base_id INTEGER REFERENCES exames(id),
    deleted_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_exames_codigo ON exames(codigo);
CREATE INDEX IF NOT EXISTS idx_exames_nome ON exames(nome);
CREATE INDEX IF NOT EXISTS idx_exames_type ON exames(type);
CREATE INDEX IF NOT EXISTS idx_exames_active ON exames(active);
CREATE INDEX IF NOT EXISTS idx_exames_exame_base_id ON exames(exame_base_id);
CREATE INDEX IF NOT EXISTS idx_exames_deleted_at ON exames(deleted_at);

-- Constraint para garantir STI correto
ALTER TABLE exames DROP CONSTRAINT IF EXISTS check_exame_base_id_only_for_custom;
ALTER TABLE exames ADD CONSTRAINT check_exame_base_id_only_for_custom
CHECK (
  (type = 'ExamePersonalizado' AND exame_base_id IS NOT NULL) OR
  (type != 'ExamePersonalizado' AND exame_base_id IS NULL)
);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar updated_at
DROP TRIGGER IF EXISTS update_exames_updated_at ON exames;
CREATE TRIGGER update_exames_updated_at
    BEFORE UPDATE ON exames
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Estrutura do banco criada com sucesso