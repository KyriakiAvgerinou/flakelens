// Config loads environment variables for application startup.
// When environment variables are missing, it falls back to local defaults.
package config

import "os"

// This struct holds the settings needed for the application startup.
type Config struct {
	Port        string // the port where the backend runs
	DatabaseURL string // the address of the database
}

// The function that loads environment variables for application startup.
// Called by cmd/api/main.go.
func Load() Config {
	return Config{
		Port:        getEnv("PORT", "8080"),
		DatabaseURL: getEnv("DATABASE_URL", "postgres://flakelens:flakelens@localhost:5432/flakelens?sslmode=disable"),
	}
}

// Returns the value of the input environment variable (key).
// If the environment variable is not set,
// it returns the input default value (fallback).
func getEnv(key string, fallback string) string {
	// Try to read the environment variable.
	value := os.Getenv(key)

	if value == "" {
		return fallback // the default value
	}

	return value
}
