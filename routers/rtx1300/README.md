# rtx1300

Yamaha RTX1300 router. Configs are pasted on the console, not imported: a bad line makes an import stop part-way and the router loses its LAN address.

| File | Use |
|---|---|
| `config1.txt` | Full config: v6plus static IPv4, AdGuard DNS, filters, NTP, syslog. Template: `just render routers/rtx1300/config1.txt` writes it to `dist/` |
| `config0.txt` | Fallback: plain v6plus MAP-E, ISP DNS, only the IPv6 inbound filter. No secrets, paste as is |
| `secrets.yaml` | Values for `config1.txt`: `just edit-secrets routers/rtx1300` |

Passwords are not in the files; set them on the console (`administrator password`, `login user admin`).

Factory reset: hold microSD + USB + DOWNLOAD while powering on. Login `admin` / `admin`, LAN `192.168.100.1` on ports 1-8. This erases all saved configs.

## Config slots

The router stores configs in slots 0-4 and boots the default one. `save` writes to the slot it booted from; `show config list` lists the slots.

Setup, from the factory state:

1. Paste `config0.txt`, set the passwords, check the internet, `save 0`
1. Paste `dist/routers/rtx1300/config1.txt`
1. Remove what only `config0.txt` sets:
   ```
   no ipv6 lan1 address dhcp-prefix@lan2::1/64
   no ipv6 lan2 address dhcp
   no dns server dhcp lan2
   tunnel select 1
   no tunnel map-e type
   tunnel select none
   no nat descriptor address outer 1000
   no nat descriptor type 1000
   no ipv6 filter 200030
   no ipv6 filter 200031
   no ipv6 filter 200038
   no ipv6 filter 200039
   no ipv6 filter 200099
   no ipv6 filter dynamic 200098
   no ipv6 filter dynamic 200099
   ```
1. Check the internet, `save 1`, `set-default-config 1`

Switch to the fallback: `set-default-config 0`, then reboot. Back: `set-default-config 1`, then reboot. `set-default-config` only takes effect at the next boot. Reboot with `restart` over SSH or the console (the web GUI's command screen blocks it), the web GUI's reboot page, or by power-cycling.

Before a risky change, schedule a reboot into the saved config, e.g. `schedule at 9 */* 01:30 * restart`. If the change works, `save` and `no schedule at 9`.
