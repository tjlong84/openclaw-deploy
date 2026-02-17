# Tunnel Credentials

The tunnel JSON credential file goes here:

```
state/cloudflared/etc/<YOUR_TUNNEL_UUID>.json
```

Get it by running on the host that has cloudflared installed:

```bash
cloudflared tunnel list                          # find your tunnel UUID
cloudflared tunnel token <tunnel-name>           # get the token (for cloudflared.env)
cat ~/.cloudflared/<tunnel-uuid>.json            # the credentials file content
```

Or from Cloudflare Zero Trust dashboard:
- Access → Tunnels → your tunnel → Configure → Credentials → Download
