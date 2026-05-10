import * as webgl2 from './webgl2'
import {bswap} from './util'


export type SubModEventHandler = {
  onProgress(step: number, workerId?: number) : void
  onComplete(nonce: Uint32Array) : void
  onError(err: Error) : void
}

let isRunning: boolean
let gpuMod: typeof webgl2 = webgl2;


function eventHandler(resolve: (nonce: string) => void, reject: (reason?: any) => void): SubModEventHandler {
  return {
    onProgress(step, workerId) {
      console.log(step);
    },
    onComplete(nonce) {
      if (!isRunning) {
        return
      }
      stop()

      for (let i = 0; i < 4; i++) {
        nonce[i] = bswap(nonce[i])
      }
      const bytes = new Uint8Array(nonce.buffer)
      resolve(toB64(bytes));
    },
    onError(err) {
      reject(err);
    },
  }
}

export function fromB64(base64: string): Uint8Array {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

export function toB64(bytes: Uint8Array): string {
  let binaryString = '';
  for (let i = 0; i < bytes.length; i++) {
    binaryString += String.fromCharCode(bytes[i]);
  }
  return btoa(binaryString);
}

export async function pow(challenge: string, difficulty: number): Promise<string> {
  return new Promise<string>((resolve, reject) => {
    webgl2.init(eventHandler(resolve, reject))
    console.log('challenge', challenge);

    const words = new Uint32Array(fromB64(challenge).buffer)
    const masks = new Uint32Array(2)

    for (let i = 0; i < 4; i++) {
      words[i] = bswap(words[i])
    }

    if (difficulty > 32) {
      masks[0] = -1
      masks[1] = -1 << (64 - difficulty)
    } else {
      masks[0] = -1 << (32 - difficulty)
    }

    isRunning = true

    gpuMod.start(words, masks)
  });
}

export function stop() {
  gpuMod.stop()
  isRunning = false
}
