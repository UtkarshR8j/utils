# Client
```
cd /etc/wireguard
wg genkey | tee privatekey | wg pubkey > publickey
vi wg0.conf
```

```
[Interface]
PrivateKey = 
Address = 10.9.0.X/24

[Peer]
PublicKey = dg1cKCId81d6h5cWUQ61BMHksBbi0FdFnitjxDuOuno=
Endpoint = vpn.danman.eu:51820
AllowedIPs = 10.9.0.0/24
PersistentKeepalive = 25
```
```
wg-quick up /etc/wireguard/wg0.conf
systemctl enable wg-quick@wg0.service
systemctl edit wg-quick@wg0.service
```
```
[Service]
Restart=on-failure
RestartSec=5s
```
# Server

```
systemctl stop wg-quick@wg0.service
vi /etc/wireguard/wg0
systemctl start wg-quick@wg0.service
```
# Reload
```
wg syncconf wg0 <(wg-quick strip wg0)
```
