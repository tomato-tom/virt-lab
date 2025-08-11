---
title: nspawn
markmap:
  colorFreezeLevel: 2
---

## 特徴
- 軽量コンテナ
- systemdサービス
- 高機能なchroot
## 用途
- 開発・テスト環境
- 軽量サーバー
- CI/CD
## 主要ツール
### コンテナ管理
- systemd-nspawn
- machinectl
### ネットワーク管理
- systemd-networkd
  - 仮想デバイス作成管理
  - ルーティング
  - DNS, DHCP
- iproute2
  - コマンド・スクリプトでの設定
  - 一時的なネットワーク設定に向いてる
- nftables
  - NAT
  - パケットフィルタリング
### イメージ作成
- debootstrap: debian, ubuntu
- pacstrap: Archlinux
- dnf: Fedora
- mkosi: 各種ディストリ
## ファイルシステム
## 参考リンク
- [systemd-nspawn](https://www.freedesktop.org/software/systemd/man/latest/systemd-nspawn.html)
- [machinectl](https://www.freedesktop.org/software/systemd/man/latest/machinectl.html#)
