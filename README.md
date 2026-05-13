# iDRAC6 v2.92 IPv6 Web Patcher

Patches iDRAC6 firmware to enable IPv6 dual-stack listening on Appweb HTTPS.

## What it changes

- `appweb.conf.template`: `Listen ${AIM_HTTPS_PORT}` → `Listen [::]:${AIM_HTTPS_PORT}`
- `appweb.conf.template`: `Listen ${AIM_HTTP_PORT}` → `Listen [::]:${AIM_HTTP_PORT}`

## Flashing

```bash
racadm fwupdate -g -u http://YOUR_NAS_IP/firmimg_patched.d6
racadm racreset
```
