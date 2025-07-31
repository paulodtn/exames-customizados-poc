-- ============================================
-- DADOS DE EXEMPLO - EXAMES CUSTOMIZADOS
-- ============================================
-- Execute este arquivo APENAS se quiser popular o banco com dados de teste
-- Comando: docker compose exec db psql -U postgres -d exames_customizados_development -f /app/db/seed.sql

-- Limpar dados existentes (opcional)
-- TRUNCATE exames RESTART IDENTITY CASCADE;

-- Exames Base (Principais do laboratório)
INSERT INTO exames (codigo, nome, descricao, preco, type) VALUES
('HEM001', 'Hemograma Completo', 'Análise completa dos elementos do sangue incluindo contagem de células', 45.50, 'Exame'),
('GLI001', 'Glicemia de Jejum', 'Dosagem de glicose no sangue após jejum de 8-12 horas', 25.00, 'Exame'),
('COL001', 'Colesterol Total e Frações', 'Dosagem de colesterol total, HDL, LDL e triglicerídeos', 35.75, 'Exame'),
('TIR001', 'Perfil Tireoidiano', 'TSH, T3 livre, T4 livre para avaliação da tireoide', 85.00, 'Exame'),
('URI001', 'Urina Tipo I', 'Exame completo de urina com sedimentoscopia', 18.50, 'Exame'),
('CRE001', 'Creatinina Sérica', 'Dosagem de creatinina para avaliação da função renal', 22.00, 'Exame')
ON CONFLICT (codigo) DO NOTHING;

-- Exames Personalizados (Filhos que herdam preço dos pais)
INSERT INTO exames (codigo, nome, descricao, preco, type, exame_base_id) VALUES
-- Variações do Hemograma
('HEM001-URG', 'Hemograma Urgente', 'Resultado liberado em até 2 horas', 45.50, 'ExamePersonalizado', 
  (SELECT id FROM exames WHERE codigo = 'HEM001')),
('HEM001-DOM', 'Hemograma Domiciliar', 'Coleta realizada no domicílio do paciente', 45.50, 'ExamePersonalizado', 
  (SELECT id FROM exames WHERE codigo = 'HEM001')),

-- Variações da Glicemia
('GLI001-GTT', 'Curva Glicêmica (GTT)', 'Teste de tolerância à glicose oral', 25.00, 'ExamePersonalizado', 
  (SELECT id FROM exames WHERE codigo = 'GLI001')),
('GLI001-HB', 'Glicemia + Hemoglobina Glicada', 'Glicemia de jejum com HbA1c', 25.00, 'ExamePersonalizado', 
  (SELECT id FROM exames WHERE codigo = 'GLI001')),

-- Variações do Colesterol
('COL001-COMP', 'Perfil Lipídico Completo', 'Inclui apolipoproteínas A1 e B', 35.75, 'ExamePersonalizado', 
  (SELECT id FROM exames WHERE codigo = 'COL001')),
('COL001-PED', 'Perfil Lipídico Pediátrico', 'Adaptado para crianças e adolescentes', 35.75, 'ExamePersonalizado', 
  (SELECT id FROM exames WHERE codigo = 'COL001')),

-- Variações da Tireoide
('TIR001-AUTO', 'Tireoide + Autoimunidade', 'Inclui Anti-TPO e Anti-Tireoglobulina', 85.00, 'ExamePersonalizado', 
  (SELECT id FROM exames WHERE codigo = 'TIR001')),

-- Variações da Urina
('URI001-24H', 'Urina 24 Horas', 'Coleta de urina em 24 horas para análise quantitativa', 18.50, 'ExamePersonalizado', 
  (SELECT id FROM exames WHERE codigo = 'URI001')),

-- Variações da Creatinina
('CRE001-DEP', 'Depuração de Creatinina', 'Clearance de creatinina para avaliação detalhada renal', 22.00, 'ExamePersonalizado', 
  (SELECT id FROM exames WHERE codigo = 'CRE001'))
ON CONFLICT (codigo) DO NOTHING;

-- Atualizar preços dos exames personalizados (herança automática)
UPDATE exames SET preco = (
  SELECT parent.preco 
  FROM exames parent 
  WHERE parent.id = exames.exame_base_id
) WHERE type = 'ExamePersonalizado';

-- Estatísticas finais
\echo '📊 DADOS INSERIDOS COM SUCESSO!'
\echo ''
SELECT 
  '📋 Total de Exames: ' || COUNT(*) as estatistica
FROM exames WHERE deleted_at IS NULL
UNION ALL
SELECT 
  '🔬 Exames Base: ' || COUNT(*)
FROM exames WHERE type = 'Exame' AND deleted_at IS NULL
UNION ALL
SELECT 
  '⚡ Exames Personalizados: ' || COUNT(*)
FROM exames WHERE type = 'ExamePersonalizado' AND deleted_at IS NULL;

\echo ''
\echo '🌐 Acesse: http://localhost:3000'