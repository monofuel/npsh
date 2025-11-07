# Nim Parallel Shell (npsh)

A parallel shell implementation in Nim that allows you to execute commands on multiple remote hosts via SSH simultaneously.

## Features

- Execute commands on multiple hosts in parallel
- Support for hostnames and node IDs
- Configurable host settings (IP addresses, ports, usernames)
- Output prefixing for easy identification
- Dry-run mode for testing
- SSH connectivity testing

## Usage

### Basic Usage

```bash
# Run command on specific hosts
npsh host1,host2 uptime

# Run command on all configured hosts
npsh -a uptime

# Run command on hosts by node ID
npsh 0,1 ls -la

# Test SSH connectivity
npsh -a --test
```

### Command Line Options

- `-a, --all`: Run command on all configured hosts
- `-p, --prefix`: Prefix output with host names
- `-d, --dry-run`: Show what would be executed without running
- `--test`: Test SSH connectivity by running 'true'
- `-h, --help`: Show help message

### Examples

```bash
# Run 'ls -la' on node 0
npsh 0 ls -la

# Check uptime on specific hosts with prefixed output
npsh high-steel,solution-nine -p uptime

# Run 'df -h' on all hosts
npsh -a df -h

# Test connectivity to all hosts
npsh -a --test

# Dry run to see what would be executed
npsh 0,1 -d ls
```

## Configuration

npsh reads host configuration from `~/.npsh` file.

### Configuration File Format

The config file contains one host per line with the following format:

```
hostname [key=value] [key=value] ...
```

Available keys:
- `ip=address`: IP address to use (defaults to hostname if not specified)
- `port=number`: SSH port (defaults to 22)
- `username=name`: SSH username (defaults to current user)
- `node=id`: Manual node ID assignment (auto-assigned based on line number if not specified, starting from 0)

### Example Configuration

```
# ~/.npsh
high-steel ip=10.11.2.14
solution-nine ip=10.11.2.16 port=2222
web-server username=deploy node=10
```

## SSH Setup Assumptions

npsh makes the following assumptions about your SSH setup:

1. **Current User**: If no username is specified in the config, npsh assumes SSH should connect as the current user
2. **Host Key Accepted**: SSH host keys for all configured hosts must already be accepted (in `~/.ssh/known_hosts`)
3. **Public Key Authentication**: SSH public key authentication must be set up on all remote hosts
4. **No Password Authentication**: npsh does not support password-based authentication - only public key authentication is supported

### SSH Setup

Before using npsh, ensure:

1. Generate SSH key pair (if not already done):
   ```bash
   ssh-keygen -t ed25519
   ```

2. Copy public key to remote hosts:
   ```bash
   ssh-copy-id user@hostname
   ```

3. Accept host keys:
   ```bash
   ssh-keyscan hostname >> ~/.ssh/known_hosts
   ```

## TODO

- [ ] npsh should preserve the CWD of the local shell
  - npsh will assume similar folder structure (likely nfs mounted, syncthing, or similar) on the remote hosts
  - add a cwd flag to allow the user to specify the CWD on the remote host
- [ ] `-s` sequential mode, run command on hosts one at a time
- [ ] `-I {file}` `-O {file}` `-E {file}` redirect stdin, stdout, and stderr to on the remote host.

## License

MIT License
