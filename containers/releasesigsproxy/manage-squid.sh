#!/bin/bash

CONTAINER_NAME="squid-openshift-proxy"
IMAGE_NAME="squid-openshift:v3"
PROXY_PORT="3128"

case "$1" in
    start)
        echo "Starting Squid OpenShift proxy container..."
        podman run -d \
            --name $CONTAINER_NAME \
            -p $PROXY_PORT:3128 \
            --restart unless-stopped \
            $IMAGE_NAME
        echo "Container started. Proxy available at: http://192.168.124.56:$PROXY_PORT"
        ;;
    stop)
        echo "Stopping Squid OpenShift proxy container..."
        podman stop $CONTAINER_NAME
        ;;
    restart)
        echo "Restarting Squid OpenShift proxy container..."
        podman restart $CONTAINER_NAME
        ;;
    status)
        echo "Container status:"
        podman ps -f name=$CONTAINER_NAME
        ;;
    logs)
        echo "Container logs:"
        podman logs --tail 20 $CONTAINER_NAME
        ;;
    remove)
        echo "Removing Squid OpenShift proxy container..."
        podman rm -f $CONTAINER_NAME
        ;;
    test)
        echo "Testing proxy with mirror.openshift.com..."
        curl -I -x http://192.168.124.56:$PROXY_PORT http://mirror.openshift.com/readme.md
        echo -e "\nTesting blocked domain (should return 403)..."
        curl -I -x http://192.168.124.56:$PROXY_PORT http://google.com --connect-timeout 5
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|remove|test}"
        echo "  start   - Start the Squid container"
        echo "  stop    - Stop the Squid container"  
        echo "  restart - Restart the Squid container"
        echo "  status  - Show container status"
        echo "  logs    - Show container logs"
        echo "  remove  - Remove the Squid container"
        echo "  test    - Test proxy functionality"
        exit 1
        ;;
esac
