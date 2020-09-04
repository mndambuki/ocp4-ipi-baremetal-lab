variant: fcos
version: 1.1.0
passwd:
  users:
    - name: maintuser
      uid: 1001
      groups:
        - sudo
      ssh_authorized_keys:
        - '${ssh_pubkey}'
    - name: registry
      uid: 9998
      system: true
      no_create_home: true
      shell: /usr/sbin/nologin
storage:
  directories:
    - path: /etc/registry
      mode: 0755
      user:
        name: registry
      group:
        name: registry
    - path: /var/lib/registry/data
      mode: 0755
      user:
        name: registry
      group:
        name: registry
    - path: /var/lib/registry/auth
      mode: 0755
      user:
        name: registry
      group:
        name: registry
    - path: /var/lib/registry/certs
      mode: 0755
      user:
        name: registry
      group:
        name: registry
  files:
    - path: /etc/hostname
      overwrite: true
      mode: 0644
      user:
        name: root
      group:
        name: root
      contents:
        inline: ${fqdn}
    - path: /etc/registry/configuration.env
      overwrite: true
      mode: 0644
      user:
        name: root
      group:
        name: root
      contents:
        inline: |
          REGISTRY_AUTH=htpasswd
          REGISTRY_AUTH_HTPASSWD_REALM=Registry credentials
          REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd
          REGISTRY_HTTP_TLS_CERTIFICATE=/certs/certificate.pem
          REGISTRY_HTTP_TLS_KEY=/certs/private.key
          REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true
    - path: /var/lib/registry/auth/htpasswd
      overwrite: true
      mode: 0644
      user:
        name: root
      group:
        name: root
      contents:
        inline: ${registry_htpasswd}
    - path: /var/lib/registry/certs/certificate.pem
      overwrite: true
      mode: 0644
      user:
        name: root
      group:
        name: root
      contents:
        inline: |
          ${registry_tls_certificate}
    - path: /var/lib/registry/certs/private.key
      overwrite: true
      mode: 0644
      user:
        name: root
      group:
        name: root
      contents:
        inline: |
          ${registry_tls_private_key}
systemd:
  units:
    - name: registry.service
      enabled: true
      contents: |
        [Unit]
        Description=Registry
        Documentation=https://hub.docker.com/_/registry
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=simple
        TimeoutStartSec=180
        StandardOutput=journal
        ExecStartPre=-/bin/podman pull docker.io/registry:${registry_version}
        ExecStart=/bin/podman run --name %n --rm \
            --publish  5000:5000 \
            --env-file /etc/registry/configuration.env \
            --volume   /var/lib/registry/data:/var/lib/registry:z \
            --volume   /var/lib/registry/auth:/auth:ro,z \
            --volume   /var/lib/registry/certs:/certs:ro,z \
            docker.io/registry:${registry_version}
        Restart=on-failure
        RestartSec=5
        ExecStop=/bin/podman stop %n
        ExecReload=/bin/podman restart %n

        [Install]
        WantedBy=multi-user.target
