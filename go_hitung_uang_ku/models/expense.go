package models

import "time"

type Expense struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	UserID      uint      `json:"user_id"`
	Category    string    `json:"category"`
	Type        string    `json:"type"` // Income / Expense
	Amount      int       `json:"amount"`
	Description string    `json:"description"`
	Date        time.Time `json:"date"`

	User User `gorm:"foreignKey:UserID"`
}
