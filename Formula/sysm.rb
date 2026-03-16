# typed: false
# frozen_string_literal: true

# Homebrew formula for sysm - unified CLI for Apple ecosystem on macOS
class Sysm < Formula
  desc "Unified CLI for Apple ecosystem integration on macOS"
  homepage "https://github.com/brndnsvr/sysm"
  version "1.12.1"
  url "https://github.com/brndnsvr/sysm/releases/download/v1.12.1/sysm-1.12.1-macos-arm64.tar.gz"
  sha256 "045d6253267654a41cc4f3f10f9efe4630263616017d791cbe58937f846afd94"
  license "MIT"

  depends_on :macos
  depends_on arch: :arm64

  resource "claude-skill" do
    url "https://github.com/brndnsvr/sysm/releases/download/v1.12.1/sysm.skill"
    sha256 "1d672103aa88be95d7a1ac12d77d61425786ce7c0c927fd7f8fddb2f6e78ac5c"
  end

  def install
    bin.install "sysm"
    generate_completions_from_executable(bin/"sysm", "--generate-completion-script")
    share("sysm").install resource("claude-skill") => "sysm.skill"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sysm --version").strip
  end

  def caveats
    <<~EOS
      sysm requires macOS privacy permissions to function properly.

      Framework-based services (require explicit permission):
        • Calendars  - System Settings > Privacy & Security > Calendars
        • Reminders  - System Settings > Privacy & Security > Reminders
        • Contacts   - System Settings > Privacy & Security > Contacts
        • Photos     - System Settings > Privacy & Security > Photos

      AppleScript-based services (prompt on first use):
        • Mail, Notes, Messages, Music, Safari
        • System Settings > Privacy & Security > Automation

      Run this to check permissions:
        #{HOMEBREW_PREFIX}/bin/sysm focus status

      Claude Code skill:
        To give Claude Code knowledge of sysm commands, install the bundled skill:
          unzip -o #{share}/sysm/sysm.skill -d ~/.claude/skills/

      Documentation: https://github.com/brndnsvr/sysm
    EOS
  end
end
