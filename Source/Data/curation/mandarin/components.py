# fmt: off
CONSONANT_MASK = 0x001F  # 0000 0000 0001 1111, 21 consonants
MEDIAL_MASK = 0x0060     # 0000 0000 0110 0000, 3 medials (I, U, Ü)
RHYME_MASK = 0x0780      # 0000 0111 1000 0000, 13 rhymes
TONE_MASK = 0x3800       # 0011 1000 0000 0000, 5 tones (first tone is 0)

B = 0x0001
P = 0x0002
M = 0x0003
F = 0x0004
D = 0x0005
T = 0x0006
N = 0x0007
L = 0x0008
G = 0x0009
K = 0x000A
H = 0x000B
J = 0x000C
Q = 0x000D
X = 0x000E
ZH = 0x000F
CH = 0x0010
SH = 0x0011
R = 0x0012
Z = 0x0013
C = 0x0014
S = 0x0015
I = 0x0020
U = 0x0040
Ü = 0x0060
A = 0x0080
O = 0x0100
E = 0x0180     # ㄜ
Ê = 0x0200     # ㄝ
AI = 0x0280
EI = 0x0300
AO = 0x0380
OU = 0x0400
AN = 0x0480
EN = 0x0500
ANG = 0x0580
ENG = 0x0600
ER = 0x0680    # ㄦ
TONE1 = 0x0000
TONE2 = 0x0800
TONE3 = 0x1000
TONE4 = 0x1800
TONE5 = 0x2000
# fmt: on

BOPOMOFO_TO_COMPONENT = {
    "ㄅ": B,
    "ㄆ": P,
    "ㄇ": M,
    "ㄈ": F,
    "ㄉ": D,
    "ㄊ": T,
    "ㄋ": N,
    "ㄌ": L,
    "ㄍ": G,
    "ㄎ": K,
    "ㄏ": H,
    "ㄐ": J,
    "ㄑ": Q,
    "ㄒ": X,
    "ㄓ": ZH,
    "ㄔ": CH,
    "ㄕ": SH,
    "ㄖ": R,
    "ㄗ": Z,
    "ㄘ": C,
    "ㄙ": S,
    "ㄧ": I,
    "ㄨ": U,
    "ㄩ": Ü,
    "ㄚ": A,
    "ㄛ": O,
    "ㄜ": E,
    "ㄝ": Ê,
    "ㄞ": AI,
    "ㄟ": EI,
    "ㄠ": AO,
    "ㄡ": OU,
    "ㄢ": AN,
    "ㄣ": EN,
    "ㄤ": ANG,
    "ㄥ": ENG,
    "ㄦ": ER,
    "ˊ": TONE2,
    "ˇ": TONE3,
    "ˋ": TONE4,
    "˙": TONE5,
}

COMPONENT_TO_BOPOMOFO = {v: k for k, v in BOPOMOFO_TO_COMPONENT.items()}
