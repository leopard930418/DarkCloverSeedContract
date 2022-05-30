# Basic Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
# Traits info

Guidance of uploadTraits(traitType, traitIds, traits) function

    // Common traitType: 0 - 6 - 1, 3, 6, 6, 10, 8 
                         1 - 6 - 1, 2, 2, 2, 3, 5
                         2 - 4 -1, 1, 1, 1

    // Field traitType : 0 - 6 - 1, 2, 3, 3, 4, 4
                         1 - 6 - 1, 1, 1, 1, 2, 2
                         2 - 6 - 1, 1, 1, 1, 2, 2
                         3 - 6 - 1, 2, 2, 3, 3, 4
                         4 - 6 - 1, 2, 3, 4, 4, 6
                         5 - 6 - 1, 2, 3, 5, 4, 5
                         6 - 6 - 1, 1, 2, 3, 4, 6
                         7 - 6 - 1, 2, 5, 6, 7, 9
                         8 - 6 - 1, 2, 3, 4, 4, 7

    // Yard traitType : 0 - 6 - 1, 2, 3, 3, 4, 4
                        1 - 6 - 1, 1, 1, 1, 2, 2
                        2 - 6 - 1, 1, 1, 1, 2, 2
                        3 - 6 - 1, 2, 3, 4, 4, 6
                        4 - 6 - 2, 4, 5, 8, 7, 8
                        5 - 6 - 2, 3, 7, 9, 11, 14
                        6 - 6 - 1, 2, 3, 3, 3, 7

    // Pot traitType :  0 - 6 - 1, 2, 3, 3, 4, 4
                        1 - 6 - 1, 1, 1, 1, 2, 2
                        2 - 6 - 1, 1, 1, 1, 2, 2
                        3 - 6 - 3, 6, 8, 12, 11, 13
                        4 - 6 - 3, 4, 11, 12, 14, 19

 -  common background : common traitType 0
    rarity : [0, 1, 2, 3, 4, 5]
    traitData : 
        -rarity 0
            traitIds: 1
            traits : [
                {
                    name : "BACKGROUND GRADIENT DARK MIDNIGHT BLUE"
                    png: ""
                }
            ] 
        -rarity 1
            traitIds: 3
            traits : [
                {
                    name : "BACKGROUND GRADIENT MEDIUM GREEN PASTEL"
                    png: ""
                },
                {
                    name : "BACKGROUND GRADIENT MIDNIGHT BLUE"
                    png: ""
                },
                {
                    name : "BACKGROUND GRADIENT SAND BROWN"
                    png: ""
                }
            ]
        -rarity 2
        

