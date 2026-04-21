# Nim Parallel Shell (npsh)

A parallel shell implementation in Nim that allows you to execute commands on multiple remote hosts via SSH simultaneously.

## Features

- Execute commands on multiple hosts in parallel using thread pools
- Support for hostnames and node IDs with automatic/manual ID assignment
- Configurable host settings (IP addresses, ports, usernames, custom node IDs)
- Output prefixing for easy identification with aligned formatting
- Dry-run mode for testing command execution
- SSH connectivity testing
- Stdin streaming and piping (single host only)
- Real-time output streaming from all hosts simultaneously
- Custom configuration file path via NPSH_CONFIG environment variable

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
- `-p, --prefix`: Prefix output with host names (aligned formatting)
- `-d, --dry-run`: Show what would be executed without running
- `-i, --stdin`: Read from stdin and pipe to remote command (single host only)
- `--test`: Test SSH connectivity by running 'true' command
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

# Pipe script content to bash on a single host
echo 'echo "Hello from remote host"' | npsh -i host1 bash

# Stream stdin to a remote command
npsh -i host1 cat
```

## Configuration

npsh reads host configuration from `~/.npsh` file by default. You can override this by setting the `NPSH_CONFIG` environment variable to point to a different configuration file.

### Configuration File Format

The config file contains one host per line with the following format:

```
hostname [key=value] [key=value] ...
```

Available keys:
- `ip=address`: IP address to use for SSH (defaults to hostname if not specified)
- `port=number`: SSH port (defaults to 22)
- `username=name`: SSH username (defaults to current user)
- `node=id`: Manual node ID assignment (auto-assigned sequentially if not specified, starting from 0)

Node IDs can be assigned manually to maintain consistent host numbering, or left unspecified for automatic sequential assignment. Manual node IDs take precedence over auto-assignment.

### Example Configuration

```
# ~/.npsh
high-steel ip=10.11.2.14
solution-nine ip=10.11.2.16 port=2222
web-server username=deploy node=10
gpu-node-01 node=20
gpu-node-02 node=21
```

### Custom Configuration File

You can use a custom configuration file by setting the `NPSH_CONFIG` environment variable:

```bash
export NPSH_CONFIG=/path/to/my/npsh-config
npsh -a uptime
```

## Execution Architecture

npsh uses Nim's thread pool to execute commands concurrently across multiple hosts. Each host gets its own thread for command execution, allowing true parallel execution rather than sequential processing.

### Output Streaming

- Commands output is streamed in real-time from all hosts simultaneously
- When using `-p/--prefix`, output from each host is prefixed with the hostname and aligned for easy reading
- Exit codes are collected from all hosts, with the overall exit code indicating success (0) only if all host commands succeeded

### Stdin Handling

The `-i/--stdin` option enables advanced stdin handling:
- **Streaming**: Reads from stdin incrementally and pipes to the remote command
- **Threaded**: Uses a separate thread to avoid blocking the main execution
- **Single-host only**: --stdin Currently restricted to one host (TODO implement multiple hosts? when would we want this?)

## SSH Setup Assumptions

npsh makes the following assumptions about your SSH setup:

1. **Current User**: If no username is specified in the config, npsh assumes SSH should connect as the current user
2. **Host Key Accepted**: SSH host keys for all configured hosts must already be accepted (in `~/.ssh/known_hosts`)
3. **Public Key Authentication**: SSH public key authentication must be set up on all remote hosts
4. **No Password Authentication**: npsh does not support password-based authentication - only public key authentication is supported
5. **SSH Options**: Uses `BatchMode=yes` to prevent interactive prompts, and supports custom ports via `-p` option

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

- [ ] add arbitrary tags like cpu count, memory amount, gpu count, gpu types, etc
- [x] npsh should preserve the CWD of the local shell
  - npsh will assume similar folder structure (likely nfs mounted, syncthing, or similar) on the remote hosts
  - add a cwd flag to allow the user to specify the CWD on the remote host
- [ ] `-s` sequential mode, run command on hosts one at a time
- [ ] `-I {file}` `-O {file}` `-E {file}` redirect stdin, stdout, and stderr to on the remote host.

## License

MIT License
