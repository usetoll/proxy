final index = '''
<!doctype html>
<html>
<head>
<title>Loading...</title>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width">
<base target="_blank">
<script type="module">/******/ var __webpack_modules__ = ({

/***/ "./src/load-manager.ts"
/*!*****************************!*\
  !*** ./src/load-manager.ts ***!
  \*****************************/
(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   LoadManager: () => (/* binding */ LoadManager)
/* harmony export */ });
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./util */ "./src/util.ts");

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
/*!*********************!*\
  !*** ./src/util.ts ***!
  \*********************/
(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
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
    return atob(tmpl).replace(/__(\\w+)__/g, (_, \$1) => {
        return params[\$1] + '';
    });
}


/***/ },

/***/ "./src/webgl2.ts"
/*!***********************!*\
  !*** ./src/webgl2.ts ***!
  \***********************/
(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   init: () => (/* binding */ init),
/* harmony export */   setLoadRate: () => (/* binding */ setLoadRate),
/* harmony export */   start: () => (/* binding */ start),
/* harmony export */   stop: () => (/* binding */ stop)
/* harmony export */ });
/* harmony import */ var _assets_webgl2_b64_glsl__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./assets/webgl2.b64.glsl */ "./src/assets/webgl2.b64.glsl");
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./util */ "./src/util.ts");
/* harmony import */ var _load_manager__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./load-manager */ "./src/load-manager.ts");



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
console.log('first char codes:', code.charCodeAt(0), code.charCodeAt(1), code.charCodeAt(2));
console.log('starts with #version?', code.startsWith('#version'));
console.log(JSON.stringify(code.slice(0, 20)));
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
/*!************************************!*\
  !*** ./src/assets/webgl2.b64.glsl ***!
  \************************************/
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
/******/ 	// Check if module exists (development only)
/******/ 	if (__webpack_modules__[moduleId] === undefined) {
/******/ 		var e = new Error("Cannot find module '" + moduleId + "'");
/******/ 		e.code = 'MODULE_NOT_FOUND';
/******/ 		throw e;
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
// This entry needs to be wrapped in an IIFE because it needs to be isolated against other modules in the chunk.
(() => {
/*!**********************!*\
  !*** ./src/index.ts ***!
  \**********************/
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   fromB64: () => (/* binding */ fromB64),
/* harmony export */   pow: () => (/* binding */ pow),
/* harmony export */   stop: () => (/* binding */ stop),
/* harmony export */   toB64: () => (/* binding */ toB64)
/* harmony export */ });
/* harmony import */ var _webgl2__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./webgl2 */ "./src/webgl2.ts");
/* harmony import */ var _util__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./util */ "./src/util.ts");


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

})();

var __webpack_export_target__ = self;
for(var __webpack_i__ in __webpack_exports__) __webpack_export_target__[__webpack_i__] = __webpack_exports__[__webpack_i__];
if(__webpack_exports__.__esModule) Object.defineProperty(__webpack_export_target__, "__esModule", { value: true });

//# sourceMappingURL=index.js.map</script></head>
<body>
<h2>Loading...</h2>

<script type="module">

    
    const challenge = '{{{challenge}}}';
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
        .catch((err) => console.error(err));
</script>
</body>
</html>
''';