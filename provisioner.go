package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/hashicorp/terraform/communicator"
	"github.com/hashicorp/terraform/communicator/remote"
	"github.com/hashicorp/terraform/terraform"
	"github.com/mitchellh/go-homedir"
	"github.com/mitchellh/go-linereader"
)

const (
	installURL = "https://github.com/armenr/ansiformer/raw/master/bootstrap_ansible_node.sh"
)

const (
	tmpPath = "/tmp/ansible"
)

const (
	tmpInventory = "/tmp"
)

type Provisioner struct {
	useSudo        bool
	AnsibleVersion string            `mapstructure:"ansible_version"`
	Playbook       string            `mapstructure:"playbook"`
	Plays          []string          `mapstructure:"plays"`
	Hosts          []string          `mapstructure:"hosts"`
	ModulePath     string            `mapstructure:"module_path"`
	GroupVars      []string          `mapstructure:"group_vars"` // group_vars are expected to be under <ModulePath>/group_var/name
	ExtraVars      map[string]string `mapstructure:"extra_vars"`
	InstanceID     string            `mapstructure:"instance_id"`
}

func (p *Provisioner) Run(o terraform.UIOutput, comm communicator.Communicator) error {
	// parse the playbook path and ensure that it is valid before doing
	// anything else. This is done in validate but is repeated here, just
	// in case.
	playbookPath, err := p.resolvePath(p.Playbook)
	if err != nil {
		return err
	}

	prefix := ""
	// Ansible version to be install
	ansible_version := p.AnsibleVersion

	// Check before install ansible, system to be ready
	err = p.runCommand(o, comm, fmt.Sprintf("%sbash -c 'until curl -o /dev/null -sIf %s ; do echo \"Waiting for ansible installURL to be available..\"; ((c++)) && ((c==20)) && break ; sleep 5 ; done'", prefix, installURL))
	if err != nil {
		return err
	}

	// Then execute the bootstrap_ansible_node.sh script to download and install Ansible
	err = p.runCommand(o, comm, fmt.Sprintf("%scurl -L -s -S %s | sudo bash -s -- %s", prefix, installURL, ansible_version))
	if err != nil {
		return err
	}

	// ansible projects are structured such that the playbook file is in
	// the top level of the module path. As such, we parse the playbook
	// path's directory and upload the entire thing
	playbookDir := filepath.Dir(playbookPath)

	// remove stale ansible files from last successful run
	// this lets you make rapid changes & deploys from the branch
	// you're working in
	deleteCommand := fmt.Sprintf("rm -rf /tmp/ansible")

	if _, err := os.Stat(tmpPath); !os.IsExist(err) {
		o.Output(fmt.Sprintf("Removing old playbooks plays with command: %s", deleteCommand))
		if err := p.runCommand(o, comm, deleteCommand); err != nil {
			return err
		}
	}

	// the host playbook path is the path on the host where the playbook
	// will be uploaded too
	remotePlaybookPath := filepath.Join("/tmp/ansible", filepath.Base(playbookPath))

	// upload ansible source and playbook to the host
	if err := comm.UploadDir("/tmp/ansible", playbookDir); err != nil {
		return err
	}

	// extraVars, err := json.Marshal(p.ExtraVars)
	// if err != nil {
	// 	return err
	// }

	command2 := fmt.Sprintf("ansible-playbook -i %s/%s-inventory %s",
		tmpInventory,
		string(p.InstanceID),
		remotePlaybookPath)

	// TODO: Think of ways to make this work better for complex tag scenarios, with inheritance, etc.
	// Will need community feedback on this one.
	o.Output(fmt.Sprintf("Running the following Ansible plays on target host: \n --> Playbook: %s \n --> Plays: %s", remotePlaybookPath, strings.Join(p.Hosts, ", ")))
	if err := p.runCommand(o, comm, command2); err != nil {
		return err
	}

	return nil
}

func (p *Provisioner) Validate() error {
	playbookPath, err := p.resolvePath(p.Playbook)
	if err != nil {
		return err
	}
	p.Playbook = playbookPath

	for _, host := range p.Hosts {
		if host == "" {
			return fmt.Errorf("Invalid hosts parameter. hosts: %s", p.Hosts)
		}
	}

	for _, play := range p.Plays {
		if play == "" {
			return fmt.Errorf("Invalid plays paramter. plays: %s", p.Plays)
		}
	}

	for _, group_vars := range p.GroupVars {
		if group_vars == "" {
			return fmt.Errorf("Invalid group_vars. group_vars: %s", p.GroupVars)
		}
	}

	for _, host := range p.Hosts {
		if host == "" {
			return fmt.Errorf("Invalid host. hosts: %s", p.Hosts)
		}
	}

	// for _, instanceid := range p.Hosts {
	// 	if instanceid == "" {
	// 		return fmt.Errorf("Invalid host. hosts: %s", p.InstanceID)
	// 	}
	// }

	return nil
}

func (p *Provisioner) runCommand(
	o terraform.UIOutput,
	comm communicator.Communicator,
	command string) error {

	var err error
	if p.useSudo {
		command = "sudo " + command
	}

	outR, outW := io.Pipe()
	errR, errW := io.Pipe()
	outDoneCh := make(chan struct{})
	errDoneCh := make(chan struct{})

	go p.copyOutput(o, outR, outDoneCh)
	go p.copyOutput(o, errR, errDoneCh)

	cmd := &remote.Cmd{
		Command: command,
		Stdout:  outW,
		Stderr:  errW,
	}

	if err := comm.Start(cmd); err != nil {
		return fmt.Errorf("Error executing command %q: %v", cmd.Command, err)
	}
	cmd.Wait()
	if cmd.ExitStatus != 0 {
		err = fmt.Errorf(
			"Command %q exited with non-zero exit status: %d", cmd.Command, cmd.ExitStatus)

	}

	outW.Close()
	errW.Close()
	<-outDoneCh
	<-errDoneCh

	return err
}

func (p *Provisioner) copyOutput(o terraform.UIOutput, r io.Reader, doneCh chan<- struct{}) {
	defer close(doneCh)
	lr := linereader.New(r)
	for line := range lr.Ch {
		o.Output(line)
	}
}

func (p *Provisioner) resolvePath(path string) (string, error) {
	expandedPath, _ := homedir.Expand(path)
	if _, err := os.Stat(expandedPath); err == nil {
		return expandedPath, nil
	}

	cwd, err := os.Getwd()
	if err != nil {
		return "", fmt.Errorf("Unable to get current working address to resolve path as a relative path")
	}

	relativePath := filepath.Join(cwd, path)
	if _, err := os.Stat(relativePath); err == nil {
		return relativePath, nil
	}

	return "", fmt.Errorf("Path not valid: [%s]", relativePath)
}
