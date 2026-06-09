package catalog

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"strings"

	"github.com/Meet-Miyani/composekit/internal/targets"
)

type SkillEntry struct {
	Name        string   `json:"name"`
	Path        string   `json:"path"`
	DisplayName string   `json:"displayName"`
	Description string   `json:"description"`
	Keywords    []string `json:"keywords"`
}

type Catalog struct {
	SchemaVersion int           `json:"schemaVersion"`
	Skills        []SkillEntry `json:"skills"`
}

func Load(efs fs.FS, path string) (*Catalog, error) {
	data, err := fs.ReadFile(efs, path)
	if err != nil {
		return nil, err
	}
	var c Catalog
	if err := json.Unmarshal(data, &c); err != nil {
		return nil, err
	}
	return &c, nil
}

func (c *Catalog) FindByQuery(query string) []SkillEntry {
	q := strings.ToLower(query)
	var results []SkillEntry
	for _, s := range c.Skills {
		if strings.Contains(strings.ToLower(s.Name), q) {
			results = append(results, s)
			continue
		}
		if strings.Contains(strings.ToLower(s.DisplayName), q) {
			results = append(results, s)
			continue
		}
		if strings.Contains(strings.ToLower(s.Description), q) {
			results = append(results, s)
			continue
		}
		for _, kw := range s.Keywords {
			if strings.Contains(strings.ToLower(kw), q) {
				results = append(results, s)
				break
			}
		}
	}
	return results
}

func (c *Catalog) FindByName(name string) *SkillEntry {
	for _, s := range c.Skills {
		if s.Name == name {
			return &s
		}
	}
	return nil
}

type InstallStatus struct {
	Name      string `json:"name"`
	Installed bool   `json:"installed"`
	Path      string `json:"path"`
}

func (c *Catalog) PrintListShort() {
	fmt.Println("Available skills:")
	fmt.Println()
	for _, s := range c.Skills {
		fmt.Printf("  %s\n", s.Name)
	}
}

func (c *Catalog) PrintSkillsLong(statuses map[string][]InstallStatus) {
	for _, s := range c.Skills {
		fmt.Printf("%s\n", s.Name)
		fmt.Printf("  Display name: %s\n", s.DisplayName)
		fmt.Printf("  Description: %s\n", s.Description)
		fmt.Printf("  Keywords: %s\n", strings.Join(s.Keywords, ", "))
		fmt.Println("  Installed:")
		if sts, ok := statuses[s.Name]; ok {
			for _, st := range sts {
				inst := "no"
				if st.Installed {
					inst = "yes"
				}
				agentName := targets.AgentNameForPath(st.Name)
				fmt.Printf("    %-12s %-4s %s\n", agentName, inst, st.Path)
			}
		}
		fmt.Println()
	}
}

func (c *Catalog) PrintFindResults(query string, results []SkillEntry) {
	if len(results) == 0 {
		fmt.Printf("No skills found matching '%s'\n", query)
		return
	}
	for _, s := range results {
		fmt.Printf("%s\n", s.Name)
		fmt.Printf("  %s\n", s.DisplayName)
		q := strings.ToLower(query)
		if strings.Contains(strings.ToLower(s.Name), q) {
			fmt.Printf("  Matched: name\n")
		} else if strings.Contains(strings.ToLower(s.DisplayName), q) {
			fmt.Printf("  Matched: display name\n")
		} else if strings.Contains(strings.ToLower(s.Description), q) {
			fmt.Printf("  Matched: description\n")
		} else {
			for _, kw := range s.Keywords {
				if strings.Contains(strings.ToLower(kw), q) {
					fmt.Printf("  Matched: keyword %s\n", kw)
					break
				}
			}
		}
	}
}
