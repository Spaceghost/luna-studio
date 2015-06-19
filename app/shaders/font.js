var xtend = require('xtend')
var THREE = require('three')

module.exports = function(opt) {
  opt = opt||{}
  var opacity = typeof opt.opacity === 'number' ? opt.opacity : 1
  var alphaTest = typeof opt.alphaTest === 'number' ? opt.alphaTest : 0.06
  var smooth = typeof opt.smooth === 'number' ? opt.smooth : 1/16 
  return xtend({
    uniforms: xtend({
      opacity: { type: 'f', value: opacity },
      smooth: { type: 'f', value: smooth },
      map: { type: 't', value: opt.map || new THREE.Texture() },
      color: { type: 'c', value: new THREE.Color(opt.color) }
    },opt.myuniforms),
    vertexShader: [
      "attribute float page;",
      "varying vec2 vUv;",
      "varying float vPage;",
      "void main() {",
        "vUv = uv;",
        "vPage = page;",
        "gl_Position = projectionMatrix * modelViewMatrix * vec4( position.xyz, 1.0 );",
      "}"
    ].join("\n"),
    fragmentShader: [   

      "#define SQRT2 1.4142135623730951",
      "uniform float opacity;",
      "uniform vec3 color;",
      "uniform sampler2D map;",
      "uniform float smooth;",
      "varying float vPage;",
      "varying vec2 vUv;",
      "void main() {",
        "vec4 texColor = texture2D(map, vUv);",
        "float dst = texColor.a;",
        "float afwidth = smooth * SQRT2 / (2.0 * gl_FragCoord.w);",
        "float alpha = smoothstep(0.5 - afwidth, 0.5 + afwidth, dst);",

        "gl_FragColor = vec4(color, opacity * alpha);",
        "#ifdef ALPHATEST\n\n  if ( gl_FragColor.a < ALPHATEST ) discard; \n\n#endif",
      "}"
      
      //       "uniform sampler2D map;",
      //       "varying vec2 vUv;",
      // "void main() {",
      //           "float smoothing = 1.0/16.0 * SQRT2 / (2.0 * gl_FragCoord.w);",
      //     "float distance = texture2D(map, vUv).a;",
      //     "float alpha = smoothstep(0.5 - smoothing, 0.5 + smoothing, distance);",
      //     "gl_FragColor = vec4(1.0, 1.0, 1.0, alpha);",
      // "}"
    ].join("\n"),
    defines: {
      "USE_MAP": "",
      "ALPHATEST": Number(alphaTest || 0).toFixed(1)
    }
  }, opt)
}