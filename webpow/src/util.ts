export function sleep(ms: number) {
  return new Promise(fn => {
    setTimeout(fn, ms)
  })
}

export function randU32() {
  return Math.random() * 0xFFFFFFFF >>> 0
}

export function bswap(n: number) {
  return (
    ((n & 0x0000FF) << 24) |
    ((n & 0x00FF00) <<  8) |
    ((n & 0xFF0000) >>  8) |
    (n >>> 24)
  ) >>> 0
}

export function fillTmpl(
  tmpl: string,
  params: { [key: string] : number }
) {
  // glsl is embedded in base64 to avoid issue with dart templating
  return atob(tmpl).replace(/__(\w+)__/g, (_, $1) => {
    return params[$1] + ''
  })
}