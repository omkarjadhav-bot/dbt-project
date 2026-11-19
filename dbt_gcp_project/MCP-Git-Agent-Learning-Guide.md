# Learning Guide: MCP, GitHub, BigQuery, and a Git Operations Agent

This guide explains the integrations discussed for this workspace, the setup that was actually verified, and sample configurations for learning. The samples are examples; they do not prove that a service is configured or authenticated on this machine.

## 1. The concepts: Git, GitHub, MCP, and agents

- **Git** is version control running locally. It tracks file changes and branches.
- **GitHub** hosts remote Git repositories and provides APIs for issues, pull requests, and repository information.
- **MCP (Model Context Protocol)** is a standard way for an AI client to call tools exposed by an MCP server.
- **An MCP server** is a program or remote service that exposes tools. For example, a filesystem server exposes file operations; a GitHub server exposes GitHub API operations.
- **A custom agent** is a Markdown instruction file that gives Copilot a role and a tool allow-list. It is not itself an MCP server and does not create authentication.

A useful picture:

```text
Copilot Chat / AI client
  ├─ reads custom agent instructions
  ├─ calls local Git through terminal tools
  └─ calls MCP server tools
       ├─ filesystem server → files
       ├─ GitHub MCP → GitHub API
       └─ BigQuery MCP → Google BigQuery API
```

Git commands such as `git add`, `git commit`, and `git push` do not require MCP. GitHub MCP is for API-level interactions; it does not automatically upload a local project.

## 2. What is currently configured in this workspace

The file [`.vscode/mcp.json`](.vscode/mcp.json) currently configures only a local filesystem server named `project-files`. It runs with `npx` and is limited to the `dbt_gcp_project` directory. It does **not** contain GitHub or BigQuery MCP entries.

The Git Operations custom agent is at the repository root in [`../.github/agents/git-operations.agent.md`](../.github/agents/git-operations.agent.md). It can use `execute`, `read`, and `search` tools (as supported by the selected Copilot host) and contains workflow and safety instructions.

At the last local check, the repository was on `feature-bhagya`, had no commits, and had no Git remote configured. Since there was no first commit, the new branch had no committed history to branch from yet. A Git Credential Manager helper was configured, but that alone does not confirm valid GitHub credentials. Local `user.name`/`user.email` are commit attribution, not proof of authentication.

Earlier in the conversation, GitHub MCP tools returned an authenticated account and repository search results in that assistant session. This is separate from the workspace `mcp.json`; the tools could have been supplied by the host rather than the project config.

## 3. How VS Code starts an MCP server

A VS Code workspace MCP config is JSON with a `servers` object. Each entry describes how the client connects to a server:

- `command` and `args` launch a local process using stdio, or
- `type` and `url` connect to a remote HTTP MCP endpoint.

Saving the config and starting a server only means the MCP process/connection started. It does not necessarily mean the service accepted the user’s credentials or that an API call is authorized. Verify by invoking a read-only tool and checking its result.

### Existing filesystem example

This is the shape currently used (the path is specific to this computer):

```json
{
  "servers": {
    "project-files": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "D:\\bhagya\\dbt-practice\\dbt_gcp_project"
      ]
    }
  }
}
```

Because this is a local process, Node.js/npm/npx must be installed. The filesystem server is not a GitHub or BigQuery connection.

## 4. GitHub MCP: remote service sample

GitHub provides a hosted MCP endpoint. A typical VS Code entry looks like:

```json
{
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    }
  }
}
```

If you retain the existing filesystem server, keep it under the same `servers` object and add `github` as a sibling; do not replace the complete JSON with only one entry unless that is intended.

Typical setup and verification:

1. In VS Code, use the MCP Registry/gallery or add the remote server configuration supported by your VS Code version.
2. Start the server and use its **Authenticate/Auth** action if available. A browser OAuth flow is preferable to manually pasting a token.
3. Sign in with the intended GitHub account in the browser and approve the requested access.
4. Check the MCP server tools list.
5. Test a read-only operation such as listing repositories or reading a repository file.

**Important:** the server showing as running proves the connection process started, not that it is authorized as a particular GitHub user. OAuth may re-use an existing browser session. VS Code account sign-in, Git HTTPS credentials, and GitHub MCP OAuth are separate authentication contexts and may need to be switched separately.

