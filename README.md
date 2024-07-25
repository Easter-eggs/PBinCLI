[![Gitlab license](https://img.shields.io/gitlab/license/ee/ee-paste-cli.svg?gitlab_url=https://gitlab.easter-eggs.com)](https://gitlab.easter-eggs.com/ee/ee-paste-cli/blob/master/LICENSE)
[![Gitlab tag](https://img.shields.io/gitlab/v/tag/ee/ee-paste-cli.svg?gitlab_url=https://gitlab.easter-eggs.com)](https://gitlab.easter-eggs.com/ee/ee-paste-cli/tags/)

# Ee Paste CLI

Ee Paste CLI is a command line client [PrivateBin](https://github.com/PrivateBin/PrivateBin/) written in Python 3,
defaulty configured to use [Easter-eggs instance](https://paste.easter-eggs.com). It's based on [PBinCLI](https://github.com/r4sas/PBinCLI).

# Installation

Installing globally using pip3:
```bash
python3 -m pip install -U git+https://gitlab.easter-eggs.com/ee/ee-paste-cli.git@ee
```

Installing with `virtualenv`:
```bash
python3 -m virtualenv --python=python3 venv
. venv/bin/activate
python3 -m pip install -U git+https://gitlab.easter-eggs.com/ee/ee-paste-cli.git@ee
```

*Note*: if you used `virtualenv` installation method, don't forget to activate your virtual environment before running the tool: call `. /path/to/venv/bin/activate` in terminal

# Configuration

By default ee-paste-cli is configured to use `https://paste.easter-eggs.com/` for sending and receiving pastes. No proxy is used by default.

You can always create a config file to use different settings.

Configuration file is expected to be found in `~/.config/ee-paste/ee-paste.conf`, `%APPDATA%/ee-paste/ee-paste.conf` (Windows) and `~/Library/Application Support/ee-paste/ee-paste.conf` (MacOS)

## Example of config file content

```ini
server=https://paste.easter-eggs.com/
proxy=http://127.0.0.1:3128
```

## List of OPTIONS available

| Option               | Default                 | Possible value |
|----------------------|-------------------------|----------------|
| server               | https://paste.easter-eggs.com/ | Domain ending with slash |
| mirrors              | None                    | Domains separated with comma, like `http://privatebin.ygg/,http://privatebin.i2p/` |
| proxy                | None                    | Proxy address starting with scheme `http://` or `socks5://` |
| expire               | 1day                    | 5min / 10min / 1hour / 1day / 1week / 1month / 1year / never |
| burn                 | False                   | True / False |
| discus               | False                   | True / False |
| format               | plaintext               | plaintext / syntaxhighlighting / markdown |
| short                | False                   | True / False |
| short_api            | None                    | `tinyurl`, `clckru`, `isgd`, `vgd`, `cuttly`, `yourls`, `custom` |
| short_url            | None                    | Domain name of shortener service for `yourls`, or URL (with required parameters) for `custom` |
| short_user           | None                    | Used only in `yourls` |
| short_pass           | None                    | Used only in `yourls` |
| short_token          | None                    | Used only in `yourls` |
| output               | None                    | Path to the directory where the received data will be saved |
| no_check_certificate | False                   | True / False |
| no_insecure_warning  | False                   | True / False |
| compression          | zlib                    | zlib / none |
| auth                 | None                    | `basic`, `custom` |
| auth_user            | None                    | Basic authorization username |
| auth_pass            | None                    | Basic authorization password |
| auth_custom          | None                    | Custom authorization headers in JSON format, like `{'Authorization': 'Bearer token'}` |

# Usage

EePasteCLI tool is started with `ee-paste` command. Detailed help on command usage is provided with `-h` option:
```bash
ee-paste {send|get|delete} -h
```

## Sending

* Sending text:
```bash
ee-paste send -t "Hello! This is a test paste!"
```

* Using stdin input to read text into a paste:
```bash
ee-paste send - <<EOF
Hello! This is a test paste!
EOF
```

* Sending a file with text attached into a paste:
```bash
ee-paste send -f info.pdf -t "I'm sending my document."
```

* Sending a file only with no text attached:
```bash
ee-paste send -q -f info.pdf
```

### Other options

It is also possible to set-up paste parameters such as "burn after reading", expiritaion time, formatting, enabling discussions and changing compression algorithm. Please refer to `ee-paste send -h` output for more information.

## Receiving

To retrieve a paste from a server, you need to use `get` command with the paste info.

Paste info must be formated as `pasteID#Passphrase` or just use full URL to a paste. Example:
```bash
ee-paste get "xxx#yyy"                        ### receive paste xxx from https://paste.easter-eggs.com/ by default
ee-paste get "https://example.com/?xxx#yyy"   ### receive paste xxx from https://example.com/
```

## Deletion

To delete a paste from a server, use `delete` command with paste info:
```bash
ee-paste delete "pasteid=xxx&deletetoken=yyy"                        ### delete paste xxx from https://paste.easter-eggs.com/ by default
ee-paste delete "https://example.com/?pasteid=xxx&deletetoken=yyy"   ### delete paste xxx from https://example.com/
```

If you need to delete a paste on different server than the configured one, use `-s` option together with the instance URL.

# Additional examples

Here you can find additional examples.

## Usage with I2P enabled services

Change settings to set server to `http://privatebin.i2p/` and proxy to `http://127.0.0.1:4444`. Configuration file for this example is:
```ini
server=http://privatebin.i2p/
proxy=http://127.0.0.1:4444
```

## Using aliases

Example of alias to send a paste from `stdin` direclty to I2P service:
```bash
alias pastei2p="echo 'paste the text to stdin' && ee-paste send -s http://privatebin.i2p/ -x http://127.0.0.1:4444 -"
```

Call it by running `pastei2p` in terminal.

# License

This project is licensed under the MIT license, which can be found in the file [LICENSE](https://gitlab.easter-eggs.com/ee/ee-paste-cli/blob/master/LICENSE) in the root of the project source code.
