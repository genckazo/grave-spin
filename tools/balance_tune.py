import random, statistics

random.seed(1)

WEIGHTS = {"sword": 30, "shield": 21, "potion": 11, "coin": 18, "skull": 20}
VALUES = {"sword": 3, "shield": 2, "potion": 2, "coin": 1, "skull": 2}
HP = 45
HEAL_BETWEEN = 7

FIGHTS = [
    ("Skeleton", 24, [6, 6, 9]),
    ("Slime", 28, [5, 8, 5]),
    ("Cultist", 32, [7, 7, 11]),
    ("Bone Captain", 40, [8, 8, 12]),
    ("Grave Warden", 50, [9, 9, 14]),
]

def spin():
    syms = list(WEIGHTS)
    w = [WEIGHTS[s] for s in syms]
    grid = [[random.choices(syms, w)[0] for _ in range(3)] for _ in range(3)]
    return grid

def sim(first_relic_only=False):
    hp = HP; coins = 0; fight = 0
    turns = 0
    while fight < len(FIGHTS):
        name, ehp, pattern = FIGHTS[fight]
        ehp = ehp + fight * 2  # small scale
        eblock = 0
        turn = 0
        while ehp > 0 and hp > 0:
            turns += 1
            grid = spin()
            dmg = 0; block = 0; heal = 0
            for row in grid:
                swords = row.count("sword"); shields = row.count("shield")
                potions = row.count("potion"); cs = row.count("coin"); skulls = row.count("skull")
                dmg += swords * VALUES["sword"]
                block += shields * VALUES["shield"]
                heal += potions * VALUES["potion"]
                coins += cs * VALUES["coin"]
            intent = pattern[turn % len(pattern)]
            attack = intent + 2 * sum(row.count("skull") for row in grid)
            hp = min(HP, hp + heal)
            ehp -= max(0, dmg - eblock)
            eblock = 0
            block_used = min(block, attack)
            hp -= max(0, attack - block_used)
            turn += 1
        if hp <= 0:
            return False, fight, turns, coins
        fight += 1
        hp = min(HP, hp + HEAL_BETWEEN)
    return True, fight, turns, coins

N = 5000
res = [sim() for _ in range(N)]
wins = sum(1 for r in res if r[0])
print(f"win rate {wins/N:.1%}")
print("avg fights", statistics.mean(r[1] for r in res))
print("avg turns", statistics.mean(r[2] for r in res))
print("avg coins", statistics.mean(r[3] for r in res))
