// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import Chart from "chart.js/auto";
import topbar from "../vendor/topbar";
import SignaturePad from "../vendor/signature_pad";

function DATAMatrix(Q) {
  var M = [],
    xx = 0,
    yy = 0,
    bit = function (x, y) {
      ((M[y] = M[y] || []), (M[y][x] = 1));
    },
    toAscii = function (t) {
      var r = [],
        l = t.length;

      for (var i = 0; i < l; i++) {
        var c = t.charCodeAt(i),
          c1 = i + 1 < l ? t.charCodeAt(i + 1) : 0;

        if (c > 47 && c < 58 && c1 > 47 && c1 < 58) {
          /* 2 digits */

          (r.push((c - 48) * 10 + c1 + 82) /* - 48 + 130 = 82 */, i++);
        } else if (c > 127) {
          /* extended char */

          (r.push(235), r.push((c - 127) & 255));
        } else r.push(c + 1); /* char */
      }

      return r;
    },
    toBase = function (t) {
      var r = [231] /* switch to Base 256 */,
        l = t.length;

      if (250 < l) {
        r.push(
          (37 + ((l / 250) | 0)) & 255,
        ); /* length high byte (in 255 state algo) */
      }

      r.push(
        ((l % 250) + ((149 * (r.length + 1)) % 255) + 1) & 255,
      ); /* length low byte (in 255 state algo) */

      for (var i = 0; i < l; i++) {
        r.push(
          (t.charCodeAt(i) + ((149 * (r.length + 1)) % 255) + 1) & 255,
        ); /* data in 255 state algo */
      }

      return r;
    },
    toEdifact = function (t) {
      var n = t.length,
        l = (n + 1) & -4,
        cw = 0,
        ch,
        r = l > 0 ? [240] : []; /* switch to Edifact */

      for (var i = 0; i < l; i++) {
        if (i < l - 1) {
          /* encode char */
          ch = t.charCodeAt(i);
          if (ch < 32 || ch > 94) return []; /* not in set */
        } else ch = 31; /* return to ASCII */

        cw = cw * 64 + (ch & 63);

        if ((i & 3) == 3) {
          /* 4 data in 3 words */
          (r.push(cw >> 16),
            r.push((cw >> 8) & 255),
            r.push(cw & 255),
            (cw = 0));
        }
      }

      return l > n
        ? r
        : r.concat(toAscii(t.substr(l == 0 ? 0 : l - 1))); /* last chars*/
    },
    toText = function (t, s) {
      var i,
        j,
        cc = 0,
        cw = 0,
        l = t.length,
        r = [s[0]] /* start switch */,
        push = function (v) {
          /* pack 3 chars in 2 codes */
          cw = 40 * cw + v;

          /* add code */
          if (cc++ == 2) {
            (r.push(++cw >> 8), r.push(cw & 255), (cc = cw = 0));
          }
        };

      for (i = 0; i < l; i++) {
        /* last char in ASCII is shorter */
        if (0 == cc && i == l - 1) break;

        var ch = t.charCodeAt(i);

        if (ch > 127 && 238 != r[0]) {
          /* extended char */

          (push(1), push(30), (ch -= 128)); /* hi bit in C40 & TEXT */
        }

        for (j = 1; ch > s[j]; j += 3); /* select char set */

        var x = s[j + 1]; /* shift */

        if (8 == x || (9 == x && 0 == cc && i == l - 1))
          return []; /* char not in set or padding fails */

        if (x < 5 && cc == 2 && i == l - 1) break; /* last char in ASCII */
        if (x < 5) push(x); /* shift */

        push(ch - s[j + 2]); /* char offset */
      }

      if (2 == cc && 238 !== r[0]) {
        /* add pad */

        push(0);
      }

      r.push(254); /* return to ASCII */

      if (cc > 0 || i < l)
        r = r.concat(toAscii(t.substr(i - cc))); /* last chars */

      return r;
    },
    encodeMsg = function (text, rct) {
      text = unescape(encodeURI(text));

      var M = [];

      var enc = toAscii(text),
        el = enc.length,
        k = toText(
          text,
          [
            /* C40 */ 230, 31, 0, 0, 32, 9, 29, 47, 1, 33, 57, 9, 44, 64, 1, 43,
            90, 9, 51, 95, 1, 69, 127, 2, 96, 255, 1, 0,
          ],
        ),
        l = k.length;
      if (l > 0 && l < el) ((enc = k), (el = l));

      k = toText(
        text,
        [
          /* TEXT */ 239, 31, 0, 0, 32, 9, 29, 47, 1, 33, 57, 9, 44, 64, 1, 43,
          90, 2, 64, 95, 1, 69, 122, 9, 83, 127, 2, 96, 255, 1, 0,
        ],
      );
      l = k.length;
      if (l > 0 && l < el) ((enc = k), (el = l));

      k = toText(
        text,
        [
          /* X12*/ 238, 12, 8, 0, 13, 9, 13, 31, 8, 0, 32, 9, 29, 41, 8, 0, 42,
          9, 41, 47, 8, 0, 57, 9, 44, 64, 8, 0, 90, 9, 51, 255, 8, 0,
        ],
      );
      l = k.length;
      if (l > 0 && l < el) ((enc = k), (el = l));

      k = toEdifact(text);
      l = k.length;
      if (l > 0 && l < el) ((enc = k), (el = l));

      k = toBase(text);
      l = k.length;
      if (l > 0 && l < el) ((enc = k), (el = l));

      var h,
        w,
        nc = 1,
        nr = 1,
        fw,
        fh /* symbol size, regions, region size */,
        i,
        j = -1,
        c,
        r,
        s,
        b = 1 /* compute symbol size */,
        rs = new Array(70) /* reed / solomon code */,
        rc = new Array(70),
        lg = new Array(256) /* log / exp table for multiplication */,
        ex = new Array(255);

      if (rct && el < 50) {
        /* rect */

        k = [
          /* symbol width, checkwords */ 16, 7, 28, 11, 24, 14, 32, 18, 32, 24,
          44, 28,
        ];

        do {
          w = k[++j]; /* width */
          h = 6 + (j & 12); /* height */
          l = (w * h) / 8; /* bytes count in symbol */
        } while (l - k[++j] < el); /* could we fill the rect? */

        /* column regions */
        if (w > 25) nc = 2;
      } else {
        /* square */

        w = h = 6;
        i = 2; /* size increment */
        k = [
          5, 7, 10, 12, 14, 18, 20, 24, 28, 36, 42, 48, 56, 68, 84, 112, 144,
          192, 224, 272, 336, 408, 496, 620,
        ]; /* rs checkwords */

        do {
          if (++j == k.length) return [0, 0]; /* msg is too long */

          if (w > 11 * i) i = (4 + i) & 12; /* advance increment */

          w = h += i;
          l = (w * h) >> 3;
        } while (l - k[j] < el);

        if (w > 27) nr = nc = 2 * ((w / 54) | 0) + 2; /* regions */
        if (l > 255) b = 2 * (l >> 9) + 2; /* blocks */
      }

      ((s = k[j]) /* rs checkwords */,
        (fw = w / nc) /* region size */,
        (fh = h / nr));

      /* first padding */
      if (el < l - s) enc[el++] = 129;

      /* more padding */
      while (el < l - s) {
        enc[el++] = (((149 * el) % 253) + 130) % 254;
      }

      /* Reed Solomon error detection and correction */
      s /= b;

      /* log / exp table of Galois field */
      for (j = 1, i = 0; i < 255; i++) {
        ((ex[i] = j), (lg[j] = i), (j += j));

        if (j > 255) j ^= 301; /* 301 == a^8 + a^5 + a^3 + a^2 + 1 */
      }

      /* RS generator polynomial */
      for (rs[s] = 0, i = 1; i <= s; i++)
        for (j = s - i, rs[j] = 1; j < s; j++)
          rs[j] = rs[j + 1] ^ ex[(lg[rs[j]] + i) % 255];

      /* RS correction data for each block */
      for (c = 0; c < b; c++) {
        for (i = 0; i <= s; i++) rc[i] = 0;
        for (i = c; i < el; i += b)
          for (j = 0, x = rc[0] ^ enc[i]; j < s; j++)
            rc[j] = rc[j + 1] ^ (x ? ex[(lg[rs[j]] + lg[x]) % 255] : 0);

        /* interleaved correction data */
        for (i = 0; i < s; i++) enc[el + c + i * b] = rc[i];
      }

      /* layout perimeter finder pattern */
      /* horizontal */
      for (i = 0; i < h + 2 * nr; i += fh + 2)
        for (j = 0; j < w + 2 * nc; j++) {
          bit(j, i + fh + 1);
          if ((j & 1) == 0) bit(j, i);
        }

      /* vertical */
      for (i = 0; i < w + 2 * nc; i += fw + 2)
        for (j = 0; j < h; j++) {
          bit(i, j + ((j / fh) | 0) * 2 + 1);
          if ((j & 1) == 1) bit(i + fw + 1, j + ((j / fh) | 0) * 2);
        }

      ((s = 2) /* step */,
        (c = 0) /* column */,
        (r = 4) /* row */,
        (b = [
          /* nominal byte layout */ 0, 0, -1, 0, -2, 0, 0, -1, -1, -1, -2, -1,
          -1, -2, -2, -2,
        ]));

      /* diagonal steps */
      for (i = 0; i < l; r -= s, c += s) {
        if (r == h - 3 && c == -1)
          k = [
            /* corner A layout */ w,
            6 - h,
            w,
            5 - h,
            w,
            4 - h,
            w,
            3 - h,
            w - 1,
            3 - h,
            3,
            2,
            2,
            2,
            1,
            2,
          ];
        else if (r == h + 1 && c == 1 && (w & 7) == 0 && (h & 7) == 6)
          k = [
            /* corner D layout */ w - 2,
            -h,
            w - 3,
            -h,
            w - 4,
            -h,
            w - 2,
            -1 - h,
            w - 3,
            -1 - h,
            w - 4,
            -1 - h,
            w - 2,
            -2,
            -1,
            -2,
          ];
        else {
          if (r == 0 && c == w - 2 && w & 3)
            continue; /* corner B: omit upper left */
          if (r < 0 || c >= w || r >= h || c < 0) {
            /* outside */

            ((s = -s) /* turn around */, (r += 2 + s / 2), (c += 2 - s / 2));

            while (r < 0 || c >= w || r >= h || c < 0) {
              ((r -= s), (c += s));
            }
          }
          if (r == h - 2 && c == 0 && w & 3)
            k = [
              /* corner B layout */ w - 1,
              3 - h,
              w - 1,
              2 - h,
              w - 2,
              2 - h,
              w - 3,
              2 - h,
              w - 4,
              2 - h,
              0,
              1,
              0,
              0,
              0,
              -1,
            ];
          else if (r == h - 2 && c == 0 && (w & 7) == 4)
            k = [
              /* corner C layout */ w - 1,
              5 - h,
              w - 1,
              4 - h,
              w - 1,
              3 - h,
              w - 1,
              2 - h,
              w - 2,
              2 - h,
              0,
              1,
              0,
              0,
              0,
              -1,
            ];
          else if (r == 1 && c == w - 1 && (w & 7) == 0 && (h & 7) == 6)
            continue; /* omit corner D */
          else k = b; /* nominal L - shape layout */
        }

        /* layout each bit */
        for (el = enc[i++], j = 0; el > 0; j += 2, el >>= 1) {
          if (el & 1) {
            var x = c + k[j],
              y = r + k[j + 1];

            /* wrap around */
            if (x < 0) ((x += w), (y += 4 - ((w + 4) & 7)));
            if (y < 0) ((y += h), (x += 4 - ((h + 4) & 7)));

            /* region gap */
            bit(x + 2 * ((x / fw) | 0) + 1, y + 2 * ((y / fh) | 0) + 1);
          }
        }
      }

      /* unfilled corner */
      for (i = w; i & 3; i--) {
        bit(i, i);
      }

      ((xx = w + 2 * nc), (yy = h + 2 * nr));
    };

  return (function () {
    function ishex(c) {
      return /^#[0-9a-f]{3}(?:[0-9a-f]{3})?$/i.test(c);
    }

    function svg(n, a) {
      n = document.createElementNS(ns, n);

      for (var o in a || {}) {
        n.setAttribute(o, a[o]);
      }

      return n;
    }

    var abs = Math.abs,
      r,
      x,
      y,
      d,
      sx,
      sy,
      ns = "http://www.w3.org/2000/svg",
      path = "",
      q = "string" == typeof Q ? { msg: Q } : Q || {},
      p = q.pal || ["#000"],
      dm = abs(q.dim) || 256,
      pd = abs(q.pad),
      pd = pd > -1 ? pd : 2,
      mx = [1, 0, 0, 1, pd, pd],
      fg = p[0],
      fg = ishex(fg) ? fg : "#000",
      bg = p[1],
      bg = ishex(bg) ? bg : 0,
      /* render optimized or verbose svg */
      optimized = q.vrb ? 0 : 1;

    encodeMsg(q.msg || "", q.rct);

    ((sx = xx + pd * 2), (sy = yy + pd * 2));

    y = yy;

    while (y--) {
      ((d = 0), (x = xx));

      while (x--) {
        if (M[y][x]) {
          if (optimized) {
            d++;

            if (!M[y][x - 1])
              ((path += "M" + x + "," + y + "h" + d + "v1h-" + d + "v-1z"),
                (d = 0));
          } else path += "M" + x + "," + y + "h1v1h-1v-1z";
        }
      }
    }

    r = svg("svg", {
      viewBox: [0, 0, sx, sy].join(" "),
      width: ((dm / sy) * sx) | 0,
      height: dm,
      fill: fg,
      "shape-rendering": "crispEdges",
      xmlns: ns,
      version: "1.1",
    });

    if (bg)
      r.appendChild(
        svg("path", {
          fill: bg,
          d: "M0,0v" + sy + "h" + sx + "V0H0Z",
        }),
      );

    r.appendChild(
      svg("path", {
        transform: "matrix(" + mx + ")",
        d: path,
      }),
    );

    return r;
  })();
}

