#!/bin/bash
# setup.sh - Configuração inicial (executar como root)
# Define PROJECTO como o diretório actual

PROJECTO=$(pwd)

echo "=== Configuração do Católica Market em $PROJECTO ==="

# 1. Criar grupos
groupadd -f admin
groupadd -f gerente
groupadd -f atendentes
groupadd -f logistica

# 2. Criar utilizadores e associar aos grupos
useradd -m -s /bin/bash albert
usermod -aG admin albert

useradd -m -s /bin/bash benedito
usermod -aG gerente benedito

useradd -m -s /bin/bash joelCosta
usermod -aG atendentes joelCosta

useradd -m -s /bin/bash antonia
usermod -aG atendentes antonia

useradd -m -s /bin/bash heloisa
usermod -aG logistica heloisa

# 3. Criar estrutura de diretórios
mkdir -p $PROJECTO/{bin,data/{produtos,clientes,funcionarios,vendas,filiais},logs,backup,config,lib,tmp,relatorios}

# 4. Criar ficheiros CSV com cabeçalhos
echo "codigo|nome|categoria|preco|quantidade|estoque_minimo|data_cadastro" > $PROJECTO/data/produtos/produtos.csv
echo "numero_cartao|nome|nif|telefone|email|saldo|data_cadastro|filial_origem" > $PROJECTO/data/clientes/clientes.csv
echo "id|nome|cargo|grupo|utilizador_linux|filial|data_admissao|ativo" > $PROJECTO/data/funcionarios/funcionarios.csv
echo "id_venda|data|hora|id_funcionario|utilizador_linux|numero_caixa|numero_cartao|total_bruto|desconto|total_liquido" > $PROJECTO/data/vendas/vendas.csv
echo "id_venda|codigo_produto|nome_produto|quantidade|preco_unitario|subtotal" > $PROJECTO/data/vendas/itens_venda.csv
echo "id_filial|nome|cidade|ip_fixo|responsavel|telefone|ativo" > $PROJECTO/data/filiais/filiais.csv

# 5. Atribuir donos e permissões
chown -R root:admin $PROJECTO
chmod -R 750 $PROJECTO

# Grupos específicos para subdiretórios
chgrp -R logistica $PROJECTO/data/produtos
chmod 760 $PROJECTO/data/produtos

chgrp -R atendentes $PROJECTO/data/clientes
chmod 750 $PROJECTO/data/clientes

chgrp -R atendentes $PROJECTO/data/vendas
chmod 770 $PROJECTO/data/vendas

chgrp -R gerente $PROJECTO/data/funcionarios
chmod 750 $PROJECTO/data/funcionarios

chgrp -R gerente $PROJECTO/logs
chmod 750 $PROJECTO/logs

chmod 700 $PROJECTO/backup
chmod 770 $PROJECTO/tmp

# 6. Criar ficheiro de configuração com o caminho do projecto
echo "$PROJECTO" > $PROJECTO/config/project_path.conf
chmod 644 $PROJECTO/config/project_path.conf

# 7. Colocar os scripts em bin/ e definir permissões específicas
if [ -f "./vendas.sh" ]; then
    cp ./vendas.sh $PROJECTO/bin/
    chown root:atendentes $PROJECTO/bin/vendas.sh
    chmod 750 $PROJECTO/bin/vendas.sh
fi

if [ -f "./relatorios.sh" ]; then
    cp ./relatorios.sh $PROJECTO/bin/
    chown root:gerente $PROJECTO/bin/relatorios.sh
    chmod 750 $PROJECTO/bin/relatorios.sh
fi

if [ -f "./gestao_produtos.sh" ]; then
    cp ./gestao_produtos.sh $PROJECTO/bin/
    chown root:logistica $PROJECTO/bin/gestao_produtos.sh
    chmod 750 $PROJECTO/bin/gestao_produtos.sh
fi

if [ -f "./gestao_clientes.sh" ]; then
    cp ./gestao_clientes.sh $PROJECTO/bin/
    chown root:atendentes $PROJECTO/bin/gestao_clientes.sh
    chmod 750 $PROJECTO/bin/gestao_clientes.sh
fi

if [ -f "./gestao_funcionarios.sh" ]; then
    cp ./gestao_funcionarios.sh $PROJECTO/bin/
    chown root:gerente $PROJECTO/bin/gestao_funcionarios.sh
    chmod 750 $PROJECTO/bin/gestao_funcionarios.sh
fi

if [ -f "./backup.sh" ]; then
    cp ./backup.sh $PROJECTO/bin/
    chown root:admin $PROJECTO/bin/backup.sh
    chmod 700 $PROJECTO/bin/backup.sh
fi

if [ -f "./sincronizar_clientes.sh" ]; then
    cp ./sincronizar_clientes.sh $PROJECTO/bin/
    chown root:admin $PROJECTO/bin/sincronizar_clientes.sh
    chmod 750 $PROJECTO/bin/sincronizar_clientes.sh
fi

if [ -f "./manutencao.sh" ]; then
    cp ./manutencao.sh $PROJECTO/bin/
    chown root:admin $PROJECTO/bin/manutencao.sh
    chmod 700 $PROJECTO/bin/manutencao.sh
fi

if [ -f "./auditoria.sh" ]; then
    cp ./auditoria.sh $PROJECTO/bin/
    chown root:gerente $PROJECTO/bin/auditoria.sh
    chmod 750 $PROJECTO/bin/auditoria.sh
fi

# 8. Definir passwords
echo "albert:SO1" | chpasswd
echo "benedito:SO12" | chpasswd
echo "joelCosta:SO123" | chpasswd
echo "antonia:SO1234" | chpasswd
echo "heloisa:SO12345" | chpasswd

# BY JD 
