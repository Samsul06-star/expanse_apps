package controllers

import (
    "net/http"
    "os"
    "path/filepath"
    "strings"
    "time"
    "github.com/google/uuid" 
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"go_hitung_uang_ku/config"
	"go_hitung_uang_ku/models"
	"go_hitung_uang_ku/providers" 
)

// CREATE
type RegisterInput struct {
    FullName string `json:"full_name" binding:"required"`
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required,min=6"`
}

type LoginInput struct {
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required"`
}

// CREATE (Register)
func CreateUser(c *gin.Context) {
    var input RegisterInput
    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // Check if email already exists
    var exist models.User
    if err := config.DB.Where("email = ?", input.Email).First(&exist).Error; err == nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "email already registered"})
        return
    } else if err != nil && err != gorm.ErrRecordNotFound {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    // Hash password
    hashed, err := providers.HashPassword(input.Password)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to hash password"})
        return
    }

    user := models.User{
        FullName: input.FullName,
        Email:    input.Email,
        Password: hashed,
    }

    if err := config.DB.Create(&user).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    // Generate token
    token, err := providers.GenerateToken(user.ID, 24)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{
        "user": gin.H{
            "id":         user.ID,
            "full_name":  user.FullName,
            "email":      user.Email,
            "avatar":     user.Avatar,
            "birth_date": user.BirthDate,
            "created_at": user.CreatedAt,
        },
        "token": token,
    })
}

// LOGIN
func Login(c *gin.Context) {
    var input LoginInput
    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    var user models.User
    if err := config.DB.Where("email = ?", input.Email).First(&user).Error; err != nil {
        if err == gorm.ErrRecordNotFound {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
            return
        }
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    if !providers.CheckPasswordHash(user.Password, input.Password) {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
        return
    }

    token, err := providers.GenerateToken(user.ID, 24)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "token": token,
        "user": gin.H{
            "id":         user.ID,
            "full_name":  user.FullName,
            "email":      user.Email,
            "avatar":     user.Avatar,
            "birth_date": user.BirthDate,
            "created_at": user.CreatedAt,
        },
    })
}

// GET ALL
func GetUsers(c *gin.Context) {
    var users []models.User
    config.DB.Find(&users)
    c.JSON(http.StatusOK, users)
}

// GET BY ID
func GetUser(c *gin.Context) {
    id := c.Param("id")
    var user models.User

    result := config.DB.First(&user, id)
    if result.Error != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
        return
    }

    c.JSON(http.StatusOK, user)
}

func saveAvatar(c *gin.Context, field string) (string, error) {
    file, err := c.FormFile(field)
    if err != nil {
        // no file uploaded or field missing -> not an error for update
        return "", nil
    }

    ext := strings.ToLower(filepath.Ext(file.Filename))
    if ext != ".png" && ext != ".jpg" && ext != ".jpeg" && ext != ".gif" {
        return "", gin.Error{
            Err:  err,
            Type: gin.ErrorTypePublic,
        }
    }

    if err := os.MkdirAll("uploads", os.ModePerm); err != nil {
        return "", err
    }

    filename := uuid.NewString() + ext
    dst := filepath.Join("uploads", filename)

    if err := c.SaveUploadedFile(file, dst); err != nil {
        return "", err
    }

    return "/uploads/" + filename, nil
}

// UPDATE
func UpdateUser(c *gin.Context) {
    id := c.Param("id")

    // current user from middleware
    u, ok := c.Get("currentUser")
    if !ok {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
        return
    }
    currentUser := u.(models.User)

    // fetch user to update
    var user models.User
    if err := config.DB.First(&user, id).Error; err != nil {
        if err == gorm.ErrRecordNotFound {
            c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
            return
        }
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    // only owner can update
    if currentUser.ID != user.ID {
        c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
        return
    }

    // support JSON and multipart
    ct := c.GetHeader("Content-Type")
    var updateData struct {
        FullName string `json:"full_name"`
        Email    string `json:"email" binding:"omitempty,email"`
        Password string `json:"password"`
    }

    newAvatar := ""
    if strings.HasPrefix(ct, "multipart/form-data") {
        // values may be empty; update only when provided
        if v := c.PostForm("full_name"); v != "" {
            updateData.FullName = v
        }
        if v := c.PostForm("email"); v != "" {
            updateData.Email = v
        }
        if v := c.PostForm("password"); v != "" {
            updateData.Password = v
        }
        av, err := saveAvatar(c, "avatar")
        if err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
        newAvatar = av
    } else {
        if err := c.ShouldBindJSON(&updateData); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }
    }

    // Email uniqueness check if changed
    if updateData.Email != "" && updateData.Email != user.Email {
        var exist models.User
        if err := config.DB.Where("email = ?", updateData.Email).First(&exist).Error; err == nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": "email already registered"})
            return
        } else if err != nil && err != gorm.ErrRecordNotFound {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }
    }

    // Apply updates
    if updateData.FullName != "" {
        user.FullName = updateData.FullName
    }
    if updateData.Email != "" {
        user.Email = updateData.Email
    }
    if updateData.Password != "" {
        hashed, err := providers.HashPassword(updateData.Password)
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to hash password"})
            return
        }
        user.Password = hashed
    }

    // handle avatar replacement
    if newAvatar != "" {
        // remove old file if it is in /uploads
        if strings.HasPrefix(user.Avatar, "/uploads/") {
            oldPath := filepath.Join(".", user.Avatar) // user.Avatar is "/uploads/..."
            if err := os.Remove(oldPath); err != nil && !os.IsNotExist(err) {
                // non-fatal; log in response for debug
                c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to remove old avatar"})
                return
            }
        }
        user.Avatar = newAvatar
    }

    user.UpdatedAt = time.Now()
    if err := config.DB.Save(&user).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "id":         user.ID,
        "full_name":  user.FullName,
        "email":      user.Email,
        "avatar":     user.Avatar,
        "birth_date": user.BirthDate,
        "created_at": user.CreatedAt,
        "updated_at": user.UpdatedAt,
    })
}

// DELETE
func DeleteUser(c *gin.Context) {
    id := c.Param("id")
    config.DB.Delete(&models.User{}, id)
    c.JSON(http.StatusOK, gin.H{"message": "User deleted"})
}
