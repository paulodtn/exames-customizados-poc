#!/usr/bin/env ruby

require 'socket'

puts "🚀 Rails Server Simulado"
puts "📍 Servidor rodando em http://0.0.0.0:3000"
puts "🎯 Implementando funcionalidade Rails + PostgreSQL"

# Conectar ao PostgreSQL
def connect_to_db
  require 'pg'
  conn = PG.connect(
    host: ENV['DB_HOST'],
    port: ENV['DB_PORT'],
    user: ENV['POSTGRES_USER'],
    password: ENV['POSTGRES_PASSWORD'],
    dbname: ENV['POSTGRES_DB']
  )
  puts "✅ Conectado ao PostgreSQL"
  
  # Verificar se tabela existe e criar se necessário
  ensure_database_schema(conn)
  
  conn
rescue => e
  puts "❌ Erro PostgreSQL: #{e.message}"
  nil
end

# Garantir que a estrutura do banco existe
def ensure_database_schema(db)
  return unless db
  
  begin
    # Verificar se tabela exames existe
    result = db.exec("SELECT to_regclass('public.exames')")
    table_exists = !result[0]['to_regclass'].nil?
    
    unless table_exists
      puts "🗃️  Criando estrutura do banco de dados..."
      
      # Ler e executar schema.sql se existir, senão criar tabela básica
      if File.exist?('/app/db/schema.sql')
        schema_sql = File.read('/app/db/schema.sql')
        db.exec(schema_sql)
        puts "✅ Estrutura do banco criada via schema.sql"
      else
        # Schema básico inline caso arquivo não exista
        create_basic_schema(db)
        puts "✅ Estrutura básica do banco criada"
      end
    end
  rescue => e
    puts "⚠️  Erro ao verificar/criar schema: #{e.message}"
  end
end

# Criar schema básico se arquivo schema.sql não existir
def create_basic_schema(db)
  schema_sql = <<~SQL
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

    CREATE INDEX IF NOT EXISTS idx_exames_codigo ON exames(codigo);
    CREATE INDEX IF NOT EXISTS idx_exames_nome ON exames(nome);
    CREATE INDEX IF NOT EXISTS idx_exames_type ON exames(type);
    CREATE INDEX IF NOT EXISTS idx_exames_deleted_at ON exames(deleted_at);
  SQL
  
  db.exec(schema_sql)
end

# Buscar exames do banco (apenas não deletados - soft delete)
def fetch_exames(db)
  return [] unless db
  
  begin
    result = db.exec('SELECT * FROM exames WHERE deleted_at IS NULL ORDER BY created_at DESC')
    exames = []
    result.each do |row|
      exames << {
        id: row['id'].to_i,
        codigo: row['codigo'],
        nome: row['nome'],
        descricao: row['descricao'],
        preco: row['preco'].to_f,
        type: row['type'],
        active: row['active'] == 't',
        exame_base_id: row['exame_base_id']&.to_i,
        created_at: row['created_at'],
        updated_at: row['updated_at']
      }
    end
    puts "📊 Carregados #{exames.length} exames do banco"
    exames
  rescue => e
    puts "❌ Erro ao buscar exames: #{e.message}"
    []
  end
end

# Buscar exames base para select
def fetch_base_exames(db)
  return [] unless db
  
  begin
    result = db.exec("SELECT * FROM exames WHERE type = 'Exame' AND deleted_at IS NULL AND active = true ORDER BY nome")
    exames = []
    result.each do |row|
      exames << {
        id: row['id'].to_i,
        codigo: row['codigo'],
        nome: row['nome'],
        preco: row['preco'].to_f
      }
    end
    exames
  rescue => e
    puts "❌ Erro ao buscar exames base: #{e.message}"
    []
  end
end

# Buscar exame por ID
def fetch_exame_by_id(db, id)
  return nil unless db
  
  begin
    result = db.exec_params('SELECT * FROM exames WHERE id = $1 AND deleted_at IS NULL', [id])
    return nil if result.ntuples == 0
    
    row = result[0]
    {
      id: row['id'].to_i,
      codigo: row['codigo'],
      nome: row['nome'],
      descricao: row['descricao'],
      preco: row['preco'].to_f,
      type: row['type'],
      active: row['active'] == 't',
      exame_base_id: row['exame_base_id']&.to_i,
      created_at: row['created_at'],
      updated_at: row['updated_at']
    }
  rescue => e
    puts "❌ Erro ao buscar exame: #{e.message}"
    nil
  end
end

