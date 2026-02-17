FROM node:22-bookworm

# Install openclaw globally
RUN npm install -g openclaw@latest

# Install cloudflared, supervisor, pstree
RUN curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared bookworm main" \
       > /etc/apt/sources.list.d/cloudflared.list \
    && apt-get update && apt-get install -y cloudflared supervisor psmisc \
    && rm -rf /var/lib/apt/lists/*

# Create supervisord.conf and log dirs
RUN mkdir -p /etc/supervisor/conf.d /var/log/supervisor
COPY supervisord.conf /etc/supervisor/supervisord.conf

ENV HOME=/home/node
ENV NODE_ENV=production
WORKDIR /home/node

# openclaw gateway (loopback), bridge, V2 frontend, V2 backend API
EXPOSE 18789 18790 4174 8788

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
