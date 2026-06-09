package config

import (
	"encoding/json"
	"os"
	"path/filepath"

	"github.com/Meet-Miyani/composekit/internal/targets"
)

type Config struct {
	Targets []string `json:"targets"`
}

func ConfigDir() (string, error) {
	if v := os.Getenv("COMPOSEKIT_CONFIG_HOME"); v != "" {
		return v, nil
	}
	userDir, err := os.UserConfigDir()
	if err != nil {
		return "", err
	}
	dir := filepath.Join(userDir, "composekit")
	if err := os.MkdirAll(dir, 0755); err != nil {
		return "", err
	}
	return dir, nil
}

func ConfigPath() (string, error) {
	dir, err := ConfigDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "config.json"), nil
}

func Load() *Config {
	cfg := &Config{}
	p, err := ConfigPath()
	if err != nil {
		return cfg
	}
	data, err := os.ReadFile(p)
	if err != nil {
		return cfg
	}
	json.Unmarshal(data, cfg)
	for i, t := range cfg.Targets {
		cfg.Targets[i] = targets.ExpandHome(t)
	}
	return cfg
}

func Save(cfg *Config) error {
	p, err := ConfigPath()
	if err != nil {
		return err
	}
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(p, data, 0644)
}
