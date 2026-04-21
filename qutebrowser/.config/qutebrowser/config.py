# qutebrowser config
# Load autoconfig.yml so settings changed via :set are preserved
config.load_autoconfig(True)

# Widevine is auto-detected by Qt 6 WebEngine from
# /opt/google/chrome/WidevineCdm/ (installed via the AUR google-chrome
# package).
#
# Force software video decoding: Qt WebEngine's HW video decoder conflicts
# with Widevine's protected-content path on Linux and causes the screen to
# flash / go blank when a DRM video starts (Udemy, Netflix, etc.).
c.qt.args = [
    "disable-accelerated-video-decode",
    "disable-features=UseChromeOSDirectVideoDecoder",
]

# Google blocks qutebrowser's default User-Agent on sign-in pages
# ("No puedes acceder / this browser or app may not be secure").
# Spoof a recent Chrome UA on Google domains so sign-in works.
config.set(
    "content.headers.user_agent",
    "Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} "
    "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/{webkit_version}",
    "https://accounts.google.com/*",
)
config.set(
    "content.headers.user_agent",
    "Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} "
    "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/{webkit_version}",
    "https://*.google.com/*",
)

c.auto_save.session = True
c.session.lazy_restore = True

# ---------------------------------------------------------------------------
# Dark theme for web content.
# 1. Sites that ship their own dark mode (ChatGPT, GitHub, X, …) will serve
#    the dark variant because we advertise prefers-color-scheme: dark.
# 2. Sites without a native dark theme are inverted by Chromium's built-in
#    forced-dark. We keep images/videos untouched (`images = never`) so
#    YouTube/Udemy/Netflix keep rendering correctly.
# ---------------------------------------------------------------------------
c.colors.webpage.preferred_color_scheme = "dark"
c.colors.webpage.bg = "#181a1b"

c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = "lightness-cielab"
c.colors.webpage.darkmode.policy.images = "never"
c.colors.webpage.darkmode.policy.page = "smart"
c.colors.webpage.darkmode.contrast = 0.0
c.colors.webpage.darkmode.threshold.background = 205
c.colors.webpage.darkmode.threshold.foreground = 150

# Silently block third-party resources with invalid / expired certificates
# (e.g. the expired img.devrant.com image embedded on random pages) instead
# of popping up a blocking prompt on every page. The main page's cert is
# still validated and will prompt normally if it's broken.
c.content.tls.certificate_errors = "ask-block-thirdparty"

# Tab navigation: Alt+l = next tab, Alt+h = previous tab.
# (H / L are left to their defaults: back / forward in browser history.)
config.bind("<Alt-l>", "tab-next")
config.bind("<Alt-h>", "tab-prev")

# Dark Reader (greasemonkey/darkreader.user.js):
#   ,d  -> toggle on the current page
#   ,D  -> force-disable on the current page
#   ,a  -> follow system color scheme
config.bind(
    ",d",
    "jseval --world=main --quiet window.__qbDarkReader && window.__qbDarkReader.toggle()",
)
config.bind(
    ",D",
    "jseval --world=main --quiet window.__qbDarkReader && window.__qbDarkReader.disable()",
)
config.bind(
    ",a",
    "jseval --world=main --quiet window.__qbDarkReader && window.__qbDarkReader.auto()",
)
