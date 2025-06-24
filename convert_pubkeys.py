#!/usr/bin/env python3
"""Convert hex pubkeys to npub format using bech32 encoding."""

import sys

# Bech32 character set
CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

def bech32_polymod(values):
    """Internal function for bech32 checksum."""
    GEN = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]
    chk = 1
    for v in values:
        b = chk >> 25
        chk = (chk & 0x1ffffff) << 5 ^ v
        for i in range(5):
            chk ^= GEN[i] if ((b >> i) & 1) else 0
    return chk

def bech32_hrp_expand(hrp):
    """Expand the HRP into values for checksum computation."""
    return [ord(x) >> 5 for x in hrp] + [0] + [ord(x) & 31 for x in hrp]

def bech32_verify_checksum(hrp, data):
    """Verify a checksum given HRP and converted data characters."""
    return bech32_polymod(bech32_hrp_expand(hrp) + data) == 1

def bech32_create_checksum(hrp, data):
    """Compute the checksum values given HRP and data."""
    values = bech32_hrp_expand(hrp) + data
    polymod = bech32_polymod(values + [0, 0, 0, 0, 0, 0]) ^ 1
    return [(polymod >> 5 * (5 - i)) & 31 for i in range(6)]

def bech32_encode(hrp, data):
    """Compute a Bech32 string given HRP and data values."""
    combined = data + bech32_create_checksum(hrp, data)
    return hrp + '1' + ''.join([CHARSET[d] for d in combined])

def convertbits(data, frombits, tobits, pad=True):
    """General power-of-2 base conversion."""
    acc = 0
    bits = 0
    ret = []
    maxv = (1 << tobits) - 1
    max_acc = (1 << (frombits + tobits - 1)) - 1
    for value in data:
        if value < 0 or (value >> frombits):
            return None
        acc = ((acc << frombits) | value) & max_acc
        bits += frombits
        while bits >= tobits:
            bits -= tobits
            ret.append((acc >> bits) & maxv)
    if pad:
        if bits:
            ret.append((acc << (tobits - bits)) & maxv)
    elif bits >= frombits or ((acc << (tobits - bits)) & maxv):
        return None
    return ret

def hex_to_npub(hex_pubkey):
    """Convert a hex pubkey to npub format."""
    # Convert hex to bytes
    try:
        pubkey_bytes = bytes.fromhex(hex_pubkey)
    except ValueError:
        return None
    
    # Convert 8-bit bytes to 5-bit groups
    data = convertbits(pubkey_bytes, 8, 5)
    if data is None:
        return None
    
    # Encode with 'npub' HRP
    return bech32_encode('npub', data)

# List of pubkeys to convert
pubkeys = [
    ("e0f6050d930a61323bac4a5b47d58e961da2919834f3f58f3b312c2918852b55", "Flame_of_Man⚡️"),
    ("9349c924270bf5b2390f6d780dde344e965512470321b1603cef68522f9c01cc", "Tsuki"),
    ("5be6189315d16136de600c1491b1dea44c79605b79bb2cda3452841a646b0e69", "Product Hunt"),
    ("7fca15288725e8054d4fc59055d74f14b06a29a85f8188c6534953acc15a396c", "MidyReyes"),
    ("622394fa87409558e8522a19fd5e5594f7b1912b9c4984de23cb1f9d1c804705", "クラケドヒ"),
    ("db5081dad260eb68c49fb2a2fc680e988b9776f0343b4a110c6e29572a5618f6", "OrphansOfUgandaChildrenCenter"),
    ("728c9db15e8337d132cbd58f8d486f94900c4886aebfebb3a51a6e3bf99a8434", "(no name)"),
    ("38e02d76b4299acea0c847217b602bce12a9d3cea3cabdfd616c58324cff73d3", "VaderBass"),
    ("2e0ec46e448abd51bfb97de5bd36608658e72584285dfbb018256f6538d096d5", "DarkGura"),
    ("d8c896c5af04b74cb83f6a1adc0030dc2ee49b41eb7c00438808589b081b583b", "jon saibeaks"),
    ("c6d131868bda14d54afb67f18acb3b8fd6f1e264f3d97966cf255ad4a4847744", "Tom Kindlon"),
    ("da8a6dfed32fa83927e37ce58c419180473ce662238b600594928119c69875e7", "Chadd Kirlin"),
    ("2eedecc049e7f54b761572787c0be1e74ac7e6ad3480b4ce6300817677e12d31", "🧈ButterMilk 🍼"),
    ("db959d6afc5bb6d0b65dd44eb5c84f883b8202df8d2a2cfaac1b61ebfa968f1e", "Antoinne Sterk"),
    ("b3a1cb3945b4e7eb57b2c1d3b5487386b2a87b655e09aa20f6a918472b9d9470", "Wendell Kshlerin"),
    ("b2b098597d9792bcd1a3098727fdb389ace6d8db708dc3c60a953e2e07cc66bd", "Lilly Mohr"),
    ("6c516eefe1dfc59598eb79162f909abead01062d7f2bb2e89b87fde05d928e2f", "DeusVult"),
    ("a497ec36968c1498b82b9e16934802bff827a76fb6fd5469d2a18782c209de1b", "Terrazas"),
    ("b4301b4a69978c54b6b1a0d8af2e0f4ba2a4063c83971cdc9ee64ccdfb94f05d", "皐月 那府 (Satsuki Nafu)"),
    ("6a4bc5b8528362fe7b3134b34bd923d6b8db6859859d494c3afbf6e97060ebb6", "Micaela Braun"),
]

# Convert and print results
print("Trending Nostr Profiles - Hex to npub conversion:\n")
for i, (hex_key, name) in enumerate(pubkeys, 1):
    npub = hex_to_npub(hex_key)
    if npub:
        print(f"{i}. {name}")
        print(f"   Hex: {hex_key}")
        print(f"   npub: {npub}\n")
    else:
        print(f"{i}. {name} - Conversion failed\n")