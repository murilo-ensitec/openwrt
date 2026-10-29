# Como utilizar o firmware

## TODO

Basicamente ensinar como o binario é instalado, uboot, tftp, sysupgrade, luci, etc.

Quando compilado uma nova versão, no caso deste projeto teremos um arquivo binário em `bin/targets/ramips/mt76x8/`, porque o nossos módulo possui um micro processador mt7628an cuja arquitetura é ramips.
Esse binario pode ser enviado ao modem por *scp*, *ftp*, *tftp* ou qualquer outro protocolo/aplicação que desejar e utilizar o sysupgrade para atualizar/trocar o firmware do modem.
```bash
# dado um arquivo .bin que foi enviado para o modem podemos usar o comando sysupgrade para trocar o fimrware, TODO colocar um exemplo aqui
```
Ainda, é possível utilizar o bootloader do modulo hlk-7628an. Por padrão, alguns lotes vem com uma versão do uboot da ralink. Hoje em dia o das uboot é o bootloader mais comum, porém o que vem nos módulos é esta versão mais limitada e antiga. Foi gasto uma quantidade significativa de esforços e foram brickados 2 módulos e um foi queimado no processo de tentar trocar o uboot da placa. Para facilitar os próximos esforços a mais atual revisão do MODEM-VPN (no momento em que escrevo este documento é a rev1.1) possui os pinos JTAG e os pinos necessários para fazer o bootstrap da placa em modo debug expostos. Dessa forma será mais facil recuperar o módulo caso seja brickado e mais fácil fazer o backup do binário do uboot utilizado no modulo.
Para gravar o firmware pelo bootloader é necessário acessar a placa por serial usando os pinos UART expostos. Para entrar no uboot basta reiniciar a placa (pode ser soft or hard reset) e interagir com o menu que será printado na tela. Em alguns lotes do módulo o bootloader exibe a opção `2: Load system code then write to Flash via TFTP.` e a utilização é intuitiva. Caso não exista essa opção é necessário interagir com o CLI do bootloader, fazer o download manualmente do firmware para RAM e então escrever na flash.
```
TODO descrever o processo de como utilizar o CLI do bootloader para fazer o download e escrever na flash
```

TODO Obviamente será necessário explicar o servidor TFTP...
