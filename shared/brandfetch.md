# Fetching a logo from Brandfetch

Read when `~/.claude/shared/AGENTS.md` §0 sends you here. The API key is in the macOS Keychain
(service `brandfetch`, account `api-key`). Read it into a shell variable and use it in the same
command, so it never shows in output, a file, a commit or a memory note:

```bash
K=$(security find-generic-password -s brandfetch -a api-key -w)
curl -s -H "Authorization: Bearer $K" "https://api.brandfetch.io/v2/brands/<domain>"
```

The reply lists each logo with its type, theme and download links. Download the one that suits
the background and look at the file before using it. If the key reads back empty or the API
answers 401, say so in one line and ask the user to store it again from the Terminal app with
`security add-generic-password -U -s brandfetch -a api-key -w`; the `!` prefix cannot take typed
input and stores an empty value.

Done is a logo that came from Brandfetch and a key that was never shown.
