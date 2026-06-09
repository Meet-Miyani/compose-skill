package github

import (
	"archive/tar"
	"compress/gzip"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

type ReleaseAsset struct {
	Name string `json:"name"`
	URL  string `json:"browser_download_url"`
}

type GitHubRelease struct {
	TagName string         `json:"tag_name"`
	Assets  []ReleaseAsset `json:"assets"`
}

func Repo() string {
	if v := os.Getenv("COMPOSEKIT_REPO"); v != "" {
		return v
	}
	return "Meet-Miyani/composekit"
}

func FetchLatestRelease() (*GitHubRelease, error) {
	apiURL := fmt.Sprintf("https://api.github.com/repos/%s/releases/latest", Repo())
	resp, err := http.Get(apiURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("GitHub API returned %d", resp.StatusCode)
	}
	var release GitHubRelease
	if err := json.NewDecoder(resp.Body).Decode(&release); err != nil {
		return nil, err
	}
	return &release, nil
}

func FindAsset(release *GitHubRelease, pattern string) *ReleaseAsset {
	for _, a := range release.Assets {
		if strings.Contains(a.Name, pattern) {
			return &a
		}
	}
	return nil
}

func DownloadFile(url, destination string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return fmt.Errorf("download returned %d for %s", resp.StatusCode, url)
	}
	if err := os.MkdirAll(filepath.Dir(destination), 0755); err != nil {
		return err
	}
	out, err := os.Create(destination)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, resp.Body)
	return err
}

func VerifyChecksum(filePath, expectedHex string) error {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}
	sum := fmt.Sprintf("%x", sha256.Sum256(data))
	if sum != expectedHex {
		return fmt.Errorf("checksum mismatch: expected %s, got %s", expectedHex, sum)
	}
	return nil
}

func ParseChecksums(checksumsPath string) (map[string]string, error) {
	data, err := os.ReadFile(checksumsPath)
	if err != nil {
		return nil, err
	}
	result := make(map[string]string)
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		parts := strings.Fields(line)
		if len(parts) >= 2 {
			result[parts[1]] = parts[0]
		}
	}
	return result, nil
}

func ExtractTarGz(archivePath, destDir string) error {
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return err
	}
	f, err := os.Open(archivePath)
	if err != nil {
		return err
	}
	defer f.Close()

	gzr, err := gzip.NewReader(f)
	if err != nil {
		return err
	}
	defer gzr.Close()

	tr := tar.NewReader(gzr)
	for {
		header, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		target := filepath.Join(destDir, header.Name)
		switch header.Typeflag {
		case tar.TypeDir:
			if err := os.MkdirAll(target, 0755); err != nil {
				return err
			}
		case tar.TypeReg:
			if err := os.MkdirAll(filepath.Dir(target), 0755); err != nil {
				return err
			}
			out, err := os.Create(target)
			if err != nil {
				return err
			}
			if _, err := io.Copy(out, tr); err != nil {
				out.Close()
				return err
			}
			out.Close()
		}
	}
	return nil
}

func DownloadSkillsBundle(release *GitHubRelease, tmpDir string) (string, error) {
	bundlePattern := fmt.Sprintf("composekit-skills_%s.tar.gz", release.TagName)
	asset := FindAsset(release, bundlePattern)
	if asset == nil {
		bundlePattern = "composekit-skills_"
		asset = FindAsset(release, bundlePattern)
	}
	if asset == nil {
		return "", fmt.Errorf("no skills bundle found in release %s", release.TagName)
	}

	archivePath := filepath.Join(tmpDir, asset.Name)
	if err := DownloadFile(asset.URL, archivePath); err != nil {
		return "", fmt.Errorf("download skills bundle: %w", err)
	}

	checksumsAsset := FindAsset(release, "checksums.txt")
	if checksumsAsset != nil {
		checksumsPath := filepath.Join(tmpDir, "checksums.txt")
		if err := DownloadFile(checksumsAsset.URL, checksumsPath); err != nil {
			return "", fmt.Errorf("download checksums: %w", err)
		}
		checksums, err := ParseChecksums(checksumsPath)
		if err != nil {
			return "", fmt.Errorf("parse checksums: %w", err)
		}
		if expectedHex, ok := checksums[asset.Name]; ok {
			if err := VerifyChecksum(archivePath, expectedHex); err != nil {
				return "", fmt.Errorf("checksum verification: %w", err)
			}
		}
	}

	extractDir := filepath.Join(tmpDir, "skills-bundle")
	if err := ExtractTarGz(archivePath, extractDir); err != nil {
		return "", fmt.Errorf("extract skills bundle: %w", err)
	}

	return extractDir, nil
}
