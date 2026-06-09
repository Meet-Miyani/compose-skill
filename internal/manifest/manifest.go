package manifest

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"
)

const ManifestFile = ".composekit-manifest.json"

type Manifest struct {
	Name         string   `json:"name"`
	DisplayName  string   `json:"displayName"`
	InstalledBy  string   `json:"installedBy"`
	SkillVersion string   `json:"skillVersion"`
	CliVersion   string   `json:"cliVersion"`
	GitCommit    string   `json:"gitCommit"`
	Source       string   `json:"source"`
	InstalledAt  string   `json:"installedAt"`
	ManagedFiles []string `json:"managedFiles"`
}

func Read(skillDir string) (*Manifest, error) {
	p := filepath.Join(skillDir, ManifestFile)
	data, err := os.ReadFile(p)
	if err != nil {
		return nil, err
	}
	var m Manifest
	if err := json.Unmarshal(data, &m); err != nil {
		return nil, err
	}
	return &m, nil
}

func Write(skillDir, name, displayName, cliVersion, gitCommit, source string, managedFiles []string) error {
	m := Manifest{
		Name:         name,
		DisplayName:  displayName,
		InstalledBy:  "composekit",
		SkillVersion: cliVersion,
		CliVersion:   cliVersion,
		GitCommit:    gitCommit,
		Source:       source,
		InstalledAt:  time.Now().UTC().Format(time.RFC3339),
		ManagedFiles: managedFiles,
	}
	data, err := json.MarshalIndent(m, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(skillDir, ManifestFile), data, 0644)
}

func Exists(skillDir string) bool {
	_, err := os.Stat(filepath.Join(skillDir, ManifestFile))
	return err == nil
}

func IsManaged(skillDir string) bool {
	m, err := Read(skillDir)
	if err != nil {
		return false
	}
	return m.InstalledBy == "composekit"
}
