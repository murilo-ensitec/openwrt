# Firmware Modem Ensitec Mx

Firmware personalizado para as placas MODEM-VPN (também conhecidas como Modem Industrial ou Mx, onde `x` indica a quantidade de entradas). 

O projeto roda sobre o módulo [HLK-7628AN](docs/datasheets/hlk-7628n.pdf) e utiliza o OpenWrt como base. O objetivo primário é substituir os modems RUT200 nos pontos VPN da infraestrutura e, posteriormente, substituir a placa V8+ nesses mesmos pontos.

Para mais detalhes sobre a arquitetura do código e suas funcionalidades, consulte a [documentação interna](docs/README.md).

---

## Requisitos

O desenvolvimento é focado no **Debian** (ou distribuições derivadas), pois ele fornece grande parte dos utilitários e binários pré-compilados necessários para o ambiente de build.

* **SO recomendado:** Debian Linux / derivados.
* **Windows:** Não suportado.
* **Dependências:** A lista completa de pacotes necessários para o ambiente de compilação está disponível no guia de [Build System Setup do OpenWrt](https://openwrt.org/docs/guide-developer/build-system/install-buildsystem).

---

## Quickstart

Este repositório é um fork do OpenWrt adaptado para o hardware da Ensitec. A branch principal (`master`) é feita em cima da branch **`openwrt-25.12`** do repositório original do OpenWrt.

### Gestão de Configurações (`diffconfig`)
* **Configuração mínima:** Mantida no arquivo `diffconfig`. Qualquer novo pacote essencial ao funcionamento base do firmware deve ser adicionado gerando uma nova versão desse arquivo (conforme as instruções do OpenWrt).
* **Pacotes opcionais:** Pacotes não essenciais ou voltados para uso futuro devem ser adicionados ao arquivo `optional_packages.config`, utilizado na pipeline de CI/CD para gerar as imagens finais de release.

### Passo a Passo de Build

1. Atualize as definições de pacotes listadas no `feeds.conf`:
```bash
./scripts/feeds update -a

```

2. Crie os links simbólicos dos pacotes para o diretório `package/feeds/`:
```bash
./scripts/feeds install -a

```


3. Configure a toolchain, target system e pacotes do firmware:
```bash
# Caso queira configurar manualmente
make menuconfig

# Caso queira utilizar as configurações prontas
cp diffconfig .config
# Caso queira utilizar as configurações opcionais
cat optional_packages.config >> .config


make defconfig
```

4. Inicie o processo de compilação (fará o download dos fontes, criará a toolchain e compilará a imagem final):
```bash
make download
make -j$(($(nproc)+1)) V=s
```

### Instalação

Para saber como gravar e instalar o firmware no equipamento, consulte o guia de instalação em [docs/using.md](docs/using.md).

---

## Links e Documentação OpenWrt

Documentação de apoio sobre a estrutura e desenvolvimento no ecossistema OpenWrt:

* [Quick Start Guide](https://openwrt.org/docs/guide-quick-start/start)
* [User Guide](https://openwrt.org/docs/guide-user/start)
* [Developer Documentation](https://openwrt.org/docs/guide-developer/start)
* [Technical Reference](https://openwrt.org/docs/techref/start)

### Repositórios Oficiais

* [LuCI Web Interface](https://github.com/openwrt/luci): Interface web do sistema.
* [OpenWrt Packages](https://github.com/openwrt/packages): Repositório comunitário de pacotes gerais.
* [OpenWrt Routing](https://github.com/openwrt/routing): Pacotes voltados para roteamento e mesh.

---

## Licença

Este projeto é baseado no OpenWrt e está licenciado sob a [GPL-2.0](https://www.google.com/search?q=LICENSE).
