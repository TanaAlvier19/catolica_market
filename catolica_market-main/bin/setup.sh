#!/bin/bash
PROJECTO=$(pwd)
# OBJECTIVO=CRIAÇÃO DE GRUPOS, UTILIZADORES E PERMISSSÕES 

# Criando grupos 
sudo groupadd -f admin
sudo groupadd -f gerente
sudo groupadd -f atendentes
sudo groupadd -f logistica

# Criando utilizadores e colocandos nos seus respectivos grupos
sudo useradd -m -s /bin/bash albert 
sudo usermod -aG admin albert

sudo useradd -m -s /bin/bash benedito 
sudo usermod -aG gerente benedito 

sudo useradd -m -s /bin/bash joelCosta 
sudo usermod -aG atendente joelCosta

sudo useradd -m -s /bin/bash antonia 
sudo usermod -aG atendente antonia

sudo useradd -m -s /bin/bash heloisa 
sudo usermod -aG logistica heloisa

# Atribuir permissões de acesso totatl admin
sudo chown -R root: admin $PROJECTO
sudo chmor -R 770 $PROJECTO

# atribuir permissões ao gerente
# primeiro permissão de leitur total   
sudo chgrp -R gerente $PROJECTO
sudo chmod -R 750 $PROJECTO

#permissão de escrita em pastas especificas 
sudo chmod -R 770 $PROJECTO/bin/vendas.sh 
sudo chmod -R 770 $PROJECTO/bin/gestao_funcionarios.sh 
sudo chmod -R 770 $PROJECTO/bin/relatorios.sh

# atribuir permissões a outros processos  
sudo chmod -R 770 $PROJECTO/bin/vendas.sh
sudo chmod -R 750 $PROJECTO/bin/gestao_produtos.sh
sudo chmod -R 750 $PROJECTO/bin/gestao_clientes.sh
sudo chmod -R 750 $PROJECTO/bin/sincronizar_clientes.sh
sudo chmod -R 750 $PROJECTO/bin/catolica_market.csv

sudo chgrp -R logistica $PROJECTO/data
sudo chmod -R 770 $PROJECTO/data

# criando password 
echo "albert: SO1" | sudo chpassword
echo "benedito: SO12" | sudo chpassword
echo "joelCosta: SO123" | sudo chpassword
echo "antonia: SO1234" | sudo chpassword
echo "heloisa: SO12345" | sudo chpassword

#executar o programa
sudo chmod +x $PROJECTO/bin/*.sh
# BY JD 