window.addEventListener("phx:printDiv", (e) => printDiv(e));

function printDiv(e) {
  var printContents = document.getElementById(e.detail.id).innerHTML;
  var originalContents = document.body.innerHTML;

  document.body.innerHTML = printContents;

  window.print();

  document.body.innerHTML = originalContents;
}

let Hooks = {};

Hooks.ReportWorkspace = {
  mounted() {
    this.scale = 1;
    this.sourceVisible = true;
    this.bindControls();

    this.handleFullscreenChange = () => {
      this.syncFullscreenControl();
      requestAnimationFrame(() => this.fitWidth());
    };

    document.addEventListener("fullscreenchange", this.handleFullscreenChange);
    this.applyViewState();
  },

  updated() {
    this.bindControls();
    this.applyViewState();
  },

  destroyed() {
    document.removeEventListener("fullscreenchange", this.handleFullscreenChange);
  },

  bindControls() {
    this.stage = this.el.querySelector("[data-report-stage]");
    this.pages = this.el.querySelector("[data-report-pages]");
    this.zoomOutput = this.el.querySelector("[data-report-zoom]");

    this.el.querySelectorAll("[data-report-action]").forEach((button) => {
      if (button.dataset.reportBound === "true") return;

      button.dataset.reportBound = "true";
      button.addEventListener("click", () => {
        switch (button.dataset.reportAction) {
          case "toggle-source":
            this.sourceVisible = !this.sourceVisible;
            this.applyViewState();
            requestAnimationFrame(() => this.fitWidth());
            break;
          case "fit-width":
            this.fitWidth();
            break;
          case "fit-page":
            this.fitPage();
            break;
          case "zoom-out":
            this.setScale(this.scale - 0.1);
            break;
          case "zoom-in":
            this.setScale(this.scale + 0.1);
            break;
          case "fullscreen":
            this.toggleFullscreen();
            break;
        }
      });
    });
  },

  applyViewState() {
    this.el.classList.toggle("report-source-hidden", !this.sourceVisible);

    const sourceButton = this.el.querySelector(
      "[data-report-action='toggle-source']",
    );
    if (sourceButton) {
      sourceButton.setAttribute("aria-pressed", String(this.sourceVisible));
    }

    this.setScale(this.scale);
    this.syncFullscreenControl();
  },

  setScale(value) {
    this.scale = Math.min(1.6, Math.max(0.4, Math.round(value * 100) / 100));
    if (this.pages) {
      this.pages.style.setProperty("--report-zoom", this.scale);
    }
    if (this.zoomOutput) {
      this.zoomOutput.textContent = `${Math.round(this.scale * 100)}%`;
    }
  },

  measureAtNormalSize(callback) {
    if (!this.pages || !this.stage) return;

    this.pages.style.setProperty("--report-zoom", 1);
    requestAnimationFrame(() => {
      const page = this.pages.querySelector(".report-html-page");
      if (!page) return;

      callback(page.getBoundingClientRect());
    });
  },

  fitWidth() {
    this.measureAtNormalSize((pageRect) => {
      const availableWidth = this.stage.clientWidth - 36;
      this.setScale(availableWidth / pageRect.width);
      this.stage.scrollTo({ left: 0, behavior: "smooth" });
    });
  },

  fitPage() {
    this.measureAtNormalSize((pageRect) => {
      const availableWidth = this.stage.clientWidth - 36;
      const availableHeight = this.stage.clientHeight - 36;
      this.setScale(
        Math.min(availableWidth / pageRect.width, availableHeight / pageRect.height),
      );
      this.stage.scrollTo({ top: 0, left: 0, behavior: "smooth" });
    });
  },

  async toggleFullscreen() {
    if (document.fullscreenElement === this.el) {
      await document.exitFullscreen();
    } else if (this.el.requestFullscreen) {
      await this.el.requestFullscreen();
    }
  },

  syncFullscreenControl() {
    const button = this.el.querySelector("[data-report-action='fullscreen']");
    if (!button) return;

    const isFullscreen = document.fullscreenElement === this.el;
    button.setAttribute("aria-pressed", String(isFullscreen));
    button.setAttribute(
      "aria-label",
      isFullscreen ? "Exit fullscreen" : "Open fullscreen",
    );
    button.setAttribute(
      "title",
      isFullscreen ? "Exit fullscreen" : "Open fullscreen",
    );
  },
};

