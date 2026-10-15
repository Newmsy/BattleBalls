## Clip export: records a fight as a vertical (9:16) video in the browser.
##
## The game plays the clip full screen in a 720x1280 layout (clip_card.gd);
## the page copies that part of the game canvas into a 720x1280 canvas each
## frame and records it with MediaRecorder (MP4 on Safari, WebM elsewhere),
## with the game's sound when the browser allows it. Saving goes through the
## share sheet ("Save Video" on iPhone) or a download.
##
## Copying a WebGL canvas needs preserveDrawingBuffer, which the export
## preset's head_include switches on before Godot creates its context; the
## same snippet remembers the audio nodes Godot plays through so they can be
## recorded too (window.bbGLPreserved, window.bbAudioOuts).
extends RefCounted

const WIDTH := 720
const HEIGHT := 1280

const CLIP_JS := """
if (!window.bbClip) {
	const pickType = () => {
		if (!MediaRecorder.isTypeSupported) return "";
		// H.264 first: it plays and uploads everywhere (Safari only offers MP4).
		for (const t of ["video/mp4;codecs=avc1.42E01E,mp4a.40.2", "video/mp4;codecs=avc1", "video/mp4", "video/webm;codecs=vp9", "video/webm"]) {
			if (MediaRecorder.isTypeSupported(t)) return t;
		}
		return "";
	};
	window.bbClip = {
		status: "", file: null, rec: null, loop: 0, discard: false, noAudio: false,
		supported() {
			return !!(window.MediaRecorder && HTMLCanvasElement.prototype.captureStream && window.bbGLPreserved);
		},
		audioTrack() {
			if (this.noAudio || !window.bbAudioOuts || !window.bbAudioOuts.size) return null;
			const nodes = [...window.bbAudioOuts];
			const ctx = nodes[0].context;
			if (!ctx.createMediaStreamDestination) return null;
			if (!window.bbAudioTap || window.bbAudioTap.context !== ctx) {
				window.bbAudioTap = ctx.createMediaStreamDestination();
				for (const n of nodes) { try { if (n.context === ctx) n.connect(window.bbAudioTap); } catch (e) {} }
			}
			return window.bbAudioTap.stream.getAudioTracks()[0] || null;
		},
		start(rect, name) {
			this.file = null;
			this.discard = false;
			try {
				const src = document.querySelector("canvas");
				const out = document.createElement("canvas");
				out.width = 720; out.height = 1280; // WIDTH x HEIGHT
				const g = out.getContext("2d");
				const draw = () => {
					g.drawImage(src, rect.x * src.width, rect.y * src.height, rect.w * src.width, rect.h * src.height, 0, 0, out.width, out.height);
					this.loop = requestAnimationFrame(draw);
				};
				draw();
				const stream = out.captureStream(30);
				const audio = this.audioTrack();
				if (audio) stream.addTrack(audio);
				const type = pickType();
				const opts = { videoBitsPerSecond: 5000000 };
				if (type) opts.mimeType = type;
				const rec = new MediaRecorder(stream, opts);
				const chunks = [];
				rec.ondataavailable = (e) => { if (e.data && e.data.size) chunks.push(e.data); };
				rec.onstop = () => {
					cancelAnimationFrame(this.loop);
					stream.getVideoTracks().forEach((t) => t.stop());
					if (this.discard) { this.status = ""; return; }
					const mime = (rec.mimeType || type || "video/webm").split(";")[0];
					const blob = new Blob(chunks, { type: mime });
					console.log("CLIP_BLOB " + blob.size + " " + mime + (audio ? " audio" : ""));
					if (blob.size < 20000) { this.fail(audio); return; }
					this.file = new File([blob], name + (mime.indexOf("mp4") >= 0 ? ".mp4" : ".webm"), { type: mime });
					this.status = "ready";
				};
				rec.onerror = () => { cancelAnimationFrame(this.loop); this.fail(audio); };
				rec.start(1000);
				this.rec = rec;
				this.status = "recording";
				return true;
			} catch (e) {
				console.log("CLIP_ERROR " + e);
				cancelAnimationFrame(this.loop);
				this.status = "failed";
				return false;
			}
		},
		// A failed take with sound is retried without it next time.
		fail(hadAudio) {
			if (hadAudio) this.noAudio = true;
			this.status = "failed";
		},
		stop(discard) {
			this.discard = !!discard;
			if (this.rec && this.rec.state !== "inactive") {
				this.status = discard ? "" : "encoding";
				this.rec.stop();
			}
		},
		// Runs inside the player's tap (see SHARE_JS in main.gd).
		save(done) {
			const f = this.file;
			if (!f) { done("failed"); return; }
			if (navigator.canShare && navigator.share && navigator.canShare({ files: [f] })) {
				navigator.share({ files: [f], title: "Battle Balls" })
					.then(() => done("saved"), (err) => err && err.name === "AbortError" ? done("cancelled") : this.download(done));
			} else {
				this.download(done);
			}
		},
		download(done) {
			const a = document.createElement("a");
			a.href = URL.createObjectURL(this.file);
			a.download = this.file.name;
			document.body.appendChild(a);
			a.click();
			a.remove();
			setTimeout(() => URL.revokeObjectURL(a.href), 60000);
			done("downloaded");
		},
	};
}
"""


static func install() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(CLIP_JS, true)


## True when this browser can record the clip to a video file.
static func can_record() -> bool:
	return OS.has_feature("web") and bool(JavaScriptBridge.eval("!!(window.bbClip && window.bbClip.supported())", true))


## Starts recording `rect` (fractions of the canvas). False if it couldn't.
static func start(rect: Rect2, file_name: String) -> bool:
	var r := {"x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y}
	return bool(JavaScriptBridge.eval("window.bbClip.start(%s, %s)" % [JSON.stringify(r), JSON.stringify(file_name)], true))


static func stop(discard := false) -> void:
	JavaScriptBridge.eval("window.bbClip && window.bbClip.stop(%s)" % ("true" if discard else "false"), true)


## "", "recording", "encoding", "ready" or "failed".
static func status() -> String:
	return str(JavaScriptBridge.eval("window.bbClip ? window.bbClip.status : ''", true))


static func file_name(p1: String, p2: String) -> String:
	return "battle-balls-%s-vs-%s" % [p1, p2]


## Clip playback speed: long fights are sped up so the clip stays short
## enough to post (the finisher still plays in slow motion).
static func fight_speed(fight_seconds: float) -> float:
	return clampf(fight_seconds / 24.0, 1.0, 3.0)
