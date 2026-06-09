package targets

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type AgentTarget struct {
	Name       string
	SkillDir   string
	DetectPath string
}

var KnownAgentTargets = []AgentTarget{
	{Name: "antigravity", SkillDir: ".gemini/antigravity/skills", DetectPath: ".gemini/antigravity"},
	{Name: "claude", SkillDir: ".claude/skills", DetectPath: ".claude"},
	{Name: "codex", SkillDir: ".codex/skills", DetectPath: ".codex"},
	{Name: "cursor", SkillDir: ".cursor/skills", DetectPath: ".cursor"},
	{Name: "firebender", SkillDir: ".firebender/skills", DetectPath: ".firebender"},
	{Name: "gemini", SkillDir: ".gemini/skills", DetectPath: ".gemini"},
	{Name: "opencode", SkillDir: ".config/opencode/skills", DetectPath: ".config/opencode"},
}

func HomeDir() string {
	if v := os.Getenv("COMPOSEKIT_HOME"); v != "" {
		return v
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "."
	}
	return home
}

func ExpandHome(path string) string {
	if strings.HasPrefix(path, "~/") {
		return filepath.Join(HomeDir(), path[2:])
	}
	return path
}

func AgentSkillDir(t AgentTarget) string {
	return filepath.Join(HomeDir(), t.SkillDir)
}

func Detect() []AgentTarget {
	var detected []AgentTarget
	for _, t := range KnownAgentTargets {
		p := ExpandHome(filepath.Join("~", t.DetectPath))
		if _, err := os.Stat(p); err == nil {
			detected = append(detected, t)
		}
	}
	return detected
}

func ResolveTargets(agents []string, allAgents bool, customTargets []string) []string {
	var dirs []string
	seen := make(map[string]bool)

	if allAgents {
		for _, t := range KnownAgentTargets {
			d := AgentSkillDir(t)
			if !seen[d] {
				dirs = append(dirs, d)
				seen[d] = true
			}
		}
	}

	if len(agents) > 0 {
		agentSet := make(map[string]bool)
		for _, a := range agents {
			agentSet[strings.ToLower(strings.TrimSpace(a))] = true
		}
		for _, t := range KnownAgentTargets {
			if agentSet[t.Name] {
				d := AgentSkillDir(t)
				if !seen[d] {
					dirs = append(dirs, d)
					seen[d] = true
				}
			}
		}
	}

	if len(agents) == 0 && !allAgents {
		detected := Detect()
		for _, t := range detected {
			d := AgentSkillDir(t)
			if !seen[d] {
				dirs = append(dirs, d)
				seen[d] = true
			}
		}
	}

	for _, t := range customTargets {
		if !seen[t] {
			dirs = append(dirs, t)
			seen[t] = true
		}
	}

	return dirs
}

func DefaultTargets() []string {
	return []string{
		filepath.Join(HomeDir(), ".gemini/antigravity/skills"),
		filepath.Join(HomeDir(), ".gemini/skills"),
	}
}

type DetectResult struct {
	Name   string `json:"name"`
	Path   string `json:"path"`
	Exists bool   `json:"exists"`
}

func DetectAll() []DetectResult {
	var results []DetectResult
	for _, t := range KnownAgentTargets {
		p := ExpandHome(filepath.Join("~", t.DetectPath))
		_, err := os.Stat(p)
		results = append(results, DetectResult{
			Name:   t.Name,
			Path:   AgentSkillDir(t),
			Exists: err == nil,
		})
	}
	sort.Slice(results, func(i, j int) bool {
		return results[i].Name < results[j].Name
	})
	return results
}

func AgentNameForPath(path string) string {
	for _, t := range KnownAgentTargets {
		expected := AgentSkillDir(t)
		if expected == path {
			return t.Name
		}
	}
	return filepath.Base(path)
}

func PrintDetect(results []DetectResult) {
	fmt.Println("Detected agent targets:")
	fmt.Println()
	for _, r := range results {
		if r.Exists {
			fmt.Printf("  %-12s %s\n", r.Name, r.Path)
		}
	}
	fmt.Println()
	fmt.Println("Not detected:")
	fmt.Println()
	for _, r := range results {
		if !r.Exists {
			fmt.Printf("  %-12s %s\n", r.Name, r.Path)
		}
	}
}
