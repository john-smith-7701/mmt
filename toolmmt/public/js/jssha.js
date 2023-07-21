
function createCommonjsModule(fn, basedir, module) {
  return module = {
    path: basedir,
    exports: {},
    require: function(path, base) {
      return commonjsRequire(path, base === void 0 || base === null ? module.path : base);
    }
  }, fn(module, module.exports), module.exports;
}
function commonjsRequire() {
  throw new Error("Dynamic requires are not currently supported by @rollup/plugin-commonjs");
}
var sha = createCommonjsModule(function(module, exports) {
  (function(aa) {
    function C(d, b, a2) {
      var h = 0, k = [], m = 0, g, l, c2, f, n, q, u, r, I = false, v = [], x2 = [], t2, y2 = false, z = false, w = -1;
      a2 = a2 || {};
      g = a2.encoding || "UTF8";
      t2 = a2.numRounds || 1;
      if (t2 !== parseInt(t2, 10) || 1 > t2)
        throw Error("numRounds must a integer >= 1");
      if (d === "SHA-1")
        n = 512, q = K, u = ba, f = 160, r = function(b2) {
          return b2.slice();
        };
      else if (d.lastIndexOf("SHA-", 0) === 0)
        if (q = function(b2, h2) {
          return L(b2, h2, d);
        }, u = function(b2, h2, k2, a3) {
          var e, f2;
          if (d === "SHA-224" || d === "SHA-256")
            e = (h2 + 65 >>> 9 << 4) + 15, f2 = 16;
          else if (d === "SHA-384" || d === "SHA-512")
            e = (h2 + 129 >>> 10 << 5) + 31, f2 = 32;
          else
            throw Error("Unexpected error in SHA-2 implementation");
          for (; b2.length <= e; )
            b2.push(0);
          b2[h2 >>> 5] |= 128 << 24 - h2 % 32;
          h2 = h2 + k2;
          b2[e] = h2 & 4294967295;
          b2[e - 1] = h2 / 4294967296 | 0;
          k2 = b2.length;
          for (h2 = 0; h2 < k2; h2 += f2)
            a3 = L(b2.slice(h2, h2 + f2), a3, d);
          if (d === "SHA-224")
            b2 = [a3[0], a3[1], a3[2], a3[3], a3[4], a3[5], a3[6]];
          else if (d === "SHA-256")
            b2 = a3;
          else if (d === "SHA-384")
            b2 = [a3[0].a, a3[0].b, a3[1].a, a3[1].b, a3[2].a, a3[2].b, a3[3].a, a3[3].b, a3[4].a, a3[4].b, a3[5].a, a3[5].b];
          else if (d === "SHA-512")
            b2 = [
              a3[0].a,
              a3[0].b,
              a3[1].a,
              a3[1].b,
              a3[2].a,
              a3[2].b,
              a3[3].a,
              a3[3].b,
              a3[4].a,
              a3[4].b,
              a3[5].a,
              a3[5].b,
              a3[6].a,
              a3[6].b,
              a3[7].a,
              a3[7].b
            ];
          else
            throw Error("Unexpected error in SHA-2 implementation");
          return b2;
        }, r = function(b2) {
          return b2.slice();
        }, d === "SHA-224")
          n = 512, f = 224;
        else if (d === "SHA-256")
          n = 512, f = 256;
        else if (d === "SHA-384")
          n = 1024, f = 384;
        else if (d === "SHA-512")
          n = 1024, f = 512;
        else
          throw Error("Chosen SHA variant is not supported");
      else if (d.lastIndexOf("SHA3-", 0) === 0 || d.lastIndexOf("SHAKE", 0) === 0) {
        var F = 6;
        q = D;
        r = function(b2) {
          var d2 = [], a3;
          for (a3 = 0; 5 > a3; a3 += 1)
            d2[a3] = b2[a3].slice();
          return d2;
        };
        w = 1;
        if (d === "SHA3-224")
          n = 1152, f = 224;
        else if (d === "SHA3-256")
          n = 1088, f = 256;
        else if (d === "SHA3-384")
          n = 832, f = 384;
        else if (d === "SHA3-512")
          n = 576, f = 512;
        else if (d === "SHAKE128")
          n = 1344, f = -1, F = 31, z = true;
        else if (d === "SHAKE256")
          n = 1088, f = -1, F = 31, z = true;
        else
          throw Error("Chosen SHA variant is not supported");
        u = function(b2, d2, a3, h2, k2) {
          a3 = n;
          var e = F, f2, g2 = [], m2 = a3 >>> 5, l2 = 0, c3 = d2 >>> 5;
          for (f2 = 0; f2 < c3 && d2 >= a3; f2 += m2)
            h2 = D(b2.slice(f2, f2 + m2), h2), d2 -= a3;
          b2 = b2.slice(f2);
          for (d2 %= a3; b2.length < m2; )
            b2.push(0);
          f2 = d2 >>> 3;
          b2[f2 >> 2] ^= e << f2 % 4 * 8;
          b2[m2 - 1] ^= 2147483648;
          for (h2 = D(b2, h2); 32 * g2.length < k2; ) {
            b2 = h2[l2 % 5][l2 / 5 | 0];
            g2.push(b2.b);
            if (32 * g2.length >= k2)
              break;
            g2.push(b2.a);
            l2 += 1;
            64 * l2 % a3 === 0 && (D(null, h2), l2 = 0);
          }
          return g2;
        };
      } else
        throw Error("Chosen SHA variant is not supported");
      c2 = M(b, g, w);
      l = A(d);
      this.setHMACKey = function(b2, a3, k2) {
        var e;
        if (I === true)
          throw Error("HMAC key already set");
        if (y2 === true)
          throw Error("Cannot set HMAC key after calling update");
        if (z === true)
          throw Error("SHAKE is not supported for HMAC");
        g = (k2 || {}).encoding || "UTF8";
        a3 = M(a3, g, w)(b2);
        b2 = a3.binLen;
        a3 = a3.value;
        e = n >>> 3;
        k2 = e / 4 - 1;
        for (e < b2 / 8 && (a3 = u(a3, b2, 0, A(d), f)); a3.length <= k2; )
          a3.push(0);
        for (b2 = 0; b2 <= k2; b2 += 1)
          v[b2] = a3[b2] ^ 909522486, x2[b2] = a3[b2] ^ 1549556828;
        l = q(v, l);
        h = n;
        I = true;
      };
      this.update = function(b2) {
        var d2, a3, e, f2 = 0, g2 = n >>> 5;
        d2 = c2(b2, k, m);
        b2 = d2.binLen;
        a3 = d2.value;
        d2 = b2 >>> 5;
        for (e = 0; e < d2; e += g2)
          f2 + n <= b2 && (l = q(a3.slice(e, e + g2), l), f2 += n);
        h += f2;
        k = a3.slice(f2 >>> 5);
        m = b2 % n;
        y2 = true;
      };
      this.getHash = function(b2, a3) {
        var e, g2, c3, n2;
        if (I === true)
          throw Error("Cannot call getHash after setting HMAC key");
        c3 = N(a3);
        if (z === true) {
          if (c3.shakeLen === -1)
            throw Error("shakeLen must be specified in options");
          f = c3.shakeLen;
        }
        switch (b2) {
          case "HEX":
            e = function(b3) {
              return O(b3, f, w, c3);
            };
            break;
          case "B64":
            e = function(b3) {
              return P(b3, f, w, c3);
            };
            break;
          case "BYTES":
            e = function(b3) {
              return Q(b3, f, w);
            };
            break;
          case "ARRAYBUFFER":
            try {
              g2 = new ArrayBuffer(0);
            } catch (p) {
              throw Error("ARRAYBUFFER not supported by this environment");
            }
            e = function(b3) {
              return R(b3, f, w);
            };
            break;
          case "UINT8ARRAY":
            try {
              g2 = new Uint8Array(0);
            } catch (p) {
              throw Error("UINT8ARRAY not supported by this environment");
            }
            e = function(b3) {
              return S(b3, f, w);
            };
            break;
          default:
            throw Error("format must be HEX, B64, BYTES, ARRAYBUFFER, or UINT8ARRAY");
        }
        n2 = u(k.slice(), m, h, r(l), f);
        for (g2 = 1; g2 < t2; g2 += 1)
          z === true && f % 32 !== 0 && (n2[n2.length - 1] &= 16777215 >>> 24 - f % 32), n2 = u(n2, f, 0, A(d), f);
        return e(n2);
      };
      this.getHMAC = function(b2, a3) {
        var e, g2, c3, p;
        if (I === false)
          throw Error("Cannot call getHMAC without first setting HMAC key");
        c3 = N(a3);
        switch (b2) {
          case "HEX":
            e = function(b3) {
              return O(b3, f, w, c3);
            };
            break;
          case "B64":
            e = function(b3) {
              return P(b3, f, w, c3);
            };
            break;
          case "BYTES":
            e = function(b3) {
              return Q(b3, f, w);
            };
            break;
          case "ARRAYBUFFER":
            try {
              e = new ArrayBuffer(0);
            } catch (v2) {
              throw Error("ARRAYBUFFER not supported by this environment");
            }
            e = function(b3) {
              return R(b3, f, w);
            };
            break;
          case "UINT8ARRAY":
            try {
              e = new Uint8Array(0);
            } catch (v2) {
              throw Error("UINT8ARRAY not supported by this environment");
            }
            e = function(b3) {
              return S(b3, f, w);
            };
            break;
          default:
            throw Error("outputFormat must be HEX, B64, BYTES, ARRAYBUFFER, or UINT8ARRAY");
        }
        g2 = u(k.slice(), m, h, r(l), f);
        p = q(x2, A(d));
        p = u(g2, f, n, p, f);
        return e(p);
      };
    }
    function a(d, b) {
      this.a = d;
      this.b = b;
    }
    function T(d, b, a2, h) {
      var k, m, g, l, c2;
      b = b || [0];
      a2 = a2 || 0;
      m = a2 >>> 3;
      c2 = h === -1 ? 3 : 0;
      for (k = 0; k < d.length; k += 1)
        l = k + m, g = l >>> 2, b.length <= g && b.push(0), b[g] |= d[k] << 8 * (c2 + l % 4 * h);
      return {value: b, binLen: 8 * d.length + a2};
    }
    function O(a2, b, e, h) {
      var k = "";
      b /= 8;
      var m, g, c2;
      c2 = e === -1 ? 3 : 0;
      for (m = 0; m < b; m += 1)
        g = a2[m >>> 2] >>> 8 * (c2 + m % 4 * e), k += "0123456789abcdef".charAt(g >>> 4 & 15) + "0123456789abcdef".charAt(g & 15);
      return h.outputUpper ? k.toUpperCase() : k;
    }
    function P(a2, b, e, h) {
      var k = "", m = b / 8, g, c2, p, f;
      f = e === -1 ? 3 : 0;
      for (g = 0; g < m; g += 3)
        for (c2 = g + 1 < m ? a2[g + 1 >>> 2] : 0, p = g + 2 < m ? a2[g + 2 >>> 2] : 0, p = (a2[g >>> 2] >>> 8 * (f + g % 4 * e) & 255) << 16 | (c2 >>> 8 * (f + (g + 1) % 4 * e) & 255) << 8 | p >>> 8 * (f + (g + 2) % 4 * e) & 255, c2 = 0; 4 > c2; c2 += 1)
          8 * g + 6 * c2 <= b ? k += "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt(p >>> 6 * (3 - c2) & 63) : k += h.b64Pad;
      return k;
    }
    function Q(a2, b, e) {
      var h = "";
      b /= 8;
      var k, c2, g;
      g = e === -1 ? 3 : 0;
      for (k = 0; k < b; k += 1)
        c2 = a2[k >>> 2] >>> 8 * (g + k % 4 * e) & 255, h += String.fromCharCode(c2);
      return h;
    }
    function R(a2, b, e) {
      b /= 8;
      var h, k = new ArrayBuffer(b), c2, g;
      g = new Uint8Array(k);
      c2 = e === -1 ? 3 : 0;
      for (h = 0; h < b; h += 1)
        g[h] = a2[h >>> 2] >>> 8 * (c2 + h % 4 * e) & 255;
      return k;
    }
    function S(a2, b, e) {
      b /= 8;
      var h, k = new Uint8Array(b), c2;
      c2 = e === -1 ? 3 : 0;
      for (h = 0; h < b; h += 1)
        k[h] = a2[h >>> 2] >>> 8 * (c2 + h % 4 * e) & 255;
      return k;
    }
    function N(a2) {
      var b = {outputUpper: false, b64Pad: "=", shakeLen: -1};
      a2 = a2 || {};
      b.outputUpper = a2.outputUpper || false;
      a2.hasOwnProperty("b64Pad") === true && (b.b64Pad = a2.b64Pad);
      if (a2.hasOwnProperty("shakeLen") === true) {
        if (a2.shakeLen % 8 !== 0)
          throw Error("shakeLen must be a multiple of 8");
        b.shakeLen = a2.shakeLen;
      }
      if (typeof b.outputUpper !== "boolean")
        throw Error("Invalid outputUpper formatting option");
      if (typeof b.b64Pad !== "string")
        throw Error("Invalid b64Pad formatting option");
      return b;
    }
    function M(a2, b, e) {
      switch (b) {
        case "UTF8":
        case "UTF16BE":
        case "UTF16LE":
          break;
        default:
          throw Error("encoding must be UTF8, UTF16BE, or UTF16LE");
      }
      switch (a2) {
        case "HEX":
          a2 = function(b2, a3, d) {
            var g = b2.length, c2, p, f, n, q, u;
            if (g % 2 !== 0)
              throw Error("String of HEX type must be in byte increments");
            a3 = a3 || [0];
            d = d || 0;
            q = d >>> 3;
            u = e === -1 ? 3 : 0;
            for (c2 = 0; c2 < g; c2 += 2) {
              p = parseInt(b2.substr(c2, 2), 16);
              if (isNaN(p))
                throw Error("String of HEX type contains invalid characters");
              n = (c2 >>> 1) + q;
              for (f = n >>> 2; a3.length <= f; )
                a3.push(0);
              a3[f] |= p << 8 * (u + n % 4 * e);
            }
            return {value: a3, binLen: 4 * g + d};
          };
          break;
        case "TEXT":
          a2 = function(a3, d, c2) {
            var g, l, p = 0, f, n, q, u, r, t2;
            d = d || [0];
            c2 = c2 || 0;
            q = c2 >>> 3;
            if (b === "UTF8")
              for (t2 = e === -1 ? 3 : 0, f = 0; f < a3.length; f += 1)
                for (g = a3.charCodeAt(f), l = [], 128 > g ? l.push(g) : 2048 > g ? (l.push(192 | g >>> 6), l.push(128 | g & 63)) : 55296 > g || 57344 <= g ? l.push(224 | g >>> 12, 128 | g >>> 6 & 63, 128 | g & 63) : (f += 1, g = 65536 + ((g & 1023) << 10 | a3.charCodeAt(f) & 1023), l.push(240 | g >>> 18, 128 | g >>> 12 & 63, 128 | g >>> 6 & 63, 128 | g & 63)), n = 0; n < l.length; n += 1) {
                  r = p + q;
                  for (u = r >>> 2; d.length <= u; )
                    d.push(0);
                  d[u] |= l[n] << 8 * (t2 + r % 4 * e);
                  p += 1;
                }
            else if (b === "UTF16BE" || b === "UTF16LE")
              for (t2 = e === -1 ? 2 : 0, l = b === "UTF16LE" && e !== 1 || b !== "UTF16LE" && e === 1, f = 0; f < a3.length; f += 1) {
                g = a3.charCodeAt(f);
                l === true && (n = g & 255, g = n << 8 | g >>> 8);
                r = p + q;
                for (u = r >>> 2; d.length <= u; )
                  d.push(0);
                d[u] |= g << 8 * (t2 + r % 4 * e);
                p += 2;
              }
            return {value: d, binLen: 8 * p + c2};
          };
          break;
        case "B64":
          a2 = function(b2, a3, d) {
            var c2 = 0, l, p, f, n, q, u, r, t2;
            if (b2.search(/^[a-zA-Z0-9=+\/]+$/) === -1)
              throw Error("Invalid character in base-64 string");
            p = b2.indexOf("=");
            b2 = b2.replace(/\=/g, "");
            if (p !== -1 && p < b2.length)
              throw Error("Invalid '=' found in base-64 string");
            a3 = a3 || [0];
            d = d || 0;
            u = d >>> 3;
            t2 = e === -1 ? 3 : 0;
            for (p = 0; p < b2.length; p += 4) {
              q = b2.substr(p, 4);
              for (f = n = 0; f < q.length; f += 1)
                l = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".indexOf(q.charAt(f)), n |= l << 18 - 6 * f;
              for (f = 0; f < q.length - 1; f += 1) {
                r = c2 + u;
                for (l = r >>> 2; a3.length <= l; )
                  a3.push(0);
                a3[l] |= (n >>> 16 - 8 * f & 255) << 8 * (t2 + r % 4 * e);
                c2 += 1;
              }
            }
            return {value: a3, binLen: 8 * c2 + d};
          };
          break;
        case "BYTES":
          a2 = function(b2, a3, d) {
            var c2, l, p, f, n, q;
            a3 = a3 || [0];
            d = d || 0;
            p = d >>> 3;
            q = e === -1 ? 3 : 0;
            for (l = 0; l < b2.length; l += 1)
              c2 = b2.charCodeAt(l), n = l + p, f = n >>> 2, a3.length <= f && a3.push(0), a3[f] |= c2 << 8 * (q + n % 4 * e);
            return {
              value: a3,
              binLen: 8 * b2.length + d
            };
          };
          break;
        case "ARRAYBUFFER":
          try {
            a2 = new ArrayBuffer(0);
          } catch (h) {
            throw Error("ARRAYBUFFER not supported by this environment");
          }
          a2 = function(b2, a3, d) {
            return T(new Uint8Array(b2), a3, d, e);
          };
          break;
        case "UINT8ARRAY":
          try {
            a2 = new Uint8Array(0);
          } catch (h) {
            throw Error("UINT8ARRAY not supported by this environment");
          }
          a2 = function(b2, a3, d) {
            return T(b2, a3, d, e);
          };
          break;
        default:
          throw Error("format must be HEX, TEXT, B64, BYTES, ARRAYBUFFER, or UINT8ARRAY");
      }
      return a2;
    }
    function y(a2, b) {
      return a2 << b | a2 >>> 32 - b;
    }
    function U(d, b) {
      return 32 < b ? (b -= 32, new a(d.b << b | d.a >>> 32 - b, d.a << b | d.b >>> 32 - b)) : b !== 0 ? new a(d.a << b | d.b >>> 32 - b, d.b << b | d.a >>> 32 - b) : d;
    }
    function x(a2, b) {
      return a2 >>> b | a2 << 32 - b;
    }
    function t(d, b) {
      var e = null, e = new a(d.a, d.b);
      return e = 32 >= b ? new a(e.a >>> b | e.b << 32 - b & 4294967295, e.b >>> b | e.a << 32 - b & 4294967295) : new a(e.b >>> b - 32 | e.a << 64 - b & 4294967295, e.a >>> b - 32 | e.b << 64 - b & 4294967295);
    }
    function V(d, b) {
      var e = null;
      return e = 32 >= b ? new a(d.a >>> b, d.b >>> b | d.a << 32 - b & 4294967295) : new a(0, d.a >>> b - 32);
    }
    function ca(a2, b, e) {
      return a2 & b ^ ~a2 & e;
    }
    function da(d, b, e) {
      return new a(d.a & b.a ^ ~d.a & e.a, d.b & b.b ^ ~d.b & e.b);
    }
    function W(a2, b, e) {
      return a2 & b ^ a2 & e ^ b & e;
    }
    function ea(d, b, e) {
      return new a(d.a & b.a ^ d.a & e.a ^ b.a & e.a, d.b & b.b ^ d.b & e.b ^ b.b & e.b);
    }
    function fa(a2) {
      return x(a2, 2) ^ x(a2, 13) ^ x(a2, 22);
    }
    function ga(d) {
      var b = t(d, 28), e = t(d, 34);
      d = t(d, 39);
      return new a(b.a ^ e.a ^ d.a, b.b ^ e.b ^ d.b);
    }
    function ha(a2) {
      return x(a2, 6) ^ x(a2, 11) ^ x(a2, 25);
    }
    function ia(d) {
      var b = t(d, 14), e = t(d, 18);
      d = t(d, 41);
      return new a(b.a ^ e.a ^ d.a, b.b ^ e.b ^ d.b);
    }
    function ja(a2) {
      return x(a2, 7) ^ x(a2, 18) ^ a2 >>> 3;
    }
    function ka(d) {
      var b = t(d, 1), e = t(d, 8);
      d = V(d, 7);
      return new a(b.a ^ e.a ^ d.a, b.b ^ e.b ^ d.b);
    }
    function la(a2) {
      return x(a2, 17) ^ x(a2, 19) ^ a2 >>> 10;
    }
    function ma(d) {
      var b = t(d, 19), e = t(d, 61);
      d = V(d, 6);
      return new a(b.a ^ e.a ^ d.a, b.b ^ e.b ^ d.b);
    }
    function G(a2, b) {
      var e = (a2 & 65535) + (b & 65535);
      return ((a2 >>> 16) + (b >>> 16) + (e >>> 16) & 65535) << 16 | e & 65535;
    }
    function na(a2, b, e, h) {
      var c2 = (a2 & 65535) + (b & 65535) + (e & 65535) + (h & 65535);
      return ((a2 >>> 16) + (b >>> 16) + (e >>> 16) + (h >>> 16) + (c2 >>> 16) & 65535) << 16 | c2 & 65535;
    }
    function H(a2, b, e, h, c2) {
      var m = (a2 & 65535) + (b & 65535) + (e & 65535) + (h & 65535) + (c2 & 65535);
      return ((a2 >>> 16) + (b >>> 16) + (e >>> 16) + (h >>> 16) + (c2 >>> 16) + (m >>> 16) & 65535) << 16 | m & 65535;
    }
    function oa(d, b) {
      var e, h, c2;
      e = (d.b & 65535) + (b.b & 65535);
      h = (d.b >>> 16) + (b.b >>> 16) + (e >>> 16);
      c2 = (h & 65535) << 16 | e & 65535;
      e = (d.a & 65535) + (b.a & 65535) + (h >>> 16);
      h = (d.a >>> 16) + (b.a >>> 16) + (e >>> 16);
      return new a((h & 65535) << 16 | e & 65535, c2);
    }
    function pa(d, b, e, h) {
      var c2, m, g;
      c2 = (d.b & 65535) + (b.b & 65535) + (e.b & 65535) + (h.b & 65535);
      m = (d.b >>> 16) + (b.b >>> 16) + (e.b >>> 16) + (h.b >>> 16) + (c2 >>> 16);
      g = (m & 65535) << 16 | c2 & 65535;
      c2 = (d.a & 65535) + (b.a & 65535) + (e.a & 65535) + (h.a & 65535) + (m >>> 16);
      m = (d.a >>> 16) + (b.a >>> 16) + (e.a >>> 16) + (h.a >>> 16) + (c2 >>> 16);
      return new a((m & 65535) << 16 | c2 & 65535, g);
    }
    function qa(d, b, e, h, c2) {
      var m, g, l;
      m = (d.b & 65535) + (b.b & 65535) + (e.b & 65535) + (h.b & 65535) + (c2.b & 65535);
      g = (d.b >>> 16) + (b.b >>> 16) + (e.b >>> 16) + (h.b >>> 16) + (c2.b >>> 16) + (m >>> 16);
      l = (g & 65535) << 16 | m & 65535;
      m = (d.a & 65535) + (b.a & 65535) + (e.a & 65535) + (h.a & 65535) + (c2.a & 65535) + (g >>> 16);
      g = (d.a >>> 16) + (b.a >>> 16) + (e.a >>> 16) + (h.a >>> 16) + (c2.a >>> 16) + (m >>> 16);
      return new a((g & 65535) << 16 | m & 65535, l);
    }
    function B(d, b) {
      return new a(d.a ^ b.a, d.b ^ b.b);
    }
    function A(d) {
      var b = [], e;
      if (d === "SHA-1")
        b = [1732584193, 4023233417, 2562383102, 271733878, 3285377520];
      else if (d.lastIndexOf("SHA-", 0) === 0)
        switch (b = [3238371032, 914150663, 812702999, 4144912697, 4290775857, 1750603025, 1694076839, 3204075428], e = [1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225], d) {
          case "SHA-224":
            break;
          case "SHA-256":
            b = e;
            break;
          case "SHA-384":
            b = [new a(3418070365, b[0]), new a(1654270250, b[1]), new a(2438529370, b[2]), new a(355462360, b[3]), new a(1731405415, b[4]), new a(41048885895, b[5]), new a(3675008525, b[6]), new a(1203062813, b[7])];
            break;
          case "SHA-512":
            b = [new a(e[0], 4089235720), new a(e[1], 2227873595), new a(e[2], 4271175723), new a(e[3], 1595750129), new a(e[4], 2917565137), new a(e[5], 725511199), new a(e[6], 4215389547), new a(e[7], 327033209)];
            break;
          default:
            throw Error("Unknown SHA variant");
        }
      else if (d.lastIndexOf("SHA3-", 0) === 0 || d.lastIndexOf("SHAKE", 0) === 0)
        for (d = 0; 5 > d; d += 1)
          b[d] = [new a(0, 0), new a(0, 0), new a(0, 0), new a(0, 0), new a(0, 0)];
      else
        throw Error("No SHA variants supported");
      return b;
    }
    function K(a2, b) {
      var e = [], h, c2, m, g, l, p, f;
      h = b[0];
      c2 = b[1];
      m = b[2];
      g = b[3];
      l = b[4];
      for (f = 0; 80 > f; f += 1)
        e[f] = 16 > f ? a2[f] : y(e[f - 3] ^ e[f - 8] ^ e[f - 14] ^ e[f - 16], 1), p = 20 > f ? H(y(h, 5), c2 & m ^ ~c2 & g, l, 1518500249, e[f]) : 40 > f ? H(y(h, 5), c2 ^ m ^ g, l, 1859775393, e[f]) : 60 > f ? H(y(h, 5), W(c2, m, g), l, 2400959708, e[f]) : H(y(h, 5), c2 ^ m ^ g, l, 3395469782, e[f]), l = g, g = m, m = y(c2, 30), c2 = h, h = p;
      b[0] = G(h, b[0]);
      b[1] = G(c2, b[1]);
      b[2] = G(m, b[2]);
      b[3] = G(g, b[3]);
      b[4] = G(l, b[4]);
      return b;
    }
    function ba(a2, b, e, c2) {
      var k;
      for (k = (b + 65 >>> 9 << 4) + 15; a2.length <= k; )
        a2.push(0);
      a2[b >>> 5] |= 128 << 24 - b % 32;
      b += e;
      a2[k] = b & 4294967295;
      a2[k - 1] = b / 4294967296 | 0;
      b = a2.length;
      for (k = 0; k < b; k += 16)
        c2 = K(a2.slice(k, k + 16), c2);
      return c2;
    }
    function L(d, b, e) {
      var h, k, m, g, l, p, f, n, q, u, r, t2, v, x2, y2, A2, z, w, F, B2, C2, D2, E = [], J;
      if (e === "SHA-224" || e === "SHA-256")
        u = 64, t2 = 1, D2 = Number, v = G, x2 = na, y2 = H, A2 = ja, z = la, w = fa, F = ha, C2 = W, B2 = ca, J = c;
      else if (e === "SHA-384" || e === "SHA-512")
        u = 80, t2 = 2, D2 = a, v = oa, x2 = pa, y2 = qa, A2 = ka, z = ma, w = ga, F = ia, C2 = ea, B2 = da, J = X;
      else
        throw Error("Unexpected error in SHA-2 implementation");
      e = b[0];
      h = b[1];
      k = b[2];
      m = b[3];
      g = b[4];
      l = b[5];
      p = b[6];
      f = b[7];
      for (r = 0; r < u; r += 1)
        16 > r ? (q = r * t2, n = d.length <= q ? 0 : d[q], q = d.length <= q + 1 ? 0 : d[q + 1], E[r] = new D2(n, q)) : E[r] = x2(z(E[r - 2]), E[r - 7], A2(E[r - 15]), E[r - 16]), n = y2(f, F(g), B2(g, l, p), J[r], E[r]), q = v(w(e), C2(e, h, k)), f = p, p = l, l = g, g = v(m, n), m = k, k = h, h = e, e = v(n, q);
      b[0] = v(e, b[0]);
      b[1] = v(h, b[1]);
      b[2] = v(k, b[2]);
      b[3] = v(m, b[3]);
      b[4] = v(g, b[4]);
      b[5] = v(l, b[5]);
      b[6] = v(p, b[6]);
      b[7] = v(f, b[7]);
      return b;
    }
    function D(d, b) {
      var e, c2, k, m, g = [], l = [];
      if (d !== null)
        for (c2 = 0; c2 < d.length; c2 += 2)
          b[(c2 >>> 1) % 5][(c2 >>> 1) / 5 | 0] = B(b[(c2 >>> 1) % 5][(c2 >>> 1) / 5 | 0], new a(d[c2 + 1], d[c2]));
      for (e = 0; 24 > e; e += 1) {
        m = A("SHA3-");
        for (c2 = 0; 5 > c2; c2 += 1) {
          k = b[c2][0];
          var p = b[c2][1], f = b[c2][2], n = b[c2][3], q = b[c2][4];
          g[c2] = new a(k.a ^ p.a ^ f.a ^ n.a ^ q.a, k.b ^ p.b ^ f.b ^ n.b ^ q.b);
        }
        for (c2 = 0; 5 > c2; c2 += 1)
          l[c2] = B(g[(c2 + 4) % 5], U(g[(c2 + 1) % 5], 1));
        for (c2 = 0; 5 > c2; c2 += 1)
          for (k = 0; 5 > k; k += 1)
            b[c2][k] = B(b[c2][k], l[c2]);
        for (c2 = 0; 5 > c2; c2 += 1)
          for (k = 0; 5 > k; k += 1)
            m[k][(2 * c2 + 3 * k) % 5] = U(b[c2][k], Y[c2][k]);
        for (c2 = 0; 5 > c2; c2 += 1)
          for (k = 0; 5 > k; k += 1)
            b[c2][k] = B(m[c2][k], new a(~m[(c2 + 1) % 5][k].a & m[(c2 + 2) % 5][k].a, ~m[(c2 + 1) % 5][k].b & m[(c2 + 2) % 5][k].b));
        b[0][0] = B(b[0][0], Z[e]);
      }
      return b;
    }
    var c, X, Y, Z;
    c = [
      1116352408,
      1899447441,
      3049323471,
      3921009573,
      961987163,
      1508970993,
      2453635748,
      2870763221,
      3624381080,
      310598401,
      607225278,
      1426881987,
      1925078388,
      2162078206,
      2614888103,
      3248222580,
      3835390401,
      4022224774,
      264347078,
      604807628,
      770255983,
      1249150122,
      1555081692,
      1996064986,
      2554220882,
      2821834349,
      2952996808,
      3210313671,
      3336571891,
      3584528711,
      113926993,
      338241895,
      666307205,
      773529912,
      1294757372,
      1396182291,
      1695183700,
      1986661051,
      2177026350,
      2456956037,
      2730485921,
      2820302411,
      3259730800,
      3345764771,
      3516065817,
      3600352804,
      4094571909,
      275423344,
      430227734,
      506948616,
      659060556,
      883997877,
      958139571,
      1322822218,
      1537002063,
      1747873779,
      1955562222,
      2024104815,
      2227730452,
      2361852424,
      2428436474,
      2756734187,
      3204031479,
      3329325298
    ];
    X = [
      new a(c[0], 3609767458),
      new a(c[1], 602891725),
      new a(c[2], 3964484399),
      new a(c[3], 2173295548),
      new a(c[4], 4081628472),
      new a(c[5], 3053834265),
      new a(c[6], 2937671579),
      new a(c[7], 3664609560),
      new a(c[8], 2734883394),
      new a(c[9], 1164996542),
      new a(c[10], 1323610764),
      new a(c[11], 3590304994),
      new a(c[12], 4068182383),
      new a(c[13], 991336113),
      new a(c[14], 633803317),
      new a(c[15], 3479774868),
      new a(c[16], 2666613458),
      new a(c[17], 944711139),
      new a(c[18], 2341262773),
      new a(c[19], 2007800933),
      new a(c[20], 1495990901),
      new a(c[21], 1856431235),
      new a(c[22], 3175218132),
      new a(c[23], 2198950837),
      new a(c[24], 3999719339),
      new a(c[25], 766784016),
      new a(c[26], 2566594879),
      new a(c[27], 3203337956),
      new a(c[28], 1034457026),
      new a(c[29], 2466948901),
      new a(c[30], 3758326383),
      new a(c[31], 168717936),
      new a(c[32], 1188179964),
      new a(c[33], 1546045734),
      new a(c[34], 1522805485),
      new a(c[35], 2643833823),
      new a(c[36], 2343527390),
      new a(c[37], 1014477480),
      new a(c[38], 1206759142),
      new a(c[39], 344077627),
      new a(c[40], 1290863460),
      new a(c[41], 3158454273),
      new a(c[42], 3505952657),
      new a(c[43], 106217008),
      new a(c[44], 3606008344),
      new a(c[45], 1432725776),
      new a(c[46], 1467031594),
      new a(c[47], 851169720),
      new a(c[48], 3100823752),
      new a(c[49], 1363258195),
      new a(c[50], 3750685593),
      new a(c[51], 3785050280),
      new a(c[52], 3318307427),
      new a(c[53], 3812723403),
      new a(c[54], 2003034995),
      new a(c[55], 3602036899),
      new a(c[56], 1575990012),
      new a(c[57], 1125592928),
      new a(c[58], 2716904306),
      new a(c[59], 442776044),
      new a(c[60], 593698344),
      new a(c[61], 3733110249),
      new a(c[62], 2999351573),
      new a(c[63], 3815920427),
      new a(3391569614, 3928383900),
      new a(3515267271, 566280711),
      new a(3940187606, 3454069534),
      new a(4118630271, 4000239992),
      new a(116418474, 1914138554),
      new a(174292421, 2731055270),
      new a(289380356, 3203993006),
      new a(460393269, 320620315),
      new a(685471733, 587496836),
      new a(852142971, 1086792851),
      new a(1017036298, 365543100),
      new a(1126000580, 2618297676),
      new a(1288033470, 3409855158),
      new a(1501505948, 4234509866),
      new a(1607167915, 987167468),
      new a(1816402316, 1246189591)
    ];
    Z = [new a(0, 1), new a(0, 32898), new a(2147483648, 32906), new a(2147483648, 2147516416), new a(0, 32907), new a(0, 2147483649), new a(2147483648, 2147516545), new a(2147483648, 32777), new a(0, 138), new a(0, 136), new a(0, 2147516425), new a(0, 2147483658), new a(0, 2147516555), new a(2147483648, 139), new a(2147483648, 32905), new a(2147483648, 32771), new a(2147483648, 32770), new a(2147483648, 128), new a(0, 32778), new a(2147483648, 2147483658), new a(2147483648, 2147516545), new a(2147483648, 32896), new a(0, 2147483649), new a(2147483648, 2147516424)];
    Y = [[0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61], [28, 55, 25, 21, 56], [27, 20, 39, 8, 14]];
    module.exports && (module.exports = C), exports = C;
  })();
});
export default sha;


