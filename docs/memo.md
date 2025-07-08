# メモ

ディレクトリ構成、とりあえず

├── docs
│   ├── memo.md
│   └── note_create_vm.md
├── examples
│   ├── ha-cluster
│   ├── multi-node
│   ├── README.md
│   └── single-node
├── experimental
│   ├── docker_setup.sh
│   ├── incus_docker.sh
│   ├── incus_install.sh
│   ├── incus_uninstall.sh
│   └── lxd_setup.sh
├── kvm
│   ├── clone_vm.sh
│   ├── create_vm.sh
│   ├── delete_vm.sh
│   ├── install_vm.sh
│   └── vm_title.sh
├── lib
│   └── libvirt_domain.py
├── logs
├── nspawn
│   ├── create_container.sh
│   ├── create_rootfs.sh
│   ├── custom.conf
│   └── default.conf
├── README.md
└── setup
    ├── install_kvm_qemu_libvirt.sh
    └── uninstall_kvm.sh


とにかくKVMとnspawnでやって、dockerとかは他でやってVM内にクローンして使うか。
基本的なVMの作成、削除、クローンなどできたら、そのスクリプトを組み合わせてexamples内に単一あるいは複数のVMスクリプトを作成

初期段階でapt-cacher-ng構築しとけば、その後のVM作成時のキャッシュ利用などに使える。
PXEブート、prebootでの自動インストール
debootstrapでの自動インストール

典型的なクラスタ、AWSとかのサンプルとかにあるやつ
ホームラボ向けのネットワーク
実験的なの


