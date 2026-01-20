import
  std/[unittest, osproc, strutils, os],
  npsh

proc runNpshWithArgs(args: seq[string]): int =
  ## Run npsh with specific arguments and get exit code.
  let npshPath = currentSourcePath().parentDir().parentDir() / "src" / "npsh.nim"
  let configPath = currentSourcePath().parentDir() / "example_npsh"
  # Set NPSH_CONFIG environment variable for the subprocess
  putEnv("NPSH_CONFIG", configPath)
  let cmd = "nim r " & npshPath & " " & args.join(" ")
  let exitCode = execCmd(cmd)
  return exitCode

suite "Argument Parsing Tests":

  test "help option":
    let exitCode = runNpshWithArgs(@["--help"])
    check exitCode == 0

  test "help option short form":
    let exitCode = runNpshWithArgs(@["-h"])
    check exitCode == 0

  test "no arguments shows help":
    let exitCode = runNpshWithArgs(@[])
    check exitCode == 1

  test "dry run option":
    let exitCode = runNpshWithArgs(@["-d", "-a", "true"])
    check exitCode == 0

  test "dry run with prefix":
    let exitCode = runNpshWithArgs(@["-d", "-p", "-a", "ls"])
    check exitCode == 0

  test "dry run with stdin":
    let exitCode = runNpshWithArgs(@["-d", "-i", "-a", "cat"])
    check exitCode == 0

  test "test mode":
    let exitCode = runNpshWithArgs(@["-d", "-a", "--test"])
    check exitCode == 0

  test "invalid option":
    let exitCode = runNpshWithArgs(@["--invalid-option"])
    check exitCode == 1

  test "missing hosts with -a not specified":
    let exitCode = runNpshWithArgs(@["ls", "-la"])
    check exitCode == 1

  test "missing command":
    let exitCode = runNpshWithArgs(@["-a"])
    check exitCode == 1

  test "missing command with test mode":
    let exitCode = runNpshWithArgs(@["-d", "-a", "--test"])
    check exitCode == 0  # Test mode doesn't require command

  test "option ordering - options before hosts":
    let exitCode = runNpshWithArgs(@["-d", "-a", "true"])
    check exitCode == 0

  test "option ordering - options after hosts":
    let exitCode = runNpshWithArgs(@["-a", "-d", "true"])
    check exitCode == 0

  test "complex command with multiple arguments":
    let exitCode = runNpshWithArgs(@["-d", "-a", "ls", "-la", "/tmp"])
    check exitCode == 0

  test "host specification parsing":
    let exitCode = runNpshWithArgs(@["-d", "0", "uptime"])
    check exitCode == 0

  test "multiple options combination":
    let exitCode = runNpshWithArgs(@["-d", "-p", "-a", "--test"])
    check exitCode == 0
