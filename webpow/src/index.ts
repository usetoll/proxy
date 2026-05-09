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
      resolve(bytes.toString());
    },
    onError(err) {
      reject(err);
    },
  }
}

function fromHex(hex: string): Uint8Array {
  // Strip optional "0x" prefix and any whitespace
  const cleaned = hex.replace(/^0x/i, '').replace(/\s+/g, '');

  if (cleaned.length % 2 !== 0) {
    throw new Error(`Invalid hex string: odd length (${cleaned.length})`);
  }

  if (!/^[0-9a-fA-F]*$/.test(cleaned)) {
    throw new Error('Invalid hex string: contains non-hex characters');
  }

  const bytes = new Uint8Array(cleaned.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(cleaned.substr(i * 2, 2), 16);
  }
  return bytes;
}

export async function pow(challenge: string, difficulty: number): Promise<string> {
  return new Promise<string>((resolve, reject) => {
    webgl2.init(eventHandler(resolve, reject))

    const words = new Uint32Array(fromHex(challenge).buffer)
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
