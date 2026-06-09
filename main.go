package main

import (
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/Meet-Miyani/composekit/internal/catalog"
	"github.com/Meet-Miyani/composekit/internal/config"
	gh "github.com/Meet-Miyani/composekit/internal/github"
	"github.com/Meet-Miyani/composekit/internal/install"
	"github.com/Meet-Miyani/composekit/internal/manifest"
	"github.com/Meet-Miyani/composekit/internal/targets"
	"github.com/Meet-Miyani/composekit/internal/ui"
)

//go:embed skills/** catalog/**
var embeddedFiles embed.FS

var (
	version = "dev"
	commit  = "unknown"
	date    = "unknown"
)

const defaultSkillName = "compose"
const catalogRoot = "catalog/skills.json"

func main() {
	if len(os.Args) < 2 {
		help()
		return
	}

	switch os.Args[1] {
	case "init":
		ui.Must(cmdInit())
	case "update":
		ui.Must(cmdUpdate())
	case "doctor":
		ui.Must(cmdDoctor())
	case "remove":
		ui.Must(cmdRemove())
	case "version":
		fmt.Printf("composekit %s\ncommit: %s\nbuilt: %s\n", version, commit, date)
	case "skills":
		if len(os.Args) < 3 {
			help()
			return
		}
		ui.Must(cmdSkills(os.Args[2]))
	case "targets":
		if len(os.Args) < 3 {
			help()
			return
		}
		ui.Must(cmdTargets(os.Args[2]))
	case "help", "--help", "-h":
		help()
	default:
		fmt.Println("Unknown command:", os.Args[1])
		help()
		os.Exit(1)
	}
}

func resolveTargets() []string {
	if dir := ui.GetFlagValue("--target"); dir != "" {
		abs, err := filepath.Abs(dir)
		ui.Must(err)
		return []string{abs}
	}

	if ui.HasFlag("--all-agents") {
		cfg := config.Load()
		return targets.ResolveTargets(nil, true, cfg.Targets)
	}

	if agents := ui.GetAgents(); len(agents) > 0 {
		cfg := config.Load()
		return targets.ResolveTargets(agents, false, cfg.Targets)
	}

	cfg := config.Load()
	result := targets.ResolveTargets(nil, false, cfg.Targets)
	if len(result) > 0 {
		return result
	}

	return targets.DefaultTargets()
}

func loadCatalog() (*catalog.Catalog, error) {
	return catalog.Load(embeddedFiles, catalogRoot)
}

func installFromEmbedded(skill *catalog.SkillEntry, dest string, version, commit, source string) error {
	return install.InstallSkill(embeddedFiles, skill.Path, dest, skill.Name, skill.DisplayName, version, commit, source)
}

func installFromDir(skillDir, dest, name, displayName, version, commit, source string) error {
	return install.InstallSkillFromDir(skillDir, dest, name, displayName, version, commit, source)
}

func cmdInit() error {
	cat, err := loadCatalog()
	if err != nil {
		return fmt.Errorf("failed to load catalog: %w", err)
	}

	skill := cat.FindByName(defaultSkillName)
	if skill == nil {
		return fmt.Errorf("skill '%s' not found in catalog", defaultSkillName)
	}

	targetDirs := resolveTargets()
	force := ui.HasFlag("--force")
	dryRun := ui.HasFlag("--dry-run")
	useJSON := ui.HasFlag("--json")

	type result struct {
		Target string `json:"target"`
		Status string `json:"status"`
	}
	var results []result

	for _, target := range targetDirs {
		dest := filepath.Join(target, skill.Name)
		if install.Exists(dest) {
			if !manifest.IsManaged(dest) && !force {
				errMsg := fmt.Sprintf("unmanaged install at %s; use --force to overwrite", dest)
				if useJSON {
					results = append(results, result{Target: dest, Status: "error: " + errMsg})
				} else {
					fmt.Fprintf(os.Stderr, "Error: %s\n", errMsg)
				}
				continue
			}
			if !dryRun {
				os.RemoveAll(dest)
			}
		}
		if !dryRun {
			if err := installFromEmbedded(skill, dest, version, commit, "embedded"); err != nil {
				return err
			}
		}
		if useJSON {
			results = append(results, result{Target: dest, Status: "installed"})
		} else {
			fmt.Printf("Skill '%s' installed to %s\n", skill.Name, dest)
		}
	}

	if dryRun && !useJSON {
		fmt.Println("Dry run — no changes made")
		for _, target := range targetDirs {
			dest := filepath.Join(target, skill.Name)
			fmt.Printf("Would install '%s' to %s\n", skill.Name, dest)
		}
	}

	if useJSON {
		ui.PrintJSON(results)
	}
	return nil
}

