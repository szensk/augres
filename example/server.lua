local server = http.server(80)
server.send(sha256("secretkey"))
