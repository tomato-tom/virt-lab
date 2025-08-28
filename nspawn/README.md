# コンテナのスクリプト

## 機能

### コンテナ
- base rootfs作成
- コンテナ作成・実行・停止・削除
- コンテナのリスト・情報
- 複数のコンテナを組み合わせるスクリプトのサンプル


### ネットワーク
- ブリッジ、netns、veth
- ネットワーク情報表示、保存、復元


## ディレクトリ構成
スクリプトの実行はこのディレクトリ`nspawn`からで、相対パス指定

- lib
    - logger.sh
- logs
    - script.log
- nspawn
    - README.md
    - create_base_rootfs.sh
    - create_container.sh
    - run_container.sh
    - list_container.sh
    - stop_container.sh
    - remove_container.sh
    - debian_static_address.sh
    - setup_nspawn.sh
- config
    - default.conf
    - custom.conf
- docs

> 開発環境用、運用は/usr/local/binとかに入れればいいんじゃないか

