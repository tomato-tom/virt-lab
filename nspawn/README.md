# コンテナのスクリプト

## 機能
rootfs作成
コンテナ作成・削除
コンテナ実行・停止
コンテナのリスト・情報
コンテナをコピー
複数のコンテナを組み合わせるスクリプトのサンプル

スクリプトの実行はこのディレクトリ`nspawn`からで、ログのスクリプトは相対パス
- lib
    - logger.sh
- logs
    - script.log
- nspawn
    - create_base_rootfs.sh
    - create_container.sh
    - ...

## setup_nspawn.sh
必要なパッケージをインストール
- debootstrap
- systemd-container


## create_base_rootfs.sh
debootstrapでrootfs作成
```
# ./create_rootfs.sh [ <custom config> ]
```

rootの初期パスワードを`root`に設定
rootfs作成時にtmpfsにマウントしてメモリ活用
デフォルトでdebian stable、変更可能
- custom.conf
- default.conf


## create_container.sh
base_rootfsよりコンテナ作成

