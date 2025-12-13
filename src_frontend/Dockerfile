# src_frontend/Dockerfile

FROM nginx:1.29.0-alpine

# పాత డిఫాల్ట్ NGINX కాన్ఫిగరేషన్ ఫైల్‌లను తొలగించండి
RUN rm /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf

# NGINX క్యాష్ మరియు లాగ్ డైరెక్టరీలను సృష్టించి, అనుమతులను సెట్ చేయండి
RUN mkdir -p /var/cache/nginx/client_temp && \
    mkdir -p /var/cache/nginx/proxy_temp && \
    mkdir -p /var/cache/nginx/fastcgi_temp && \
    mkdir -p /var/cache/nginx/uwsgi_temp && \
    mkdir -p /var/cache/nginx/scgi_temp && \
    chown -R nginx:nginx /etc/nginx/ && \
    chown -R nginx:nginx /var/log/nginx

# SSL డైరెక్టరీలను సృష్టించండి
RUN mkdir -p /etc/nginx/ssl/ && \
    chown -R nginx:nginx /etc/nginx/ssl/ && \
    chmod -R 755 /etc/nginx/ssl/

# PID ఫైల్ కోసం అనుమతులు
RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid /run/nginx.pid

# 1. కస్టమ్ NGINX కాన్ఫిగరేషన్‌ను కాపీ చేయండి
ADD nginx.conf /etc/nginx/nginx.conf

# 2. 📢 చాలా ముఖ్యమైనది: Massively UI ఫైల్‌లను NGINX రూట్ డైరెక్టరీలోకి కాపీ చేయండి
ADD static /usr/share/nginx/html/ 


USER nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]