func cmdUpdate() error {
	offline := ui.HasFlag("--offline")
	force := ui.HasFlag("--force")
	dryRun := ui.HasFlag("--dry-run")
	useJSON := ui.HasFlag("--json")

	var bundleDir string
	var source string
	var releaseTag string

	if !offline {
		fmt.Println("Fetching latest skill bundle from GitHub...")
		release, err := gh.FetchLatestRelease()
		if err != nil {
			return fmt.Errorf("fetch release: %w", err)
		}
		releaseTag = release.TagName
		source = "github-release:" + releaseTag

		tmpDir, err := os.MkdirTemp("", "composekit-update-*")
		if err != nil {
			return err
		}
		defer os.RemoveAll(tmpDir)

		bundleDir, err = gh.DownloadSkillsBundle(release, tmpDir)
		if err != nil {
			return fmt.Errorf("download skills bundle: %w", err)
		}
		fmt.Printf("Fetched latest skill bundle: %s\n", releaseTag)
	} else {
		source = "embedded"
	}

	targetDirs := resolveTargets()

	type result struct {
		Target string `json:"target"`
		Status string `json:"status"`
	}
	var results []result

	for _, target := range targetDirs {
		dest := filepath.Join(target, defaultSkillName)
		if !install.Exists(dest) {
			errMsg := fmt.Sprintf("not installed at %s; run init first", dest)
			if useJSON {
				results = append(results, result{Target: dest, Status: "error: " + errMsg})
			} else {
				fmt.Fprintf(os.Stderr, "Error: %s\n", errMsg)
			}
			continue
		}
		manifestPath := filepath.Join(dest, manifest.ManifestFile)
		if !install.Exists(manifestPath) && !force {
			errMsg := fmt.Sprintf("manifest missing at %s; use --force to replace unmanaged install", manifestPath)
			if useJSON {
				results = append(results, result{Target: dest, Status: "error: " + errMsg})
			} else {
				fmt.Fprintf(os.Stderr, "Error: %s\n", errMsg)
			}
			continue
		}
		if !dryRun {
			os.RemoveAll(dest)
			if offline {
				cat, err := loadCatalog()
				if err != nil {
					return err
				}
				skill := cat.FindByName(defaultSkillName)
				if skill == nil {
					return fmt.Errorf("skill '%s' not found in catalog", defaultSkillName)
				}
				if err := installFromEmbedded(skill, dest, version, commit, source); err != nil {
					return err
				}
			} else {
				skillDir := filepath.Join(bundleDir, "skills", defaultSkillName)
				if !install.Exists(skillDir) {
					return fmt.Errorf("skill '%s' not found in downloaded bundle at %s", defaultSkillName, skillDir)
				}
				if err := installFromDir(skillDir, dest, defaultSkillName, "Compose Multiplatform", version, commit, source); err != nil {
					return err
				}
			}
		}
		if useJSON {
			results = append(results, result{Target: dest, Status: "updated"})
		} else {
			fmt.Printf("Skill '%s' updated at %s\n", defaultSkillName, dest)
		}
	}

	if useJSON {
		ui.PrintJSON(results)
	}
	return nil
}

