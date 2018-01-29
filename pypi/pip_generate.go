package main

import (
	"bufio"
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
)

const workspacePrefix = "pypi_"
const pypiRulesHeader = `# AUTO GENERATED DO NOT EDIT
# Command line: pyrules/pip_generate %s
load("%s", "%s")

def pypi_repositories():` + "\n"

var pipLogLinkPattern = regexp.MustCompile(`^\s*(Found|Skipping) link\s*(http[^ #]+\.whl)`)

var pyPIPlatforms = []struct {
	bazelPlatform string
	// https://www.python.org/dev/peps/pep-0425/
	pyPIPlatform string
}{
	// not quite right: should include version and "intel" but seems unlikely we will find PPC now
	{"osx", "-cp27-cp27m-macosx_10_"},
	{"linux", "-cp27-cp27mu-manylinux1_x86_64."},
}

type ruleTypeGenerator struct {
	libraryRule    string
	wheelAttribute string
	rulePath       string
}

var pyzLibraryGenerator = ruleTypeGenerator{"pyz_library", "wheels",
	"//rules_python_zip:rules_python_zip.bzl"}
var pexLibraryGenerator = ruleTypeGenerator{"pex_library", "eggs",
	"//bazel_rules_pex/pex:pex_rules.bzl"}

type wheelInfo struct {
	url    string
	sha256 string
	deps   []string
	extras map[string][]string
}

func (w *wheelInfo) fileName() string {
	return filepath.Base(w.url)
}
func (w *wheelInfo) bazelPlatform() string {
	return bazelPlatform(w.fileName())
}
func (w *wheelInfo) bazelWorkspaceName() string {
	fileName := w.fileName()
	packageName := fileName[:strings.IndexByte(fileName, '-')]
	name := workspacePrefix + pyPIToBazelPackageName(packageName)
	platform := w.bazelPlatform()
	if platform != "" {
		name += "__" + platform
	}
	return name
}

type wheelsByPlatform []wheelInfo

func (w wheelsByPlatform) Len() int          { return len(w) }
func (w wheelsByPlatform) Swap(i int, j int) { w[i], w[j] = w[j], w[i] }
func (w wheelsByPlatform) Less(i int, j int) bool {
	// platform then file name to resolve ties
	iPlatform := w[i].bazelPlatform()
	jPlatform := w[j].bazelPlatform()
	if iPlatform < jPlatform {
		return true
	}
	if iPlatform > jPlatform {
		return false
	}

	return w[i].fileName() < w[j].fileName()
}

type pyPIDependency struct {
	name   string
	wheels []wheelInfo
}

func (p *pyPIDependency) bazelLibraryName() string {
	return pyPIToBazelPackageName(p.name)
}

func pyPIToBazelPackageName(packageName string) string {
	// PyPI packages can contain upper case characters, but they are matched insensitively:
	// drop the capitalization for Bazel
	packageName = strings.ToLower(packageName)
	// PyPI packages contain -, but the wheel and bazel names convert them to _
	packageName = strings.Replace(packageName, "-", "_", -1)

	// If the package contains an extras suffix of [], replace it with __
	packageName = strings.Replace(packageName, "[", "__", -1)
	packageName = strings.Replace(packageName, "]", "", -1)
	return packageName
}

// Takes a PyPI dependency and returns just the package name part, without extras
func dependencyPackageName(dependency string) string {
	// PyPI packages can contain upper case characters, but are matched insensitively
	dependency = strings.ToLower(dependency)
	// PyPI packages contain -, but the wheel and bazel names convert them to _
	dependency = strings.Replace(dependency, "-", "_", -1)

	extraStart := strings.IndexByte(dependency, '[')
	if extraStart >= 0 {
		return dependency[:extraStart]
	}
	return dependency
}

// Returns the wheel package name and version
func wheelFileParts(filename string) (string, string) {
	parts := strings.SplitN(filename, "-", 3)
	return parts[0], parts[1]
}

