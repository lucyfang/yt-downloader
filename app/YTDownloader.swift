import Cocoa
import WebKit

let appVersion = "1.2"

// MARK: - Preferences

let defaultFolder = NSHomeDirectory() + "/Downloads"
let prefsPath     = NSHomeDirectory() + "/.ytdownloader_prefs.json"

func loadFolder() -> String {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: prefsPath)),
          let obj  = try? JSONSerialization.jsonObject(with: data) as? [String: String],
          let path = obj["folder"] else { return defaultFolder }
    return path
}

func saveFolder(_ path: String) {
    if let data = try? JSONSerialization.data(withJSONObject: ["folder": path]) {
        try? data.write(to: URL(fileURLWithPath: prefsPath))
    }
}

// MARK: - HTML
// Raw string (#"""..."""#) so \n inside JS string literals is preserved literally
// and doesn't become a real newline that would break JS syntax.

let HTML = #"""
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>YT Downloader</title>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;700&display=swap" rel="stylesheet">
<style>
@font-face {
  font-family: 'Milling';
  font-weight: 400;
  src: url('https://d2n8i6crd2t3p1.cloudfront.net/font/milling/205TF-Milling-Duplex1mm.woff2') format('woff2');
}
@font-face {
  font-family: 'Milling';
  font-weight: 700;
  src: url('https://d2n8i6crd2t3p1.cloudfront.net/font/milling/205TF-Milling-Triplex1mm.woff2') format('woff2');
}
*, *::before, *::after { box-sizing: border-box; }
h1,h2,h3,h4,h5,h6,p,ul,ol,li { margin: 0; padding: 0; }
body {
  margin: 0;
  background: #F4F3F3;
  font-family: 'Milling', 'Helvetica Neue', sans-serif;
  color: #1D1C1B;
  -webkit-user-select: none;
  user-select: none;
}
.header { background: #1D1C1B; display: flex; flex-direction: column; }
.header-row {
  display: flex; align-items: center; gap: 10px;
  padding: 14px 20px;
}
.header-title { color: #F4F3F3; font-size: 14px; font-weight: 700; }
.header-sub   { color: #8F8984; font-size: 13px; margin-left: 8px; }
.header-gradient {
  height: 5px;
  background: linear-gradient(90deg, #60E21B 0%, #FABA17 32.5%, #FFB592 69%, #FFB0CD 100%);
}
.body { padding: 20px; display: flex; flex-direction: column; gap: 12px; }
.card { background: #ECECEC; border-radius: 12px; padding: 16px; }
.field-label {
  font-family: 'IBM Plex Mono', monospace;
  font-size: 10px; color: #8F8984;
  text-transform: uppercase; letter-spacing: 1.5px; margin-bottom: 8px;
}
.url-input, .folder-input {
  width: 100%; border: 1.5px solid #D3D1CF; border-radius: 8px;
  padding: 10px 14px;
  font-family: 'Milling', 'Helvetica Neue', sans-serif;
  font-size: 14px; color: #1D1C1B; background: #FFFFFF; outline: none;
  transition: border-color 0.15s;
  -webkit-user-select: text; user-select: text;
}
.url-input::placeholder, .folder-input::placeholder { color: #8F8984; }
.url-input:focus, .folder-input:focus { border-color: #1D1C1B; }
.folder-row { display: flex; gap: 8px; }
.folder-input { flex: 1; font-size: 12px; font-family: 'IBM Plex Mono', monospace; }
.btn-outline {
  padding: 9px 16px; background: transparent;
  border: 1.5px solid #1D1C1B; border-radius: 8px;
  font-family: 'Milling', sans-serif; font-size: 12px; color: #1D1C1B;
  cursor: pointer; white-space: nowrap; transition: background 0.12s;
}
.btn-outline:hover { background: #D3D1CF; }
.format-row { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 4px; }
.fmt-btn {
  padding: 6px 14px; border-radius: 999px;
  border: 1.5px solid #D3D1CF; background: #FFFFFF;
  font-family: 'IBM Plex Mono', monospace;
  font-size: 11px; color: #1D1C1B; cursor: pointer;
  transition: all 0.12s;
}
.fmt-btn:hover { border-color: #1D1C1B; }
.fmt-btn.active { background: #BFF3A4; border-color: #60E21B; }
.fmt-dropdown-wrap { position: relative; }
.fmt-dropdown-wrap .fmt-btn { display: flex; align-items: center; gap: 6px; }
.fmt-chevron { font-size: 9px; transition: transform 0.15s; }
.fmt-dropdown-wrap.open .fmt-chevron { transform: rotate(180deg); }
.fmt-menu {
  display: none; position: absolute; top: calc(100% + 6px); left: 0;
  background: #FFFFFF; border: 1.5px solid #D3D1CF; border-radius: 10px;
  overflow: hidden; z-index: 100; min-width: 220px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
}
.fmt-dropdown-wrap.open .fmt-menu { display: block; }
.fmt-menu-item {
  padding: 9px 14px; font-family: 'IBM Plex Mono', monospace;
  font-size: 11px; color: #1D1C1B; cursor: pointer;
  display: flex; align-items: center; gap: 8px; transition: background 0.1s;
}
.fmt-menu-item:hover { background: #F4F3F3; }
.fmt-menu-item .check { color: #60E21B; font-size: 12px; width: 14px; }
.fmt-menu-item .fmt-sub { color: #8F8984; font-size: 10px; margin-left: auto; }
.btn-primary {
  width: 100%; padding: 14px; background: #1D1C1B; color: #F4F3F3;
  border: none; border-radius: 10px;
  font-family: 'Milling', sans-serif; font-size: 15px; font-weight: 700;
  cursor: pointer; transition: background 0.12s;
  box-shadow: 0 2px 8px rgba(0,0,0,0.18);
}
.btn-primary:hover:not(:disabled) { background: #333231; }
.btn-primary:disabled { opacity: 0.5; cursor: default; }
.log-card {
  background: #1D1C1B; border-radius: 12px; padding: 14px;
  min-height: 160px; max-height: 220px; overflow-y: auto;
  font-family: 'IBM Plex Mono', monospace; font-size: 11px;
  color: #60E21B; line-height: 1.6; white-space: pre-wrap; word-break: break-all;
  -webkit-user-select: text; user-select: text;
}
.log-card::-webkit-scrollbar { width: 4px; }
.log-card::-webkit-scrollbar-thumb { background: #45423F; border-radius: 2px; }
</style>
</head>
<body>

<div class="header">
  <div class="header-row">
    <img src="icon.png" style="width:24px;height:24px;border-radius:5px;flex-shrink:0;" alt="">
    <span class="header-title">YT Downloader</span>
    <span class="header-sub">v\#(appVersion)</span>
  </div>
  <div class="header-gradient"></div>
</div>

<div class="body">
  <div class="card">
    <div class="field-label">YouTube URL</div>
    <input id="url" class="url-input" type="text" placeholder="Paste a YouTube link here…" autocomplete="off" spellcheck="false">
  </div>

  <div class="card">
    <div class="field-label">Save to</div>
    <div class="folder-row">
      <input id="folder" class="folder-input" type="text" spellcheck="false">
      <button class="btn-outline" onclick="pickFolder()">Browse</button>
    </div>
    <div class="field-label" style="margin-top:14px;">Format</div>
    <div class="format-row">
      <div class="fmt-dropdown-wrap" id="video-wrap">
        <button class="fmt-btn active" id="video-btn" onclick="toggleVideoMenu()">
          <span id="video-label">MP4 · H.264 Video</span>
          <span class="fmt-chevron">▾</span>
        </button>
        <div class="fmt-menu">
          <div class="fmt-menu-item" onclick="selectVideo('h264','MP4 · H.264 Video')">
            <span class="check" id="check-h264">✓</span>
            H.264 Video
            <span class="fmt-sub">Most universal</span>
          </div>
          <div class="fmt-menu-item" onclick="selectVideo('h265','MP4 · H.265 Video')">
            <span class="check" id="check-h265"></span>
            H.265 Video
            <span class="fmt-sub">Best quality</span>
          </div>
        </div>
      </div>
      <button class="fmt-btn" data-fmt="mp3" onclick="setFmt(this)">MP3 · Audio only</button>
    </div>
  </div>

  <button id="dl-btn" class="btn-primary" onclick="download()">Download</button>
  <div id="log" class="log-card">Ready.
</div>
  <div style="text-align:right;margin-top:6px;">
    <button id="update-btn" onclick="checkUpdates()" style="background:none;border:1px solid #D3D1CF;border-radius:6px;padding:5px 10px;font-family:'IBM Plex Mono',monospace;font-size:10px;color:#8F8984;cursor:pointer;letter-spacing:0.5px;transition:border-color 0.12s,color 0.12s;">↻ Check for yt-dlp updates</button>
  </div>
</div>

<script>
let selectedFmt = 'h264';
let polling     = false;

// Swift WKWebView bridge: call(action, params) returns a Promise
let _cbs = {}, _cbId = 0;
function call(action, params) {
  return new Promise(resolve => {
    const id = String(++_cbId);
    _cbs[id] = resolve;
    window.webkit.messageHandlers.bridge.postMessage({id, action, ...params});
  });
}
function handleResponse(id, result) {
  if (_cbs[id]) { _cbs[id](result); delete _cbs[id]; }
}

// Load saved folder on startup
call('getFolder').then(f => { if (f) document.getElementById('folder').value = f; });

function toggleVideoMenu() {
  document.getElementById('video-wrap').classList.toggle('open');
}

function selectVideo(fmt, label) {
  selectedFmt = fmt;
  document.getElementById('video-label').textContent = label;
  document.getElementById('check-h264').textContent = fmt === 'h264' ? '✓' : '';
  document.getElementById('check-h265').textContent = fmt === 'h265' ? '✓' : '';
  document.querySelectorAll('.fmt-btn').forEach(b => b.classList.remove('active'));
  document.getElementById('video-btn').classList.add('active');
  document.getElementById('video-wrap').classList.remove('open');
}

function setFmt(btn) {
  document.querySelectorAll('.fmt-btn').forEach(b => b.classList.remove('active'));
  document.getElementById('video-wrap').classList.remove('open');
  btn.classList.add('active');
  selectedFmt = btn.dataset.fmt;
}

document.addEventListener('click', e => {
  const wrap = document.getElementById('video-wrap');
  if (!wrap.contains(e.target)) wrap.classList.remove('open');
});

function pickFolder() {
  call('pickFolder', {current: document.getElementById('folder').value}).then(f => {
    if (f) document.getElementById('folder').value = f;
  });
}

function log(text) {
  const el = document.getElementById('log');
  el.textContent += text;
  el.scrollTop = el.scrollHeight;
}

function resetBtn() {
  document.getElementById('dl-btn').disabled = false;
  document.getElementById('dl-btn').textContent = 'Download';
  polling = false;
}

function startPolling() {
  if (polling) return;
  polling = true;
  function tick() {
    if (!polling) return;
    call('poll').then(data => {
      if (data.lines) data.lines.forEach(l => log(l));
      if (data.done) { resetBtn(); }
      else { setTimeout(tick, 200); }
    }).catch(() => { resetBtn(); });
  }
  setTimeout(tick, 200);
}

function resetUpdateBtn() {
  const btn = document.getElementById('update-btn');
  btn.textContent = '↻ Check for yt-dlp updates';
  btn.onclick = checkUpdates;
  btn.style.color = '#8F8984';
  btn.style.borderColor = '#D3D1CF';
}
function checkUpdates() {
  const btn = document.getElementById('update-btn');
  btn.textContent = '✕ Stop';
  btn.onclick = stopUpdates;
  btn.style.color = '#1D1C1B';
  btn.style.borderColor = '#1D1C1B';
  call('checkUpdates').then(resetUpdateBtn);
}
function stopUpdates() {
  call('stopUpdate').then(resetUpdateBtn);
}

function download() {
  const url    = document.getElementById('url').value.trim();
  const folder = document.getElementById('folder').value.trim();
  if (!url) { log('Paste a YouTube URL first.\n'); return; }

  document.getElementById('dl-btn').disabled = true;
  document.getElementById('dl-btn').textContent = 'Downloading…';
  document.getElementById('log').textContent = '⏳ Connecting…\n';

  call('startDownload', {url, folder, fmt: selectedFmt}).then(ok => {
    if (ok) { startPolling(); }
    else { resetBtn(); log('Already downloading.\n'); }
  }).catch(() => { resetBtn(); log('Failed to start.\n'); });
}
</script>
</body>
</html>
"""#

// MARK: - Bridge (JS ↔ Swift)

class Bridge: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?
    private var logLines: [String] = []
    private var done = true
    private let lock = NSLock()
    private var updateProc: Process?

    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String,
              let id     = body["id"]     as? String else { return }

        switch action {

        case "getFolder":
            reply(id, string: loadFolder())

        case "pickFolder":
            let cur = body["current"] as? String ?? defaultFolder
            DispatchQueue.main.async { self.pickFolder(id: id, current: cur) }

        case "startDownload":
            guard let url    = body["url"]    as? String,
                  let folder = body["folder"] as? String,
                  let fmt    = body["fmt"]    as? String else {
                reply(id, raw: "false"); return
            }
            lock.lock(); let busy = !done; lock.unlock()
            if busy { reply(id, raw: "false"); return }
            saveFolder(folder)
            lock.lock(); logLines.removeAll(); done = false; lock.unlock()
            DispatchQueue.global(qos: .userInitiated).async { self.run(url: url, folder: folder, fmt: fmt) }
            reply(id, raw: "true")

        case "poll":
            lock.lock()
            let lines = logLines; logLines.removeAll()
            let isDone = done
            lock.unlock()
            let escaped = lines.map { line -> String in
                var s = line
                s = s.replacingOccurrences(of: "\r\n", with: "\n") // normalize CRLF first
                s = s.replacingOccurrences(of: "\r", with: "\n")   // bare CR → newline
                s = s.replacingOccurrences(of: "\\", with: "\\\\")
                s = s.replacingOccurrences(of: "\"", with: "\\\"")
                s = s.replacingOccurrences(of: "\n", with: "\\n")
                return s
            }
            let arr = escaped.map { "\"\($0)\"" }.joined(separator: ",")
            reply(id, raw: "{\"lines\":[\(arr)],\"done\":\(isDone)}")

        case "checkUpdates":
            lock.lock(); let busy = !done; lock.unlock()
            if busy { reply(id, raw: "false"); return }
            DispatchQueue.global(qos: .userInitiated).async {
                self.autoUpdateYtDlp()
                self.reply(id, raw: "true")
            }

        case "stopUpdate":
            stopUpdateYtDlp()
            reply(id, raw: "true")

        default: break
        }
    }

    private func pickFolder(id: String, current: String) {
        let panel = NSOpenPanel()
        panel.canChooseFiles        = false
        panel.canChooseDirectories  = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: current)
        panel.prompt = "Select Folder"
        panel.begin { [weak self] response in
            if response == .OK, let path = panel.url?.path {
                saveFolder(path)
                self?.reply(id, string: path)
            } else {
                self?.reply(id, string: "")
            }
        }
    }

    private func run(url: String, folder: String, fmt: String) {
        let resources = Bundle.main.resourcePath ?? ""
        let ytdlp  = resources + "/bin/yt-dlp"
        let ffmpeg = resources + "/bin/ffmpeg"

        let output: String
        let args: [String]
        switch fmt {
        case "mp3":
            output = folder + "/%(title)s.%(ext)s"
            args = ["--ffmpeg-location", ffmpeg, "-o", output, "-x", "--audio-format", "mp3", url]
        case "h265":
            output = folder + "/%(title)s [H.265].%(ext)s"
            args = ["--ffmpeg-location", ffmpeg, "-o", output, "--merge-output-format", "mp4", "-S", "vcodec:h265", url]
        default:
            output = folder + "/%(title)s.%(ext)s"
            args = ["--ffmpeg-location", ffmpeg, "-o", output, "--merge-output-format", "mp4", "-S", "vcodec:h264", url]
        }

        push("⏳ Starting download…\n\n")

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: ytdlp)
        proc.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        proc.environment = env

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError  = pipe

        let handle = pipe.fileHandleForReading
        let sem = DispatchSemaphore(value: 0)

        handle.readabilityHandler = { fh in
            let data = fh.availableData
            if data.isEmpty {
                // EOF — process exited and all output has been read
                fh.readabilityHandler = nil
                sem.signal()
            } else if let text = String(data: data, encoding: .utf8) {
                self.push(text)
            }
        }

        do {
            try proc.run()
            sem.wait()
            if proc.terminationStatus == 0 {
                push("\n✅ Download complete.\n")
            } else {
                push("\n⚠️ Download failed. Retrying with fallback format…\n\n")
                let fallbackOutput = folder + "/%(title)s.%(ext)s"
                let fallbackArgs = ["--ffmpeg-location", ffmpeg, "-o", fallbackOutput, "-f", "best", url]
                let proc2 = Process()
                proc2.executableURL = URL(fileURLWithPath: ytdlp)
                proc2.arguments = fallbackArgs
                proc2.environment = env
                let pipe2 = Pipe()
                proc2.standardOutput = pipe2
                proc2.standardError  = pipe2
                let handle2 = pipe2.fileHandleForReading
                let sem2 = DispatchSemaphore(value: 0)
                handle2.readabilityHandler = { fh in
                    let data = fh.availableData
                    if data.isEmpty { fh.readabilityHandler = nil; sem2.signal() }
                    else if let text = String(data: data, encoding: .utf8) { self.push(text) }
                }
                try proc2.run()
                sem2.wait()
                push(proc2.terminationStatus == 0 ? "\n✅ Download complete.\n" : "\n❌ Download failed. The video may be unavailable or restricted.\n")
            }
        } catch {
            handle.readabilityHandler = nil
            push("❌ Failed to launch yt-dlp: \(error.localizedDescription)\n")
        }

        lock.lock(); done = true; lock.unlock()
    }

    private func push(_ text: String) {
        lock.lock(); logLines.append(text); lock.unlock()
    }

    // MARK: - Auto-update yt-dlp

    func autoUpdateYtDlp() {
        let resources = Bundle.main.resourcePath ?? ""
        let ytdlp = resources + "/bin/yt-dlp"

        setLog("🔄 Checking for yt-dlp updates…\n")

        let proc = Process()
        updateProc = proc
        proc.executableURL = URL(fileURLWithPath: ytdlp)
        proc.arguments = ["-U"]
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        proc.environment = env

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError  = pipe

        do {
            try proc.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            updateProc = nil

            if proc.terminationReason == .uncaughtSignal {
                setLog("Ready.\n")
                return
            }

            let output = String(data: data, encoding: .utf8) ?? ""

            if output.lowercased().contains("up to date") || output.lowercased().contains("latest version") {
                setLog("✓ yt-dlp is up to date.\n\nReady.\n")
            } else if proc.terminationStatus == 0 && !output.isEmpty {
                // Successfully updated — extract version if possible
                let version = output.components(separatedBy: .newlines)
                    .first(where: { $0.lowercased().contains("updated") || $0.lowercased().contains("yt-dlp") })
                    ?? ""
                setLog("✓ yt-dlp updated\(version.isEmpty ? "" : ": \(version.trimmingCharacters(in: .whitespaces))")\n\nReady.\n")
            } else {
                setLog("Ready.\n")
            }
        } catch {
            updateProc = nil
            setLog("Ready.\n")
        }
    }

    func stopUpdateYtDlp() {
        updateProc?.terminate()
        updateProc = nil
    }

    private func setLog(_ text: String) {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        let js = "document.getElementById('log').textContent = \"\(escaped)\";"
        DispatchQueue.main.async { self.webView?.evaluateJavaScript(js, completionHandler: nil) }
    }

    func reply(_ id: String, string: String) {
        let escaped = string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
        reply(id, raw: "\"\(escaped)\"")
    }

    func reply(_ id: String, raw: String) {
        let js = "handleResponse(\"\(id)\",\(raw))"
        DispatchQueue.main.async { self.webView?.evaluateJavaScript(js, completionHandler: nil) }
    }
}

// MARK: - App

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    let bridge = Bridge()

    func buildMenu() {
        let bar = NSMenu()

        let appItem = NSMenuItem(); bar.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "Check for yt-dlp Updates", action: #selector(checkForUpdates), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit YT Downloader", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let editItem = NSMenuItem(); bar.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        editMenu.addItem(NSMenuItem(title: "Undo",       action: Selector(("undo:")),                    keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo",       action: Selector(("redo:")),                    keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut",        action: #selector(NSText.cut(_:)),              keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy",       action: #selector(NSText.copy(_:)),             keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste",      action: #selector(NSText.paste(_:)),            keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)),        keyEquivalent: "a"))

        NSApp.mainMenu = bar
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        let config = WKWebViewConfiguration()
        config.userContentController.add(bridge, name: "bridge")

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 520, height: 660), configuration: config)
        bridge.webView = webView

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 660),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "YT Downloader"
        window.contentView = webView
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        webView.loadHTMLString(HTML, baseURL: Bundle.main.resourceURL)

    }

    @objc func checkForUpdates() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.bridge.autoUpdateYtDlp()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

// MARK: - Entry point

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
