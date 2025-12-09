package routes

import (
	"github.com/gin-gonic/gin"
	"go_hitung_uang_ku/controllers"
	"go_hitung_uang_ku/middlewares"
)

func RegisterRoutes(r *gin.Engine) {

	// Public: register & login
	r.POST("/register", controllers.CreateUser)
	r.POST("/login", controllers.Login)

	// Protected routes (require Authorization: Bearer <token>)
	auth := r.Group("/")
	auth.Use(middlewares.AuthMiddleware())
	{
		// current user
		auth.GET("/me", func(c *gin.Context) {
			user := c.MustGet("currentUser")
			c.JSON(200, user)
		})

		// User Routes (protected)
		auth.GET("/users", controllers.GetUsers)
		auth.GET("/users/:id", controllers.GetUser)
		auth.PUT("/users/:id", controllers.UpdateUser)
		auth.DELETE("/users/:id", controllers.DeleteUser)

		// Expense Routes (protected)
		auth.POST("/expenses", controllers.CreateExpense)
		auth.GET("/expenses", controllers.GetExpenses)
		auth.GET("/expenses/:id", controllers.GetExpense)
		auth.PUT("/expenses/:id", controllers.UpdateExpense)
		auth.DELETE("/expenses/:id", controllers.DeleteExpense)
	}
}
