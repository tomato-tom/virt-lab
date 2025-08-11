# nspawnの基本
<!-- 02-nspawn-basic.md -->
<!-- tags(basic container nspawn) -->

## 主要ツール
- systemd-nspawn
- machinectl

どちらも`systemd-conteiner`に含まれてる


## イメージの作成
- debootstrap
- pacstrap
- dnf


## ライフサイクル管理

### 作成、実行、停止、削除
### クローン
### コンテナにログイン
### ホストからコンテナ内スクリプト実行
### コンテナのリスト表示
### 各コンテナの情報表示


## ネットワーク
- ホストのネットワークをそのまま使用
- 自動的なネットワーク、要systemd-networkd, systemd-resolved


## ファイルシステム
- ディレクトリバインドマウント（--bind=/path）
- 読み込み専用マウント（--read-only）


## リソース制限
- CPU/Memory制限の基本（--cpu-shares, --memory=）


## 環境変数の渡し方

--setenv=KEY=VALUE
