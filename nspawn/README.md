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

```
.
├── bin
├── config
│   ├── custom.conf
│   ├── custom-nat-template.nft
│   └── default.conf
├── docs
│   ├── getting-started-nspawn.md
│   ├── index.md
│   └── nspawn-markmap.md
├── lib
│   ├── common.sh
│   ├── container
│   │   ├── create_base_rootfs.sh
│   │   ├── create_container.sh
│   │   ├── list_container.sh
│   │   ├── remove_container.sh
│   │   ├── run_container.sh
│   │   └── stop_container.sh
│   ├── logger.sh
│   ├── query.sh
│   ├── setup_nspawn.sh
│   └── vnet
│       ├── bridge.sh
│       ├── netns.sh
│       ├── network.sh
│       └── veth.sh
├── logs
│   └── script.log
├── misc
│   ├── debian_static_address.sh
│   ├── nat.sh
│   └── netns_bridge.sh
├── README.md
└── tests
    ├── logger_test.sh
    └── logs
        ├── test.log
        ├── test.log.1
        ├── test.log.2
        └── test.log.3
```

> 開発環境用、運用は/usr/local/binとかに入れればいいんじゃないか

