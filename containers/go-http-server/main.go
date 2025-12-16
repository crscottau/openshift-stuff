package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
)

func helloHandler(w http.ResponseWriter, r *http.Request) {
	ip := getLocalIP()
	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown"
	}
	fmt.Fprintf(w, "<p>Go HTTP server (%s: %s)</p>\n", hostname, ip)
}

// getLocalIP finds a non-loopback IPv4 address of the server
func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "unknown"
	}
	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return "unknown"
}

func main() {
	http.HandleFunc("/", helloHandler)

	port := ":8080"
	log.Printf("Starting server on port %s\n", port)
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