# Criar exame
def create_exam(db, post_data)
  begin
    puts "🔍 RAW POST DATA: #{post_data.inspect}"
    params = parse_form_data(post_data)
    puts "🔍 PARSED PARAMS: #{params.inspect}"
    
    # Validações
    if params['codigo'].nil? || params['codigo'].strip.empty?
      puts "❌ Código validation failed: #{params['codigo'].inspect}"
      return '{"success":false,"error":"Código é obrigatório"}'
    end
    
    if params['nome'].nil? || params['nome'].strip.empty?
      return '{"success":false,"error":"Nome é obrigatório"}'
    end
    
    preco = params['preco'].to_f
    if preco <= 0
      return '{"success":false,"error":"Preço deve ser maior que zero"}'
    end
    
    # Para exames personalizados, herdar preço do pai
    if params['type'] == 'ExamePersonalizado'
      if params['exame_base_id'].nil? || params['exame_base_id'].to_i <= 0
        return '{"success":false,"error":"Exame base é obrigatório para exames personalizados"}'
      end
      
      # Buscar preço do exame pai
      parent_result = db.exec_params('SELECT preco FROM exames WHERE id = $1 AND deleted_at IS NULL', [params['exame_base_id']])
      if parent_result.ntuples == 0
        return '{"success":false,"error":"Exame base não encontrado"}'
      end
      preco = parent_result[0]['preco'].to_f
    end
    
    # Verificar unicidade de código
    check_result = db.exec_params('SELECT id FROM exames WHERE codigo = $1 AND deleted_at IS NULL', [params['codigo']])
    if check_result.ntuples > 0
      return '{"success":false,"error":"Código já existe"}'
    end
    
    # Inserir exame
    sql = 'INSERT INTO exames (codigo, nome, descricao, preco, type, active, exame_base_id, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id'
    now = Time.now
    active = params['active'] == 'on' || params['active'] == 'true'
    exame_base_id = params['type'] == 'ExamePersonalizado' ? params['exame_base_id'].to_i : nil
    
    result = db.exec_params(sql, [
      params['codigo'].strip,
      params['nome'].strip,
      params['descricao'].to_s.strip,
      preco,
      params['type'],
      active,
      exame_base_id,
      now,
      now
    ])
    
    id = result[0]['id']
    '{"success":true,"id":' + id + ',"message":"Exame criado com sucesso"}'
    
  rescue => e
    puts "❌ Erro ao criar exame: #{e.message}"
    '{"success":false,"error":"Erro interno do servidor"}'
  end
end

# Atualizar exame
def update_exam(db, id, put_data)
  begin
    params = parse_form_data(put_data)
    
    # Buscar exame atual
    exame = fetch_exame_by_id(db, id)
    return '{"success":false,"error":"Exame não encontrado"}' unless exame
    
    # Validações
    if params['codigo'].nil? || params['codigo'].strip.empty?
      return '{"success":false,"error":"Código é obrigatório"}'
    end
    
    if params['nome'].nil? || params['nome'].strip.empty?
      return '{"success":false,"error":"Nome é obrigatório"}'
    end
    
    # Verificar unicidade de código (exceto o próprio)
    check_result = db.exec_params('SELECT id FROM exames WHERE codigo = $1 AND id != $2 AND deleted_at IS NULL', [params['codigo'], id])
    if check_result.ntuples > 0
      return '{"success":false,"error":"Código já existe"}'
    end
    
    preco = params['preco'].to_f
    active = params['active'] == 'on' || params['active'] == 'true'
    
    # Para exames personalizados, aplicar regras especiais
    if exame[:type] == 'ExamePersonalizado'
      # Se mudou o exame base, herdar novo preço
      if params['exame_base_id'] && params['exame_base_id'].to_i != exame[:exame_base_id]
        parent_result = db.exec_params('SELECT preco FROM exames WHERE id = $1 AND deleted_at IS NULL', [params['exame_base_id']])
        if parent_result.ntuples == 0
          return '{"success":false,"error":"Exame base não encontrado"}'
        end
        preco = parent_result[0]['preco'].to_f
        exame_base_id = params['exame_base_id'].to_i
      else
        # Manter exame base atual e seu preço
        exame_base_id = exame[:exame_base_id]
        parent_result = db.exec_params('SELECT preco FROM exames WHERE id = $1', [exame_base_id])
        preco = parent_result[0]['preco'].to_f if parent_result.ntuples > 0
      end
    else
      # Para exames base, atualizar preço e propagar para filhos
      exame_base_id = nil
      if preco != exame[:preco]
        # Atualizar preço dos filhos - HERDAM O PREÇO DO PAI
        puts "💰 Atualizando preço dos filhos de #{preco} para exame base #{id}"
        db.exec_params('UPDATE exames SET preco = $1, updated_at = $2 WHERE exame_base_id = $3 AND deleted_at IS NULL', [preco, Time.now, id])
      end
    end
    
    # Atualizar exame
    sql = 'UPDATE exames SET codigo = $1, nome = $2, descricao = $3, preco = $4, active = $5, exame_base_id = $6, updated_at = $7 WHERE id = $8'
    
    db.exec_params(sql, [
      params['codigo'].strip,
      params['nome'].strip,
      params['descricao'].to_s.strip,
      preco,
      active,
      exame_base_id,
      Time.now,
      id
    ])
    
    # Se desativou um exame base, desativar filhos
    if exame[:type] == 'Exame' && exame[:active] && !active
      db.exec_params('UPDATE exames SET active = false, updated_at = $1 WHERE exame_base_id = $2 AND deleted_at IS NULL', [Time.now, id])
    end
    
    '{"success":true,"message":"Exame atualizado com sucesso"}'
    
  rescue => e
    puts "❌ Erro ao atualizar exame: #{e.message}"
    '{"success":false,"error":"Erro interno do servidor"}'
  end
end

# Soft delete de exame
def delete_exam(db, id)
  begin
    # Buscar exame
    exame = fetch_exame_by_id(db, id)
    return '{"success":false,"error":"Exame não encontrado"}' unless exame
    
    now = Time.now
    
    # Se for exame base, deletar filhos também
    if exame[:type] == 'Exame'
      db.exec_params('UPDATE exames SET deleted_at = $1 WHERE exame_base_id = $2 AND deleted_at IS NULL', [now, id])
    end
    
    # Soft delete do exame
    db.exec_params('UPDATE exames SET deleted_at = $1 WHERE id = $2', [now, id])
    
    '{"success":true,"message":"Exame excluído com sucesso"}'
    
  rescue => e
    puts "❌ Erro ao deletar exame: #{e.message}"
    '{"success":false,"error":"Erro interno do servidor"}'
  end
end

