# 使用官方 Nginx 镜像作为基础镜像
FROM nginx:alpine

# 将项目文件复制到容器中
COPY dist/ /usr/share/nginx/html/shouyin/

# 复制 Nginx 配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 8080

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]
