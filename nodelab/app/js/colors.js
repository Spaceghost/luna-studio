"use strict";

var colors = [
    new THREE.Vector4(0xFF, 0xFF, 0xFF, 0xFF).divideScalar(0xFF), // white 0
    new THREE.Vector4(0x00, 0x00, 0x00, 0x00).divideScalar(0xFF), // black 1
    new THREE.Vector4(0x30, 0x30, 0x30, 0xFF).divideScalar(0x140),// grey 2
    new THREE.Vector4(0xFF, 0x99, 0x33, 0xAA).divideScalar(0xFF), // orange 3
    new THREE.Vector4(0x00, 0x99, 0x99, 0xAA).divideScalar(0xFF), // dark cyan 4
    new THREE.Vector4(0xBB, 0x33, 0x00, 0xAA).divideScalar(0xFF), // light blood 5
    new THREE.Vector4(0x18, 0x90, 0x38, 0xFF).divideScalar(0xFF), // greeny 6
    new THREE.Vector4(0xA0, 0x36, 0x58, 0xFF).divideScalar(0xFF), // pinky 7
    new THREE.Vector4(0x30, 0x50, 0xA0, 0xFF).divideScalar(0xFF), // bluish 8
    new THREE.Vector4(0x20, 0x60, 0x90, 0xFF).divideScalar(0xFF), // cyano bluish 9
    new THREE.Vector4(0x80, 0x80, 0x08, 0xFF).divideScalar(0xFF), // yellowish 10
    new THREE.Vector4(0xC0, 0x80, 0x58, 0xFF).divideScalar(0xFF), // orange 11
    new THREE.Vector4(0xFF, 0xFF, 0xFF, 0xFF).divideScalar(0xFF), // white 12
    new THREE.Vector4(0xFF, 0x00, 0x00, 0xFF).divideScalar(0xFF), // red 13
    new THREE.Vector4(0xFF, 0xFF, 0xFF, 0xFF).divideScalar(0xFF), // white 14
    new THREE.Vector4(0xFF, 0xFF, 0xFF, 0xFF).divideScalar(0xFF), // white 15
    new THREE.Vector4(0xFF, 0xFF, 0xFF, 0xFF).divideScalar(0xFF), // white 16
    new THREE.Vector4(0xFF, 0xFF, 0xFF, 0xFF).divideScalar(0xFF), // white 17
    new THREE.Vector4(0xFF, 0xFF, 0xFF, 0xFF).divideScalar(0xFF), // white 18
    new THREE.Vector4(0xFF, 0xFF, 0xFF, 0xFF).divideScalar(0xFF), // white 19
    new THREE.Vector4(0xFF, 0xFF, 0xFF, 0xFF).divideScalar(0xFF)  // white 20
]

module.exports = colors;