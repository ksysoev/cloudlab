# Outline VPN — Key Management

The Shadowbox management API (port 8443) is not published to the host network.
All key management is done over SSH via `docker exec` into the running container.

## Prerequisites

SSH access to the server:

```bash
ssh -p 1923 deployer@make-it-public.dev
```

## Helper variables

Run these once per session to avoid repetition.
The container name changed when the stack was renamed — make sure to use the
current filter `outline-vpn_shadowbox`:

```bash
CONTAINER=$(docker ps -q --filter name=outline-vpn_shadowbox)
PREFIX=$(docker inspect "$CONTAINER" \
  --format '{{range .Config.Env}}{{println .}}{{end}}' \
  | grep SB_API_PREFIX | cut -d= -f2)

# Verify both are set before proceeding
echo "CONTAINER=$CONTAINER  PREFIX=$PREFIX"
```

> **Tip:** if `CONTAINER` or `PREFIX` is empty, Shadowbox is not running.
> Check with `docker ps` and look for a container named `outline-vpn_shadowbox.*`.

## List existing keys

```bash
docker exec "$CONTAINER" \
  curl -sk "https://localhost:8443/$PREFIX/access-keys" \
  | python3 -m json.tool
```

## Create a new key

```bash
docker exec "$CONTAINER" \
  curl -sk -X POST "https://localhost:8443/$PREFIX/access-keys" \
  | python3 -m json.tool
```

The response contains an `accessUrl` field — the `ss://` link to paste into
the Outline client app (iOS, Android, macOS, Windows, Linux).

## Rename a key

Replace `<id>` with the numeric key id returned when listing or creating keys:

```bash
docker exec "$CONTAINER" \
  curl -sk -X PUT "https://localhost:8443/$PREFIX/access-keys/<id>/name" \
  -H 'Content-Type: application/json' \
  -d '{"name":"alice-phone"}'
```

## Delete a key

```bash
docker exec "$CONTAINER" \
  curl -sk -X DELETE "https://localhost:8443/$PREFIX/access-keys/<id>"
```

## Set a data limit on a key

Limit is specified in bytes (e.g. `10737418240` = 10 GB):

```bash
docker exec "$CONTAINER" \
  curl -sk -X PUT "https://localhost:8443/$PREFIX/access-keys/<id>/data-limit" \
  -H 'Content-Type: application/json' \
  -d '{"limit":{"bytes":10737418240}}'
```

## Remove a data limit from a key

```bash
docker exec "$CONTAINER" \
  curl -sk -X DELETE "https://localhost:8443/$PREFIX/access-keys/<id>/data-limit"
```

## Full example — create and share a key in one command

Run this from your local machine (or directly on the server):

```bash
ssh -p 1923 deployer@make-it-public.dev bash << 'EOF'
CONTAINER=$(docker ps -q --filter name=outline-vpn_shadowbox)
if [ -z "$CONTAINER" ]; then echo "ERROR: shadowbox container not running"; exit 1; fi
PREFIX=$(docker inspect "$CONTAINER" \
  --format '{{range .Config.Env}}{{println .}}{{end}}' \
  | grep SB_API_PREFIX | cut -d= -f2)
if [ -z "$PREFIX" ]; then echo "ERROR: SB_API_PREFIX not set in container env"; exit 1; fi
docker exec "$CONTAINER" \
  curl -sk -X POST "https://localhost:8443/$PREFIX/access-keys" \
  | python3 -c "import sys,json; k=json.load(sys.stdin); print('Key id:', k['id']); print('Access URL:', k['accessUrl'])"
EOF
```

Paste the printed `ss://` URL into the Outline client to connect.

## Connecting with the Outline client

1. Download the Outline client: https://getoutline.org/get-started/#step-3
2. Tap **+** → **Add server**
3. Paste the `ss://` URL from the key creation output
4. Tap **Connect**

## Server details

| Parameter         | Value                                                              |
|-------------------|--------------------------------------------------------------------|
| VPN port          | `8388` (TCP + UDP)                                                 |
| Management port   | `8443` (internal only — not exposed externally)                    |

