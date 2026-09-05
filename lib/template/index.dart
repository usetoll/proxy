final index = '''
<!doctype html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Loading...</title><style>:root {
            --primary-blue: rgb(46, 55, 103);
            --bg: #f8fafc;
            --text: #0f172a;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
        }

        body {
            min-height: 100vh;
            display: grid;
            place-items: center;
            background: var(--bg);
            color: var(--text);
        }

        .loading-container {
            text-align: center;
            width: 300px;
        }


        .spinner {
            width: 56px;
            height: 56px;
            border: 6px solid #dbeafe;
            border-top-color: var(--primary-blue);
            border-radius: 50%;
            margin: 0 auto 16px;
            animation: spin 0.9s linear infinite;
        }

        .loading-text {
            font-size: 1rem;
            color: var(--primary-blue);
            letter-spacing: 0.4px;
            margin-top: 20px;
            margin-bottom: 20px;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }</style><script type="module">/******/ var __webpack_modules__ = ({

/***/ "./src/load-manager.ts"
(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   LoadManager: () => (/* binding */ LoadManager)
/* harmony export */ });
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__("./src/util.ts");

class LoadManager {
    _time = 0;
    _busyCount = 0;
    _expCallTime = 1000;
    step = 0;
    period = 1000;
    setRate(v) {
        this._expCallTime = v * this.period;
    }
    timeBegin() {
        this._time = performance.now();
    }
    timeEnd() {
        const t = performance.now() - this._time;
        this._time = Math.max(t, 0.1);
    }
    idle() {
        // update step
        const stepPerMs = this.step / this._time;
        // console.log(
        //   'step:', this.step,
        //   'time:', this._time,
        //   'stepPerMs:',stepPerMs,
        //   'expCallTime',this._expCallTime
        // )
        this.step = Math.ceil(stepPerMs * this._expCallTime);
        const remain = this.period - this._time;
        if (remain > 0) {
            this._busyCount = 0;
            return (0,_util__WEBPACK_IMPORTED_MODULE_0__.sleep)(remain);
        }
        if (++this._busyCount > 5) {
            this._busyCount = 0;
            return (0,_util__WEBPACK_IMPORTED_MODULE_0__.sleep)(0);
        }
        // no sleep (sync)
    }
}


/***/ },

/***/ "./src/util.ts"
(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   bswap: () => (/* binding */ bswap),
/* harmony export */   fillTmpl: () => (/* binding */ fillTmpl),
/* harmony export */   randU32: () => (/* binding */ randU32),
/* harmony export */   sleep: () => (/* binding */ sleep)
/* harmony export */ });
function sleep(ms) {
    return new Promise(fn => {
        setTimeout(fn, ms);
    });
}
function randU32() {
    return Math.random() * 0xFFFFFFFF >>> 0;
}
function bswap(n) {
    return (((n & 0x0000FF) << 24) |
        ((n & 0x00FF00) << 8) |
        ((n & 0xFF0000) >> 8) |
        (n >>> 24)) >>> 0;
}
function fillTmpl(tmpl, params) {
    // glsl is embedded in base64 to avoid issue with dart templating
    return atob(tmpl).replace(/__(\\w+)__/g, (_, \$1) => {
        return params[\$1] + '';
    });
}


/***/ },

/***/ "./src/webgl2.ts"
(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   init: () => (/* binding */ init),
/* harmony export */   setLoadRate: () => (/* binding */ setLoadRate),
/* harmony export */   start: () => (/* binding */ start),
/* harmony export */   stop: () => (/* binding */ stop)
/* harmony export */ });
/* harmony import */ var _assets_webgl2_b64_glsl__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__("./src/assets/webgl2.b64.glsl");
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__("./src/util.ts");
/* harmony import */ var _load_manager__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__("./src/load-manager.ts");



const MAGIC_CODE = 0x19260817;
const texW = 1024;
const texH = 1024;
const thread = texW * texH;
let events;
let isRunning;
const loadmgr = new _load_manager__WEBPACK_IMPORTED_MODULE_2__.LoadManager();
loadmgr.period = 200;
function createWebGl() {
    const canvas = new OffscreenCanvas(texW, texH);
    const ctx = canvas.getContext('webgl2', {
        powerPreference: 'high-performance',
    });
    return { canvas, ctx };
}
function init(handler) {
    events = handler;
    const { ctx } = createWebGl();
    return !!ctx;
}
async function start(words, masks) {
    try {
        await startImpl(words, masks);
    }
    catch (err) {
        events.onError(err);
    }
    isRunning = false;
}
async function startImpl(words, masks) {
    const { canvas, ctx: gl } = createWebGl();
    if (!gl) {
        throw Error('webgl error');
    }
    loadmgr.step = 128;
    isRunning = true;
    canvas.addEventListener('webglcontextlost', () => {
        isRunning = false;
        events.onError(Error('webgl contextlost'));
    });
    // setTimeout(() => {
    //   console.log('mock contextlost')
    //   gl.getExtension("WEBGL_lose_context")!.loseContext()
    // }, 3000)
    const vertexData = new Float32Array([
        -1, +1, // left top
        -1, -1, // left bottom
        +1, +1, // right top
        +1, -1, // right bottom
    ]);
    gl.bindBuffer(34962 /* GL.ARRAY_BUFFER */, gl.createBuffer());
    gl.bufferData(34962 /* GL.ARRAY_BUFFER */, vertexData, 35044 /* GL.STATIC_DRAW */);
    const program = gl.createProgram();
    const VERTEX_SHADER = `\\
#version 300 es
in vec2 v_pos;
void main() {
gl_Position = vec4(v_pos, 0., 1.);
}`;
    const vertexShader = createShader(gl, VERTEX_SHADER, 35633 /* GL.VERTEX_SHADER */);
    const w4 = (0,_util__WEBPACK_IMPORTED_MODULE_1__.randU32)();
    const code = (0,_util__WEBPACK_IMPORTED_MODULE_1__.fillTmpl)(_assets_webgl2_b64_glsl__WEBPACK_IMPORTED_MODULE_0__, {
        'TEX_W': texW,
        'W0': words[0],
        'W1': words[1],
        'W2': words[2],
        'W3': words[3],
        'W4': w4,
        'MASK0': masks[0],
        'MASK1': masks[1],
        'MAGIC_CODE': MAGIC_CODE,
    });
    // console.log(code)
    const fragShader = createShader(gl, code, 35632 /* GL.FRAGMENT_SHADER */);
    // const dbg = gl.getExtension('WEBGL_debug_shaders')
    // if (dbg) {
    //   const s = dbg.getTranslatedShaderSource(fragShader)
    //   console.log(s)
    // } else {
    //   console.warn('WEBGL_debug_shaders not available')
    // }
    gl.attachShader(program, fragShader);
    gl.attachShader(program, vertexShader);
    await (0,_util__WEBPACK_IMPORTED_MODULE_1__.sleep)(0);
    gl.linkProgram(program);
    gl.useProgram(program);
    const posHandle = 0;
    gl.vertexAttribPointer(posHandle, 2 /*vec2*/, 5126 /* GL.FLOAT */, false, 0, 0);
    gl.enableVertexAttribArray(posHandle);
    const fbo = gl.createFramebuffer();
    const tex = gl.createTexture();
    gl.bindTexture(3553 /* GL.TEXTURE_2D */, tex);
    gl.texStorage2D(3553 /* GL.TEXTURE_2D */, 1, 36208 /* GL.RGBA32UI */, texW, texH);
    gl.bindFramebuffer(36160 /* GL.FRAMEBUFFER */, fbo);
    gl.framebufferTexture2D(36160 /* GL.FRAMEBUFFER */, 36064 /* GL.COLOR_ATTACHMENT0 */, 3553 /* GL.TEXTURE_2D */, tex, 0);
    // gl.disable(GL.DEPTH_TEST)
    // gl.disable(GL.STENCIL_TEST)
    // gl.depthMask(false)
    // gl.disable(GL.CULL_FACE)
    // gl.disable(GL.BLEND)
    const inStep = gl.getUniformLocation(program, 'in_step');
    const inW5 = gl.getUniformLocation(program, 'in_w5');
    const query = gl.createQuery();
    LOOP: for (let w5 = 0; w5 < 0xFFFFFFFF; w5++) {
        gl.beginQuery(35887 /* GL.ANY_SAMPLES_PASSED */, query);
        gl.uniform1ui(inW5, w5);
        gl.uniform1ui(inStep, loadmgr.step);
        gl.drawArrays(5 /* GL.TRIANGLE_STRIP */, 0, 4);
        gl.endQuery(35887 /* GL.ANY_SAMPLES_PASSED */);
        loadmgr.timeBegin();
        for (;;) {
            await (0,_util__WEBPACK_IMPORTED_MODULE_1__.sleep)(5);
            if (!isRunning) {
                break LOOP;
            }
            const done = gl.getQueryParameter(query, 34919 /* GL.QUERY_RESULT_AVAILABLE */);
            if (done) {
                break;
            }
        }
        loadmgr.timeEnd();
        const found = gl.getQueryParameter(query, 34918 /* GL.QUERY_RESULT */);
        if (found) {
            const arr = new Uint32Array(thread * 4);
            gl.readPixels(0, 0, texW, texH, 36249 /* GL.RGBA_INTEGER */, 5125 /* GL.UNSIGNED_INT */, arr);
            const index = arr.indexOf(MAGIC_CODE);
            console.assert(index >= 0, 'webgl error');
            const w6 = arr[index + 1];
            const w7 = arr[index + 2];
            const nonce = Uint32Array.of(w4, w5, w6, w7);
            events.onComplete(nonce);
            break;
        }
        events.onProgress(thread * loadmgr.step);
        await loadmgr.idle();
    }
}
function stop() {
    isRunning = false;
}
function setLoadRate(rate) {
    loadmgr.setRate(rate);
}
function createShader(gl, code, type) {
    const shader = gl.createShader(type);
    if (!shader) {
        throw Error('createShader failed');
    }
    gl.shaderSource(shader, code);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, 35713 /* GL.COMPILE_STATUS */)) {
        const msg = gl.getShaderInfoLog(shader);
        throw Error(msg);
    }
    return shader;
}


/***/ },

/***/ "./src/assets/webgl2.b64.glsl"
(module) {

module.exports = "I3ZlcnNpb24gMzAwIGVzCgpwcmVjaXNpb24gaGlnaHAgaW50OwpwcmVjaXNpb24gaGlnaHAgZmxvYXQ7Cgp1bmlmb3JtIHVpbnQgaW5fdzU7CnVuaWZvcm0gdWludCBpbl9zdGVwOwoKb3V0IHV2ZWM0IG91dF92OwoKCi8vIFNIQTI1NiB1dGlscwojZGVmaW5lIENoKHgsIHksIHopICAgKCh4ICYgKHkgXiB6KSkgXiB6KQojZGVmaW5lIE1haih4LCB5LCB6KSAgKCh4ICYgKHkgfCB6KSkgfCAoeSAmIHopKQojZGVmaW5lIFNIUih4LCBuKSAgICAgKHggPj4gbikKI2RlZmluZSBST1RSKHgsIG4pICAgICgoeCA+PiBuKSB8ICh4IDw8ICgzMiAtIG4pKSkKCiNkZWZpbmUgUzAoeCkgICAgICAgICAoUk9UUih4LCAgMikgXiBST1RSKHgsIDEzKSBeIFJPVFIoeCwgMjIpKQojZGVmaW5lIFMxKHgpICAgICAgICAgKFJPVFIoeCwgIDYpIF4gUk9UUih4LCAxMSkgXiBST1RSKHgsIDI1KSkKI2RlZmluZSBzMCh4KSAgICAgICAgIChST1RSKHgsICA3KSBeIFJPVFIoeCwgMTgpIF4gU0hSKHgsIDMpKQojZGVmaW5lIHMxKHgpICAgICAgICAgKFJPVFIoeCwgMTcpIF4gUk9UUih4LCAxOSkgXiBTSFIoeCwgMTApKQoKLyogU0hBMjU2IHJvdW5kIGZ1bmN0aW9uICovCiNkZWZpbmUgUk5EKGEsIGIsIGMsIGQsIGUsIGYsIGcsIGgsIGspICBcCiAgdDAgPSBoICsgUzEoZSkgKyBDaChlLCBmLCBnKSArIGs7ICAgICBcCiAgdDEgPSBTMChhKSArIE1haihhLCBiLCBjKTsgICAgICAgICAgICBcCiAgZCArPSB0MDsgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBcCiAgaCAgPSB0MCArIHQxOwoKCmNvbnN0IHVpbnQgS1s2NF0gPSB1aW50WzY0XSAoCiAgMHg0MjhBMkY5OHUsIDB4NzEzNzQ0OTF1LCAweEI1QzBGQkNGdSwgMHhFOUI1REJBNXUsCiAgMHgzOTU2QzI1QnUsIDB4NTlGMTExRjF1LCAweDkyM0Y4MkE0dSwgMHhBQjFDNUVENXUsCiAgMHhEODA3QUE5OHUsIDB4MTI4MzVCMDF1LCAweDI0MzE4NUJFdSwgMHg1NTBDN0RDM3UsCiAgMHg3MkJFNUQ3NHUsIDB4ODBERUIxRkV1LCAweDlCREMwNkE3dSwgMHhDMTlCRjE3NHUsCiAgMHhFNDlCNjlDMXUsIDB4RUZCRTQ3ODZ1LCAweDBGQzE5REM2dSwgMHgyNDBDQTFDQ3UsCiAgMHgyREU5MkM2RnUsIDB4NEE3NDg0QUF1LCAweDVDQjBBOURDdSwgMHg3NkY5ODhEQXUsCiAgMHg5ODNFNTE1MnUsIDB4QTgzMUM2NkR1LCAweEIwMDMyN0M4dSwgMHhCRjU5N0ZDN3UsCiAgMHhDNkUwMEJGM3UsIDB4RDVBNzkxNDd1LCAweDA2Q0E2MzUxdSwgMHgxNDI5Mjk2N3UsCiAgMHgyN0I3MEE4NXUsIDB4MkUxQjIxMzh1LCAweDREMkM2REZDdSwgMHg1MzM4MEQxM3UsCiAgMHg2NTBBNzM1NHUsIDB4NzY2QTBBQkJ1LCAweDgxQzJDOTJFdSwgMHg5MjcyMkM4NXUsCiAgMHhBMkJGRThBMXUsIDB4QTgxQTY2NEJ1LCAweEMyNEI4QjcwdSwgMHhDNzZDNTFBM3UsCiAgMHhEMTkyRTgxOXUsIDB4RDY5OTA2MjR1LCAweEY0MEUzNTg1dSwgMHgxMDZBQTA3MHUsCiAgMHgxOUE0QzExNnUsIDB4MUUzNzZDMDh1LCAweDI3NDg3NzRDdSwgMHgzNEIwQkNCNXUsCiAgMHgzOTFDMENCM3UsIDB4NEVEOEFBNEF1LCAweDVCOUNDQTRGdSwgMHg2ODJFNkZGM3UsCiAgMHg3NDhGODJFRXUsIDB4NzhBNTYzNkZ1LCAweDg0Qzg3ODE0dSwgMHg4Q0M3MDIwOHUsCiAgMHg5MEJFRkZGQXUsIDB4QTQ1MDZDRUJ1LCAweEJFRjlBM0Y3dSwgMHhDNjcxNzhGMnUKKTsKCnZvaWQgbWFpbigpIHsKICB1aW50IHggPSB1aW50KGdsX0ZyYWdDb29yZC54KTsKICB1aW50IHkgPSB1aW50KGdsX0ZyYWdDb29yZC55KTsKICB1aW50IHRocmVhZF9pZCA9IHkgKiBfX1RFWF9XX191ICsgeDsKCiAgdWludCBXWzE2XSwgU1s4XTsKICB1aW50IHQwLCB0MTsKCiAgZm9yICh1aW50IGkgPSBpbl9zdGVwOyBpID4gMHU7IGktLSkgewogICAgU1swXSA9IDB4NkEwOUU2Njd1OwogICAgU1sxXSA9IDB4QkI2N0FFODV1OwogICAgU1syXSA9IDB4M0M2RUYzNzJ1OwogICAgU1szXSA9IDB4QTU0RkY1M0F1OwogICAgU1s0XSA9IDB4NTEwRTUyN0Z1OwogICAgU1s1XSA9IDB4OUIwNTY4OEN1OwogICAgU1s2XSA9IDB4MUY4M0Q5QUJ1OwogICAgU1s3XSA9IDB4NUJFMENEMTl1OwoKICAgIC8vIGNoYWxsZW5nZQogICAgV1swXSA9IF9fVzBfX3U7CiAgICBXWzFdID0gX19XMV9fdTsKICAgIFdbMl0gPSBfX1cyX191OwogICAgV1szXSA9IF9fVzNfX3U7CgogICAgLy8gbm9uY2UKICAgIFdbNF0gPSBfX1c0X191OwogICAgV1s1XSA9IGluX3c1OwogICAgV1s2XSA9IHRocmVhZF9pZDsKICAgIFdbN10gPSBpOwoKICAgIC8vIHBhZGRpbmcKICAgIFdbOF0gPSAweDgwMDAwMDAwdTsgLy8gMSA8PCAzMQogICAgV1s5XSA9IDB1OwogICAgV1sxMF0gPSAwdTsKICAgIFdbMTFdID0gMHU7CiAgICBXWzEyXSA9IDB1OwogICAgV1sxM10gPSAwdTsKICAgIFdbMTRdID0gMHU7CiAgICBXWzE1XSA9IDI1NnU7ICAgICAgIC8vIGlucHV0IGJpdCBsZW4KCiAgICBSTkQoU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgV1sgMF0gKyBLWzBdKQogICAgUk5EKFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFdbIDFdICsgS1sxXSkKICAgIFJORChTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBXWyAyXSArIEtbMl0pCiAgICBSTkQoU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgV1sgM10gKyBLWzNdKQogICAgUk5EKFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFdbIDRdICsgS1s0XSkKICAgIFJORChTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBXWyA1XSArIEtbNV0pCiAgICBSTkQoU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgV1sgNl0gKyBLWzZdKQogICAgUk5EKFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFdbIDddICsgS1s3XSkKICAgIFJORChTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBXWyA4XSArIEtbOF0pCiAgICBSTkQoU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgV1sgOV0gKyBLWzldKQogICAgUk5EKFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFdbMTBdICsgS1sxMF0pCiAgICBSTkQoU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgV1sxMV0gKyBLWzExXSkKICAgIFJORChTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBXWzEyXSArIEtbMTJdKQogICAgUk5EKFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFdbMTNdICsgS1sxM10pCiAgICBSTkQoU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgV1sxNF0gKyBLWzE0XSkKICAgIFJORChTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBXWzE1XSArIEtbMTVdKQoKICAgIFdbIDBdICs9IHMxKFdbMTRdKSArIFdbIDldICsgczAoV1sgMV0pOwogICAgV1sgMV0gKz0gczEoV1sxNV0pICsgV1sxMF0gKyBzMChXWyAyXSk7CiAgICBXWyAyXSArPSBzMShXWyAwXSkgKyBXWzExXSArIHMwKFdbIDNdKTsKICAgIFdbIDNdICs9IHMxKFdbIDFdKSArIFdbMTJdICsgczAoV1sgNF0pOwogICAgV1sgNF0gKz0gczEoV1sgMl0pICsgV1sxM10gKyBzMChXWyA1XSk7CiAgICBXWyA1XSArPSBzMShXWyAzXSkgKyBXWzE0XSArIHMwKFdbIDZdKTsKICAgIFdbIDZdICs9IHMxKFdbIDRdKSArIFdbMTVdICsgczAoV1sgN10pOwogICAgV1sgN10gKz0gczEoV1sgNV0pICsgV1sgMF0gKyBzMChXWyA4XSk7CiAgICBXWyA4XSArPSBzMShXWyA2XSkgKyBXWyAxXSArIHMwKFdbIDldKTsKICAgIFdbIDldICs9IHMxKFdbIDddKSArIFdbIDJdICsgczAoV1sxMF0pOwogICAgV1sxMF0gKz0gczEoV1sgOF0pICsgV1sgM10gKyBzMChXWzExXSk7CiAgICBXWzExXSArPSBzMShXWyA5XSkgKyBXWyA0XSArIHMwKFdbMTJdKTsKICAgIFdbMTJdICs9IHMxKFdbMTBdKSArIFdbIDVdICsgczAoV1sxM10pOwogICAgV1sxM10gKz0gczEoV1sxMV0pICsgV1sgNl0gKyBzMChXWzE0XSk7CiAgICBXWzE0XSArPSBzMShXWzEyXSkgKyBXWyA3XSArIHMwKFdbMTVdKTsKICAgIFdbMTVdICs9IHMxKFdbMTNdKSArIFdbIDhdICsgczAoV1sgMF0pOwoKICAgIFJORChTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBXWyAwXSArIEtbMTZdKQogICAgUk5EKFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFdbIDFdICsgS1sxN10pCiAgICBSTkQoU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgV1sgMl0gKyBLWzE4XSkKICAgIFJORChTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBXWyAzXSArIEtbMTldKQogICAgUk5EKFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFdbIDRdICsgS1syMF0pCiAgICBSTkQoU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgV1sgNV0gKyBLWzIxXSkKICAgIFJORChTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBXWyA2XSArIEtbMjJdKQogICAgUk5EKFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFdbIDddICsgS1syM10pCiAgICBSTkQoU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgV1sgOF0gKyBLWzI0XSkKICAgIFJORChTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBXWyA5XSArIEtbMjVdKQogICAgUk5EKFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFdbMTBdICsgS1syNl0pCiAgICBSTkQoU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgV1sxMV0gKyBLWzI3XSkKICAgIFJORChTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBXWzEyXSArIEtbMjhdKQogICAgUk5EKFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFdbMTNdICsgS1syOV0pCiAgICBSTkQoU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgV1sxNF0gKyBLWzMwXSkKICAgIFJORChTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBXWzE1XSArIEtbMzFdKQoKICAgIFdbIDBdICs9IHMxKFdbMTRdKSArIFdbIDldICsgczAoV1sgMV0pOwogICAgV1sgMV0gKz0gczEoV1sxNV0pICsgV1sxMF0gKyBzMChXWyAyXSk7CiAgICBXWyAyXSArPSBzMShXWyAwXSkgKyBXWzExXSArIHMwKFdbIDNdKTsKICAgIFdbIDNdICs9IHMxKFdbIDFdKSArIFdbMTJdICsgczAoV1sgNF0pOwogICAgV1sgNF0gKz0gczEoV1sgMl0pICsgV1sxM10gKyBzMChXWyA1XSk7CiAgICBXWyA1XSArPSBzMShXWyAzXSkgKyBXWzE0XSArIHMwKFdbIDZdKTsKICAgIFdbIDZdICs9IHMxKFdbIDRdKSArIFdbMTVdICsgczAoV1sgN10pOwogICAgV1sgN10gKz0gczEoV1sgNV0pICsgV1sgMF0gKyBzMChXWyA4XSk7CiAgICBXWyA4XSArPSBzMShXWyA2XSkgKyBXWyAxXSArIHMwKFdbIDldKTsKICAgIFdbIDldICs9IHMxKFdbIDddKSArIFdbIDJdICsgczAoV1sxMF0pOwogICAgV1sxMF0gKz0gczEoV1sgOF0pICsgV1sgM10gKyBzMChXWzExXSk7CiAgICBXWzExXSArPSBzMShXWyA5XSkgKyBXWyA0XSArIHMwKFdbMTJdKTsKICAgIFdbMTJdICs9IHMxKFdbMTBdKSArIFdbIDVdICsgczAoV1sxM10pOwogICAgV1sxM10gKz0gczEoV1sxMV0pICsgV1sgNl0gKyBzMChXWzE0XSk7CiAgICBXWzE0XSArPSBzMShXWzEyXSkgKyBXWyA3XSArIHMwKFdbMTVdKTsKICAgIFdbMTVdICs9IHMxKFdbMTNdKSArIFdbIDhdICsgczAoV1sgMF0pOwoKICAgIFJORChTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBXWyAwXSArIEtbMzJdKQogICAgUk5EKFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFdbIDFdICsgS1szM10pCiAgICBSTkQoU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgV1sgMl0gKyBLWzM0XSkKICAgIFJORChTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBXWyAzXSArIEtbMzVdKQogICAgUk5EKFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFdbIDRdICsgS1szNl0pCiAgICBSTkQoU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgV1sgNV0gKyBLWzM3XSkKICAgIFJORChTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBXWyA2XSArIEtbMzhdKQogICAgUk5EKFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFdbIDddICsgS1szOV0pCiAgICBSTkQoU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgV1sgOF0gKyBLWzQwXSkKICAgIFJORChTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBXWyA5XSArIEtbNDFdKQogICAgUk5EKFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFdbMTBdICsgS1s0Ml0pCiAgICBSTkQoU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgV1sxMV0gKyBLWzQzXSkKICAgIFJORChTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBXWzEyXSArIEtbNDRdKQogICAgUk5EKFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFdbMTNdICsgS1s0NV0pCiAgICBSTkQoU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgV1sxNF0gKyBLWzQ2XSkKICAgIFJORChTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBXWzE1XSArIEtbNDddKQoKICAgIFdbIDBdICs9IHMxKFdbMTRdKSArIFdbIDldICsgczAoV1sgMV0pOwogICAgV1sgMV0gKz0gczEoV1sxNV0pICsgV1sxMF0gKyBzMChXWyAyXSk7CiAgICBXWyAyXSArPSBzMShXWyAwXSkgKyBXWzExXSArIHMwKFdbIDNdKTsKICAgIFdbIDNdICs9IHMxKFdbIDFdKSArIFdbMTJdICsgczAoV1sgNF0pOwogICAgV1sgNF0gKz0gczEoV1sgMl0pICsgV1sxM10gKyBzMChXWyA1XSk7CiAgICBXWyA1XSArPSBzMShXWyAzXSkgKyBXWzE0XSArIHMwKFdbIDZdKTsKICAgIFdbIDZdICs9IHMxKFdbIDRdKSArIFdbMTVdICsgczAoV1sgN10pOwogICAgV1sgN10gKz0gczEoV1sgNV0pICsgV1sgMF0gKyBzMChXWyA4XSk7CiAgICBXWyA4XSArPSBzMShXWyA2XSkgKyBXWyAxXSArIHMwKFdbIDldKTsKICAgIFdbIDldICs9IHMxKFdbIDddKSArIFdbIDJdICsgczAoV1sxMF0pOwogICAgV1sxMF0gKz0gczEoV1sgOF0pICsgV1sgM10gKyBzMChXWzExXSk7CiAgICBXWzExXSArPSBzMShXWyA5XSkgKyBXWyA0XSArIHMwKFdbMTJdKTsKICAgIFdbMTJdICs9IHMxKFdbMTBdKSArIFdbIDVdICsgczAoV1sxM10pOwogICAgV1sxM10gKz0gczEoV1sxMV0pICsgV1sgNl0gKyBzMChXWzE0XSk7CiAgICBXWzE0XSArPSBzMShXWzEyXSkgKyBXWyA3XSArIHMwKFdbMTVdKTsKICAgIFdbMTVdICs9IHMxKFdbMTNdKSArIFdbIDhdICsgczAoV1sgMF0pOwoKICAgIFJORChTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBXWyAwXSArIEtbNDhdKQogICAgUk5EKFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFdbIDFdICsgS1s0OV0pCiAgICBSTkQoU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgV1sgMl0gKyBLWzUwXSkKICAgIFJORChTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBXWyAzXSArIEtbNTFdKQogICAgUk5EKFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFdbIDRdICsgS1s1Ml0pCiAgICBSTkQoU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgV1sgNV0gKyBLWzUzXSkKICAgIFJORChTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBXWyA2XSArIEtbNTRdKQogICAgUk5EKFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFdbIDddICsgS1s1NV0pCiAgICBSTkQoU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgV1sgOF0gKyBLWzU2XSkKICAgIFJORChTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBXWyA5XSArIEtbNTddKQogICAgUk5EKFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFNbM10sIFNbNF0sIFNbNV0sIFdbMTBdICsgS1s1OF0pCiAgICBSTkQoU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgU1syXSwgU1szXSwgU1s0XSwgV1sxMV0gKyBLWzU5XSkKICAgIFJORChTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBTWzFdLCBTWzJdLCBTWzNdLCBXWzEyXSArIEtbNjBdKQogICAgUk5EKFNbM10sIFNbNF0sIFNbNV0sIFNbNl0sIFNbN10sIFNbMF0sIFNbMV0sIFNbMl0sIFdbMTNdICsgS1s2MV0pCiAgICBSTkQoU1syXSwgU1szXSwgU1s0XSwgU1s1XSwgU1s2XSwgU1s3XSwgU1swXSwgU1sxXSwgV1sxNF0gKyBLWzYyXSkKICAgIFJORChTWzFdLCBTWzJdLCBTWzNdLCBTWzRdLCBTWzVdLCBTWzZdLCBTWzddLCBTWzBdLCBXWzE1XSArIEtbNjNdKQoKICAgIGlmICgwdSA9PSAoKFNbMF0gKyAweDZBMDlFNjY3dSkgJiBfX01BU0swX191KSAmJgogICAgICAgIDB1ID09ICgoU1sxXSArIDB4QkI2N0FFODV1KSAmIF9fTUFTSzFfX3UpCiAgICApIHsKICAgICAgb3V0X3YgPSB1dmVjNCgwdSwgX19NQUdJQ19DT0RFX191LCB0aHJlYWRfaWQsIGkpOwogICAgICByZXR1cm47CiAgICB9CiAgfQogIGRpc2NhcmQ7Cn0K";

/***/ }

/******/ });
/************************************************************************/
/******/ // The module cache
/******/ var __webpack_module_cache__ = {};
/******/ 
/******/ // The require function
/******/ function __webpack_require__(moduleId) {
/******/ 	// Check if module is in cache
/******/ 	var cachedModule = __webpack_module_cache__[moduleId];
/******/ 	if (cachedModule !== undefined) {
/******/ 		return cachedModule.exports;
/******/ 	}
/******/ 	// Create a new module (and put it into the cache)
/******/ 	var module = __webpack_module_cache__[moduleId] = {
/******/ 		// no module.id needed
/******/ 		// no module.loaded needed
/******/ 		exports: {}
/******/ 	};
/******/ 
/******/ 	// Execute the module function
/******/ 	__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 
/******/ 	// Return the exports of the module
/******/ 	return module.exports;
/******/ }
/******/ 
/************************************************************************/
/******/ /* webpack/runtime/define property getters */
/******/ (() => {
/******/ 	// define getter functions for harmony exports
/******/ 	__webpack_require__.d = (exports, definition) => {
/******/ 		for(var key in definition) {
/******/ 			if(__webpack_require__.o(definition, key) && !__webpack_require__.o(exports, key)) {
/******/ 				Object.defineProperty(exports, key, { enumerable: true, get: definition[key] });
/******/ 			}
/******/ 		}
/******/ 	};
/******/ })();
/******/ 
/******/ /* webpack/runtime/hasOwnProperty shorthand */
/******/ (() => {
/******/ 	__webpack_require__.o = (obj, prop) => (Object.prototype.hasOwnProperty.call(obj, prop))
/******/ })();
/******/ 
/******/ /* webpack/runtime/make namespace object */
/******/ (() => {
/******/ 	// define __esModule on exports
/******/ 	__webpack_require__.r = (exports) => {
/******/ 		if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 			Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 		}
/******/ 		Object.defineProperty(exports, '__esModule', { value: true });
/******/ 	};
/******/ })();
/******/ 
/************************************************************************/
var __webpack_exports__ = {};
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   fromB64: () => (/* binding */ fromB64),
/* harmony export */   pow: () => (/* binding */ pow),
/* harmony export */   stop: () => (/* binding */ stop),
/* harmony export */   toB64: () => (/* binding */ toB64)
/* harmony export */ });
/* harmony import */ var _webgl2__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__("./src/webgl2.ts");
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__("./src/util.ts");


let isRunning;
let gpuMod = _webgl2__WEBPACK_IMPORTED_MODULE_0__;
function eventHandler(resolve, reject) {
    return {
        onProgress(step, workerId) {
            console.log(step);
        },
        onComplete(nonce) {
            if (!isRunning) {
                return;
            }
            stop();
            for (let i = 0; i < 4; i++) {
                nonce[i] = (0,_util__WEBPACK_IMPORTED_MODULE_1__.bswap)(nonce[i]);
            }
            const bytes = new Uint8Array(nonce.buffer);
            resolve(toB64(bytes));
        },
        onError(err) {
            reject(err);
        },
    };
}
function fromB64(base64) {
    const binaryString = atob(base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes;
}
function toB64(bytes) {
    let binaryString = '';
    for (let i = 0; i < bytes.length; i++) {
        binaryString += String.fromCharCode(bytes[i]);
    }
    return btoa(binaryString);
}
async function pow(challenge, difficulty) {
    return new Promise((resolve, reject) => {
        _webgl2__WEBPACK_IMPORTED_MODULE_0__.init(eventHandler(resolve, reject));
        console.log('challenge', challenge);
        const words = new Uint32Array(fromB64(challenge).buffer);
        const masks = new Uint32Array(2);
        for (let i = 0; i < 4; i++) {
            words[i] = (0,_util__WEBPACK_IMPORTED_MODULE_1__.bswap)(words[i]);
        }
        if (difficulty > 32) {
            masks[0] = -1;
            masks[1] = -1 << (64 - difficulty);
        }
        else {
            masks[0] = -1 << (32 - difficulty);
        }
        isRunning = true;
        gpuMod.start(words, masks);
    });
}
function stop() {
    gpuMod.stop();
    isRunning = false;
}

var __webpack_export_target__ = self;
for(var __webpack_i__ in __webpack_exports__) __webpack_export_target__[__webpack_i__] = __webpack_exports__[__webpack_i__];
if(__webpack_exports__.__esModule) Object.defineProperty(__webpack_export_target__, "__esModule", { value: true });

//# sourceMappingURL=index.js.map</script></head><body><div class="loading-container"><div class="spinner"></div><p class="loading-text">Please wait. This page is protected by</p><img width="" alt="" src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjwhRE9DVFlQRSBzdmcgUFVCTElDICItLy9XM0MvL0RURCBTVkcgMS4xLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL0dyYXBoaWNzL1NWRy8xLjEvRFREL3N2ZzExLmR0ZCI+CjwhLS0gQ3JlYXRlZCB3aXRoIFZlY3Rvcm5hdG9yIChodHRwOi8vdmVjdG9ybmF0b3IuaW8vKSAtLT4KPHN2ZyBoZWlnaHQ9IjEwMCUiIHN0cm9rZS1taXRlcmxpbWl0PSIxMCIgc3R5bGU9ImZpbGwtcnVsZTpub256ZXJvO2NsaXAtcnVsZTpldmVub2RkO3N0cm9rZS1saW5lY2FwOnJvdW5kO3N0cm9rZS1saW5lam9pbjpyb3VuZDsiIHZlcnNpb249IjEuMSIgdmlld0JveD0iMCAwIDE5MjAgNjQwLjU3NSIgd2lkdGg9IjEwMCUiIHhtbDpzcGFjZT0icHJlc2VydmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiPgo8ZGVmcy8+CjxnIGlkPSJDYWxxdWUtMSI+CjxnIGZpbGw9IiMzNDNmNzQiIG9wYWNpdHk9IjEiIHN0cm9rZT0ibm9uZSI+CjxwYXRoIGQ9Ik0yMTcuOTEzIDQzMC4zOTdDMjE3LjkxMyA0NjUuMjkxIDIxMC44MjcgNDkwLjc4NSAxOTYuNjU2IDUwNi44OEMxODIuNDg0IDUyMi45NzQgMTYwLjk0MiA1MzEuMDIxIDEzMi4wMyA1MzEuMDIxQzczLjc3NzEgNTMxLjAyMSA0NC42NTA4IDQ5Ny43NjQgNDQuNjUwOCA0MzEuMjUxTDQ0LjY1MDggMjIzLjgwNkw3OS42ODc4IDIyMy44MDZMNzkuNjg3OCA0MjguMDQ2Qzc5LjY4NzggNDc2LjE4NyA5Ny4xMzUxIDUwMC4yNTcgMTMyLjAzIDUwMC4yNTdDMTQ5LjU0OCA1MDAuMjU3IDE2Mi40MDIgNDk0LjU2IDE3MC41OTIgNDgzLjE2NkMxNzguNzgxIDQ3MS43NzIgMTgyLjg3NiA0NTMuMjU2IDE4Mi44NzYgNDI3LjYxOUwxODIuODc2IDIyMy44MDZMMjE3LjkxMyAyMjMuODA2TDIxNy45MTMgNDMwLjM5N1oiLz4KPHBhdGggZD0iTTQ1Ni43NjMgMzM0LjQ3MkM0MzguMTA1IDMyOC4zNDggNDIwLjUxNSAzMjUuMjg2IDQwMy45OTQgMzI1LjI4NkMzODUuOTA1IDMyNS4yODYgMzcxLjU5MiAzMjguMzEyIDM2MS4wNTIgMzM0LjM2NUMzNTAuNTEyIDM0MC40MTggMzQ1LjI0MyAzNDguNTAxIDM0NS4yNDMgMzU4LjYxM0MzNDUuMjQzIDM2NS4wMjMgMzQ3LjY2NCAzNzAuNjEzIDM1Mi41MDYgMzc1LjM4NEMzNTcuMzQ5IDM4MC4xNTUgMzY3LjAzNCAzODQuNjA2IDM4MS41NjEgMzg4LjczN0w0MTMuMzk0IDM5Ny45MjNDNDI4LjA2NCA0MDIuMDU0IDQ0MC4wMjggNDA3LjAwMyA0NDkuMjg1IDQxMi43NzFDNDU4LjU0MyA0MTguNTM5IDQ2NS40ODYgNDI1LjUxOCA0NzAuMTE1IDQzMy43MDhDNDc0Ljc0NCA0NDEuODk3IDQ3Ny4wNTkgNDUxLjQwNCA0NzcuMDU5IDQ2Mi4yMjlDNDc3LjA1OSA0ODMuNDUxIDQ2OC4xNTcgNTAwLjIyMSA0NTAuMzU0IDUxMi41NDFDNDMyLjU1IDUyNC44NjEgNDA5LjkwNCA1MzEuMDIxIDM4Mi40MTYgNTMxLjAyMUMzNTUuMDcgNTMxLjAyMSAzMzIuNDk1IDUyNi44OTEgMzE0LjY5MiA1MTguNjNMMzIxLjEwMSA0ODkuNzg5QzMzOS43NTkgNDk4LjYxOSAzNTkuNzcgNTAzLjAzNCAzODEuMTM0IDUwMy4wMzRDMzk5LjY1IDUwMy4wMzQgNDE0LjcxMSA0OTkuNTggNDI2LjMxOSA0OTIuNjczQzQzNy45MjcgNDg1Ljc2NSA0NDMuNzMxIDQ3Ni42MTQgNDQzLjczMSA0NjUuMjJDNDQzLjczMSA0NTcuNTI5IDQ0MC44NDcgNDUwLjY1NyA0MzUuMDc4IDQ0NC42MDRDNDI5LjMxIDQzOC41NSA0MTUuNzQ0IDQzMi4yNDggMzk0LjM4IDQyNS42OTZDMzc3LjE0NiA0MjAuNDI3IDM2NC40NyA0MTYuNDc0IDM1Ni4zNTIgNDEzLjgzOUMzNDguMjM0IDQxMS4yMDUgMzQwLjY4NSA0MDcuMzIzIDMzMy43MDYgNDAyLjE5NkMzMjYuNzI3IDM5Ny4wNjkgMzIxLjQyMiAzOTAuOTQ0IDMxNy43OSAzODMuODIzQzMxNC4xNTggMzc2LjcwMiAzMTIuMzQyIDM2OC43MjYgMzEyLjM0MiAzNTkuODk1QzMxMi4zNDIgMzQwLjY2OCAzMjAuNzQ1IDMyNS40MjggMzM3LjU1MiAzMTQuMTc2QzM1NC4zNTggMzAyLjkyNSAzNzYuNjQ4IDI5Ny4yOTkgNDA0LjQyMSAyOTcuMjk5QzQyMi4zNjcgMjk3LjI5OSA0NDIuMzA3IDMwMC4zNjEgNDY0LjI0IDMwNi40ODVMNDU2Ljc2MyAzMzQuNDcyWiIvPgo8cGF0aCBkPSJNNzQ5LjIzNiA0MTUuMDE0TDU5Ni40ODQgNDE1LjAxNEM1OTYuNDg0IDQ0MC4yMjQgNjAzLjc4MyA0NjEuMDE4IDYxOC4zODIgNDc3LjM5N0M2MzIuOTggNDkzLjc3NiA2NTAuODkxIDUwMS45NjYgNjcyLjExMiA1MDEuOTY2QzY5Mi4zMzcgNTAxLjk2NiA3MTMuMjAyIDQ5OC4zMzQgNzM0LjcwOSA0OTEuMDdMNzQwLjQ3NyA1MTcuNzc1QzcyMC44MjIgNTI2LjYwNiA2OTcuODkxIDUzMS4wMjEgNjcxLjY4NSA1MzEuMDIxQzYzOC42NDIgNTMxLjAyMSA2MTIuMDA4IDUyMC40MSA1OTEuNzgzIDQ5OS4xODlDNTcxLjU1OSA0NzcuOTY3IDU2MS40NDcgNDQ5LjMzOSA1NjEuNDQ3IDQxMy4zMDVDNTYxLjQ0NyAzNzcuOTgzIDU3MC41MjYgMzQ5LjgxOSA1ODguNjg2IDMyOC44MTFDNjA2Ljg0NSAzMDcuODAzIDYzMC4zMSAyOTcuMjk5IDY1OS4wOCAyOTcuMjk5QzY4NC43MTcgMjk3LjI5OSA3MDYuMTUyIDMwNy4wNTUgNzIzLjM4NiAzMjYuNTY3Qzc0MC42MTkgMzQ2LjA4IDc0OS4yMzYgMzcyLjA3MyA3NDkuMjM2IDQwNC41NDZMNzQ5LjIzNiA0MTUuMDE0Wk03MTIuOTE3IDM4Ny44ODJDNzEyLjkxNyAzNzAuNTA2IDcwNy41MDUgMzU1Ljg3MiA2OTYuNjgxIDM0My45NzlDNjg1Ljg1NiAzMzIuMDg2IDY3My43NSAzMjYuMTQgNjYwLjM2MiAzMjYuMTRDNjQzLjEyOCAzMjYuMTQgNjI4Ljg1IDMzMS44MzcgNjE3LjUyNyAzNDMuMjMxQzYwNi4yMDQgMzU0LjYyNSA1OTkuOTAyIDM2OS41MDkgNTk4LjYyIDM4Ny44ODJMNzEyLjkxNyAzODcuODgyWiIvPgo8L2c+CjxnIGZpbGw9IiMzNDNmNzQiIG9wYWNpdHk9IjEiIHN0cm9rZT0ibm9uZSI+CjxwYXRoIGQ9Ik0xMjYzLjQ4IDI5Ny4yOTlDMTI5NC4xMSAyOTcuMjk5IDEzMTguNDYgMzA3Ljk4MSAxMzM2LjU1IDMyOS4zNDVDMTM1NC42NCAzNTAuNzA5IDEzNjMuNjggMzc4LjgzOCAxMzYzLjY4IDQxMy43MzNDMTM2My42OCA0NDguOTEyIDEzNTQuNjQgNDc3LjI1NSAxMzM2LjU1IDQ5OC43NjFDMTMxOC40NiA1MjAuMjY4IDEyOTQuMTEgNTMxLjAyMSAxMjYzLjQ4IDUzMS4wMjFDMTIzMi43MiA1MzEuMDIxIDEyMDguMzMgNTIwLjMwMyAxMTkwLjMxIDQ5OC44NjhDMTE3Mi4yOSA0NzcuNDMzIDExNjMuMjkgNDQ5LjA1NCAxMTYzLjI5IDQxMy43MzNDMTE2My4yOSAzNzguNjk2IDExNzIuMzMgMzUwLjUzMSAxMTkwLjQyIDMyOS4yMzhDMTIwOC41MSAzMDcuOTQ1IDEyMzIuODYgMjk3LjI5OSAxMjYzLjQ4IDI5Ny4yOTlaTTEyNjMuNDggNTAxLjk2NkMxMjgzLjcxIDUwMS45NjYgMTI5OS42NiA0OTMuNDIgMTMxMS4zNCA0NzYuMzI5QzEzMjMuMDIgNDU5LjIzOCAxMzI4Ljg2IDQzOC41MTUgMTMyOC44NiA0MTQuMTZDMTMyOC44NiAzODguNTIzIDEzMjMuMDkgMzY3LjQ0NCAxMzExLjU1IDM1MC45MjJDMTMwMC4wMiAzMzQuNDAxIDEyODMuOTkgMzI2LjE0IDEyNjMuNDggMzI2LjE0QzEyNDIuODMgMzI2LjE0IDEyMjYuODEgMzM0LjI5NCAxMjE1LjQxIDM1MC42MDJDMTIwNC4wMiAzNjYuOTEgMTE5OC4zMiAzODguMDk2IDExOTguMzIgNDE0LjE2QzExOTguMzIgNDM4Ljk0MiAxMjA0LjA5IDQ1OS43NzIgMTIxNS42MyA0NzYuNjVDMTIyNy4xNiA0OTMuNTI3IDEyNDMuMTIgNTAxLjk2NiAxMjYzLjQ4IDUwMS45NjZaIi8+CjxwYXRoIGQ9Ik0xNTk2LjEyIDUyNS4yNTNMMTUwNS4xMSA1MjUuMjUzTDE1MDUuMTEgMjUyLjY0OEwxNDQ3IDI1Mi42NDhMMTQ0NyAyMjMuODA2TDE1MzguNDQgMjIzLjgwNkwxNTM4LjQ0IDQ5Ni40MTFMMTU5Ni4xMiA0OTYuNDExTDE1OTYuMTIgNTI1LjI1M1oiLz4KPHBhdGggZD0iTTE4NTguNjkgNTI1LjI1M0wxNzY3LjY3IDUyNS4yNTNMMTc2Ny42NyAyNTIuNjQ4TDE3MDkuNTYgMjUyLjY0OEwxNzA5LjU2IDIyMy44MDZMMTgwMSAyMjMuODA2TDE4MDEgNDk2LjQxMUwxODU4LjY5IDQ5Ni40MTFMMTg1OC42OSA1MjUuMjUzWiIvPgo8L2c+CjxnIG9wYWNpdHk9IjEiPgo8cGF0aCBkPSJNODczLjcyIDQ5MC4xNjZMMTExMi41MiA0OTAuMTY2TDExMTIuNTIgNTI1LjM3Mkw4NzMuNzIgNTI1LjM3Mkw4NzMuNzIgNDkwLjE2NloiIGZpbGw9IiNlMGY3ZmQiIGZpbGwtcnVsZT0ibm9uemVybyIgb3BhY2l0eT0iMSIgc3Ryb2tlPSJub25lIi8+CjxwYXRoIGQ9Ik05MTEuNzI1IDIwLjAzODdMMTA3NC41MiAyMC4wMzg3TDEwNzQuNTIgNDcxLjIzNkw5MTEuNzI1IDQ3MS4yMzZMOTExLjcyNSAyMC4wMzg3WiIgZmlsbD0iI2UwZjdmZCIgZmlsbC1ydWxlPSJub256ZXJvIiBvcGFjaXR5PSIxIiBzdHJva2U9Im5vbmUiLz4KPHBhdGggZD0iTTg3My43MiA0OTAuMTY2TDExMTIuNTIgNDkwLjE2NkwxMTEyLjUyIDUyNS4zNzJMODczLjcyIDUyNS4zNzJMODczLjcyIDQ5MC4xNjZaIiBmaWxsPSIjMzQzZjc0IiBmaWxsLXJ1bGU9Im5vbnplcm8iIG9wYWNpdHk9IjEiIHN0cm9rZT0ibm9uZSIvPgo8cGF0aCBkPSJNMTA3NC41MiA2MC40OTEzTDE4NjguOTIgNjAuNDkxM0wxODY4LjkyIDE0NC40MDdMMTA3NC41MiAxNDQuNDA3TDEwNzQuNTIgNjAuNDkxM1oiIGZpbGw9IiMzNDNmNzQiIGZpbGwtcnVsZT0ibm9uemVybyIgb3BhY2l0eT0iMSIgc3Ryb2tlPSJub25lIi8+CjxwYXRoIGQ9Ik05MTEuNzI1IDIwLjAzODdMMTA3NC41MiAyMC4wMzg3TDEwNzQuNTIgNDcxLjIzNkw5MTEuNzI1IDQ3MS4yMzZMOTExLjcyNSAyMC4wMzg3WiIgZmlsbD0iIzM0M2Y3NCIgZmlsbC1ydWxlPSJub256ZXJvIiBvcGFjaXR5PSIxIiBzdHJva2U9Im5vbmUiLz4KPHBhdGggZD0iTTEwMDEuMDQgNjAuNDkxM0wxMDQ2LjMgNjAuNDkxM0w5ODYuODc1IDE0NC40MDdMOTM5Ljk0MSAxNDQuNDA3TDEwMDEuMDQgNjAuNDkxM1oiIGZpbGw9IiNmZmZmZmYiIGZpbGwtcnVsZT0ibm9uemVybyIgb3BhY2l0eT0iMSIgc3Ryb2tlPSJub25lIi8+CjxwYXRoIGQ9Ik0xMDg1LjQxIDYwLjQ5MTNMMTEzMC42NyA2MC40OTEzTDEwNzEuMjQgMTQ0LjQwN0wxMDI0LjMxIDE0NC40MDdMMTA4NS40MSA2MC40OTEzWiIgZmlsbD0iI2ZmZmZmZiIgZmlsbC1ydWxlPSJub256ZXJvIiBvcGFjaXR5PSIxIiBzdHJva2U9Im5vbmUiLz4KPHBhdGggZD0iTTExNjkuNzcgNjAuNDkxM0wxMjE1LjAzIDYwLjQ5MTNMMTE1NS42MSAxNDQuNDA3TDExMDguNjcgMTQ0LjQwN0wxMTY5Ljc3IDYwLjQ5MTNaIiBmaWxsPSIjZmZmZmZmIiBmaWxsLXJ1bGU9Im5vbnplcm8iIG9wYWNpdHk9IjEiIHN0cm9rZT0ibm9uZSIvPgo8cGF0aCBkPSJNMTI1NC4xNCA2MC40OTEzTDEyOTkuNCA2MC40OTEzTDEyMzkuOTcgMTQ0LjQwN0wxMTkzLjA0IDE0NC40MDdMMTI1NC4xNCA2MC40OTEzWiIgZmlsbD0iI2ZmZmZmZiIgZmlsbC1ydWxlPSJub256ZXJvIiBvcGFjaXR5PSIxIiBzdHJva2U9Im5vbmUiLz4KPHBhdGggZD0iTTEzMzguNSA2MC40OTEzTDEzODMuNzcgNjAuNDkxM0wxMzI0LjM0IDE0NC40MDdMMTI3Ny40IDE0NC40MDdMMTMzOC41IDYwLjQ5MTNaIiBmaWxsPSIjZmZmZmZmIiBmaWxsLXJ1bGU9Im5vbnplcm8iIG9wYWNpdHk9IjEiIHN0cm9rZT0ibm9uZSIvPgo8cGF0aCBkPSJNMTQyMi44NyA2MC40OTEzTDE0NjguMTMgNjAuNDkxM0wxNDA4LjcgMTQ0LjQwN0wxMzYxLjc3IDE0NC40MDdMMTQyMi44NyA2MC40OTEzWiIgZmlsbD0iI2ZmZmZmZiIgZmlsbC1ydWxlPSJub256ZXJvIiBvcGFjaXR5PSIxIiBzdHJva2U9Im5vbmUiLz4KPHBhdGggZD0iTTE1MDcuMjQgNjAuNDkxM0wxNTUyLjUgNjAuNDkxM0wxNDkzLjA3IDE0NC40MDdMMTQ0Ni4xNCAxNDQuNDA3TDE1MDcuMjQgNjAuNDkxM1oiIGZpbGw9IiNmZmZmZmYiIGZpbGwtcnVsZT0ibm9uemVybyIgb3BhY2l0eT0iMSIgc3Ryb2tlPSJub25lIi8+CjxwYXRoIGQ9Ik0xNTkxLjYgNjAuNDkxM0wxNjM2Ljg2IDYwLjQ5MTNMMTU3Ny40NCAxNDQuNDA3TDE1MzAuNSAxNDQuNDA3TDE1OTEuNiA2MC40OTEzWiIgZmlsbD0iI2ZmZmZmZiIgZmlsbC1ydWxlPSJub256ZXJvIiBvcGFjaXR5PSIxIiBzdHJva2U9Im5vbmUiLz4KPHBhdGggZD0iTTE2NzUuOTcgNjAuNDkxM0wxNzIxLjIzIDYwLjQ5MTNMMTY2MS44IDE0NC40MDdMMTYxNC44NyAxNDQuNDA3TDE2NzUuOTcgNjAuNDkxM1oiIGZpbGw9IiNmZmZmZmYiIGZpbGwtcnVsZT0ibm9uemVybyIgb3BhY2l0eT0iMSIgc3Ryb2tlPSJub25lIi8+CjxwYXRoIGQ9Ik0xNzYwLjMzIDYwLjQ5MTNMMTgwNS41OSA2MC40OTEzTDE3NzAuNyAxMDkuNzcxTDE3NDYuMTcgMTQ0LjQwN0wxNjk5LjIzIDE0NC40MDdMMTczNC45MSA5NS40MDU1TDE3NjAuMzMgNjAuNDkxM1oiIGZpbGw9IiNmZmZmZmYiIGZpbGwtcnVsZT0ibm9uemVybyIgb3BhY2l0eT0iMSIgc3Ryb2tlPSJub25lIi8+CjwvZz4KPC9nPgo8L3N2Zz4K"/></div><script type="module">const challenge = '{{{challenge}}}';
    const difficulty   = {{{difficulty}}};
    const url   = '{{{url}}}';

    function commitResult(nonce) {
        const params = new URLSearchParams(window.location.search);
        params.set("nonce", nonce);
        params.set("url", url);
        window.location.search = params.toString();
    }


    pow(challenge, difficulty)
        .then((nonce) => commitResult(nonce))
        .catch((err) => console.error(err));</script></body></html>

''';
