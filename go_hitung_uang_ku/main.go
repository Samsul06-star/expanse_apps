package main

import (
	"fmt"
	"net"

	"go_hitung_uang_ku/config"
	"go_hitung_uang_ku/models"
	"go_hitung_uang_ku/routes"

	"github.com/gin-gonic/gin"
)

// Fungsi untuk mengambil IP lokal WiFi
func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "Unknown"
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}

	return "Unknown"
}

func main() {
	config.ConnectDB()
	config.DB.AutoMigrate(&models.User{}, &models.Expense{})

	r := gin.Default()
	
	routes.RegisterRoutes(r)
    r.Static("/uploads", "./uploads")
	// Print IP WiFi kamu
	localIP := getLocalIP()
	fmt.Println("Server berjalan di: http://" + localIP + ":8080")

	// Tetap 0.0.0.0 agar semua perangkat bisa akses
	r.Run("0.0.0.0:8080")
}
