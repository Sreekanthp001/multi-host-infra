# src_frontend/Dockerfile

FROM nginx:alpine

# 1. Nginx config ని కాపీ చేయండి
COPY default.conf /etc/nginx/conf.d/default.conf

# 2. మీ 'static' ఫోల్డర్ లోని ఫైల్స్ ని Nginx వెబ్ రూట్ కి కాపీ చేయండి
# ఇక్కడ '#' తీసేసి సరిగ్గా రాయాలి
COPY static/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]