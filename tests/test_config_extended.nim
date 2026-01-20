import
  std/[unittest, os],
  npsh,
  npsh/config

suite "Extended Config Tests":

  test "assignNodeIds with no explicit IDs":
    var hosts = @[
      newHost("web1"),
      newHost("web2"),
      newHost("db1")
    ]
    assignNodeIds(hosts)
    check hosts[0].nodeId == 0
    check hosts[1].nodeId == 1
    check hosts[2].nodeId == 2

  test "assignNodeIds respecting explicit IDs":
    var hosts = @[
      newHost("web1", nodeId=5),
      newHost("web2"),
      newHost("db1", nodeId=10),
      newHost("cache1")
    ]
    assignNodeIds(hosts)
    check hosts[0].nodeId == 5
    check hosts[1].nodeId == 0  # Gets next available
    check hosts[2].nodeId == 10
    check hosts[3].nodeId == 1  # Gets next available after 0

  test "assignNodeIds with gaps":
    var hosts = @[
      newHost("web1", nodeId=0),
      newHost("web2", nodeId=5),
      newHost("db1")
    ]
    assignNodeIds(hosts)
    check hosts[0].nodeId == 0
    check hosts[1].nodeId == 5
    check hosts[2].nodeId == 1  # Fills gap at 1

  test "assignNodeIds all explicit":
    var hosts = @[
      newHost("web1", nodeId=10),
      newHost("web2", nodeId=20),
      newHost("db1", nodeId=30)
    ]
    assignNodeIds(hosts)
    check hosts[0].nodeId == 10
    check hosts[1].nodeId == 20
    check hosts[2].nodeId == 30

  test "loadConfig with empty file":
    # Create a temporary empty config file
    let tempFile = "tests/empty_config.tmp"
    writeFile(tempFile, "")
    defer: removeFile(tempFile)

    let hosts = loadConfig(tempFile)
    check hosts.len == 0

  test "loadConfig with comments":
    let tempFile = "tests/comment_config.tmp"
    let content = """
# This is a comment
web1 ip=192.168.1.1
# Another comment
web2 ip=192.168.1.2 port=2222
# End comment
"""
    writeFile(tempFile, content)
    defer: removeFile(tempFile)

    let hosts = loadConfig(tempFile)
    check hosts.len == 2
    check hosts[0].hostname == "web1"
    check hosts[0].ip == "192.168.1.1"
    check hosts[1].hostname == "web2"
    check hosts[1].ip == "192.168.1.2"
    check hosts[1].port == 2222

  test "loadConfig with blank lines":
    let tempFile = "tests/blank_config.tmp"
    let content = """

web1

web2 ip=192.168.1.2

"""
    writeFile(tempFile, content)
    defer: removeFile(tempFile)

    let hosts = loadConfig(tempFile)
    check hosts.len == 2
    check hosts[0].hostname == "web1"
    check hosts[1].hostname == "web2"

  test "parseHostLine with invalid port":
    # Test that parseHostLine throws exception for invalid port
    expect(ValueError):
      discard parseHostLine("badhost port=invalid")

  test "parseHostLine with key-value as hostname":
    # parseHostLine should reject malformed input where hostname looks like a key=value pair
    let host = parseHostLine("port=2222")
    check host == nil  # Should return nil for invalid hostname

  test "parseHostLine rejects hostname with equals":
    # Any hostname containing '=' should be rejected
    check parseHostLine("ip=192.168.1.1") == nil
    check parseHostLine("port=22") == nil
    check parseHostLine("username=admin") == nil
    check parseHostLine("bad=host") == nil

  test "parseHostLine with minimal valid config":
    let host = parseHostLine("minimal")
    check host != nil
    check host.hostname == "minimal"
    check host.ip == ""
    check host.port == 22
    check host.username == ""
    check host.nodeId == -1
