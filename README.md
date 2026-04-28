# NervesGrisp

A [Nerves](https://nerves-project.org/) application configured to run on [GRiSP2](https://github.com/nerves-project/nerves_system_grisp2) hardware and connect to [NervesHub](https://www.nerves-hub.org/) for over-the-air firmware updates via `nerves_hub_link`.

## Requirements

- Elixir and Mix installed
- `MIX_TARGET=grisp2` environment variable for hardware builds
- SSH public key in `~/.ssh/` for device access
  - **NOTE**: If you have multiple SSH keys, your client will try them in order and stop after 4 attempts — the device will reject the connection if the right key isn't among the first four tried. To avoid this, either explicitly specify the key with `-i ~/.ssh/your_key` or configure your `~/.ssh/config` to use the correct key for the device's IP/hostname:
> ```
> Host 192.168.1.*
>   IdentityFile ~/.ssh/id_rsa
>   IdentitiesOnly yes
> ```
- GRiSP2 board (for hardware deployment)

## Getting Started

Install dependencies and build firmware:

```sh
mix deps.get
MIX_TARGET=grisp2 mix firmware
```

## Flashing

### First Flash

For the initial flash, follow the [GRiSP2 boot notes](https://github.com/nerves-project/nerves_system_grisp2#boot-notes) to prepare your SD card, then build and upload:

```sh
MIX_TARGET=grisp2 mix firmware
MIX_TARGET=grisp2 mix upload <device-ip-or-hostname>
```

**Example:**
```sh
MIX_TARGET=grisp2 mix upload 192.168.1.231
# or using hostname:
MIX_TARGET=grisp2 mix upload my-grisp2.local
```

### Subsequent Updates

Once the device is running and connected to the network, you can push OTA updates directly through NervesHub or via SSH upload.

## Local Configuration & Secrets

Sensitive configuration (WiFi credentials, SSH keys, NervesHub certs, etc.) should **never** be committed to version control. Instead, use local override files that are gitignored:

| File | Purpose |
|------|---------|
| `config/grisp2.override.exs` | Overrides for GRiSP2 hardware target |
| `config/local.override.exs` | Overrides for running locally (host target) |

These files are loaded at the end of the respective target config and take precedence over defaults.

### grisp2.override.exs — Full Example

```elixir
import Config

keys =
  System.user_home!()
  |> Path.join(".ssh/id_ras.pub")
  |> Path.wildcard()

if keys == [],
  do:
    Mix.raise("""
    No SSH public keys found in ~/.ssh. An ssh authorized key is needed to
    log into the Nerves device and update firmware on it using ssh.
    See your project's config.exs for this error message.
    """)

config :nerves_ssh,
  authorized_keys: Enum.map(keys, &File.read!/1)

config :vintage_net,
  regulatory_domain: "00",
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{method: :dhcp}
     }},
    {"wlan0",
     %{
       type: VintageNetWiFi,
       vintage_net_wifi: %{
         networks: [
           %{
             key_mgmt: :wpa_psk,
             ssid: "YOUR_SSID",       # <-- replace with your WiFi SSID
             psk: "YOUR_PASSWORD"     # <-- replace with your WiFi password
           }
         ]
       },
       ipv4: %{method: :dhcp}
     }}
  ]

# Nerves Hun Link configuration
config :nerves_hub_link,
  client: Gateway.Firmware.NervesHub,
  host: "your-nerves-hub-host:4300",  # <-- replace with your NervesHub host/port
  remote_iex: true,
  connect: true,
  connect_wait_for_network: false,
  configurator: NervesHubLink.Configurator.LocalCertKey,
  ssl: [
    certfile: "/etc/bridge-001.cert.pem",
    keyfile: "/etc/bridge-001.key.pem"
  ]

```

### local.override.exs — Example

Used when running the app on your development machine (host target). Typically you only need to override things that differ from the hardware config, such as disabling hardware-specific interfaces.

```elixir
import Config

# Example: no network config needed for host target
# config :vintage_net, config: []
```

## NervesHub OTA Updates

This project uses [`nerves_hub_link`](https://github.com/nerves-hub/nerves_hub_link) to receive firmware updates from a NervesHub server. Make sure the device certificate and key are provisioned on the device before connecting.

Key configuration options (set in `grisp2.override.exs`):

| Option | Description |
|--------|-------------|
| `host` | NervesHub server hostname and port |
| `remote_iex` | Enables remote IEx shell via NervesHub |
| `connect` | Auto-connect to NervesHub on boot |
| `ssl.certfile` | Path to device certificate on the filesystem |
| `ssl.keyfile` | Path to device private key on the filesystem |

## Useful Links

- [Nerves Project](https://nerves-project.org/)
- [GRiSP2 Nerves System](https://github.com/nerves-project/nerves_system_grisp2)
- [NervesHub](https://www.nerves-hub.org/)
- [nerves_hub_link](https://github.com/nerves-hub/nerves_hub_link)
- [VintageNet](https://github.com/nerves-networking/vintage_net)