func sha256Hex(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	h := sha256.New()
	_, err = io.Copy(h, f)
	err2 := f.Close()
	if err != nil {
		return "", err
	}
	if err2 != nil {
		return "", err2
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

type wheelToolOutput struct {
	Requires []string            `json:"requires"`
	Extras   map[string][]string `json:"extras"`
}

func wheelDependencies(wheelToolPath string, path string) ([]string, map[string][]string, error) {
	start := time.Now()
	wheelToolProcess := exec.Command(wheelToolPath, path)
	wheelToolProcess.Stderr = os.Stderr
	outputBytes, err := wheelToolProcess.Output()
	if err != nil {
		return nil, nil, err
	}
	end := time.Now()
	fmt.Printf("wheeltool %s took %s\n", filepath.Base(path), end.Sub(start).String())
	output := &wheelToolOutput{}
	err = json.Unmarshal(outputBytes, output)
	if err != nil {
		return nil, nil, err
	}
	return output.Requires, output.Extras, nil
}

func bazelPlatform(filename string) string {
	for _, platformDefinition := range pyPIPlatforms {
		if strings.Contains(filename, platformDefinition.pyPIPlatform) {
			return platformDefinition.bazelPlatform
		}
	}
	return ""
}

func download(url string, path string) error {
	f, err := os.OpenFile(path, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer f.Close()

	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return fmt.Errorf("error downloading %s: %s", url, resp.Status)
	}

	_, err = io.Copy(f, resp.Body)
	err2 := resp.Body.Close()
	if err != nil {
		return err
	}
	if err2 != nil {
		return err2
	}
	return f.Close()
}

func renameIfNotExists(oldPath string, newPath string) error {
	_, err := os.Stat(newPath)
	if err == nil {
		// file exists: do nothing
		return nil
	} else if !os.IsNotExist(err) {
		// stat error
		return err
	}
	// rename the file
	return os.Rename(oldPath, newPath)
}

func main() {
	requirements := flag.String("requirements", "", "path to requirements.txt")
	output := flag.String("output", "", "path to write pypi_rules.bzl")
	wheelURLPrefix := flag.String("wheelURLPrefix", "", "prefixes where wheels can be downloaded")
	preferPyPI := flag.Bool("preferPyPI", true, "download from PyPI if possible")
	rulesWorkspace := flag.String("rulesWorkspace", "@com_bluecore_rules_pyz",
		"Bazel Workspace path for rules_python_zip")
	wheelDir := flag.String("wheelDir", "", "Directory to save wheels")
	ruleType := flag.String("rulesType", "pyz", "Type of rules to generate: pyz or pex")
	verbose := flag.Bool("verbose", false, "Log verbose output; log pip output")
	wheelToolPath := flag.String("wheelToolPath", "./wheeltool.py",
		"Path to tool to output requirements from a wheel")
	flag.Parse()
	if *requirements == "" || *output == "" || *wheelURLPrefix == "" {
		fmt.Fprintln(os.Stderr, "Error: -requirements, -output and -wheelURLPrefix are required")
		flag.Usage()
		os.Exit(1)
	}
	if (*wheelURLPrefix)[len(*wheelURLPrefix)-1] != '/' {
		fmt.Fprintln(os.Stderr, "Error: -wheelURLPrefix must end with /")
		os.Exit(1)
	}
	if *ruleType != "pyz" && *ruleType != "pex" {
		fmt.Fprintln(os.Stderr, "Error: -ruleType must be pyz or pex")
		os.Exit(1)
	}
	ruleGenerator := pyzLibraryGenerator
	if *ruleType == "pex" {
		ruleGenerator = pexLibraryGenerator
	}

	if *wheelDir != "" {
		stat, err := os.Stat(*wheelDir)
		if os.IsNotExist(err) {
			fmt.Fprintf(os.Stderr, "Error: -wheelDir='%s' does not exist\n", *wheelDir)
			os.Exit(1)
		} else if err != nil {
			panic(err)
		} else if !stat.IsDir() {
			fmt.Fprintf(os.Stderr, "Error: -wheelDir='%s' is not a directory\n", *wheelDir)
			os.Exit(1)
		}
	}

	rulesPath := *rulesWorkspace + ruleGenerator.rulePath

	outputBzl, err := os.OpenFile(*output, os.O_WRONLY|os.O_TRUNC|os.O_CREATE, 0644)
	if err != nil {
		panic(err)
	}
	defer outputBzl.Close()

	tempdir, err := ioutil.TempDir("", "")
	if err != nil {
		panic(err)
	}
	defer os.RemoveAll(tempdir)

	pipProcess := exec.Command("pip", "wheel", "--verbose", "--disable-pip-version-check",
		"--requirement", *requirements, "--wheel-dir", tempdir)
	stdout, err := pipProcess.StdoutPipe()
	if err != nil {
		panic(err)
	}
	pipProcess.Stderr = os.Stderr
	fmt.Println("running pip to resolve dependencies ...")
	if *verbose {
		fmt.Printf("  command: pip %s\n", strings.Join(pipProcess.Args, " "))
	}
	pipStart := time.Now()
	err = pipProcess.Start()
	if err != nil {
		panic(err)
	}

	wheelFilenameToLink := map[string]string{}
	scanner := bufio.NewScanner(stdout)
	for scanner.Scan() {
		if *verbose {
			os.Stdout.Write(scanner.Bytes())
			os.Stdout.WriteString("\n")
		}
		matches := pipLogLinkPattern.FindSubmatch(scanner.Bytes())
		if len(matches) > 0 {
			link := matches[2]
			lastSlashIndex := bytes.LastIndexByte(link, '/')
			if lastSlashIndex == -1 {
				panic("invalid link: " + string(link))
			}
			filename := string(link[lastSlashIndex+1:])
			wheelFilenameToLink[filename] = string(link)
		}
	}
	if scanner.Err() != nil {
		panic(scanner.Err())
	}
	err = stdout.Close()
	if err != nil {
		panic(err)
	}
	err = pipProcess.Wait()
	if err != nil {
		panic(err)
	}
	pipEnd := time.Now()
	fmt.Printf("pip executed in %v\n", pipEnd.Sub(pipStart).String())

	dirEntries, err := ioutil.ReadDir(tempdir)
	if err != nil {
		panic(err)
	}
	installedPackages := map[string]bool{}
	dependencies := []pyPIDependency{}
	for _, entry := range dirEntries {
		link := wheelFilenameToLink[entry.Name()]
		hasPyPILink := len(link) > 0
		if !*preferPyPI || !hasPyPILink {
			link = *wheelURLPrefix + entry.Name()
			hasPyPILink = false
		}

		wheelPath := tempdir + "/" + entry.Name()
		if *wheelDir != "" && !hasPyPILink {
			// use the existing wheel in wheelDir if it exists; otherwise update it
			// avoids unnecessarily updating dependencies due to possible non-reproducible behaviour
			// in pip or other tools
			destWheelPath := *wheelDir + "/" + entry.Name()
			err = renameIfNotExists(wheelPath, destWheelPath)
			if err != nil {
				panic(err)
			}
			wheelPath = destWheelPath
		}
		// TODO: Refactor this whole mess into another function somewhere
		type wheelFilePartialInfo struct {
			url      string
			filePath string
		}
		wheelFiles := []wheelFilePartialInfo{wheelFilePartialInfo{link, wheelPath}}

		packageName, version := wheelFileParts(entry.Name())

		bazelPlatform := bazelPlatform(entry.Name())
		if bazelPlatform != "" {
			// attempt to find all other platform wheels
			matchedPlatforms := map[string]string{}
			matchPrefix := packageName + "-" + version + "-"
			for wheelFile, link := range wheelFilenameToLink {
				if strings.HasPrefix(wheelFile, matchPrefix) {
					for _, pyPIPlatform := range pyPIPlatforms {
						if pyPIPlatform.bazelPlatform == bazelPlatform {
							continue
						}
						if strings.Contains(wheelFile, pyPIPlatform.pyPIPlatform) {
							if matchedPlatforms[pyPIPlatform.bazelPlatform] != "" {
								panic("found duplicate wheels for platform")
							}
							matchedPlatforms[pyPIPlatform.bazelPlatform] = link
						}
					}
				}
			}
			if len(matchedPlatforms)+1 != len(pyPIPlatforms) {
				fmt.Fprintf(os.Stderr, "WARNING: could not find all platforms for %s; needs compilation?\n",
					entry.Name())
			}

			// download the other platforms and add info for those wheels
			for _, link := range matchedPlatforms {
				// download this PyPI wheel
				filePart := filepath.Base(link)
				destPath := tempdir + "/" + filePart
				// TODO: Skip download if it already exists; combine with below rename check
				err = download(link, destPath)
				if err != nil {
					panic(err)
				}

				if !*preferPyPI && *wheelDir != "" {
					link = *wheelURLPrefix + filePart

					finalPath := *wheelDir + "/" + filePart
					// we do not update the file if it exists, but use finalPath to compute sha256
					err = renameIfNotExists(destPath, finalPath)
					if err != nil {
						panic(err)
					}
					destPath = finalPath
				}
				wheelFiles = append(wheelFiles, wheelFilePartialInfo{link, destPath})
			}
		}

		wheels := []wheelInfo{}
		for _, partialInfo := range wheelFiles {
			shaSum, err := sha256Hex(partialInfo.filePath)
			if err != nil {
				panic(err)
			}

			deps, extras, err := wheelDependencies(*wheelToolPath, partialInfo.filePath)
			if err != nil {
				panic(err)
			}

			wheels = append(wheels, wheelInfo{partialInfo.url, shaSum, deps, extras})
		}

		dependencies = append(dependencies, pyPIDependency{packageName, wheels})
		installedPackages[packageName] = true
	}

	commandLineArguments := strings.Join(os.Args[1:], " ")
	fmt.Fprintf(outputBzl, pypiRulesHeader, commandLineArguments, rulesPath, ruleGenerator.libraryRule)

	for _, dependency := range dependencies {
		sort.Sort(wheelsByPlatform(dependency.wheels))
		for _, wheel := range dependency.wheels {
			fmt.Fprintf(outputBzl, "    native.http_file(\n")
			fmt.Fprintf(outputBzl, "        name=\"%s\",\n", wheel.bazelWorkspaceName())
			fmt.Fprintf(outputBzl, "        url=\"%s\",\n", wheel.url)
			fmt.Fprintf(outputBzl, "        sha256=\"%s\",\n", wheel.sha256)
			fmt.Fprintf(outputBzl, "    )\n")
		}
	}

	fmt.Fprintf(outputBzl, "\ndef pypi_libraries():\n")
	for _, dependency := range dependencies {
		fmt.Fprintf(outputBzl, "    %s(\n", ruleGenerator.libraryRule)
		fmt.Fprintf(outputBzl, "        name=\"%s\",\n", dependency.bazelLibraryName())
		if len(dependency.wheels) == 1 {
			fmt.Fprintf(outputBzl, "        %s=[\"@%s//file\"],\n",
				ruleGenerator.wheelAttribute, dependency.wheels[0].bazelWorkspaceName())
		} else {
			fmt.Fprintf(outputBzl, "        %s=select({\n", ruleGenerator.wheelAttribute)
			for _, wheelInfo := range dependency.wheels {
				selectPlatform := bazelPlatform(wheelInfo.fileName())
				if selectPlatform == "" {
					selectPlatform = "//conditions:default"
				} else {
					selectPlatform = *rulesWorkspace + "//rules_python_zip:" + selectPlatform
				}
				fmt.Fprintf(outputBzl, "                \"%s\": [\"@%s//file\"],\n",
					selectPlatform, wheelInfo.bazelWorkspaceName())
			}
			fmt.Fprintf(outputBzl, "        }),\n")
		}

		fmt.Fprintf(outputBzl, "        deps=[\n")
		for _, dep := range dependency.wheels[0].deps {
			fmt.Fprintf(outputBzl, "            \"%s\",\n", pyPIToBazelPackageName(dep))
		}
		fmt.Fprintf(outputBzl, "        ],\n")
		// Fixes build error TODO: different type? comment that this is not the right license?
		fmt.Fprintf(outputBzl, "        licenses=[\"notice\"],\n")
		fmt.Fprintf(outputBzl, "        visibility=[\"//visibility:public\"],\n")
		fmt.Fprintf(outputBzl, "    )\n")

		// ensure output is reproducible: output extras in the same order
		extraNames := []string{}
		for extraName, _ := range dependency.wheels[0].extras {
			extraNames = append(extraNames, extraName)
		}
		sort.Strings(extraNames)
		// TODO: Refactor common code out of this and the above?
		for _, extraName := range extraNames {
			extraDeps := dependency.wheels[0].extras[extraName]
			// only include the extra if we have all the referenced packages
			hasAllPackages := true
			for _, dep := range extraDeps {
				if !installedPackages[dependencyPackageName(dep)] {
					hasAllPackages = false
					break
				}
			}
			if !hasAllPackages {
				continue
			}

			fmt.Fprintf(outputBzl, "    %s(\n", ruleGenerator.libraryRule)
			fmt.Fprintf(outputBzl, "        name=\"%s__%s\",\n", dependency.bazelLibraryName(), extraName)
			fmt.Fprintf(outputBzl, "        deps=[\n")
			fmt.Fprintf(outputBzl, "            \":%s\",\n", dependency.bazelLibraryName())
			for _, dep := range extraDeps {
				fmt.Fprintf(outputBzl, "            \"%s\",\n", pyPIToBazelPackageName(dep))
			}
			fmt.Fprintf(outputBzl, "        ],\n")
			// fmt.Fprintf(outputBzl, "        # Not the correct license but fixes a build error\n")
			fmt.Fprintf(outputBzl, "        licenses=[\"notice\"],\n")
			fmt.Fprintf(outputBzl, "        visibility=[\"//visibility:public\"],\n")
			fmt.Fprintf(outputBzl, "    )\n")
		}
	}
}
