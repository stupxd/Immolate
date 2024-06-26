// Emperor->Fool/Emperor Chains with help of Showman
// 
// How to read result: 1020304
// 1 -> longest chain 
// 2 -> showman appears ante 2 (in first 6 shop items or in a buffoon pack)
// 3 -> emperor appears ante 3  (in first 6 shop items)
// 4 -> best ante to use emperor
#include "lib/immolate.cl"
  
bool is_chained(bool hasShowman, item tarot) {
    return tarot == The_Fool || (hasShowman && tarot == The_Emperor);
}

void check_next_item(instance* inst, int ante, bool *hasShowman, int *hasShowmanAnte, bool *hasEmperor, int *hasEmperorAnte) {
    shopitem shopItem = next_shop_item(inst, ante);
    if (!(*hasShowman) && shopItem.value == Showman) {
        *hasShowman = true;
        *hasShowmanAnte = ante;
    }
    if (!(*hasEmperor) && shopItem.value == The_Emperor) {
        *hasEmperor = true;
        *hasEmperorAnte = ante;
    }
}

void check_next_pack(instance* inst, int ante, bool *hasShowman, int *hasShowmanAnte) {
    pack pack = pack_info(next_pack(inst, ante));

    if (pack.type != Buffoon_Pack) {
        return;
    }

    // Generate next x jokers that will be in the pack
    item jokers[4];
    buffoon_pack(jokers, pack.size, inst, 1);

    for (int index = 0; index < pack.size; index++) {
        if (jokers[index] == Showman) {
            *hasShowman = true;
            *hasShowmanAnte = ante;
            break;
        }
    }
}

long filter(instance* inst) {
    int bestAnte = 0;
    long bestScore = 0;
    int hasShowmanAnte = 0;
    int hasEmperorAnte = 0;

    bool hasShowman = false; // We can pick up showman ante 1 for extended emperor chain in ante 2, for example.
    int maxPacks = 4;

    // Because of ante-based RNG, we check every ante and store the best ante as the result
    for (int ante = 1; ante <= 5; ante++) {
        bool hasEmperor = false;
        
        if (!hasShowman || !hasEmperor) {
            for (int shopItem = 0; shopItem < 6; shopItem++) {
                check_next_item(inst, ante, &hasShowman, &hasShowmanAnte, &hasEmperor, &hasEmperorAnte);
            }

            if (!hasShowman) {
                for (int shopPack = 0; shopPack < maxPacks; shopPack++) {
                    check_next_pack(inst, ante, &hasShowman, &hasShowmanAnte);
                }
            }
            maxPacks = 6; // Update packs cap for the following ante
        }

        if (!hasEmperor) {
            continue;
        }

        long score = 0;
        while (true) {
            item firstTarot = next_tarot(inst, S_Emperor, ante, false);
            item secondTarot = next_tarot(inst, S_Emperor, ante, false);
            if (is_chained(hasShowman, firstTarot) || is_chained(hasShowman, secondTarot)) {
                score++;
            } else {
                break;
            }
        }

        if (score >= bestScore) {
            bestAnte = ante;
            bestScore = score;
        }
    }

    if (bestScore < 5) { // Cutoff chains that are less than 5.
        return 0;
    }

    return bestScore * 1000000 + hasShowmanAnte * 10000 + hasEmperorAnte * 100 + bestAnte;
}
