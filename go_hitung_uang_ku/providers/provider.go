package providers

import (
    "errors"
    "os"
    "strconv"
    "time"

    "github.com/golang-jwt/jwt/v4"
    "golang.org/x/crypto/bcrypt"
)

var jwtSecret = func() []byte {
    s := os.Getenv("JWT_SECRET")
    if s == "" {
        s = "secret"
    }
    return []byte(s)
}()

func HashPassword(pw string) (string, error) {
    b, err := bcrypt.GenerateFromPassword([]byte(pw), bcrypt.DefaultCost)
    return string(b), err
}

func CheckPasswordHash(hash, pw string) bool {
    return bcrypt.CompareHashAndPassword([]byte(hash), []byte(pw)) == nil
}

func GenerateToken(userID uint, ttlHours int) (string, error) {
    if ttlHours <= 0 {
        ttlHours = 24
    }
    claims := jwt.MapClaims{}
    claims["user_id"] = strconv.FormatUint(uint64(userID), 10)
    claims["exp"] = time.Now().Add(time.Duration(ttlHours) * time.Hour).Unix()

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString(jwtSecret)
}

func ValidateToken(tokenString string) (uint, error) {
    token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, errors.New("unexpected signing method")
        }
        return jwtSecret, nil
    })
    if err != nil || !token.Valid {
        return 0, errors.New("invalid token")
    }
    claims, ok := token.Claims.(jwt.MapClaims)
    if !ok {
        return 0, errors.New("invalid token claims")
    }
    uidStr, ok := claims["user_id"].(string)
    if !ok {
        return 0, errors.New("invalid user_id in claims")
    }
    u64, err := strconv.ParseUint(uidStr, 10, 64)
    if err != nil {
        return 0, err
    }
    return uint(u64), nil
}