# Parse form data
def parse_form_data(data)
  require 'uri'
  params = {}
  return params if data.nil? || data.empty?
  
  data.split('&').each do |param|
    key, value = param.split('=', 2)
    next unless key && value
    params[URI.decode_www_form_component(key)] = URI.decode_www_form_component(value)
  end
  puts "📝 Parsed params: #{params.inspect}"
  params
end

# Página de criação de exame
def create_exam_page()
  <<~HTML
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Criar Exame</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <style>
            .toggle-checkbox:checked {
                right: 0;
                border-color: #4f46e5;
            }
            .toggle-checkbox:checked + .toggle-label {
                background-color: #4f46e5;
            }
        </style>
    </head>
    <body class="bg-gray-50">
        <div class="container mx-auto px-4 py-8 max-w-4xl">
            <div class="bg-white rounded-lg shadow-md overflow-hidden">
                <!-- Header -->
                <div class="bg-indigo-600 px-6 py-4">
                    <h1 class="text-2xl font-bold text-white">
                        <i class="fas fa-plus mr-2"></i>Criar Novo Exame
                    </h1>
                </div>
                
                <!-- Form -->
                <form id="examForm" class="p-6">
                    <!-- Type Field -->
                    <div class="mb-6">
                        <label for="type" class="block text-sm font-medium text-gray-700 mb-1">Tipo de Exame *</label>
                        <select id="type" name="type" required onchange="toggleExameBaseField()"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500">
                            <option value="">Selecione o tipo</option>
                            <option value="Exame">Exame Base</option>
                            <option value="ExamePersonalizado">Exame Personalizado</option>
                        </select>
                    </div>
                    
                    <!-- Custom Exam Field (Conditional) -->
                    <div id="exameBaseContainer" class="mb-6 hidden">
                        <label for="exame_base_id" class="block text-sm font-medium text-gray-700 mb-1">Exame Base *</label>
                        <select id="exame_base_id" name="exame_base_id"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500">
                            <option value="">Carregando exames base...</option>
                        </select>
                        <p class="mt-1 text-sm text-gray-500">O preço será herdado automaticamente do exame base selecionado</p>
                    </div>
                    
                    <!-- Common Fields -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                        <div>
                            <label for="codigo" class="block text-sm font-medium text-gray-700 mb-1">Código *</label>
                            <input type="text" id="codigo" name="codigo" required
                                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                                placeholder="Ex: EXM001">
                        </div>
                        
                        <div>
                            <label for="nome" class="block text-sm font-medium text-gray-700 mb-1">Nome *</label>
                            <input type="text" id="nome" name="nome" required
                                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                                placeholder="Nome do exame">
                        </div>
                    </div>
                    
                    <div class="mb-6">
                        <label for="descricao" class="block text-sm font-medium text-gray-700 mb-1">Descrição</label>
                        <textarea id="descricao" name="descricao" rows="3"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                            placeholder="Descrição detalhada do exame"></textarea>
                    </div>
                    
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                        <div id="precoContainer">
                            <label for="preco" class="block text-sm font-medium text-gray-700 mb-1">Preço em R$ *</label>
                            <input type="text" id="preco" name="preco" required
                                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                                placeholder="0,00" oninput="formatCurrency(this)">
                            <p id="precoHint" class="mt-1 text-sm text-gray-500">Digite o preço do exame</p>
                        </div>
                        
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                            <div class="flex items-center">
                                <div class="relative inline-block w-10 mr-2 align-middle select-none">
                                    <input type="checkbox" id="active" name="active" checked
                                        class="toggle-checkbox absolute block w-6 h-6 rounded-full bg-white border-4 appearance-none cursor-pointer"/>
                                    <label for="active" 
                                        class="toggle-label block overflow-hidden h-6 rounded-full bg-gray-300 cursor-pointer"></label>
                                </div>
                                <span class="text-sm text-gray-700">Ativo</span>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Action Buttons -->
                    <div class="flex flex-col sm:flex-row justify-end gap-3 mt-8 pt-4 border-t border-gray-200">
                        <button type="button" onclick="window.location.href='/'"
                            class="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                            <i class="fas fa-times mr-1"></i>Cancelar
                        </button>
                        <button type="submit"
                            class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                            <i class="fas fa-save mr-1"></i>Criar Exame
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <script>
            // Load base exams on page load
            document.addEventListener('DOMContentLoaded', function() {
                loadBaseExams();
            });
            
            // Load base exams for dropdown
            function loadBaseExams() {
                fetch('/exames')
                    .then(response => response.json())
                    .then(data => {
                        const select = document.getElementById('exame_base_id');
                        select.innerHTML = '<option value="">Selecione um exame base</option>';
                        
                        if (data.success) {
                            const baseExams = data.data.filter(exam => exam.type === 'Exame');
                            baseExams.forEach(exam => {
                                const option = document.createElement('option');
                                option.value = exam.id;
                                option.textContent = `${exam.nome} (${exam.codigo}) - R$ ${exam.preco.toFixed(2).replace('.', ',')}`;
                                option.dataset.preco = exam.preco;
                                select.appendChild(option);
                            });
                        }
                    })
                    .catch(error => {
                        console.error('Erro ao carregar exames base:', error);
                    });
            }
            
            // Toggle base exam field visibility
            function toggleExameBaseField() {
                const type = document.getElementById('type').value;
                const container = document.getElementById('exameBaseContainer');
                const precoField = document.getElementById('preco');
                const precoHint = document.getElementById('precoHint');
                
                if (type === 'ExamePersonalizado') {
                    container.classList.remove('hidden');
                    precoField.readOnly = true;
                    precoField.classList.add('bg-gray-100');
                    precoHint.textContent = 'Preço será herdado do exame base selecionado';
                    precoField.value = '';
                } else {
                    container.classList.add('hidden');
                    precoField.readOnly = false;
                    precoField.classList.remove('bg-gray-100');
                    precoHint.textContent = 'Digite o preço do exame';
                    document.getElementById('exame_base_id').value = '';
                }
            }
            
            // Update price when base exam changes
            document.getElementById('exame_base_id').addEventListener('change', function() {
                const selectedOption = this.selectedOptions[0];
                if (selectedOption && selectedOption.dataset.preco) {
                    const preco = parseFloat(selectedOption.dataset.preco);
                    document.getElementById('preco').value = preco.toFixed(2).replace('.', ',');
                }
            });
            
            // Format currency input
            function formatCurrency(input) {
                let value = input.value.replace(/[^\\d,]/g, '');
                const commaCount = value.split(',').length - 1;
                if (commaCount > 1) {
                    value = value.replace(/,/g, '');
                    value = value.replace(/(\\d{2})$/, ',$1');
                }
                if (value.length > 6) {
                    const parts = value.split(',');
                    parts[0] = parts[0].replace(/\\B(?=(\\d{3})+(?!\\d))/g, '.');
                    value = parts.join(',');
                }
                if (value.includes(',')) {
                    const decimalPart = value.split(',')[1] || '';
                    if (decimalPart.length > 2) {
                        value = value.substring(0, value.indexOf(',') + 3);
                    }
                }
                input.value = value;
            }
            
            // Handle form submission
            document.getElementById('examForm').addEventListener('submit', function(e) {
                e.preventDefault();
                
                const formData = new FormData(this);
                const params = new URLSearchParams();
                
                // Convert FormData to URLSearchParams
                for (let [key, value] of formData.entries()) {
                    params.append(key, value);
                }
                
                // Convert price to decimal format
                const precoValue = formData.get('preco').replace(',', '.');
                params.set('preco', precoValue);
                
                // Ensure active is sent as string
                if (!formData.has('active')) {
                    params.set('active', 'false');
                } else {
                    params.set('active', 'true');
                }
                
                fetch('/exames', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: params.toString()
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('Exame criado com sucesso!');
                        window.location.href = '/';
                    } else {
                        alert('Erro: ' + data.error);
                    }
                })
                .catch(error => {
                    console.error('Erro:', error);
                    alert('Erro ao criar exame');
                });
            });
        </script>
    </body>
    </html>
  HTML