func cmdRemove() error {
	targetDirs := resolveTargets()
	force := ui.HasFlag("--force")
	dryRun := ui.HasFlag("--dry-run")
	useJSON := ui.HasFlag("--json")

	type result struct {
		Target string `json:"target"`
		Status string `json:"status"`
	}
	var results []result

	for _, target := range targetDirs {
		dest := filepath.Join(target, defaultSkillName)
		if !install.Exists(dest) {
			if useJSON {
				results = append(results, result{Target: dest, Status: "not_installed"})
			} else {
				fmt.Println("Not installed:", dest)
			}
			continue
		}
		if !manifest.IsManaged(dest) && !force {
			errMsg := fmt.Sprintf("unmanaged install at %s; use --force to remove", dest)
			if useJSON {
				results = append(results, result{Target: dest, Status: "error: " + errMsg})
			} else {
				fmt.Fprintf(os.Stderr, "Error: %s\n", errMsg)
			}
			continue
		}
		if !dryRun {
			if err := os.RemoveAll(dest); err != nil {
				return err
			}
		}
		if useJSON {
			results = append(results, result{Target: dest, Status: "removed"})
		} else {
			fmt.Println("Removed", dest)
		}
	}

	if useJSON {
		ui.PrintJSON(results)
	}
	return nil
}

func cmdDoctor() error {
	useJSON := ui.HasFlag("--json")

	cat, err := loadCatalog()
	if err != nil {
		return fmt.Errorf("failed to load catalog: %w", err)
	}

	skill := cat.FindByName(defaultSkillName)

	var skillRoot string
	if skill != nil {
		skillRoot = skill.Path
	}

	refCount := 0
	if skillRoot != "" {
		files, _ := install.ManagedFiles(embeddedFiles, skillRoot)
		for _, f := range files {
			if strings.HasSuffix(f, ".md") && strings.Contains(f, "references/") {
				refCount++
			}
		}
	}

	targetDirs := resolveTargets()

	type targetStatus struct {
		Path      string `json:"path"`
		Installed bool   `json:"installed"`
		Manifest  bool   `json:"manifest"`
		Managed   bool   `json:"managed"`
	}

	if useJSON {
		type doctorResult struct {
			CLI struct {
				Version string `json:"version"`
				Commit  string `json:"commit"`
				Date    string `json:"date"`
			} `json:"cli"`
			Catalog struct {
				Valid  bool `json:"valid"`
				Skills int  `json:"skills"`
			} `json:"catalog"`
			Payload struct {
				Skill    string `json:"skill"`
				Embedded bool   `json:"embedded"`
				Files    struct {
					SkillMD    bool `json:"SKILL.md"`
					AgentYaml  bool `json:"agents/openai.yaml"`
					References int  `json:"references"`
				} `json:"files"`
			} `json:"payload"`
			Targets []targetStatus `json:"targets"`
		}

		var result doctorResult
		result.CLI.Version = version
		result.CLI.Commit = commit
		result.CLI.Date = date
		result.Catalog.Valid = skill != nil
		if cat != nil {
			result.Catalog.Skills = len(cat.Skills)
		}
		result.Payload.Skill = defaultSkillName
		result.Payload.Embedded = true
		result.Payload.Files.SkillMD = skillRoot != "" && install.ExistsEmbedded(embeddedFiles, skillRoot, "SKILL.md")
		result.Payload.Files.AgentYaml = skillRoot != "" && install.ExistsEmbedded(embeddedFiles, skillRoot, "agents/openai.yaml")
		result.Payload.Files.References = refCount
		for _, target := range targetDirs {
			dest := filepath.Join(target, defaultSkillName)
			result.Targets = append(result.Targets, targetStatus{
				Path:      target,
				Installed: install.Exists(dest),
				Manifest:  install.Exists(filepath.Join(dest, manifest.ManifestFile)),
				Managed:   manifest.IsManaged(dest),
			})
		}
		ui.PrintJSON(result)
		return nil
	}

	fmt.Println("ComposeKit doctor")
	fmt.Println()
	fmt.Println("CLI:")
	fmt.Println("  version:", version)
	fmt.Println("  commit:", commit)
	fmt.Println("  date:", date)
	fmt.Println()
	fmt.Println("Catalog:")
	fmt.Println("  valid:", skill != nil)
	if cat != nil {
		fmt.Println("  skills:", len(cat.Skills))
	}
	fmt.Println()
	fmt.Println("Payload:")
	fmt.Println("  skill:", defaultSkillName)
	fmt.Println("  embedded: yes")
	if skillRoot != "" {
		fmt.Println("  SKILL.md:", yesno(install.ExistsEmbedded(embeddedFiles, skillRoot, "SKILL.md")))
		fmt.Println("  agents/openai.yaml:", yesno(install.ExistsEmbedded(embeddedFiles, skillRoot, "agents/openai.yaml")))
	}
	fmt.Println("  references:", refCount, "files")
	fmt.Println()
	fmt.Println("Targets:")
	for _, target := range targetDirs {
		dest := filepath.Join(target, defaultSkillName)
		fmt.Printf("  %s\n", target)
		fmt.Printf("    installed: %s\n", yesno(install.Exists(dest)))
		fmt.Printf("    manifest: %s\n", yesno(install.Exists(filepath.Join(dest, manifest.ManifestFile))))
		fmt.Printf("    managed: %s\n", yesno(manifest.IsManaged(dest)))
	}
	return nil
}