Official setup guide: [GitHub MCP Server in VS Code](https://docs.github.com/en/copilot/how-tos/copilot-in-your-ide/customize-copilot/extend-copilot-with-tools-and-context/set-up-the-github-mcp-server).

## 5. BigQuery MCP: example with Google MCP Toolbox

BigQuery MCP is separate from dbt. dbt connects to BigQuery using its own profile, while an MCP server uses its own settings and Google credentials. Google’s MCP Toolbox offers a BigQuery prebuilt server.

Example VS Code entry, alongside other entries under `servers`:

```json
{
  "servers": {
    "bigquery": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@toolbox-sdk/server",
        "--prebuilt",
        "bigquery",
        "--stdio"
      ],
      "env": {
        "BIGQUERY_PROJECT": "YOUR_GCP_PROJECT_ID",
        "BIGQUERY_LOCATION": "US",
        "BIGQUERY_READONLY": "true"
      }
    }
  }
}
```

Replace `YOUR_GCP_PROJECT_ID` with a project you are authorized to use. Do not put passwords, service-account keys, or access tokens in `mcp.json`.

Typical prerequisites and test:

1. Install Node.js (which includes npm/npx).
2. Have a Google Cloud account and project with BigQuery API enabled.
3. Authenticate using Google Application Default Credentials, for example:
   ```powershell
   gcloud auth application-default login
   ```
4. Ensure the account has the needed BigQuery IAM permissions for metadata and query jobs.
5. Start the MCP server in VS Code and make a read-only metadata request, such as listing datasets or tables.

`BIGQUERY_READONLY` asks the server to restrict writes; it does not guarantee every query is free. Billing and permissions are controlled by Google Cloud. In this user's earlier dbt run, `int_orders_incremental` specifically failed because BigQuery said billing was not enabled and DML was blocked. A BigQuery MCP connection cannot bypass that restriction.

Official Toolbox BigQuery guide: [BigQuery MCP Toolbox](https://github.com/googleapis/mcp-toolbox/blob/main/docs/BIGQUERY_README.md).

## 6. The Git Operations custom agent

A custom agent is a Markdown file with YAML frontmatter followed by instructions. For this repo it lives at:

```text
D:\bhagya\dbt-practice\.github\agents\git-operations.agent.md
```

Simplified example:

```markdown
---
name: Git Operations
description: "Use for local Git status, diffs, branches, commits, remotes, and Git troubleshooting."
tools:
  - execute
  - read
  - search
---

You are a careful Git workflow agent.

Before acting, inspect the repository root and status. Review exact files and diffs before staging or committing. Never expose credentials. Ask for explicit approval immediately before pushing or destructive/history-rewriting operations. After each state-changing operation, verify the result.
```

What each part means:

- `name`: the label shown in the agent picker.
- `description`: helps users (and agent routing) understand when to choose it.
- `tools`: limits which Copilot tools this agent may use. `execute` is needed for local Git commands; tool aliases supported depend on the Copilot harness/version.
- Markdown body: operating guidance and safety expectations.

The instructions are guidance, **not a security boundary**. Review terminal commands and VS Code permission prompts. Never give an agent credentials or approve a command you do not understand.

### Use the agent

1. Open the repository/workspace folder `D:\bhagya\dbt-practice` in VS Code. Workspace agents are discovered in the opened workspace’s `.github\agents` folder.
2. Use Copilot Chat with the Copilot harness.
3. If missing, run **Developer: Reload Window**, then open the agent picker. **Chat: Open Customizations** can help confirm which agent files VS Code discovered.
4. Select **Git Operations**.
5. Start with a safe prompt:
   > Check my Git status, branch, and remotes. Explain the result; do not change anything.
6. For a state-changing request, be specific about the intended branch/files/message. Review what the agent reports. The agent must ask before pushing or destructive actions.

## 7. Local Git workflow example

Run commands from the repository root (`D:\bhagya\dbt-practice`):

```powershell
# Inspect the repository
git rev-parse --show-toplevel
git status --short --branch
git branch --list
git remote -v

# Stage only reviewed files
git add path\to\file.sql
git diff --cached --check
git diff --cached --name-only

# Save a local checkpoint
git commit -m "Describe the change"

# Read-only check of a configured remote (does not push)
git ls-remote origin
```

A standard GitHub workflow after a remote is configured is:

```text
edit → inspect diff → stage selected files → commit locally → explicitly approve push → push to GitHub
```

For this workspace, no remote was configured at the last inspection, so `git ls-remote origin` will not work until a real remote is added. Do not invent a URL: create or select the correct GitHub repository first. Review `.gitignore` and files carefully before any initial commit; the prior status showed a root `logs/` directory, which the nested dbt `.gitignore` does not ignore.

## 8. Authentication checklist: identify which connection you mean

| Goal | Authentication/connection to check |
|---|---|
| Make a local Git commit | `user.name` and `user.email` set the commit author; no GitHub login is needed |
| Push/pull over HTTPS | Git Credential Manager or browser sign-in, tested safely against an existing remote |
| Use GitHub MCP | MCP server authorization/OAuth and GitHub API permissions |
| Use BigQuery MCP | Google ADC credentials, IAM permissions, project/API setup; billing may be required for query operations |
| Sign in to Copilot in VS Code | VS Code Accounts/Copilot sign-in; not necessarily the same credential used by Git or MCP |

Never print credential-helper contents, put secrets in `mcp.json`, or commit credential files. If changing accounts, use the specific connection's sign-out/re-auth process; signing out of VS Code does not always clear Git Credential Manager or MCP OAuth.

## 9. Official references

- [VS Code custom agents](https://code.visualstudio.com/docs/agents/custom-agents)
- [VS Code custom agent file reference](https://code.visualstudio.com/docs/agents/reference/custom-agent-file-reference)
- [GitHub MCP setup](https://docs.github.com/en/copilot/how-tos/copilot-in-your-ide/customize-copilot/extend-copilot-with-tools-and-context/set-up-the-github-mcp-server)
- [Google MCP Toolbox BigQuery guide](https://github.com/googleapis/mcp-toolbox/blob/main/docs/BIGQUERY_README.md)