// Voice dictation for clinical free-text fields. The modal owns recording,
// review, editing, and confirmation before English text reaches the note.
Hooks.VoiceInput = {
  mounted() {
    this.textarea = this.el.querySelector("textarea");
    this.button = this.el.querySelector("[data-role='voice-btn']");
    this.labelEl = this.el.querySelector("[data-role='voice-label']");
    this.modal = this.el.querySelector("[data-role='voice-language-modal']");
    this.dialog = this.el.querySelector("[data-role='voice-dialog']");
    this.setupPanel = this.el.querySelector("[data-role='voice-setup']");
    this.progressPanel = this.el.querySelector("[data-role='voice-progress']");
    this.resultPanel = this.el.querySelector("[data-role='voice-result']");
    this.errorEl = this.el.querySelector("[data-role='voice-error']");
    this.statusEl = this.el.querySelector("[data-role='voice-status']");
    this.languageSelect = this.el.querySelector("[data-role='voice-language']");
    this.startButton = this.el.querySelector("[data-role='voice-start']");
    this.cancelButton = this.el.querySelector("[data-role='voice-cancel']");
    this.stopButton = this.el.querySelector("[data-role='voice-stop']");
    this.progressCancelButton = this.el.querySelector("[data-role='voice-progress-cancel']");
    this.transcript = this.el.querySelector("[data-role='voice-transcript']");
    this.retryButton = this.el.querySelector("[data-role='voice-retry']");
    this.resultCancelButton = this.el.querySelector("[data-role='voice-result-cancel']");
    this.saveButton = this.el.querySelector("[data-role='voice-save']");
    this.selectedLanguage = "en";
    this.recording = false;
    this.cancelled = false;
    this.mediaRecorder = null;
    this.stream = null;
    this.abortController = null;
    this.chunks = [];

    const supported =
      navigator.mediaDevices &&
      typeof navigator.mediaDevices.getUserMedia === "function" &&
      typeof window.MediaRecorder !== "undefined";

    if (!supported || !this.button || !this.textarea) {
      if (this.button) this.button.style.display = "none";
      return;
    }

    this.onClick = (e) => {
      e.preventDefault();
      e.stopPropagation();
      this.openLanguageModal();
    };
    this.onStart = () => {
      this.selectedLanguage = this.languageSelect?.value || "en";
      this.startRecording();
    };
    this.onStop = () => this.stopRecording();
    this.onCancel = () => this.cancelDictation();
    this.onRetry = () => this.showSetup();
    this.onSave = () => {
      const text = this.transcript?.value.trim();
      if (!text) {
        this.showError("Please review or enter transcription text before saving.");
        return;
      }
      this.insertText(text);
      this.closeLanguageModal();
      this.resetModal();
      this.setState("idle", "Dictate");
    };
    this.onLanguageChange = (e) => {
      this.selectedLanguage = e.target.value || "en";
      e.stopPropagation();
    };
    this.onTranscriptInput = (e) => e.stopPropagation();
    this.onModalClick = (e) => {
      if (e.target === this.modal) this.cancelDictation();
    };
    this.onKeydown = (e) => {
      if (e.key === "Escape" && !this.modal?.classList.contains("hidden")) {
        this.cancelDictation();
      }
    };
    this.button.addEventListener("click", this.onClick);
    this.startButton?.addEventListener("click", this.onStart);
    this.cancelButton?.addEventListener("click", this.onCancel);
    this.stopButton?.addEventListener("click", this.onStop);
    this.progressCancelButton?.addEventListener("click", this.onCancel);
    this.retryButton?.addEventListener("click", this.onRetry);
    this.resultCancelButton?.addEventListener("click", this.onCancel);
    this.saveButton?.addEventListener("click", this.onSave);
    this.languageSelect?.addEventListener("change", this.onLanguageChange);
    this.transcript?.addEventListener("input", this.onTranscriptInput);
    this.modal?.addEventListener("click", this.onModalClick);
    document.addEventListener("keydown", this.onKeydown);
  },

  beforeUpdate() {
    this.restoreOpenModal =
      this.modal && !this.modal.classList.contains("hidden");
    this.languageBeforeUpdate =
      this.languageSelect?.value || this.selectedLanguage;
  },

  updated() {
    if (!this.restoreOpenModal || !this.modal) return;

    this.modal.classList.remove("hidden");
    this.selectedLanguage = this.languageBeforeUpdate || "en";
    if (this.languageSelect) {
      this.languageSelect.value = this.selectedLanguage;
    }
    this.restoreOpenModal = false;
  },

  openLanguageModal() {
    if (!this.modal) {
      this.startRecording();
      return;
    }
    this.resetModal();
    this.modal.classList.remove("hidden");
    this.languageSelect?.focus();
  },

  closeLanguageModal() {
    this.modal?.classList.add("hidden");
    this.button?.focus();
  },

  resetModal() {
    this.setupPanel?.classList.remove("hidden");
    this.progressPanel?.classList.add("hidden");
    this.resultPanel?.classList.add("hidden");
    this.hideError();
    if (this.transcript) this.transcript.value = "";
    if (this.stopButton) this.stopButton.disabled = false;
  },

  showSetup(error) {
    this.setupPanel?.classList.remove("hidden");
    this.progressPanel?.classList.add("hidden");
    this.resultPanel?.classList.add("hidden");
    if (error) this.showError(error);
    else this.hideError();
    this.setState("idle", "Dictate");
    this.languageSelect?.focus();
  },

  showProgress(status, processing = false) {
    this.setupPanel?.classList.add("hidden");
    this.progressPanel?.classList.remove("hidden");
    this.resultPanel?.classList.add("hidden");
    this.hideError();
    if (this.statusEl) this.statusEl.textContent = status;
    if (this.stopButton) this.stopButton.disabled = processing;
  },

  showResult(text) {
    this.setupPanel?.classList.add("hidden");
    this.progressPanel?.classList.add("hidden");
    this.resultPanel?.classList.remove("hidden");
    this.hideError();
    if (this.transcript) {
      this.transcript.value = text;
      this.transcript.focus();
      this.transcript.setSelectionRange(text.length, text.length);
    }
  },

  showError(message) {
    if (!this.errorEl) return;
    this.errorEl.textContent = message;
    this.errorEl.classList.remove("hidden");
  },

  hideError() {
    if (!this.errorEl) return;
    this.errorEl.textContent = "";
    this.errorEl.classList.add("hidden");
  },

  cancelDictation() {
    this.cancelled = true;
    this.recording = false;
    this.abortController?.abort();
    this.abortController = null;
    if (this.mediaRecorder && this.mediaRecorder.state !== "inactive") {
      this.mediaRecorder.stop();
    }
    this.stopStream();
    this.closeLanguageModal();
    this.resetModal();
    this.setState("idle", "Dictate");
  },

  async startRecording() {
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    } catch (err) {
      this.showSetup("Microphone access was blocked. Please allow microphone access and try again.");
      return;
    }

    if (this.modal?.classList.contains("hidden")) {
      this.stopStream();
      return;
    }

    this.showProgress("Recording…");
    this.chunks = [];
    this.cancelled = false;
    const mime = MediaRecorder.isTypeSupported("audio/webm") ? "audio/webm" : "";
    this.mediaRecorder = mime
      ? new MediaRecorder(this.stream, { mimeType: mime })
      : new MediaRecorder(this.stream);

    this.mediaRecorder.ondataavailable = (e) => {
      if (e.data && e.data.size > 0) this.chunks.push(e.data);
    };
    this.mediaRecorder.onstop = () => {
      if (this.cancelled) {
        this.cancelled = false;
        return;
      }
      this.uploadAudio();
    };
    this.mediaRecorder.start();
    this.recording = true;
    this.setState("recording", "Recording…");
  },

  stopRecording() {
    this.recording = false;
    if (this.mediaRecorder && this.mediaRecorder.state !== "inactive") {
      this.mediaRecorder.stop();
    }
    this.stopStream();
    this.showProgress("Transcribing and translating to English…", true);
    this.setState("transcribing", "Processing…");
  },

  stopStream() {
    if (this.stream) {
      this.stream.getTracks().forEach((t) => t.stop());
      this.stream = null;
    }
  },

  async uploadAudio() {
    const type = (this.mediaRecorder && this.mediaRecorder.mimeType) || "audio/webm";
    const blob = new Blob(this.chunks, { type });
    if (blob.size === 0) {
      this.showSetup("No audio was captured. Please try recording again.");
      return;
    }

    const form = new FormData();
    form.append("audio", blob, "recording.webm");
    form.append("language", this.selectedLanguage);
    const csrf = document
      .querySelector("meta[name='csrf-token']")
      ?.getAttribute("content");

    try {
      this.abortController = new AbortController();
      const res = await fetch("/doctor/transcribe", {
        method: "POST",
        headers: csrf ? { "x-csrf-token": csrf } : {},
        body: form,
        signal: this.abortController.signal,
      });
      this.abortController = null;
      const data = await res.json().catch(() => ({}));
      if (res.ok && data.text) {
        this.showResult(data.text);
        this.setState("reviewing", "Review");
      } else {
        this.showSetup(data.error || "Transcription failed. Please try again.");
        console.error("Transcription error:", data.error || res.status);
      }
    } catch (err) {
      this.abortController = null;
      if (err.name === "AbortError") return;
      this.showSetup("A network error interrupted transcription. Please try again.");
      console.error("Transcription request failed:", err);
    }
  },

  insertText(text) {
    const ta = this.textarea;
    if (!ta) return;
    const existing = ta.value.trim();
    ta.value = existing ? existing + " " + text : text;
    // Fire input so LiveView's phx-change="validate" picks up the new value.
    ta.dispatchEvent(new Event("input", { bubbles: true }));
    ta.focus();
  },

  setState(state, label) {
    if (this.labelEl && label) this.labelEl.textContent = label;
    if (!this.button) return;
    this.button.classList.toggle("voice-recording", state === "recording");
    this.button.disabled = state !== "idle";
  },

  destroyed() {
    if (this.button && this.onClick) {
      this.button.removeEventListener("click", this.onClick);
    }
    this.startButton?.removeEventListener("click", this.onStart);
    this.cancelButton?.removeEventListener("click", this.onCancel);
    this.stopButton?.removeEventListener("click", this.onStop);
    this.progressCancelButton?.removeEventListener("click", this.onCancel);
    this.retryButton?.removeEventListener("click", this.onRetry);
    this.resultCancelButton?.removeEventListener("click", this.onCancel);
    this.saveButton?.removeEventListener("click", this.onSave);
    this.languageSelect?.removeEventListener("change", this.onLanguageChange);
    this.transcript?.removeEventListener("input", this.onTranscriptInput);
    this.modal?.removeEventListener("click", this.onModalClick);
    document.removeEventListener("keydown", this.onKeydown);
    this.stopStream();
  },
};

