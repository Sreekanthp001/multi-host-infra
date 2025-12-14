# src_frontend/Dockerfile (Simple and reliable)

FROM nginx:1.29.0-alpine


RUN rm /etc/nginx/conf.d/default.conf
ADD nginx.conf /etc/nginx/conf.d/default.conf

ADD static /usr/share/nginx/html/ 

EXPOSE 80

