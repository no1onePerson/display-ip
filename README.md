# Display IP

A quiet, Apple-inspired connection dashboard. Built with native HTML, CSS, JavaScript, and Node.js. No third-party dependencies, tracking, or stored IP history.

## Develop

Requires Node.js 22 or newer. No dependency installation is needed.

```sh
npm run dev
```

The server listens on port 3000. Set `PORT` to override it. Use `npm start` for normal startup and `npm test` for integration validation.

## Address accuracy

The dashboard displays the IP observed on the server socket. Local development displays a loopback/local address. Behind a reverse proxy it displays the proxy address; it intentionally does not trust caller-controlled forwarding headers. It does not claim to discover the device's public IP, geolocation, or ISP. No external APIs or credentials are required.

See [DESIGN.md](DESIGN.md) for the visual direction.