func cmdSkills(subcommand string) error {
	cat, err := loadCatalog()
	if err != nil {
		return fmt.Errorf("failed to load catalog: %w", err)
	}

	switch subcommand {
	case "list":
		if ui.HasFlag("--long") || ui.HasFlag("-l") {
			targetDirs := resolveTargets()
			statuses := make(map[string][]catalog.InstallStatus)
			for _, s := range cat.Skills {
				var sts []catalog.InstallStatus
				for _, target := range targetDirs {
					dest := filepath.Join(target, s.Name)
					sts = append(sts, catalog.InstallStatus{
						Name:      target,
						Installed: install.Exists(dest),
						Path:      dest,
					})
				}
				statuses[s.Name] = sts
			}
			cat.PrintSkillsLong(statuses)
		} else {
			cat.PrintListShort()
		}

	case "find":
		if len(os.Args) < 4 {
			return fmt.Errorf("usage: composekit skills find <query>")
		}
		query := os.Args[3]
		results := cat.FindByQuery(query)
		cat.PrintFindResults(query, results)

	case "add":
		if len(os.Args) < 4 {
			return fmt.Errorf("usage: composekit skills add <skill>")
		}
		skillToAdd := os.Args[3]
		s := cat.FindByName(skillToAdd)
		if s == nil {
			return fmt.Errorf("skill '%s' not found in catalog", skillToAdd)
		}

		force := ui.HasFlag("--force")
		targetDirs := resolveTargets()
		for _, target := range targetDirs {
			dest := filepath.Join(target, s.Name)
			if install.Exists(dest) {
				if !manifest.IsManaged(dest) && !force {
					return fmt.Errorf("unmanaged install at %s; use --force to overwrite", dest)
				}
				os.RemoveAll(dest)
			}
			if err := installFromEmbedded(s, dest, version, commit, "embedded"); err != nil {
				return err
			}
			fmt.Printf("Skill '%s' installed to %s\n", s.Name, dest)
		}

	case "remove":
		if len(os.Args) < 4 {
			return fmt.Errorf("usage: composekit skills remove <skill>")
		}
		skillToRemove := os.Args[3]
		force := ui.HasFlag("--force")
		targetDirs := resolveTargets()
		for _, target := range targetDirs {
			dest := filepath.Join(target, skillToRemove)
			if !install.Exists(dest) {
				fmt.Println("Not installed:", dest)
				continue
			}
			if !manifest.IsManaged(dest) && !force {
				return fmt.Errorf("unmanaged install at %s; use --force to remove", dest)
			}
			if err := os.RemoveAll(dest); err != nil {
				return err
			}
			fmt.Println("Removed", dest)
		}

	case "installed":
		targetDirs := resolveTargets()
		fmt.Println("Installed skills:")
		for _, target := range targetDirs {
			for _, s := range cat.Skills {
				dest := filepath.Join(target, s.Name)
				if install.Exists(dest) {
					fmt.Printf("  %s at %s\n", s.Name, dest)
				}
			}
		}

	default:
		return fmt.Errorf("unknown skills subcommand: %s", subcommand)
	}
	return nil
}

