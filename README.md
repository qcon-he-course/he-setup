# he-setup

Setup for Week 1 of the InfoQ Certified AI-Assisted Engineering Program. Please do it before the first session. Most of the time goes to downloads.

When you have finished, run the check in step 7 and paste its summary into the Slack thread.

## Supported machines

- macOS 13 or later, Apple Silicon or Intel.
- Linux. The steps are written for Ubuntu and Debian; other distributions work with their own package manager.
- Windows 10 or 11 with WSL 2. Install Ubuntu with `wsl --install` in PowerShell, then do every step below in the Ubuntu terminal, including installing your coding agent. Keep the course files in your Linux home folder (`~/course`). Folders under `/mnt/c` are slow from WSL.

Native Windows, in PowerShell or CMD, isn't supported.

You need at least 8 GB of memory and 5 GB of free disk space.

## 1. Base tools

macOS: install the command-line developer tools, which include git, and [Homebrew](https://brew.sh) if you don't have it.

```bash
xcode-select --install
```

Ubuntu, Debian and WSL:

```bash
sudo apt-get update
sudo apt-get install -y git curl
```

## 2. JDK 17

Both course projects build with Java 17.

macOS:

```bash
brew install --cask temurin@17
```

Ubuntu, Debian and WSL:

```bash
sudo apt-get install -y openjdk-17-jdk
```

If you use SDKMAN, install any Temurin 17 from `sdk list java` instead.

Then check that 17 is the version your terminal uses:

```bash
java -version
```

If it shows another version, make 17 the default. On macOS, add `export JAVA_HOME=$(/usr/libexec/java_home -v 17)` to `~/.zshrc` and open a new terminal. On Ubuntu, run `sudo update-alternatives --config java` and pick 17.

## 3. A coding agent

Install Claude Code or Codex, and sign in. Start the agent for the first time in your home folder, not in the course folders.

**Claude Code** needs a Pro, Max, Team, Enterprise or Console account. The free plan doesn't include it.

```bash
curl -fsSL https://claude.ai/install.sh | bash
claude                # sign in, then /exit
claude setup-token    # prints a token
```

Keep the token somewhere safe. You'll need it in the session. Don't post it in Slack. On macOS, `brew install --cask claude-code` also works. Other options are in the [Claude Code setup guide](https://code.claude.com/docs/en/setup).

**Codex** needs a ChatGPT plan that includes Codex, or an OpenAI API key.

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
codex                 # choose "Sign in with ChatGPT", or use an API key
```

`npm install -g @openai/codex` also works. See the [Codex CLI guide](https://learn.chatgpt.com/docs/codex/cli).

## 4. Clone the course repositories

Use exactly these paths. The handouts and slides refer to them.

```bash
mkdir -p ~/course
git clone https://github.com/qcon-he-course/he-setup.git ~/course/he-setup
git clone https://github.com/qcon-he-course/he-tollgate.git ~/course/tollgate
git clone https://github.com/qcon-he-course/he-petclinic.git ~/course/petclinic
```

## 5. Build Tollgate once

```bash
cd ~/course/tollgate
./mvnw -B -DskipTests verify
```

This downloads Maven and the project's dependencies, then compiles the code. It should end with `BUILD SUCCESS`. Doing it now means the first exercise in class doesn't wait on downloads. The tests are skipped here; they take several minutes, and they come later in the course.

## 6. Don't open the course repositories in a coding agent yet

Both repositories are set up for exercises we do together in class. Opening them in an agent before the session, or asking an agent about them, spoils those exercises. Building Tollgate in step 5 is fine.

## 7. Run the check

```bash
bash ~/course/he-setup/check.sh
```

It prints one line per check, then a summary block. Paste the summary block into the Slack thread.

The check changes nothing on your machine. It reads tool versions, the two repositories and Tollgate's build output, and makes one request to each download site the course uses. It doesn't print keys, tokens or environment variables, and it shows your home folder as `~`. It can't tell whether your agent is signed in, so make sure you completed step 3.

## If a check fails

Post the summary and the error in the thread, and we'll help. The most common causes:

| Check                              | Likely cause                                      | What to do                                                       |
|------------------------------------|---------------------------------------------------|------------------------------------------------------------------|
| `java` warns about a newer version | 17 is installed but isn't the default             | Step 2, last paragraph                                           |
| `java` fails                       | No JDK, or on macOS the system stub without a JDK | Step 2                                                           |
| `build` fails                      | Step 5 hasn't run, or it stopped with an error    | Run step 5 and post the last lines of its output                 |
| `maven-central` or `pypi` fails    | A company proxy or firewall                       | Try another network, or ask your IT team about a proxy for Maven |
| `platform` fails on WSL 1          | The distribution runs on WSL 1                    | In PowerShell: `wsl --set-version Ubuntu 2`                      |

If something can't be fixed before the session, come anyway. You can follow the hands-on parts by watching.

## After each session

| Week | Homework | Also |
|---|---|---|
| 1 | [homework/week1.md](homework/week1.md) | [notes/week1.md](notes/week1.md): the ideas, text to copy and further reading |
| 2 | [homework/week2.md](homework/week2.md) | [skills/](skills/): the three skills from class. [week-2/](week-2/README.md): the class experiments, to run yourself |

## Updates

More files will appear in this repository before the session. To get them:

```bash
git -C ~/course/he-setup pull
```