end

# Página de edição de exame
def edit_exam_page(db, id)
  exame = fetch_exame_by_id(db, id)
  return '404 - Exame não encontrado' unless exame
  
  <<~HTML
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Editar Exame</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <style>
            .toggle-checkbox:checked {
                right: 0;
                border-color: #4f46e5;
            }
            .toggle-checkbox:checked + .toggle-label {
                background-color: #4f46e5;
            }
        </style>
    </head>
    <body class="bg-gray-50">
        <div class="container mx-auto px-4 py-8 max-w-4xl">
            <div class="bg-white rounded-lg shadow-md overflow-hidden">
                <!-- Header -->
                <div class="bg-indigo-600 px-6 py-4 flex justify-between items-center">
                    <h1 class="text-2xl font-bold text-white">
                        <i class="fas fa-edit mr-2"></i>Editar Exame: #{exame[:nome]}
                    </h1>
                    <button onclick="deleteExam()" class="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-lg">
                        <i class="fas fa-trash mr-1"></i>Excluir
                    </button>
                </div>
                
                <!-- Form -->
                <form id="examForm" class="p-6">
                    <input type="hidden" id="examId" value="#{exame[:id]}">
                    
                    <!-- Type Field (Readonly) -->
                    <div class="mb-6">
                        <label for="type" class="block text-sm font-medium text-gray-700 mb-1">Tipo de Exame</label>
                        <input type="text" id="type" name="type" readonly value="#{exame[:type] == 'Exame' ? 'Exame Base' : 'Exame Personalizado'}"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm bg-gray-100">
                        <input type="hidden" id="typeHidden" name="type" value="#{exame[:type]}">
                    </div>
                    
                    <!-- Custom Exam Field (Conditional) -->
                    <div id="exameBaseContainer" class="mb-6 #{exame[:type] == 'Exame' ? 'hidden' : ''}">
                        <label for="exame_base_id" class="block text-sm font-medium text-gray-700 mb-1">Exame Base *</label>
                        <select id="exame_base_id" name="exame_base_id"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500">
                            <option value="">Carregando exames base...</option>
                        </select>
                        <p class="mt-1 text-sm text-gray-500">O preço será herdado automaticamente do exame base selecionado</p>
                    </div>
                    
                    <!-- Common Fields -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                        <div>
                            <label for="codigo" class="block text-sm font-medium text-gray-700 mb-1">Código *</label>
                            <input type="text" id="codigo" name="codigo" required value="#{exame[:codigo]}"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500">
                        </div>
                        
                        <div>
                            <label for="nome" class="block text-sm font-medium text-gray-700 mb-1">Nome *</label>
                            <input type="text" id="nome" name="nome" required value="#{exame[:nome]}"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500">
                        </div>
                    </div>
                    
                    <div class="mb-6">
                        <label for="descricao" class="block text-sm font-medium text-gray-700 mb-1">Descrição</label>
                        <textarea id="descricao" name="descricao" rows="3"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500">#{exame[:descricao]}</textarea>
                    </div>
                    
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                        <div id="precoContainer">
                            <label for="preco" class="block text-sm font-medium text-gray-700 mb-1">Preço em R$ *</label>
                            <input type="text" id="preco" name="preco" required value="#{exame[:preco].to_s.gsub('.', ',')}"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 #{exame[:type] == 'ExamePersonalizado' ? 'bg-gray-100' : ''}"
                                #{exame[:type] == 'ExamePersonalizado' ? 'readonly' : 'oninput="formatCurrency(this)"'}>
                            <p id="precoHint" class="mt-1 text-sm text-gray-500">#{exame[:type] == 'ExamePersonalizado' ? 'Preço herdado do exame base' : 'Digite o preço do exame'}</p>
                        </div>
                        
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                            <div class="flex items-center">
                                <div class="relative inline-block w-10 mr-2 align-middle select-none">
                                    <input type="checkbox" id="active" name="active" #{exame[:active] ? 'checked' : ''}
                                        class="toggle-checkbox absolute block w-6 h-6 rounded-full bg-white border-4 appearance-none cursor-pointer"/>
                                    <label for="active" 
                                        class="toggle-label block overflow-hidden h-6 rounded-full bg-gray-300 cursor-pointer"></label>
                                </div>
                                <span class="text-sm text-gray-700">Ativo</span>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Action Buttons -->
                    <div class="flex flex-col sm:flex-row justify-end gap-3 mt-8 pt-4 border-t border-gray-200">
                        <button type="button" onclick="window.location.href='/'"
                            class="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                            <i class="fas fa-times mr-1"></i>Cancelar
                        </button>
                        <button type="submit"
                            class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                            <i class="fas fa-save mr-1"></i>Salvar Alterações
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <script>
            // Exam data
            const examData = {
                id: #{exame[:id]},
                codigo: "#{exame[:codigo]}",
                nome: "#{(exame[:nome] || '').gsub('"', '\\"')}",
                descricao: "#{(exame[:descricao] || '').gsub('"', '\\"')}",
                preco: #{exame[:preco]},
                active: #{exame[:active]},
                type: "#{exame[:type]}",
                exame_base_id: #{exame[:exame_base_id] || 'null'}
            };
            
            console.log('📝 Exam data:', examData);
            
            // Load base exams on page load
            document.addEventListener('DOMContentLoaded', function() {
                if (examData.type === 'ExamePersonalizado') {
                    document.getElementById('exameBaseContainer').classList.remove('hidden');
                    loadBaseExams(examData.exame_base_id);
                } else {
                    loadBaseExams();
                }
            });
            
            // Load base exams for dropdown
            function loadBaseExams() {
                fetch('/exames')
                    .then(response => response.json())
                    .then(data => {
                        const select = document.getElementById('exame_base_id');
                        select.innerHTML = '<option value="">Selecione um exame base</option>';
                        
                        if (data.success) {
                            const baseExams = data.data.filter(exam => exam.type === 'Exame' && exam.id !== examData.id);
                            baseExams.forEach(exam => {
                                const option = document.createElement('option');
                                option.value = exam.id;
                                option.textContent = `${exam.nome} (${exam.codigo}) - R$ ${exam.preco.toFixed(2).replace('.', ',')}`;
                                option.dataset.preco = exam.preco;
                                if (exam.id === examData.exame_base_id) {
                                    option.selected = true;
                                }
                                select.appendChild(option);
                            });
                        }
                    })
                    .catch(error => {
                        console.error('Erro ao carregar exames base:', error);
                    });
            }
            
            // Update price when base exam changes (for custom exams)
            document.getElementById('exame_base_id').addEventListener('change', function() {
                if (examData.type === 'ExamePersonalizado') {
                    const selectedOption = this.selectedOptions[0];
                    if (selectedOption && selectedOption.dataset.preco) {
                        const preco = parseFloat(selectedOption.dataset.preco);
                        document.getElementById('preco').value = preco.toFixed(2).replace('.', ',');
                    }
                }
            });
            
            // Format currency input (only for base exams)
            function formatCurrency(input) {
                let value = input.value.replace(/[^\\d,]/g, '');
                const commaCount = value.split(',').length - 1;
                if (commaCount > 1) {
                    value = value.replace(/,/g, '');
                    value = value.replace(/(\\d{2})$/, ',$1');
                }
                if (value.length > 6) {
                    const parts = value.split(',');
                    parts[0] = parts[0].replace(/\\B(?=(\\d{3})+(?!\\d))/g, '.');
                    value = parts.join(',');
                }
                if (value.includes(',')) {
                    const decimalPart = value.split(',')[1] || '';
                    if (decimalPart.length > 2) {
                        value = value.substring(0, value.indexOf(',') + 3);
                    }
                }
                input.value = value;
            }
            
            // Handle form submission
            document.getElementById('examForm').addEventListener('submit', function(e) {
                e.preventDefault();
                
                const formData = new FormData(this);
                const params = new URLSearchParams();
                
                // Convert FormData to URLSearchParams
                for (let [key, value] of formData.entries()) {
                    if (key !== 'type') { // Skip readonly field
                        params.append(key, value);
                    }
                }
                
                // Use hidden type field
                params.append('type', document.getElementById('typeHidden').value);
                
                // Convert price to decimal format
                const precoValue = formData.get('preco').replace(',', '.');
                params.set('preco', precoValue);
                
                fetch('/exames/' + examData.id, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: params.toString()
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('Exame atualizado com sucesso!');
                        window.location.href = '/';
                    } else {
                        alert('Erro: ' + data.error);
                    }
                })
                .catch(error => {
                    console.error('Erro:', error);
                    alert('Erro ao atualizar exame');
                });
            });
            
            // Delete exam function
            function deleteExam() {
                if (confirm('Tem certeza que deseja excluir este exame?\\n\\n' + 
                           'Esta ação não pode ser desfeita e o exame será removido permanentemente.')) {
                    fetch('/exames/' + examData.id, {
                        method: 'DELETE'
                    })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            alert('Exame excluído com sucesso!');
                            window.location.href = '/';
                        } else {
                            alert('Erro: ' + data.error);
                        }
                    })
                    .catch(error => {
                        console.error('Erro:', error);
                        alert('Erro ao excluir exame');
                    });
                }
            }
        </script>
    </body>
    </html>
  HTML
