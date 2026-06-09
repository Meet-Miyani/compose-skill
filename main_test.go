package main

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/Meet-Miyani/composekit/internal/catalog"
	"github.com/Meet-Miyani/composekit/internal/install"
	"github.com/Meet-Miyani/composekit/internal/manifest"
)

func TestManagedFiles(t *testing.T) {
	cat, err := loadCatalog()
	if err != nil {
		t.Fatal(err)
	}
	skill := cat.FindByName(defaultSkillName)
	if skill == nil {
		t.Fatalf("skill %q not found", defaultSkillName)
	}

	files, err := install.ManagedFiles(embeddedFiles, skill.Path)
	if err != nil {
		t.Fatal(err)
	}

	if len(files) == 0 {
		t.Fatal("expected at least one managed file")
	}

	found := false
	for _, f := range files {
		if f == "SKILL.md" {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected SKILL.md in managed files")
	}

	found = false
	for _, f := range files {
		if f == "agents/openai.yaml" {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected agents/openai.yaml in managed files")
	}
}

func TestExistsEmbedded(t *testing.T) {
	cat, err := loadCatalog()
	if err != nil {
		t.Fatal(err)
	}
	skill := cat.FindByName(defaultSkillName)
	if skill == nil {
		t.Fatalf("skill %q not found", defaultSkillName)
	}

	if !install.ExistsEmbedded(embeddedFiles, skill.Path, "SKILL.md") {
		t.Error("expected SKILL.md to exist in embedded payload")
	}
	if !install.ExistsEmbedded(embeddedFiles, skill.Path, "agents/openai.yaml") {
		t.Error("expected agents/openai.yaml to exist in embedded payload")
	}
	if install.ExistsEmbedded(embeddedFiles, skill.Path, "nonexistent.md") {
		t.Error("expected nonexistent.md to not exist")
	}
}

func TestInitAndRemove(t *testing.T) {
	tmpDir := t.TempDir()
	targetDir := filepath.Join(tmpDir, "skills")

	oldArgs := os.Args
	defer func() { os.Args = oldArgs }()

	t.Setenv("COMPOSEKIT_CONFIG_HOME", filepath.Join(tmpDir, "config"))
	os.Args = []string{"composekit", "init", "--target", targetDir}
	if err := cmdInit(); err != nil {
		t.Fatal(err)
	}

	dest := filepath.Join(targetDir, defaultSkillName)
	if !install.Exists(dest) {
		t.Fatal("expected skill to be installed")
	}

	if !install.Exists(filepath.Join(dest, "SKILL.md")) {
		t.Error("expected SKILL.md to exist")
	}

	if !install.Exists(filepath.Join(dest, manifest.ManifestFile)) {
		t.Error("expected manifest to exist")
	}

	// Test update (offline mode)
	os.Args = []string{"composekit", "update", "--target", targetDir, "--force", "--offline"}
	if err := cmdUpdate(); err != nil {
		t.Fatal(err)
	}

	if !install.Exists(dest) {
		t.Fatal("expected skill to still exist after update")
	}

	// Test remove
	os.Args = []string{"composekit", "remove", "--target", targetDir}
	if err := cmdRemove(); err != nil {
		t.Fatal(err)
	}

	if install.Exists(dest) {
		t.Error("expected skill to be removed")
	}
}

func TestCatalog(t *testing.T) {
	cat, err := catalog.Load(embeddedFiles, catalogRoot)
	if err != nil {
		t.Fatal(err)
	}
	if len(cat.Skills) == 0 {
		t.Fatal("expected at least one skill in catalog")
	}
}

func TestCatalogFind(t *testing.T) {
	cat, err := catalog.Load(embeddedFiles, catalogRoot)
	if err != nil {
		t.Fatal(err)
	}
	s := cat.FindByName("compose")
	if s == nil {
		t.Fatal("expected to find compose skill")
	}
	results := cat.FindByQuery("navigation")
	if len(results) == 0 {
		t.Error("expected to find skills matching 'navigation'")
	}
}
