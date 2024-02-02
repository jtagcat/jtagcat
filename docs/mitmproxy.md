## mitmproxy reverse proxy with Let's Encrypt
Prerequisite: A valid front domain (`in.example.com`) pointing at the server with mitmproxy.

```sh
certbot certonly --standalone -d in.example.com
cd /etc/letsencrypt/live/in.example.com/
cat privkey.pem fullchain.pem > mitm.pem
mitmproxy --set block_global=false -p 443 --certs 'in.example.com=mitm.pem' --mode 'reverse:https://out.example.com'
```
