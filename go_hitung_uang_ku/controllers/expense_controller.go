package controllers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"go_hitung_uang_ku/config"
	"go_hitung_uang_ku/models"
)

// CREATE
func CreateExpense(c *gin.Context) {
	var expense models.Expense

	if err := c.ShouldBindJSON(&expense); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// get current user from context
	u, ok := c.Get("currentUser")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	user := u.(models.User)

	// ensure the expense belongs to the current user
	expense.UserID = user.ID

	if err := config.DB.Create(&expense).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	config.DB.Preload("User").First(&expense, expense.ID)
	c.JSON(http.StatusCreated, expense)
}

// GET ALL (only current user's expenses)
func GetExpenses(c *gin.Context) {
	u, ok := c.Get("currentUser")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	user := u.(models.User)

	var expenses []models.Expense
	config.DB.Preload("User").Where("user_id = ?", user.ID).Find(&expenses)
	c.JSON(http.StatusOK, expenses)
}

// GET BY ID (only if owned by current user)
func GetExpense(c *gin.Context) {
	id := c.Param("id")

	u, ok := c.Get("currentUser")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	user := u.(models.User)

	var expense models.Expense
	result := config.DB.Preload("User").
		Where("id = ? AND user_id = ?", id, user.ID).
		First(&expense)

	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Expense not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, expense)
}

// UPDATE (only if owned by current user)
func UpdateExpense(c *gin.Context) {
	id := c.Param("id")

	u, ok := c.Get("currentUser")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	user := u.(models.User)

	var expense models.Expense
	if err := config.DB.Where("id = ? AND user_id = ?", id, user.ID).First(&expense).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Expense not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var data models.Expense
	if err := c.ShouldBindJSON(&data); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// prevent changing owner
	data.UserID = expense.UserID

	config.DB.Model(&expense).Updates(data)
	config.DB.Preload("User").First(&expense, expense.ID)
	c.JSON(http.StatusOK, expense)
}

// DELETE (only if owned by current user)
func DeleteExpense(c *gin.Context) {
	id := c.Param("id")

	u, ok := c.Get("currentUser")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	user := u.(models.User)

	var expense models.Expense
	if err := config.DB.Where("id = ? AND user_id = ?", id, user.ID).First(&expense).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Expense not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	config.DB.Delete(&expense)
	c.JSON(http.StatusOK, gin.H{"message": "Expense deleted"})
}
