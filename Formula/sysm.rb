# typed: false
# frozen_string_literal: true

# Homebrew formula for sysm - unified CLI for Apple ecosystem on macOS
class Sysm < Formula
  desc "Unified CLI for Apple ecosystem integration on macOS"
  homepage "https://github.com/brndnsvr/sysm"
  url "https://github.com/brndnsvr/sysm/archive/v1.0.0.tar.gz"
  sha256 "" # Will be filled in during release
  license "MIT"
  head "https://github.com/brndnsvr/sysm.git", branch: "main"

  depends_on xcode: ["15.0", :build]
  depends_on :macos => :ventura

  def install
    # Generate version file
    system "#{buildpath}/scripts/generate-version.sh"

    # Build release binary
    system "swift", "build", "-c", "release", "--disable-sandbox"

    # Install binary
    bin.install ".build/release/sysm"

    # Generate shell completions
    output = Utils.safe_popen_read(bin/"sysm", "--generate-completion-script", "bash")
    (bash_completion/"sysm").write output

    output = Utils.safe_popen_read(bin/"sysm", "--generate-completion-script", "zsh")
    (zsh_completion/"_sysm").write output

    output = Utils.safe_popen_read(bin/"sysm", "--generate-completion-script", "fish")
    (fish_completion/"sysm.fish").write output
  end

  test do
    # Test version output
    assert_match version.to_s, shell_output("#{bin}/sysm --version")

    # Test basic help
    assert_match "unified CLI for Apple ecosystem", shell_output("#{bin}/sysm --help")

    # Test calendar command existence (won't run without permissions)
    assert_match "calendar", shell_output("#{bin}/sysm --help")
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

      Or use the permission checker:
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/brndnsvr/sysm/main/scripts/check-permissions.sh)"

      Documentation: https://brndnsvr.github.io/sysm/documentation/sysmcore
      Troubleshooting: https://github.com/brndnsvr/sysm/blob/main/docs/guides/troubleshooting.md
    EOS
  end
end
