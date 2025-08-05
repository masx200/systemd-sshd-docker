FROM debian:trixie

# 设置环境变量，避免交互式配置
ENV DEBIAN_FRONTEND=noninteractive
copy ./debian.sources /etc/apt/sources.list.d/debian.sources
run apt update
run apt install apt-transport-https ca-certificates -y nano
run rm -rf /var/lib/apt/lists/*
run apt clean
COPY ./sources.list /etc/apt/sources.list
# 安装必要的软件包
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    systemd \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# 替换软件源为清华源
env EDITOR=nano

# 重新更新软件包索引
RUN apt-get update  && apt-get install -y sudo  && rm -rf /var/lib/apt/lists/*


# 创建SSH目录并设置权限
RUN mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd

# 确保sshd服务开机自启
RUN systemctl enable ssh
run apt clean
# 暴露SSH端口
EXPOSE 22

# 使用systemd作为启动命令
CMD ["/sbin/init"]
env TZ=Asia/Shanghai
env LANG=zh_CN.UTF-8