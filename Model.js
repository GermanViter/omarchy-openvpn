function parseConnections(raw) {
  var rows = []
  var lines = String(raw || "").split("\n")

  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (!line) continue

    var parts = line.split(":")
    if (parts.length < 3 || parts[parts.length - 1] !== "vpn") continue

    var uuid = parts[parts.length - 2]
    var name = parts.slice(0, parts.length - 2).join(":")
    if (!name || !uuid) continue
    rows.push({ name: name, uuid: uuid, active: false })
  }

  return rows
}

function markActive(connections, raw) {
  var activeUuids = {}
  var lines = String(raw || "").split("\n")

  for (var i = 0; i < lines.length; i++) {
    var parts = lines[i].trim().split(":")
    if (parts.length >= 2 && parts[parts.length - 1] === "vpn")
      activeUuids[parts[parts.length - 2]] = true
  }

  var result = []
  for (var j = 0; j < connections.length; j++) {
    var connection = connections[j]
    result.push({
      name: connection.name,
      uuid: connection.uuid,
      active: !!activeUuids[connection.uuid]
    })
  }
  return result
}

function activeCount(connections) {
  var count = 0
  for (var i = 0; i < connections.length; i++)
    if (connections[i].active) count++
  return count
}

if (typeof module !== "undefined") {
  module.exports = {
    parseConnections: parseConnections,
    markActive: markActive,
    activeCount: activeCount
  }
}