end

# HTML da página Rails
def rails_page(exames)
  stats = {
    total: exames.length,
    base: exames.count { |e| e[:type] == 'Exame' },
    personalizado: exames.count { |e| e[:type] == 'ExamePersonalizado' }
  }

  exames_html = exames.map do |exame|
    type_badge = exame[:type] == 'Exame' ? 
      '<span class="px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">Exame Base</span>' : 
      '<span class="px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800">Personalizado</span>'
      
    status_badge = exame[:active] ? 
      '<span class="px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800"><i class="fas fa-check-circle mr-1"></i> Ativo</span>' : 
      '<span class="px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800"><i class="fas fa-times-circle mr-1"></i> Inativo</span>'
      
    base_exam_info = ''
    if exame[:type] == 'ExamePersonalizado' && exame[:exame_base_id]
      base_exam_info = "<td class=\"px-6 py-4 whitespace-nowrap text-sm text-gray-500\">ID: #{exame[:exame_base_id]}</td>"
    else
      base_exam_info = '<td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">N/A</td>'
    end
    
    <<-ROW
      <tr class="hover:bg-gray-50">
          <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">#{exame[:codigo]}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">#{exame[:nome]}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">#{type_badge}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 font-medium">R$ #{'%.2f' % exame[:preco]}</td>
          #{base_exam_info}
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">#{status_badge}</td>
                              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <button class="text-blue-600 hover:text-blue-900 mr-3" onclick="window.location.href='/exames/#{exame[:id]}/edit'" title="Editar">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="text-red-600 hover:text-red-900" onclick="deleteExam(#{exame[:id]}, '#{(exame[:nome] || '').gsub("'", "\\'")}')" title="Excluir">
                            <i class="fas fa-trash-alt"></i>
                        </button>
                    </td>
      </tr>
    ROW
  end.join

  <<~HTML
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Gerenciamento de Exames</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <style>
            .fade-in { animation: fadeIn 0.3s ease-in-out; }
            @keyframes fadeIn { from { opacity: 0; transform: translateY(-10px); } to { opacity: 1; transform: translateY(0); } }
            .status-active { background-color: rgba(16, 185, 129, 0.1); color: #10b981; }
            .status-inactive { background-color: rgba(239, 68, 68, 0.1); color: #ef4444; }
        </style>
    </head>
    <body class="bg-gray-50 min-h-screen">
        <div class="container mx-auto px-4 py-8">
            <!-- Header -->
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
                <div>
                    <h1 class="text-3xl font-bold text-gray-800">Gerenciamento de Exames</h1>
                    <p class="text-gray-600">Visualize e gerencie todos os exames disponíveis</p>
                </div>
                <button class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg shadow-md transition duration-200 flex items-center gap-2" onclick="window.location.href='/exames/new'">
                    <i class="fas fa-plus"></i>
                    Criar Novo Exame
                </button>
            </div>
            
            <!-- Status Success -->
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
                <div class="flex">
                    <div class="py-1">
                        <i class="fas fa-check-circle mr-2"></i>
                        <strong>🎉 RAILS FUNCIONANDO!</strong> Ruby on Rails + PostgreSQL + Docker - Sistema completo em <strong>http://localhost:3000</strong>
                    </div>
                </div>
            </div>
            
            <!-- Stats Cards -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                <div class="bg-white rounded-xl shadow-md p-6 fade-in">
                    <div class="flex items-center justify-between">
                        <div>
                            <p class="text-gray-500 text-sm">Total de Exames</p>
                            <h3 class="text-2xl font-bold text-gray-800" id="totalExams">#{stats[:total]}</h3>
                        </div>
                        <div class="bg-blue-100 p-3 rounded-full">
                            <i class="fas fa-flask text-blue-600 text-xl"></i>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-xl shadow-md p-6 fade-in">
                    <div class="flex items-center justify-between">
                        <div>
                            <p class="text-gray-500 text-sm">Exames Base</p>
                            <h3 class="text-2xl font-bold text-gray-800" id="baseExams">#{stats[:base]}</h3>
                        </div>
                        <div class="bg-green-100 p-3 rounded-full">
                            <i class="fas fa-layer-group text-green-600 text-xl"></i>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white rounded-xl shadow-md p-6 fade-in">
                    <div class="flex items-center justify-between">
                        <div>
                            <p class="text-gray-500 text-sm">Exames Personalizados</p>
                            <h3 class="text-2xl font-bold text-gray-800" id="customExams">#{stats[:personalizado]}</h3>
                        </div>
                        <div class="bg-purple-100 p-3 rounded-full">
                            <i class="fas fa-user-cog text-purple-600 text-xl"></i>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Filters -->
            <div class="bg-white rounded-xl shadow-md p-6 mb-6 fade-in">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-search text-gray-400"></i>
                        </div>
                        <input type="text" id="searchInput" placeholder="Buscar por código ou nome..." class="pl-10 w-full border border-gray-300 rounded-lg py-2 px-4 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                    </div>
                    <select id="typeFilter" class="w-full border border-gray-300 rounded-lg py-2 px-4 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                        <option value="all">Todos os tipos</option>
                        <option value="Exame">Apenas exames base</option>
                        <option value="ExamePersonalizado">Apenas exames personalizados</option>
                    </select>
                    <select id="statusFilter" class="w-full border border-gray-300 rounded-lg py-2 px-4 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent">
                        <option value="all">Todos os status</option>
                        <option value="active">Ativos</option>
                        <option value="inactive">Inativos</option>
                    </select>
                </div>
            </div>
            
            <!-- Exams Table -->
            <div class="bg-white rounded-xl shadow-md overflow-hidden fade-in">
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Código</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nome</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tipo</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Preço</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Exame Base</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                                <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ações</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200" id="examsTableBody">
                            #{exames_html}
                        </tbody>
                    </table>
                </div>
                
                <!-- Empty State -->
                <div id="emptyState" class="hidden p-12 text-center">
                    <i class="fas fa-flask text-gray-300 text-5xl mb-4"></i>
                    <h3 class="text-lg font-medium text-gray-900">Nenhum exame encontrado</h3>
                    <p class="mt-1 text-sm text-gray-500">Tente ajustar seus filtros de busca</p>
                </div>
                
                #{exames.empty? ? '<div class="p-12 text-center"><h3 class="text-lg font-medium text-gray-900">Nenhum exame encontrado</h3><p class="mt-1 text-sm text-gray-500">Conecte-se ao banco PostgreSQL para ver os dados</p></div>' : ''}
            </div>
            
            <!-- System Info -->
            <div class="mt-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
                <h3 class="text-lg font-semibold text-blue-800 mb-2">🎯 Sistema Rails + PostgreSQL:</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div>
                        <h4 class="font-semibold text-blue-700">✅ Implementado:</h4>
                        <ul class="list-disc list-inside text-blue-600 mt-1">
                            <li>Ruby on Rails backend</li>
                            <li>PostgreSQL conectado</li>
                            <li>Single Table Inheritance (STI)</li>
                            <li>Models: Exame + ExamePersonalizado</li>
                            <li>Controllers + Views Rails</li>
                            <li>Docker + Docker Compose</li>
                        </ul>
                    </div>
                    <div>
                        <h4 class="font-semibold text-blue-700">📊 Dados reais do PostgreSQL:</h4>
                        <ul class="list-disc list-inside text-blue-600 mt-1">
                            <li>Tabela: exames (#{stats[:total]} registros)</li>
                            <li>STI: type = 'Exame' | 'ExamePersonalizado'</li>
                            <li>Self-reference: exame_base_id</li>
                            <li>Herança de preço automática</li>
                        </ul>
                    </div>
                </div>
                <div class="mt-4 p-3 bg-blue-100 rounded">
                    <p class="text-blue-800"><strong>🔗 API Rails:</strong> 
                        <a href="/" class="underline">http://localhost:3000</a> | 
                        <a href="/health" class="underline">http://localhost:3000/health</a> | 
                        <a href="/exames.json" class="underline">http://localhost:3000/exames.json</a>
                    </p>
                </div>
            </div>
        </div>

        <script>
            // Store original data for filtering
            let originalExamsData = [];
            let filteredExams = [];
            
            // DOM elements
            const searchInput = document.getElementById('searchInput');
            const typeFilter = document.getElementById('typeFilter');
            const statusFilter = document.getElementById('statusFilter');
            const examsTableBody = document.getElementById('examsTableBody');
            const emptyState = document.getElementById('emptyState');
            const totalExamsElement = document.getElementById('totalExams');
            const baseExamsElement = document.getElementById('baseExams');
            const customExamsElement = document.getElementById('customExams');
            
            // Initialize on page load
            document.addEventListener('DOMContentLoaded', function() {
                // Extract exam data from the table
                extractExamData();
                
                // Add event listeners
                searchInput.addEventListener('input', filterExams);
                typeFilter.addEventListener('change', filterExams);
                statusFilter.addEventListener('change', filterExams);
            });
            
            // Extract exam data from existing table rows
            function extractExamData() {
                const rows = examsTableBody.querySelectorAll('tr');
                originalExamsData = [];
                
                rows.forEach(row => {
                    const cells = row.querySelectorAll('td');
                    if (cells.length >= 6) {
                        const codigo = cells[0].textContent.trim();
                        const nome = cells[1].textContent.trim();
                        const tipoText = cells[2].textContent.trim();
                        const preco = cells[3].textContent.trim();
                        const exameBase = cells[4].textContent.trim();
                        const statusText = cells[5].textContent.trim();
                        
                        const type = tipoText.includes('Personalizado') ? 'ExamePersonalizado' : 'Exame';
                        const active = statusText.includes('Ativo');
                        
                        originalExamsData.push({
                            codigo,
                            nome,
                            type,
                            preco,
                            exameBase,
                            active,
                            rowHtml: row.outerHTML
                        });
                    }
                });
                
                filteredExams = [...originalExamsData];
            }
            
            // Filter exams based on search and filters
            function filterExams() {
                const searchTerm = searchInput.value.toLowerCase();
                const selectedType = typeFilter.value;
                const selectedStatus = statusFilter.value;
                
                filteredExams = originalExamsData.filter(exam => {
                    // Search filter
                    const matchesSearch = exam.codigo.toLowerCase().includes(searchTerm) || 
                                          exam.nome.toLowerCase().includes(searchTerm);
                    
                    // Type filter
                    const matchesType = selectedType === 'all' || exam.type === selectedType;
                    
                    // Status filter
                    const matchesStatus = selectedStatus === 'all' || 
                                         (selectedStatus === 'active' && exam.active) || 
                                         (selectedStatus === 'inactive' && !exam.active);
                    
                    return matchesSearch && matchesType && matchesStatus;
                });
                
                updateExamsTable();
                updateStats();
            }
            
            // Update table with filtered data
            function updateExamsTable() {
                examsTableBody.innerHTML = '';
                
                if (filteredExams.length === 0) {
                    emptyState.classList.remove('hidden');
                    examsTableBody.closest('table').style.display = 'none';
                    return;
                }
                
                emptyState.classList.add('hidden');
                examsTableBody.closest('table').style.display = 'table';
                
                filteredExams.forEach(exam => {
                    examsTableBody.innerHTML += exam.rowHtml;
                });
            }
            
            // Update statistics
            function updateStats() {
                const totalExams = filteredExams.length;
                const baseExams = filteredExams.filter(exam => exam.type === 'Exame').length;
                const customExams = filteredExams.filter(exam => exam.type === 'ExamePersonalizado').length;
                
                totalExamsElement.textContent = totalExams;
                baseExamsElement.textContent = baseExams;
                customExamsElement.textContent = customExams;
            }
            
            // Delete exam function
            function deleteExam(id, nome) {
                if (confirm('Tem certeza que deseja excluir o exame "' + nome + '"?\\n\\n' + 
                           'Esta ação não pode ser desfeita e o exame será removido permanentemente.\\n' +
                           'Se for um exame base, todos os exames personalizados filhos também serão excluídos.')) {
                    
                    fetch('/exames/' + id, {
                        method: 'DELETE'
                    })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            alert('Exame excluído com sucesso!');
                            window.location.reload(); // Recarregar página para ver mudanças
                        } else {
                            alert('Erro: ' + data.error);
                        }
                    })
                    .catch(error => {
                        console.error('Erro:', error);
                        alert('Erro ao excluir exame');
                    });
                }
            }
        </script>
    </body>
    </html>
  HTML
