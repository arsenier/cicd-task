#! /bin/env bash

# get current symlink
current=$(docker compose exec proxy ls -la /etc/nginx/nginx.conf)
echo $current

# conditionally deploy the other color
if [[ $current = *"green"* ]]; then
    echo "deploying BLUE"

    docker compose pull app_blue
    docker compose up -d --force-recreate app_blue

    echo "Waiting..."
    until [ $(docker ps -f name=app_blue -f health=healthy -q) ];
    do
        sleep 1;
    done;

    # have nginx reload the conf file
    docker compose exec proxy ln -sf /etc/nginx/nginx_blue.conf /etc/nginx/nginx.conf
    docker compose exec proxy nginx -s reload
    
    docker compose stop app_green
else
    echo "deploying GREEN"

    docker compose pull app_green
    docker compose up -d --force-recreate app_green

    echo "Waiting..."
    until [ $(docker ps -f name=app_green -f health=healthy -q) ];
    do
        sleep 1;
    done;
    
    # have nginx reload the conf file
    docker compose exec proxy ln -sf /etc/nginx/nginx_green.conf /etc/nginx/nginx.conf
    docker compose exec proxy nginx -s reload

    docker compose stop app_blue
fi

