# Zizmor

[Zizmor](http://docs.zizmor.sh/) is a static analysis tool for GitHub Actions.
Its purpose is to find common security issues and code smells in actions, workflows, and Dependabot configurations files.

This repository uses Zizmor as a GitHub Action, located at [.github/workflows/zizmor.yml](/.github/workflows/zizmor.yml).

## Running Locally

Zizmor can be run locally to verify changes to the GitHub configuration files that it covers.
To get started, [install the tool](https://docs.zizmor.sh/installation/) for your operating system.
Once installed and added to your `PATH`, Zizmor can be run locally from the command line.

To run Zizmor from the command line with the same settings as this repository's GitHub Actions, run the following from the repo root:
```console
$ zizmor --persona=auditor .
```

This runs Zizmor with the auditor [persona](https://docs.zizmor.sh/usage/#using-personas), which is the strictest validation sets.

## Resolving Flagged Items

Zizmor will flag items with a severity level, audit rule name, and location in the code:
```
info[anonymous-definition]: workflow or action definition without a name
  --> screens/.github/workflows/deploy-ecs.yml:43:3
   |
43 |   refresh:
   |   ^^^^^^^ this job
   |
   = note: audit confidence → High
   = tip: use 'name: ...' to give this job a name
```

Zizmor displays the audit rule name ("anonymous-definition" in the example above) OSC 8 hyperlinks.
Clicking the rule name will open your browser to the specific audit violation, which includes an explanation of the audit and often includes remediation instructions.
In the event your terminal does not support OSC 8 hyperlinks, the `--show-audit-urls=always` flag can be added to your local Zizmor command.
