# Quick Start

---

## Features Implementadas

### NAND

* A NAND é montada utilizando o **UBIFS** (*Unsorted Block Images File System*) automaticamente pelo serviço `/etc/init.d/mount_nand`.
* O serviço também é responsável por desmontar a partição de forma limpa antes do desligamento do sistema (desligamento via software; *hard-resets* por queda de energia ou botão de reset impedem o encerramento correto dos serviços Linux).

### MWAN3

* O Multi-WAN é gerenciado via `mwan3` e está configurado para priorizar a conexão Ethernet (`eth0.2`).
* Caso a conexão Ethernet falhe, o gerenciador executa automaticamente um *flush* do *conntrack* e comuta a conexão para a interface celular SimCom (`cwan`) até que a Ethernet reestabeleça a operação.
* As configurações estão localizadas no arquivo `/etc/config/mwan3`.

### SNMP

* O SNMP (*Simple Network Management Protocol*) é implementado utilizando o daemon `snmpd`.
* As configurações estão localizadas no arquivo `/etc/config/snmpd`.

#### Arquitetura de Funcionamento

1. **Produtores de Dados:**
* Scripts/programas localizados em `/usr/bin/` geram os dados e os persistem em `/tmp/`.
* São inicializados por scripts de serviço em `/etc/init.d/`.


2. **Handlers de Requisições:**
* Ao receber uma requisição SNMP, a execução é delegada a um script/programa registrado nas configurações do `snmpd` sob um prefixo OID (*Object Identifier*), conforme o exemplo abaixo. Os handlers são localizados em `/usr/libexec/snmp/`



```sh
config pass
    option name 'simcom_info'
    option miboid '.1.3.6.1.4.1.48690.3'
    option prog '/usr/libexec/snmp/simcom_info.sh'
    option persist '0'

```

> **Nota:** Existe também a opção `config exec`, atualmente não utilizada.

Dada uma requisição para o OID especificado, o script registrado (ex.: `simcom_info.sh`) é executado. O programa não precisa ser necessariamente um *shell script*; qualquer linguagem executável pode ser utilizada.

#### Argumentos de Execução (`argv`)

Ao ser executado pelo daemon, o script deve tratar dois argumentos passados via `argv`:

* **GET (`-g`):** Retorna apenas o objeto requisitado.
* **GET-NEXT (`-c`):** Retorna o próximo objeto na árvore.

#### Hierarquia de OIDs

```text
Hierarquia Global
.1 (iso)
 └── .3 (org)
     └── .6 (dod - US Dept of Defense)
          └── .1 (internet)
               ├── .2 (mgmt) --------> Standard MIBs (Network interfaces, CPU, RAM)
               └── .4 (private) -----> Custom Vendor MIBs (Teltonika, Cisco, Ensitec)

```

#### MIB e Enterprise Numbers

* Para a organização dos dados, foi criado um documento MIB (*Management Information Base*) baseado na estrutura da Teltonika, definindo quais endereços contêm cada informação.
* Em ambiente de desenvolvimento, está sendo utilizado o PEN (*Private Enterprise Number*) da Teltonika (`48690`), com migração futura planejada para o PEN da Ensitec (`67316`).
