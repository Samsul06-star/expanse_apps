package models

import "time"

type User struct {
    ID        uint       `json:"id" gorm:"primaryKey"`
    FullName  string     `json:"full_name" gorm:"size:255;not null"`
    Email     string     `json:"email" gorm:"uniqueIndex;size:255;not null"`
    Password  string     `json:"-" gorm:"size:255;not null"`
    Avatar    string     `json:"avatar" gorm:"size:255"`
    BirthDate *time.Time `json:"birth_date,omitempty"`
    CreatedAt time.Time  `json:"created_at"`
    UpdatedAt time.Time  `json:"updated_at"`
}