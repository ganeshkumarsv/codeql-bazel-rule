package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	_ "github.com/mattn/go-sqlite3" // SQLite driver
)

func main() {
	// Initialize the database connection (using SQLite for simplicity)
	db, err := sql.Open("sqlite3", "./sample.db")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// Create a sample table for demonstration
	createTable := `CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		username TEXT NOT NULL,
		password TEXT NOT NULL
	);`
	_, err = db.Exec(createTable)
	if err != nil {
		log.Fatal(err)
	}

	// Insert sample data
	insertData := `INSERT INTO users (username, password) VALUES ('admin', 'adminpass');`
	_, err = db.Exec(insertData)
	if err != nil {
		log.Fatal(err)
	}

	// Set up a simple HTTP server
	http.HandleFunc("/login", func(w http.ResponseWriter, r *http.Request) {
		// Vulnerable code: Directly using user input in the SQL query
		username := r.URL.Query().Get("username")
		password := r.URL.Query().Get("password")

		query := fmt.Sprintf("SELECT username FROM users WHERE username='%s' AND password='%s'", username, password)
		fmt.Println("Executing query:", query)

		row := db.QueryRow(query)
		var user string
		err := row.Scan(&user)
		if err != nil {
			http.Error(w, "Invalid username or password", http.StatusUnauthorized)
			return
		}

		fmt.Fprintf(w, "Welcome, %s!", user)
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