Hooks.ChartJS = {
  mounted() {
    this.renderChart();
  },

  updated() {
    this.renderChart();
  },

  destroyed() {
    this.destroyChart();
  },

  renderChart() {
    const rawConfig = this.el.dataset.chart;

    if (!rawConfig) return;

    try {
      const nextConfig = JSON.parse(rawConfig);
      const nextSignature = JSON.stringify(nextConfig);

      if (this.chartSignature === nextSignature) return;

      this.chartSignature = nextSignature;
      this.destroyChart();

      const canvas =
        this.el.querySelector("canvas") || document.createElement("canvas");

      if (!canvas.parentNode) {
        this.el.appendChild(canvas);
      }

      const context = canvas.getContext("2d");
      if (!context) return;

      this.chart = new Chart(context, nextConfig);
    } catch (error) {
      console.error("ChartJS hook failed to render chart:", error);
    }
  },

  destroyChart() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
  },
};

Hooks.QrCameraScanner = {
  mounted() {
    this.overlay = this.el.querySelector(".qr-overlay");
    this.statusEl = this.el.querySelector(".qr-status");
    this.detected = false;
    this.qrCode = null;

    // Remove the static <video> — Html5Qrcode injects its own
    const staticVideo = this.el.querySelector("video");
    if (staticVideo) staticVideo.remove();

    this.startScanner();
  },

  destroyed() {
    this.stopScanner();
  },

  startScanner() {
    if (typeof Html5Qrcode === "undefined") {
      if (this.statusEl)
        this.statusEl.textContent =
          "Scanner library not loaded. Please refresh.";
      return;
    }

    // Html5Qrcode needs a child div with a unique id to inject into
    const innerId = this.el.id + "-reader";
    this.readerDiv = document.createElement("div");
    this.readerDiv.id = innerId;
    this.el.insertBefore(this.readerDiv, this.el.firstChild);

    this.qrCode = new Html5Qrcode(innerId, { verbose: false });

    this.qrCode
      .start(
        { facingMode: "environment" },
        { fps: 15, qrbox: { width: 250, height: 250 } },
        (decodedText) => {
          if (this.detected) return;
          this.detected = true;
          this.handleScan(decodedText);
        },
        () => {
          /* scan failure — keep trying */
        },
      )
      .then(() => {
        if (this.statusEl)
          this.statusEl.textContent =
            "Point camera at QR code or Data Matrix...";
      })
      .catch((err) => {
        console.error("Camera error:", err);
        this.showPermissionButton();
      });
  },

  showPermissionButton() {
    if (this.statusEl) {
      this.statusEl.textContent = "Camera access is required to scan QR codes.";
    }

    // Avoid duplicating the button on retries
    const existing = this.el.querySelector(".camera-permission-btn");
    if (existing) return;

    const btn = document.createElement("button");
    btn.className =
      "camera-permission-btn mt-3 w-full flex items-center justify-center gap-2 bg-[#373896] hover:bg-[#2e2f7a] text-white text-sm font-medium py-2.5 px-4 rounded-lg transition-colors";
    btn.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M15 10l4.553-2.276A1 1 0 0121 8.723v6.554a1 1 0 01-1.447.894L15 14M3 8a2 2 0 012-2h8a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z" />
      </svg>
      Allow Camera Access
    `;
    btn.addEventListener("click", () => this.requestCameraPermission(btn));
    this.el.appendChild(btn);
  },

  requestCameraPermission(btn) {
    btn.disabled = true;
    btn.innerHTML = `
      <svg class="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
      </svg>
      Requesting...
    `;

    navigator.mediaDevices
      .getUserMedia({ video: { facingMode: "environment" } })
      .then((stream) => {
        // Stop the test stream — Html5Qrcode will open its own
        stream.getTracks().forEach((t) => t.stop());
        btn.remove();
        if (this.statusEl) this.statusEl.textContent = "Starting scanner...";
        this.detected = false;
        this.startScanner();
      })
      .catch(() => {
        btn.disabled = false;
        btn.innerHTML = `
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M15 10l4.553-2.276A1 1 0 0121 8.723v6.554a1 1 0 01-1.447.894L15 14M3 8a2 2 0 012-2h8a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z" />
          </svg>
          Allow Camera Access
        `;
        if (this.statusEl)
          this.statusEl.textContent =
            "Permission denied. Please enable camera access in your browser settings.";
      });
  },

  handleScan(rawValue) {
    this.stopScanner();
    if (this.overlay) {
      this.overlay.classList.remove("hidden");
      this.overlay.classList.add("flex");
    }
    if (this.statusEl) this.statusEl.textContent = "Code detected!";
    this.pushEvent("qr_scanned", { value: rawValue });
  },

  stopScanner() {
    if (this.qrCode) {
      this.qrCode.stop().catch(() => {});
      this.qrCode = null;
    }
  },
};

Hooks.SignaturePad = {
  mounted() {
    const canvas = this.el.querySelector("canvas");
    const clearBtn = this.el.querySelector("[data-clear]");
    const undoBtn = this.el.querySelector("[data-undo]");
    const hiddenInput = this.el.querySelector("input[type=hidden]");

    const syncHiddenValue = () => {
      if (hiddenInput)
        hiddenInput.value = this.pad.isEmpty() ? "" : this.pad.toDataURL();
    };

    const restoreFromHidden = () => {
      if (hiddenInput?.value) {
        try {
          this.pad.fromDataURL(hiddenInput.value);
        } catch (_error) {
          hiddenInput.value = "";
          this.pad.clear();
        }
      }
    };

    this.pad = new SignaturePad(canvas, {
      backgroundColor: "rgb(255,255,255)",
      penColor: "#1e293b",
      minWidth: 1,
      maxWidth: 2.5,
    });

    // Resize canvas to match display size (hi-DPI aware)
    const resizeCanvas = () => {
      const currentValue =
        hiddenInput?.value ||
        (this.pad && !this.pad.isEmpty() ? this.pad.toDataURL() : "");
      const ratio = Math.max(window.devicePixelRatio || 1, 1);
      canvas.width = canvas.offsetWidth * ratio;
      canvas.height = canvas.offsetHeight * ratio;
      canvas.getContext("2d").scale(ratio, ratio);
      this.pad.clear();

      if (currentValue) {
        hiddenInput.value = currentValue;
        restoreFromHidden();
      }
    };
    resizeCanvas();
    window.addEventListener("resize", resizeCanvas);
    this._resizeCanvas = resizeCanvas;

    // Persist data to hidden input on stroke end
    this.pad.addEventListener("endStroke", () => {
      syncHiddenValue();
    });

    if (clearBtn) {
      clearBtn.addEventListener("click", () => {
        this.pad.clear();
        if (hiddenInput) hiddenInput.value = "";
      });
    }

    if (undoBtn) {
      undoBtn.addEventListener("click", () => {
        const data = this.pad.toData();
        if (data.length > 0) {
          data.pop();
          this.pad.fromData(data);
          syncHiddenValue();
        }
      });
    }

    restoreFromHidden();
  },

  destroyed() {
    window.removeEventListener("resize", this._resizeCanvas);
    if (this.pad) this.pad.off();
  },
};

// Hook to stop click propagation (e.g. for delete buttons inside table rows with row_click)
Hooks.ClickNoPropagate = {
  mounted() {
    this.el.addEventListener("click", (e) => e.stopPropagation());
  },
};

// Hook to capture input/select values on change/blur for quality assurance charts
Hooks.QualityAssuranceInput = {
  mounted() {
    const el = this.el;
    let lastValue = el.value || "";

    // Handle change event (for selects - fires immediately on selection change)
    const handleChange = (e) => {
      const value = e.target.value || "";
      const day = el.getAttribute("phx-value-day");
      const field = el.getAttribute("phx-value-field");

      if (day && field) {
        lastValue = value;
        this.pushEvent("update_entry", {
          day: day,
          field: field,
          value: value,
        });
      }
    };

    // Handle blur event (for inputs to save on focus loss, but only if value changed)
    const handleBlur = (e) => {
      const value = e.target.value || "";
      const day = el.getAttribute("phx-value-day");
      const field = el.getAttribute("phx-value-field");

      // Only update if it's an input and the value has changed
      if (day && field && e.target.tagName === "INPUT" && value !== lastValue) {
        lastValue = value;
        this.pushEvent("update_entry", {
          day: day,
          field: field,
          value: value,
        });
      }
    };

    el.addEventListener("change", handleChange);
    el.addEventListener("blur", handleBlur);

    // Store handlers for cleanup
    this.handleChange = handleChange;
    this.handleBlur = handleBlur;
  },

  updated() {
    // Update lastValue when the element value changes from server
    this.el.lastValue = this.el.value || "";
  },

  destroyed() {
    if (this.handleChange) {
      this.el.removeEventListener("change", this.handleChange);
    }
    if (this.handleBlur) {
      this.el.removeEventListener("blur", this.handleBlur);
    }
  },
};

Hooks.datamatrix = {
  mounted() {
    const codes = document.querySelectorAll(".datamatrix");
    for (var i = 0; i < codes.length; i++) {
      let txt = codes[i].id;

      var element2 = document.getElementById(txt);
      data = {
        msg: txt,
        dim: 70,
        rct: 0,
        pad: 0,
        pal: ["#000000", "#f2f4f8"],
        vrb: 0,
      };
      element2.appendChild(DATAMatrix(data)).onclick = function () {
        return download(element2.innerHTML);
      };
    }
  },
};

Hooks.DownloadableDiv = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      if (e.target.matches("[data-download-trigger]")) {
        e.preventDefault();

        // Get the target div using the data attribute
        const targetSelector = e.target.getAttribute("data-target-div");
        const targetDiv = document.querySelector(targetSelector);

        if (!targetDiv) {
          console.error(`Target div not found: ${targetSelector}`);
          return;
        }

        // Use html2canvas directly from global scope (from CDN)
        html2canvas(targetDiv, {
          backgroundColor: null,
          useCORS: true,
          scale: 2, // Higher scale for better quality
          logging: false,
        })
          .then((canvas) => {
            // Convert canvas to blob
            canvas.toBlob((blob) => {
              // Create download link
              const downloadLink = document.createElement("a");
              downloadLink.href = URL.createObjectURL(blob);

              // Get filename from data attribute or use default
              const filename =
                e.target.getAttribute("data-filename") || "download.png";
              downloadLink.download = filename;

              // Trigger download
              document.body.appendChild(downloadLink);
              downloadLink.click();
              document.body.removeChild(downloadLink);

              // Clean up
              URL.revokeObjectURL(downloadLink.href);
            }, "image/png");
          })
          .catch((err) => {
            console.error("Error creating image:", err);
          });
      }
    });
  },
};

Hooks.CardQrCode = {
  mounted() {
    var qrcode = new QRCode(document.getElementById("qrcode"), {
      width: 120,
      height: 120,
    });

    function makeCode() {
      var elText = document.getElementById("text");

      if (!elText.value) {
        alert("Input a text");
        elText.focus();
        return;
      }

      qrcode.makeCode(elText.value);
    }

    makeCode();
  },
  updated() {
    var qrcode = new QRCode(document.getElementById("qrcode"), {
      width: 120,
      height: 120,
    });

    function makeCode() {
      var elText = document.getElementById("text");

      if (!elText.value) {
        alert("Input a text");
        elText.focus();
        return;
      }

      qrcode.makeCode(elText.value);
    }

    makeCode();
  },
};

Hooks.MedicalCampQrCode = {
  mounted() {
    this._render();
  },
  updated() {
    this.el.innerHTML = "";
    this._render();
  },
  _render() {
    const txt = this.el.dataset.url;
    const data = {
      msg: txt,
      dim: 70,
      rct: 0,
      pad: 0,
      pal: ["#000000", "#f2f4f8"],
      vrb: 0,
    };
    this.el.appendChild(DATAMatrix(data));
  },
};

Hooks.CKEditor = {
  mounted() {
    const editorElement = this.el;
    const updateEvent = editorElement.dataset.updateEvent || "update-content";

    // Initialize CKEditor
    ClassicEditor.create(editorElement, {
      // Optional: Configure toolbar
      toolbar: [
        "heading",
        "|",
        "bold",
        "italic",
        "underline",
        "|",
        "link",
        "|",
        "bulletedList",
        "numberedList",
        "|",
        "outdent",
        "indent",
        "|",
        "blockQuote",
        "insertTable",
        "|",
        "undo",
        "redo",
      ],
    })
      .then((editor) => {
        // Store editor instance
        this.editor = editor;

        // Set initial content if provided
        const initialContent = editorElement.dataset.initialContent || "";
        if (initialContent) {
          editor.setData(initialContent);
        }

        // Listen for content changes
        editor.model.document.on("change:data", () => {
          const content = editor.getData();

          // Send content back to LiveView
          this.pushEvent(updateEvent, { content: content });
        });

        // Optional: Debounce updates to avoid too frequent calls
        // You can uncomment and modify this if needed
        /*
        let timeout
        editor.model.document.on('change:data', () => {
          clearTimeout(timeout)
          timeout = setTimeout(() => {
            const content = editor.getData()
            this.pushEvent(updateEvent, { content: content })
          }, 500) // 500ms debounce
        })
        */
      })
      .catch((error) => {
        console.error("CKEditor initialization error:", error);
      });
  },

  updated() {
    // Handle updates from LiveView
    if (this.editor) {
      const newContent = this.el.dataset.initialContent || "";
      const currentContent = this.editor.getData();

      // Only update if content is different to avoid cursor position issues
      if (newContent !== currentContent) {
        this.editor.setData(newContent);
      }
    }
  },

  destroyed() {
    // Clean up editor instance
    if (this.editor) {
      this.editor.destroy().catch((error) => {
        console.error("CKEditor cleanup error:", error);
      });
    }
  },
};

Hooks.QrCode = {
  mounted() {
    var qrcode = new QRCode(document.getElementById("qrcode"), {
      width: 220,
      height: 220,
    });

    function makeCode() {
      var elText = document.getElementById("text");

      if (!elText.value) {
        alert("Input a text");
        elText.focus();
        return;
      }

      qrcode.makeCode(elText.value);
    }

    makeCode();
  },
  updated() {
    var qrcode = new QRCode(document.getElementById("qrcode"), {
      width: 200,
      height: 200,
    });

    function makeCode() {
      var elText = document.getElementById("text");

      if (!elText.value) {
        alert("Input a text");
        elText.focus();
        return;
      }

      qrcode.makeCode(elText.value);
    }

    makeCode();
  },
};

Hooks.CKEditor = {
  mounted() {
    const textarea = this.el;
    const form = textarea.closest("form");

    // Create a div for CKEditor right after the textarea
    const editorDiv = document.createElement("div");
    editorDiv.id = textarea.id + "_editor";
    editorDiv.style.minHeight = "200px";
    editorDiv.style.border = "1px solid #d1d5db";
    editorDiv.style.borderRadius = "0.375rem";
    textarea.style.display = "none"; // Hide the original textarea
    textarea.parentNode.insertBefore(editorDiv, textarea.nextSibling);

    // Initialize CKEditor
    ClassicEditor.create(editorDiv, {
      toolbar: [
        "heading",
        "|",
        "bold",
        "italic",
        "underline",
        "|",
        "link",
        "|",
        "bulletedList",
        "numberedList",
        "|",
        "outdent",
        "indent",
        "|",
        "blockQuote",
        "insertTable",
        "|",
        "undo",
        "redo",
      ],
      // Set minimum height
      editorConfig: {
        style: "height: 200px;",
      },
    })
      .then((editor) => {
        this.editor = editor;

        // Set initial content from textarea
        const initialContent = textarea.value || "";
        if (initialContent) {
          editor.setData(initialContent);
        }

        // Update textarea when editor content changes
        editor.model.document.on("change:data", () => {
          const content = editor.getData();
          textarea.value = content;

          // Trigger change event for LiveView form validation
          textarea.dispatchEvent(new Event("input", { bubbles: true }));

          // Also trigger change event for any other listeners
          textarea.dispatchEvent(new Event("change", { bubbles: true }));
        });

        // Handle form submission
        if (form) {
          form.addEventListener("submit", () => {
            textarea.value = editor.getData();
          });
        }
      })
      .catch((error) => {
        console.error("CKEditor initialization error:", error);
        // Show textarea if editor fails to load
        textarea.style.display = "block";
      });
  },

  destroyed() {
    // Clean up editor instance
    if (this.editor) {
      this.editor
        .destroy()
        .then(() => {
          // Show original textarea
          if (this.el) {
            this.el.style.display = "block";
          }
          // Remove editor div
          const editorDiv = document.getElementById(this.el.id + "_editor");
          if (editorDiv && editorDiv.parentNode) {
            editorDiv.parentNode.removeChild(editorDiv);
          }
        })
        .catch((error) => {
          console.error("CKEditor cleanup error:", error);
        });
    }
  },
};

// ── Sidebar collapse ─────────────────────────────────────────────────────────
// The inline script in root.html.heex already applies body.sidebar-collapsed
// before first paint. This hook only needs to wire up the toggle button and
// enable CSS transitions once the initial state is settled (no load-time flash).
Hooks.SidebarCollapse = {
  mounted() {
    this.handleToggleClick = () => {
      if (window.matchMedia("(max-width: 1023px)").matches) {
        const isOpen = document.body.classList.contains("sidebar-mobile-open");
        this.setMobileOpen(!isOpen);
      } else {
        const nowCollapsed =
          !document.body.classList.contains("sidebar-collapsed");
        this.applyDesktopState(nowCollapsed);
        localStorage.setItem("sidebar-collapsed", nowCollapsed);
      }
    };

    this.handleMobileOpenClick = () => this.setMobileOpen(true);
    this.handleBackdropClick = () => this.setMobileOpen(false);
    this.handleKeydown = (event) => {
      if (event.key === "Escape") {
        this.setMobileOpen(false);
      }
    };

    this.handleViewportChange = (event) => {
      if (event.matches) {
        this.setMobileOpen(false);
      }
    };

    // Confirm state from localStorage (the inline script already set the class,
    // so this is a no-op in almost all cases — but guards against any edge case).
    const collapsed = localStorage.getItem("sidebar-collapsed") === "true";
    this.applyDesktopState(collapsed);
    this.setMobileOpen(false);

    // Enable CSS transitions only AFTER the initial render has settled.
    // Using two rAFs ensures we're past the first paint before transitions fire.
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        document.body.classList.add("sidebar-ready");
      });
    });

    const btn = document.getElementById("sidebar-toggle-btn");
    const mobileOpenBtn = document.getElementById("sidebar-mobile-open-btn");
    const backdrop = document.getElementById("sidebar-backdrop");
    this.sidebarDesktopMedia = window.matchMedia("(min-width: 1024px)");

    if (btn) {
      btn.addEventListener("click", this.handleToggleClick);
    }

    if (mobileOpenBtn) {
      mobileOpenBtn.addEventListener("click", this.handleMobileOpenClick);
    }

    if (backdrop) {
      backdrop.addEventListener("click", this.handleBackdropClick);
    }

    window.addEventListener("keydown", this.handleKeydown);
    this.sidebarDesktopMedia.addEventListener("change", this.handleViewportChange);
  },

  destroyed() {
    const btn = document.getElementById("sidebar-toggle-btn");
    const mobileOpenBtn = document.getElementById("sidebar-mobile-open-btn");
    const backdrop = document.getElementById("sidebar-backdrop");

    if (btn) {
      btn.removeEventListener("click", this.handleToggleClick);
    }

    if (mobileOpenBtn) {
      mobileOpenBtn.removeEventListener("click", this.handleMobileOpenClick);
    }

    if (backdrop) {
      backdrop.removeEventListener("click", this.handleBackdropClick);
    }

    window.removeEventListener("keydown", this.handleKeydown);
    this.sidebarDesktopMedia?.removeEventListener("change", this.handleViewportChange);
  },

  applyDesktopState(collapsed) {
    if (collapsed) {
      document.body.classList.add("sidebar-collapsed");
    } else {
      document.body.classList.remove("sidebar-collapsed");
    }
  },

  setMobileOpen(open) {
    if (open) {
      document.body.classList.add("sidebar-mobile-open");
    } else {
      document.body.classList.remove("sidebar-mobile-open");
    }
  },
};
// ── End Sidebar collapse ──────────────────────────────────────────────────────

Hooks.DownloadPDF = {
  mounted() {
    this.el.addEventListener("click", () => {
      const invoice = document.getElementById("insurance-invoice");
      if (!invoice) {
        window.print();
        return;
      }

      const original = document.body.innerHTML;
      const style = `
        <style>
          body { font-family: sans-serif; background: white; margin: 0; padding: 0; }
          @page { size: A4; margin: 15mm; }
          * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
        </style>`;
      document.body.innerHTML = style + invoice.outerHTML;
      window.print();
      document.body.innerHTML = original;
      window.liveSocket && window.liveSocket.reconnect();
    });
  },
};

Hooks.RoomQrCode = {
  mounted() {
    var qrcode = new QRCode(document.getElementById("qrcode"), {
      width: 120,
      height: 120,
    });

    function makeCode() {
      var elText = document.getElementById("text");

      if (!elText.value) {
        alert("Input a text");
        elText.focus();
        return;
      }

      qrcode.makeCode(elText.value);
    }

    makeCode();
  },
  updated() {
    var qrcode = new QRCode(document.getElementById("qrcode"), {
      width: 120,
      height: 120,
    });

    function makeCode() {
      var elText = document.getElementById("text");

      if (!elText.value) {
        alert("Input a text");
        elText.focus();
        return;
      }

      qrcode.makeCode(elText.value);
    }

    makeCode();
  },
};

Hooks.FillQuestion = {
  mounted() {
    this.handleEvent("fill_camp_question", ({ question }) => {
      this.el.value = question;
      this.el.dispatchEvent(new Event("input", { bubbles: true }));
    });
  },
};

Hooks.ServicesSwiper = {
  mounted() {
    this.swiper = new Swiper(this.el, {
      slidesPerView: 1,
      spaceBetween: 24,
      loop: true,
      navigation: {
        nextEl: ".services-swiper-next",
        prevEl: ".services-swiper-prev",
      },
      breakpoints: {
        640: { slidesPerView: 2 },
        1024: { slidesPerView: 3 },
      },
    });
  },
  destroyed() {
    if (this.swiper) this.swiper.destroy();
  },
};

// Saves a form's in-progress values to localStorage, survives logout/crash/
// disconnect. Opt in via `phx-hook="DraftPersistence"` + a record-specific
// `data-draft-key` (e.g. "doctor_note:<patient_id>:<note_id>"). No server
// writes ever - clears only when the LiveView pushes `draft_saved`.
Hooks.DraftPersistence = {
  SAVE_DEBOUNCE_MS: 1000,
  EXPIRY_MS: 24 * 60 * 60 * 1000,

  mounted() {
    this.key = "medcamp:draft:" + this.el.dataset.draftKey;
    this.saveTimer = null;

    this.offerRestoreIfPresent();

    this.el.addEventListener("input", () => this.scheduleSave());
    this.handleEvent("draft_saved", () => this.clearDraft());
  },

  destroyed() {
    clearTimeout(this.saveTimer);
    if (this.banner) this.banner.remove();
  },

  scheduleSave() {
    clearTimeout(this.saveTimer);
    this.saveTimer = setTimeout(() => this.saveDraft(), this.SAVE_DEBOUNCE_MS);
  },

  saveDraft() {
    let data = Object.fromEntries(new FormData(this.el).entries());
    try {
      localStorage.setItem(
        this.key,
        JSON.stringify({ savedAt: Date.now(), data }),
      );
    } catch (_error) {
      // localStorage unavailable (private browsing, quota, etc.) - drafts
      // just aren't persisted this session, nothing else depends on it.
    }
  },

  clearDraft() {
    try {
      localStorage.removeItem(this.key);
    } catch (_error) {
      // see saveDraft()
    }
    if (this.banner) {
      this.banner.remove();
      this.banner = null;
    }
  },

  readDraft() {
    let raw;
    try {
      raw = localStorage.getItem(this.key);
    } catch (_error) {
      return null;
    }
    if (!raw) return null;

    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch (_error) {
      return null;
    }
    if (Date.now() - parsed.savedAt > this.EXPIRY_MS) return null;
    return parsed.data;
  },

  offerRestoreIfPresent() {
    let draft = this.readDraft();
    if (!draft) return;

    this.banner = document.createElement("div");
    this.banner.setAttribute("role", "alert");
    this.banner.className =
      "mb-4 flex items-center justify-between gap-3 rounded-lg p-3 ring-1 " +
      "bg-amber-50 text-amber-800 ring-amber-500";
    this.banner.innerHTML =
      '<p class="text-sm">You have unsaved changes from earlier. Restore them?</p>' +
      '<span class="flex gap-2 flex-shrink-0">' +
      '<button type="button" data-role="restore" class="rounded-md bg-amber-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-amber-700">Restore</button>' +
      '<button type="button" data-role="discard" class="rounded-md px-3 py-1.5 text-sm font-medium text-amber-800 hover:bg-amber-100">Discard</button>' +
      "</span>";
    this.el.insertBefore(this.banner, this.el.firstChild);

    this.banner
      .querySelector('[data-role="restore"]')
      .addEventListener("click", () => this.restoreDraft(draft));
    this.banner
      .querySelector('[data-role="discard"]')
      .addEventListener("click", () => this.clearDraft());
  },

  restoreDraft(draft) {
    Object.entries(draft).forEach(([name, value]) => {
      let field = this.el.elements.namedItem(name);
      if (!field || typeof value !== "string") return;

      field.value = value;
      // Dispatched (not just set) so the form's own phx-change picks it up
      // exactly as if the doctor had typed it, keeping the server-side
      // form/changeset in sync the normal way.
      field.dispatchEvent(new Event("input", { bubbles: true }));
    });

    if (this.banner) {
      this.banner.remove();
      this.banner = null;
    }
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

(function initInactivityLogout() {
  let authMeta = document.querySelector("meta[name='user-authenticated']");
  if (!authMeta || authMeta.content !== "true") return;

  let TIMEOUT_MS = 30 * 60 * 1000;
  let WARNING_MS = 60 * 1000;

  let CHECK_INTERVAL_MS = 5 * 1000;
  // Shared via localStorage across tabs, so activity in one tab keeps the
  // whole session alive - otherwise an idle tab could log out a session
  // that's still active elsewhere.
  let ACTIVITY_WRITE_THROTTLE_MS = 3 * 1000;
  let LOGOUT_URL = "/users/log_out/inactivity";
  let STORAGE_KEY = "medcamp:last-activity-at";

  let warningEl = null;
  let lastWriteAt = 0;

  // Same position/tokens/motion as the app's own <.flash> component
  // (core_components.ex), amber since this is a caution, not an error, and
  // the same enter/exit transition every other shown/hidden surface in the
  // app uses (core_components.ex's `show/1`/`hide/1`).
  function hideWarning() {
    if (!warningEl) return;
    let el = warningEl;
    warningEl = null;

    el.classList.remove(
      "ease-out",
      "duration-300",
      "opacity-100",
      "sm:scale-100",
    );
    el.classList.add(
      "ease-in",
      "duration-200",
      "opacity-0",
      "translate-y-4",
      "sm:scale-95",
    );
    setTimeout(() => el.remove(), 200);
  }

  function showWarning() {
    if (warningEl) return;
    warningEl = document.createElement("div");
    warningEl.id = "inactivity-warning";
    warningEl.setAttribute("role", "alert");
    warningEl.className =
      "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1 " +
      "bg-amber-50 text-amber-800 ring-amber-500 " +
      "transition-all transform ease-out duration-300 " +
      "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95";
    warningEl.innerHTML =
      '<p class="flex items-center gap-1.5 text-sm font-semibold leading-6">' +
      '<svg class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">' +
      '<path fill-rule="evenodd" clip-rule="evenodd" d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.63-1.516 2.63H3.72c-1.347 0-2.189-1.463-1.515-2.63L8.485 2.495ZM10 6a.75.75 0 0 1 .75.75v3.5a.75.75 0 0 1-1.5 0v-3.5A.75.75 0 0 1 10 6Zm0 8a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z" />' +
      "</svg>" +
      "Signed out soon" +
      "</p>" +
      '<p class="mt-2 text-sm leading-5">' +
      "You'll be signed out in 1 minute due to inactivity. Move your mouse or press a key to stay signed in." +
      "</p>";
    document.body.appendChild(warningEl);

    // Force a reflow so the browser registers the "entering" classes before
    // they're swapped, otherwise there's nothing for the transition to
    // animate from.
    void warningEl.offsetWidth;
    warningEl.classList.remove("opacity-0", "translate-y-4", "sm:scale-95");
    warningEl.classList.add("opacity-100", "translate-y-0", "sm:scale-100");
  }

  function logout() {
    let form = document.createElement("form");
    form.method = "post";
    form.action = LOGOUT_URL;
    form.style.display = "none";

    let methodInput = document.createElement("input");
    methodInput.type = "hidden";
    methodInput.name = "_method";
    methodInput.value = "delete";
    form.appendChild(methodInput);

    let csrfInput = document.createElement("input");
    csrfInput.type = "hidden";
    csrfInput.name = "_csrf_token";
    csrfInput.value = csrfToken;
    form.appendChild(csrfInput);

    document.body.appendChild(form);
    form.submit();
  }

  function recordActivity() {
    let now = Date.now();
    // Throttled so a continuous mousemove/scroll doesn't hit localStorage on
    // every single event - one write every few seconds is plenty.
    if (now - lastWriteAt < ACTIVITY_WRITE_THROTTLE_MS) return;
    lastWriteAt = now;
    hideWarning();
    try {
      localStorage.setItem(STORAGE_KEY, String(now));
    } catch (_error) {
      // localStorage unavailable (private browsing, quota, etc.) - this tab
      // falls back to tracking only its own activity via lastWriteAt.
    }
  }

  function lastActivityAt() {
    let stored = null;
    try {
      stored = localStorage.getItem(STORAGE_KEY);
    } catch (_error) {
      stored = null;
    }
    let fromStorage = stored ? Number(stored) : 0;
    return Math.max(fromStorage, lastWriteAt);
  }

  function checkInactivity() {
    let idleFor = Date.now() - lastActivityAt();

    if (idleFor >= TIMEOUT_MS) {
      logout();
    } else if (idleFor >= TIMEOUT_MS - WARNING_MS) {
      showWarning();
    } else {
      hideWarning();
    }
  }

  [
    "mousemove",
    "mousedown",
    "keydown",
    "scroll",
    "touchstart",
    "click",
  ].forEach((eventName) => {
    window.addEventListener(eventName, recordActivity, { passive: true });
  });
  window.addEventListener("phx:page-loading-stop", recordActivity);
  // Another tab recording activity should clear this tab's warning
  // immediately too, rather than waiting for the next poll.
  window.addEventListener("storage", (event) => {
    if (event.key === STORAGE_KEY) hideWarning();
  });

  recordActivity();
  setInterval(checkInactivity, CHECK_INTERVAL_MS);
})();

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
