package install

import (
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"

	"github.com/Meet-Miyani/composekit/internal/manifest"
)

func CopyPayload(efs fs.FS, payloadRoot, dest string) error {
	if err := os.MkdirAll(dest, 0755); err != nil {
		return err
	}
	return fs.WalkDir(efs, payloadRoot, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(payloadRoot, path)
		if err != nil {
			return err
		}
		if rel == "." {
			return nil
		}
		out := filepath.Join(dest, rel)
		if d.IsDir() {
			return os.MkdirAll(out, 0755)
		}
		data, err := fs.ReadFile(efs, path)
		if err != nil {
			return err
		}
		return os.WriteFile(out, data, 0644)
	})
}

func CopyDir(srcDir, dest string) error {
	if err := os.MkdirAll(dest, 0755); err != nil {
		return err
	}
	return filepath.WalkDir(srcDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(srcDir, path)
		if err != nil {
			return err
		}
		if rel == "." {
			return nil
		}
		out := filepath.Join(dest, rel)
		if d.IsDir() {
			return os.MkdirAll(out, 0755)
		}
		src, err := os.Open(path)
		if err != nil {
			return err
		}
		defer src.Close()
		outFile, err := os.Create(out)
		if err != nil {
			return err
		}
		defer outFile.Close()
		_, err = io.Copy(outFile, src)
		return err
	})
}

func ManagedFiles(efs fs.FS, payloadRoot string) ([]string, error) {
	var files []string
	err := fs.WalkDir(efs, payloadRoot, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		rel, err := filepath.Rel(payloadRoot, path)
		if err != nil {
			return err
		}
		files = append(files, filepath.ToSlash(rel))
		return nil
	})
	return files, err
}

func ManagedFilesFromDir(srcDir string) ([]string, error) {
	var files []string
	err := filepath.WalkDir(srcDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		rel, err := filepath.Rel(srcDir, path)
		if err != nil {
			return err
		}
		files = append(files, filepath.ToSlash(rel))
		return nil
	})
	return files, err
}

func ExistsEmbedded(efs fs.FS, payloadRoot, rel string) bool {
	_, err := efs.Open(filepath.ToSlash(filepath.Join(payloadRoot, rel)))
	return err == nil
}

func Exists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func InstallSkill(efs fs.FS, skillRoot, dest, name, displayName, cliVersion, gitCommit, source string) error {
	if err := CopyPayload(efs, skillRoot, dest); err != nil {
		return err
	}
	files, err := ManagedFiles(efs, skillRoot)
	if err != nil {
		return err
	}
	return manifest.Write(dest, name, displayName, cliVersion, gitCommit, source, files)
}

func InstallSkillFromDir(srcDir, dest, name, displayName, cliVersion, gitCommit, source string) error {
	if err := CopyDir(srcDir, dest); err != nil {
		return err
	}
	files, err := ManagedFilesFromDir(srcDir)
	if err != nil {
		return err
	}
	return manifest.Write(dest, name, displayName, cliVersion, gitCommit, source, files)
}

func RemoveSkill(dest string) error {
	if !Exists(dest) {
		return fmt.Errorf("not installed at %s", dest)
	}
	if !manifest.IsManaged(dest) {
		return fmt.Errorf("unmanaged install at %s; use --force to remove", dest)
	}
	return os.RemoveAll(dest)
}
