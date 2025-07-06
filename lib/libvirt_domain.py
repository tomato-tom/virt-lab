import libvirt

# 仮想化ホストへの接続（localの場合）
conn = libvirt.open('qemu:///system')

# 接続が成功したか確認
if conn is None:
    print('Failed to open connection to qemu:///system')
    exit(1)

# 仮想マシンのリストを取得
domains = conn.listAllDomains()
for domain in domains:
    print(domain.name())

# 接続を閉じる
conn.close()

