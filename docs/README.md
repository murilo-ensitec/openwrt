# Quick Start

---

## Embedded Linux

O projeto é construído em cima do OpenWrt que, por sua vez, deriva do Buildroot. Se você, assim como nós no início deste projeto, não entende muito sobre Linux embarcado, recomendamos a playlist de [Introdução a Linux Embarcado da DigiKey](https://www.youtube.com/playlist?list=PLEBQazB0HUyTpoJoZecRK6PpDG31Y7RPB). Ela não é um tutorial passo a passo do nosso projeto, mas serve para dar uma contextualização geral do potencial do Linux embarcado e de como as coisas funcionam por baixo dos panos.

Também existem materiais excelentes sobre drivers Linux que podem ser úteis, principalmente se você precisar debugar algum driver (neste caso, lembre-se: o `printf`/`printk` é seu melhor amigo e foi fundamental no desenvolvimento deste firmware). Recomendamos o [Let's code a Linux Driver](https://www.youtube.com/playlist?list=PLCGpd0Do5-I3b5TtyqeF1UdyD4C-S-dMa) e o [Understanding the Structure of a Linux Kernel Device Driver](https://www.youtube.com/watch?v=XoYkHUnmpQo).

O ecossistema de Linux embarcado é enorme e é perfeitamente normal (e esperado) que seja intimidador. A ideia desta documentação é justamente te dar um norte para que você não precise bater cabeça que nem barata tonta como nós tivemos que fazer no começo.

Alguns módulos que você habilitar pelo `make menuconfig` do OpenWrt podem simplesmente não funcionar de primeira. Na maioria das vezes, isso acontece porque algum pré-requisito precisa ser ativado no `make kernel_menuconfig` e, quase sempre, isso **não estará documentado em lugar nenhum**. Outros módulos vão exigir que você altere o arquivo `Makefile` do *target* do projeto. Tudo isso você só vai descobrir testando, errando e tentando de novo.

Na implementação da memória NAND, por exemplo, tivemos que habilitar manualmente os recursos de NAND, UBI, UBIFS e SPI-NAND no `menuconfig` do kernel, além de adicionar a *feature* de NAND no `Makefile` do *target*. Só depois disso conseguimos começar a testar a nossa NAND externa — e mesmo assim não funcionou de início, pois o driver não tinha a descrição do chip da GigaDevice que estávamos usando. Resultado: tivemos que adicionar o suporte para o nosso modelo de NAND diretamente no código-fonte do driver.

Por fim: a partir do momento em que você entrou no repositório, você também é responsável por este código. Faça commits limpos, com mensagens descritivas e em volumes que um ser humano consiga revisar sem perder o fio da meada. Escreva o código e faça suas alterações como se o próximo desenvolvedor fosse um psicopata violento que sabe onde você mora.


## Device Tree

O Device Tree é uma estrutura de dados em árvore para descrição de hardware. A função dele é informar ao kernel quais dispositivos estão disponíveis quando eles não podem ser descobertos em tempo de execução (por exemplo: um mouse USB é descoberto dinamicamente pela interface USB, mas o próprio barramento USB não tem como ser descoberto sozinhos, o kernel precisa saber previamente que ele existe).

Não entrarei no mérito de ensinar a estrutura básica e a sintaxe do Device Tree aqui. Para quem quiser se aprofundar, seguem alguns links úteis: [Introdução a Device Tree da Bootlin](https://www.youtube.com/watch?v=Nz6aBffv-Ek) e a [Especificação do Device Tree](https://github.com/devicetree-org/devicetree-specification/releases).

O ponto fundamental para este projeto é que cada nó possui uma propriedade `compatible` que define a sua estrutura. O comportamento e os parâmetros dessa propriedade estão descritos na documentação do kernel em YAML se o driver foi documentado recentemente, ou em texto plano caso a documentação seja mais antiga ([Exemplo em YAML](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/devicetree/bindings/spi/spi-controller.yaml) e [Exemplo em texto](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/devicetree/bindings/mtd/atmel-nand.txt)).

O Device Tree utilizado na versão atual do nosso modem (Release 0.1.0, Modem Rev 1.2) é derivado do `mt7628an_hilink_hlk-7628n.dts`. 

Na revisão 1.1 da placa, a ideia inicial era expandir o armazenamento interno utilizando um cartão SD. No entanto, isso se mostrou inviável com o módulo HLK-7628: o controlador SPI do MT7628 (herdado do MT7621) possui um **bug de silício** que impede a comunicação *Full-Duplex* — requisito obrigatório do driver `mmc-spi` para ler cartões SD via SPI.

A única alternativa para usar o cartão SD seria fazer *bit-banging* do SPI via software (usando o driver SPI-GPIO). Mas isso exigiria habilitar a função na compilação do kernel e alterar o driver no Device Tree, gerando um *overhead* de CPU enorme e matando a performance de leitura/escrita do módulo. Por conta disso, na Rev 1.2 decidimos abandonar o cartão SD e migrar para uma memória NAND externa.


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
