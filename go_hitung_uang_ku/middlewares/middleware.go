package middlewares

import (
    "net/http"
    "strings"

    "github.com/gin-gonic/gin"
    "go_hitung_uang_ku/config"
    "go_hitung_uang_ku/models"
    "go_hitung_uang_ku/providers"
)

func AuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        auth := c.GetHeader("Authorization")
        if auth == "" {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "authorization header required"})
            return
        }
        parts := strings.Split(auth, " ")
        if len(parts) != 2 || parts[0] != "Bearer" {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid authorization header"})
            return
        }
        token := parts[1]
        userID, err := providers.ValidateToken(token)
        if err != nil {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
            return
        }

        var user models.User
        if err := config.DB.First(&user, userID).Error; err != nil {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "user not found"})
            return
        }

        c.Set("currentUser", user)
        c.Next()
    }
}