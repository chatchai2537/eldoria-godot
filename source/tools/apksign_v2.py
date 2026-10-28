#!/usr/bin/env python3
"""เซ็น APK แบบ APK Signature Scheme v2 (ไม่ต้องใช้ Android SDK)
ใช้: python3 apksign_v2.py in.apk out.apk keystore.p12 password
อ้างอิง: https://source.android.com/docs/security/features/apksigning/v2
"""
import hashlib, struct, sys
from cryptography.hazmat.primitives.serialization import pkcs12, Encoding, PublicFormat
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes

SIG_RSA_PKCS1_SHA256 = 0x0103
V2_ID = 0x7109871A
MAGIC = b"APK Sig Block 42"
CHUNK = 1024 * 1024


def lp(b):  # length-prefixed (uint32 LE)
    return struct.pack("<I", len(b)) + b


def find_eocd(d):
    i = d.rfind(b"PK\x05\x06", max(0, len(d) - 65557))
    if i < 0:
        raise SystemExit("ไม่เจอ EOCD")
    return i


def digest(sections):
    chunks = []
    for s in sections:
        for o in range(0, len(s), CHUNK):
            c = s[o:o + CHUNK]
            chunks.append(hashlib.sha256(b"\xa5" + struct.pack("<I", len(c)) + c).digest())
    return hashlib.sha256(b"\x5a" + struct.pack("<I", len(chunks)) + b"".join(chunks)).digest()


def main(src, dst, ks, pw):
    d = open(src, "rb").read()
    e = find_eocd(d)
    cd_size, cd_off = struct.unpack("<II", d[e + 12:e + 20])
    if d[cd_off - 16:cd_off] == MAGIC:
        raise SystemExit("APK นี้เซ็นแล้ว")
    s1, s3, s4 = d[:cd_off], d[cd_off:e], bytearray(d[e:])
    key, cert, _ = pkcs12.load_key_and_certificates(open(ks, "rb").read(), pw.encode())
    cert_der = cert.public_bytes(Encoding.DER)
    pub = key.public_key().public_bytes(Encoding.DER, PublicFormat.SubjectPublicKeyInfo)
    dg = digest([s1, s3, bytes(s4)])
    digests = lp(struct.pack("<I", SIG_RSA_PKCS1_SHA256) + lp(dg))
    signed = lp(digests) + lp(lp(cert_der)) + lp(b"")
    sig = key.sign(signed, padding.PKCS1v15(), hashes.SHA256())
    signer = lp(signed) + lp(lp(struct.pack("<I", SIG_RSA_PKCS1_SHA256) + lp(sig))) + lp(pub)
    v2 = lp(lp(signer))
    pair = struct.pack("<Q", 4 + len(v2)) + struct.pack("<I", V2_ID) + v2
    size = len(pair) + 8 + 16
    block = struct.pack("<Q", size) + pair + struct.pack("<Q", size) + MAGIC
    s4[16:20] = struct.pack("<I", cd_off + len(block))
    open(dst, "wb").write(s1 + block + s3 + bytes(s4))
    print("เซ็นแล้ว:", dst)


if __name__ == "__main__":
    main(*sys.argv[1:5])
