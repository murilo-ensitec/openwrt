# Como Utilizar e Atualizar o Firmware

Quando uma nova versão é compilada, o binário fica localizado em `bin/targets/ramips/mt76x8/`. Isso ocorre porque o nosso módulo utiliza o microprocessador MT7628AN, cuja arquitetura no OpenWrt é a `ramips`.

Para atualizar ou trocar o firmware, você pode enviar esse binário ao modem via `scp`, `ftp`, `tftp` ou qualquer outro protocolo de transferência que preferir, e em seguida executar o utilitário `sysupgrade`.

Também é possível gravar o firmware diretamente pelo bootloader do módulo HLK-7628AN. Por padrão, alguns lotes chegam com uma versão do U-Boot da Ralink. Hoje em dia o DAS U-Boot (U-Boot moderno) é o bootloader mais comum no mercado, porém o que vem gravado nesses módulos é uma versão bem mais limitada e antiga. Vale registrar: foi gasta uma quantidade significativa de esforço, 2 módulos foram brickados e 1 acabou queimado na tentativa de trocar o U-Boot da placa. 

Para facilitar os próximos trabalhos, a revisão mais recente do MODEM-VPN (atualmente a REV 1.2) traz expostos os pinos de JTAG e os pinos necessários para realizar o bootstrap em modo debug. Dessa forma, fica bem mais simples recuperar o módulo caso ocorra um brick, além de facilitar o backup do binário do U-Boot original.

Para gravar o firmware via bootloader, é preciso acessar a placa via conexão serial utilizando os pinos UART expostos (nos módulos utilizados até agora, a taxa padrão é **57600 bps - 8N1**). Basta reiniciar a placa (via soft ou hard reset) e interagir com o menu exibido no terminal. Em alguns lotes, o bootloader apresenta a opção `2: Load system code then write to Flash via TFTP.`, que tem uso bastante intuitivo. Caso essa opção não apareça, é necessário acessar o CLI do bootloader, baixar a imagem manualmente para a memória RAM e gravá-la na flash.

---

## Observação Sobre os Endereços IP

Os endereços IP citados nos exemplos a seguir (`192.168.1.1`) servem apenas como referência para o ambiente de desenvolvimento e procedimentos via bootloader. Nos binários oficiais de debug e produção, o IP padrão do modem é **`192.168.5.1`**.

---

## Localização do Binário

Após a conclusão do build (`make`), a imagem do firmware estará disponível em:

```path
bin/targets/ramips/mt76x8/

```

O arquivo gerado para atualização no sistema costuma seguir a nomenclatura `openwrt-ramips-mt76x8-...-sysupgrade.bin`.

---

## Atualização via Sistema Operacional (`sysupgrade`)

Pode utilizar-se deste método se o modem já estiver rodando uma versão funcional do OpenWrt.

### 1. Enviar o arquivo para o modem

No seu computador de desenvolvimento, envie a imagem compilada para a pasta `/tmp` do modem via SCP (substitua o IP pelo IP do modem):

```bash
scp bin/targets/ramips/mt76x8/firmware.bin root@192.168.1.1:/tmp/

```

### 2. Executar o upgrade no modem

Acesse o modem via SSH e inicie a gravação:

```bash
ssh root@192.168.1.1

# Atualizar mantendo as configurações atuais:
sysupgrade -v /tmp/firmware.bin

# (Opcional) Atualizar resetando para os padrões de fábrica:
# sysupgrade -n -v /tmp/firmware.bin

```

---

## Configuração do Servidor TFTP no Host (Debian Based Linux Distros)

Para gravar via bootloader, é necessário subir um servidor TFTP na sua máquina de desenvolvimento apontando para a pasta onde está a imagem do firmware.

1. Instale o pacote `tftpd-hpa`:
```bash
sudo apt install tftpd-hpa

```

2. Configure o servidor `/etc/default/tftpd-hpa`:
```bash
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
```


3. Copie o arquivo compilado para o diretório raiz do TFTP:
```bash
sudo cp bin/targets/ramips/mt76x8/firmware.bin /srv/tftp/

```


4. Reinicie o serviço:
```bash
sudo systemctl restart tftpd-hpa

```



---

## Gravação via U-Boot (Menu Interativo)

1. Conecte a interface Serial aos pinos UART da placa (57600 8N1).
2. Ligue ou reinicie a placa e observe o terminal.
3. Quando o menu do U-Boot for exibido, selecione a opção `2`:

```text
Please choose the operation:
   1: Load system code to SDRAM via TFTP.
   2: Load system code then write to Flash via TFTP.
   3: Boot system code via Flash (default).
   4: Enter boot command line interface.
   ...

```

4. Preencha as informações de IP e nome de arquivo solicitadas pelo prompt:

```text
You chose 2

2: System Load Linux Kernel then write to Flash via TFTP.
 Warning!! Erase Linux in Flash then burn new one. Are you sure?(Y/N) Y
 Input device IP (192.168.50.200) ==: 192.168.1.1
 Input server IP (192.168.50.146) ==: 192.168.1.100
 Input Linux Kernel filename ==: firmware.bin

```

---

## Gravação via U-Boot (CLI Manual)

Caso o U-Boot do módulo não possua a opção de menu, pressione qualquer tecla durante o boot inicial para interromper o processo e entrar no prompt (`=>` ou `MT7628 #`).

### 1. Configurar variáveis de rede no U-Boot

Defina os IPs para a comunicação temporária via bootloader:

```stage
setenv ipaddr 192.168.1.1
setenv serverip 192.168.1.100

```

*(Nota: Configure a interface de rede do seu PC de forma estática no IP `192.168.1.100`)*.

### 2. Baixar a imagem para a RAM

```stage
tftpboot 0x82000000 firmware.bin

```

Guarde o valor do tamanho do arquivo (em bytes/hexadecimal) que o comando informará na tela. Esse valor será usado no campo `<tamanho_bytes>`.

### 3. Identificar a memória Flash

```stage
sf probe

```

### 4. Gravar o firmware na Flash

```stage
sf update 0x82000000 0x50000 <tamanho_bytes>

```

### 5. Definir o comando de boot padrão e salvar

```stage
setenv bootcmd 'sf probe; sf read 0x82000000 0x50000 0x1fb0000; bootm 0x82000000'
saveenv

```

### 6. Inicializar o sistema

```stage
boot

```