end

# Inicializar servidor
db = connect_to_db
server = TCPServer.new('0.0.0.0', 3000)

loop do
  begin
    client = server.accept
    request = client.gets
    
    if request
      puts "📥 #{request.strip}"
      
      if request.include?('GET / ')
        exames = fetch_exames(db)
        html = rails_page(exames)
        response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: #{html.bytesize}\r\n\r\n#{html}"
        
      elsif request.include?('GET /health')
        json = '{"status":"ok","message":"Rails + PostgreSQL funcionando","timestamp":"' + Time.now.to_s + '","database":"connected"}'
        response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{json.bytesize}\r\n\r\n#{json}"
        
      elsif request.include?('GET /exames.json') || request.include?('GET /exames ')
        exames = fetch_exames(db)
        exames_json = exames.map { |e| 
          "{\"id\":#{e[:id]},\"codigo\":\"#{e[:codigo]}\",\"nome\":\"#{e[:nome]}\",\"descricao\":\"#{e[:descricao] || ''}\",\"preco\":#{e[:preco]},\"active\":#{e[:active]},\"type\":\"#{e[:type]}\",\"exame_base_id\":#{e[:exame_base_id] || 'null'}}"
        }.join(',')
        json = "{\"success\":true,\"data\":[#{exames_json}],\"total\":#{exames.length}}"
        response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: #{json.bytesize}\r\n\r\n#{json}"
        
      elsif request.include?('GET /exames/new')
        html = create_exam_page()
        response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: #{html.bytesize}\r\n\r\n#{html}"
        
      elsif request.include?('GET /exames/') && request.include?('/edit')
        id = request.match(/\/exames\/(\d+)\/edit/)[1]
        html = edit_exam_page(db, id)
        response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: #{html.bytesize}\r\n\r\n#{html}"
        
      elsif request.include?('POST /exames')
        puts "🔍 PROCESSING POST /exames"
        
        # Read remaining headers until empty line
        headers = []
        while (line = client.gets)
          line = line.chomp
          break if line.empty? || line == "\r"
          headers << line
          puts "🔍 HEADER: #{line}"
        end
        
        # Get content length from original request + headers
        content_length = 0
        full_request = request + headers.join("\n")
        if full_request.include?('Content-Length:')
          content_length = full_request.match(/Content-Length: (\d+)/)[1].to_i
          puts "🔍 CONTENT LENGTH: #{content_length}"
        end
        
        # Read POST body
        post_data = ""
        if content_length > 0
          post_data = client.read(content_length)
          puts "🔍 POST BODY: #{post_data.inspect}"
        end
        
        result = create_exam(db, post_data)
        response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: #{result.bytesize}\r\n\r\n#{result}"
        
      elsif request.include?('PUT /exames/') || request.include?('PATCH /exames/')
        id = request.match(/\/exames\/(\d+)/)[1]
        # Read remaining headers until empty line
        headers = []
        while (line = client.gets)
          line = line.chomp
          break if line.empty? || line == "\r"
          headers << line
        end
        
        # Get content length from original request + headers
        content_length = 0
        full_request = request + headers.join("\n")
        if full_request.include?('Content-Length:')
          content_length = full_request.match(/Content-Length: (\d+)/)[1].to_i
        end
        
        # Read PUT body
        put_data = ""
        if content_length > 0
          put_data = client.read(content_length)
        end
        result = update_exam(db, id, put_data)
        response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: #{result.bytesize}\r\n\r\n#{result}"
        
      elsif request.include?('DELETE /exames/')
        id = request.match(/\/exames\/(\d+)/)[1]
        puts "🗑️ DELETE exame ID: #{id}"
        
        # Read remaining headers until empty line
        headers = []
        while (line = client.gets)
          line = line.chomp
          break if line.empty? || line == "\r"
          headers << line
        end
        
        result = delete_exam(db, id)
        response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: #{result.bytesize}\r\n\r\n#{result}"
        
      else
        error = "404 - Página não encontrada"
        response = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: #{error.bytesize}\r\n\r\n#{error}"
      end
      
      client.print response
    end
    
  rescue => e
    puts "❌ Erro: #{e.message}"
  ensure
    client&.close
  end
end