func cmdTargets(subcommand string) error {
	switch subcommand {
	case "detect":
		results := targets.DetectAll()
		targets.PrintDetect(results)

	case "list":
		cfg := config.Load()
		if len(cfg.Targets) == 0 {
			fmt.Println("No targets configured")
			return nil
		}
		fmt.Println("Configured targets:")
		for _, t := range cfg.Targets {
			dest := filepath.Join(t, defaultSkillName)
			status := "not installed"
			if install.Exists(dest) {
				status = "installed"
			}
			fmt.Printf("  %s (%s)\n", t, status)
		}

	case "add":
		if len(os.Args) < 4 {
			return fmt.Errorf("usage: composekit targets add <dir>")
		}
		dir := os.Args[3]
		abs, err := filepath.Abs(dir)
		if err != nil {
			return err
		}
		cfg := config.Load()
		for _, t := range cfg.Targets {
			if t == abs {
				fmt.Println("Target already exists:", abs)
				return nil
			}
		}
		cfg.Targets = append(cfg.Targets, abs)
		if err := config.Save(cfg); err != nil {
			return err
		}
		fmt.Println("Added target:", abs)

	case "remove":
		if len(os.Args) < 4 {
			return fmt.Errorf("usage: composekit targets remove <dir>")
		}
		dir := os.Args[3]
		abs, err := filepath.Abs(dir)
		if err != nil {
			return err
		}
		cfg := config.Load()
		var updated []string
		found := false
		for _, t := range cfg.Targets {
			if t == abs {
				found = true
				continue
			}
			updated = append(updated, t)
		}
		if !found {
			return fmt.Errorf("target not found: %s", abs)
		}
		cfg.Targets = updated
		if err := config.Save(cfg); err != nil {
			return err
		}
		fmt.Println("Removed target:", abs)

	default:
		return fmt.Errorf("unknown targets subcommand: %s", subcommand)
	}
	return nil
}

func yesno(b bool) string {
	if b {
		return "yes"
	}
	return "no"
}

func help() {
	fmt.Println(strings.TrimSpace(`ComposeKit

A CLI tool to install and manage AI coding skills for Jetpack Compose,
Compose Multiplatform, and Kotlin Multiplatform workflows.

Usage:
  composekit init [--target <dir>] [--agent <names>] [--all-agents] [--force] [--dry-run] [--json]
  composekit update [--target <dir>] [--agent <names>] [--all-agents] [--force] [--dry-run] [--json] [--offline]
  composekit doctor [--target <dir>] [--json]
  composekit remove [--target <dir>] [--agent <names>] [--all-agents] [--force] [--dry-run] [--json]
  composekit version

Skills:
  composekit skills list [--long]
  composekit skills find <query>
  composekit skills add <skill> [--target <dir>] [--agent <names>] [--all-agents] [--force]
  composekit skills remove <skill> [--target <dir>] [--agent <names>] [--all-agents] [--force]
  composekit skills installed

Targets:
  composekit targets detect
  composekit targets list
  composekit targets add <dir>
  composekit targets remove <dir>
`))
}
