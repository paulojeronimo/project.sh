# project.sh

Reusable project script bootstrap.

## Install in a repository

```sh
curl -SsL https://paulojeronimo.com/project.sh/install | sh
```

This copies `scripts/` and creates:

```sh
project.sh -> scripts/project.sh
```

## Local customization (recommended)

Do not edit `scripts/common.sh` directly.

Use a local extension file instead:

- `scripts/common.local.sh`

`scripts/common.sh` will source this file automatically when present.

For project-specific modules, keep core modules in:

- `scripts/project/modules.conf`

and put local modules in:

- `scripts/project/modules.local.conf`

## Self-update behavior

`./project.sh self-update` reinstalls scripts from `PROJECT_SH_ORIGIN_INSTALL`.

- `scripts/common.sh` is updated from upstream.
- local project logic should live in `scripts/common.local.sh`.
