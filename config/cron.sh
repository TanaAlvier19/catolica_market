#!/bin/bash
arquivo="manutencao.sh"
#Função que programa a execução automática de um script
confCron()
{
    cronConf="0 18 * * * $(pwd)/$1"
    echo "adicionando: $cronConf "
    (crontab -l 2>/dev/null | grep -Fv "$cronConf"; echo "$cronConf") | crontab -
    echo "Código de retorno: $?"
}

# definir execução automática para o manutencao
confCron "$arquivo"

exit 1
