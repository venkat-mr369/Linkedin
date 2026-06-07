### Podman Cheat Sheet



#### What is Podman?

* Podman = Pod Manager
* Container engine similar to Docker
* Daemonless (no background service required)
* Supports rootless containers
* OCI (Open Container Initiative) compliant

---

### Installation

#### RHEL / Oracle Linux / Rocky Linux

```bash
sudo dnf install podman -y
```

#### Verify

```bash
podman --version
```

---

### Image Management

#### Search Image

```bash
podman search nginx
```

#### Pull Image

```bash
podman pull nginx
```

#### List Images

```bash
podman images
```

#### Remove Image

```bash
podman rmi nginx
```

#### Remove All Images

```bash
podman rmi -a
```

#### Inspect Image

```bash
podman inspect nginx
```

---

### Container Management

#### Run Container

```bash
podman run nginx
```

#### Run in Background

```bash
podman run -d nginx
```

#### Run with Name

```bash
podman run -d --name web nginx
```

#### List Running Containers

```bash
podman ps
```

#### List All Containers

```bash
podman ps -a
```

#### Stop Container

```bash
podman stop web
```

#### Start Container

```bash
podman start web
```

#### Restart Container

```bash
podman restart web
```

#### Remove Container

```bash
podman rm web
```

#### Force Remove

```bash
podman rm -f web
```

---

### Port Mapping

#### Map Host Port to Container Port

```bash
podman run -d -p 8080:80 nginx
```

Access:

```text
http://server-ip:8080
```

---

### Volume Management

#### Mount Host Directory

```bash
podman run -d \
-v /data:/usr/share/nginx/html \
nginx
```

#### Read-Only Volume

```bash
podman run -v /data:/data:ro nginx
```

---

### Execute Commands

#### Enter Running Container

```bash
podman exec -it web bash
```

#### Run Command

```bash
podman exec web hostname
```

---

### Logs

#### View Logs

```bash
podman logs web
```

#### Follow Logs

```bash
podman logs -f web
```

---

### Networking

#### List Networks

```bash
podman network ls
```

#### Create Network

```bash
podman network create appnet
```

#### Run Container on Network

```bash
podman run -d --network appnet nginx
```

#### Inspect Network

```bash
podman network inspect appnet
```

---

### Pods

#### Create Pod

```bash
podman pod create --name mypod
```

#### List Pods

```bash
podman pod ps
```

#### Run Container in Pod

```bash
podman run -dt \
--pod mypod \
nginx
```

#### Stop Pod

```bash
podman pod stop mypod
```

#### Remove Pod

```bash
podman pod rm mypod
```

---

### Registry Login

#### Login

```bash
podman login docker.io
```

#### Logout

```bash
podman logout docker.io
```

---

### Build Images

#### Build Image

```bash
podman build -t myapp:v1 .
```

#### Build from Dockerfile

```bash
podman build -f Dockerfile -t myapp:v1 .
```

---

### Push & Pull

#### Tag Image

```bash
podman tag myapp:v1 myrepo/myapp:v1
```

#### Push Image

```bash
podman push myrepo/myapp:v1
```

#### Pull Image

```bash
podman pull myrepo/myapp:v1
```

---

### Save & Load Images

#### Save Image

```bash
podman save -o nginx.tar nginx
```

#### Load Image

```bash
podman load -i nginx.tar
```

---

### System Cleanup

#### Remove Unused Objects

```bash
podman system prune
```

#### Remove Everything Unused

```bash
podman system prune -a
```

---

### Generate Systemd Service

#### Create Service File

```bash
podman generate systemd \
--name web \
--files
```

#### Enable Service

```bash
systemctl --user enable container-web.service
```

---

### Rootless Containers

#### Check User Namespace

```bash
podman info
```

#### Run Rootless

```bash
podman run -d nginx
```

No sudo required.

---

### Docker vs Podman

| Docker         | Podman                |
| -------------- | --------------------- |
| Docker Daemon  | Daemonless            |
| Root Required  | Rootless Supported    |
| Docker CLI     | Podman CLI Compatible |
| Docker Compose | Podman Compose        |
| Docker Swarm   | Kubernetes/Pods       |

---

### Interview Commands

```bash
podman images
podman ps -a
podman logs <container>
podman exec -it <container> bash
podman inspect <container>
podman network ls
podman pod ps
podman build -t app:v1 .
podman push image
podman system prune -a
```

### Real-Time Example

Run Nginx Web Server:

```bash
podman pull nginx

podman run -d \
--name nginx-web \
-p 8080:80 \
nginx

podman ps

curl http://localhost:8080
```

Expected Result:

```text
Welcome to nginx!
```
