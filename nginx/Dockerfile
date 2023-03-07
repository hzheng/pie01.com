FROM nginx:alpine
 
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf/ghost.conf conf/remark42.conf /etc/nginx/conf.d/
RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.disabled
#RUN mkdir -p /var/www/html
#COPY html/* /var/www/html/
