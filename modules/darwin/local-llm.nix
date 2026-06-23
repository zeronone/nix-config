{ ... }:
{
  # Framework for running local LLMs.
  #
  # Ollama is installed via the Homebrew cask (rather than the nixpkgs package)
  # because nix-darwin has no `services.ollama` launchd module. The cask ships
  # the full menu-bar app with a background launch agent, so the local server
  # (OpenAI-compatible API on http://localhost:11434) starts automatically and
  # Metal acceleration on Apple Silicon works out of the box.
  homebrew.casks = [ "ollama" ];
}
