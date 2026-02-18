# Where Are Structs, Mappings, and Arrays Stored in Solidity?

In Solidity (and the EVM), every variable has a **storage location**. Understanding where data lives is critical for writing gas-efficient and correct smart contracts.

## The Three Storage Locations

| Location   | Persistent? | Gas Cost | Where Used                        
|------------|-------------|----------|-----------------------------------
| `storage`  | ✅ Yes       | High     | State variables (on-chain)        
| `memory`   | ❌ No        | Low      | Function parameters, local vars   
| `calldata` | ❌ No        | Lowest   | External function inputs (read-only)

## 1. Storage (On-Chain Persistent)

`storage` is the **blockchain itself** — it lives inside the contract's state and persists between transactions. It is organized as a key-value store with **2²⁵⁶ slots**, each 32 bytes wide.

### How Slots Are Assigned

Slot 0  →  First state variable
Slot 1  →  Second state variable
Slot 2  →  Third state variable
...

Small variables (< 32 bytes) are **packed together** into the same slot to save gas.

```solidity
uint128 a;   // Slot 0 (first 16 bytes)
uint128 b;   // Slot 0 (last 16 bytes)  ← packed!
uint256 c;   // Slot 1 (full slot)
```

---

## 2. Structs in Storage

Structs are stored **sequentially** in storage slots, starting at the slot of the state variable that holds the struct. Each field occupies its natural slot, and smaller fields are packed when possible.

```solidity
struct Person {
    uint256 age;
    address wallet;
    bool active;
}

Person public user;
```

### Struct in Memory

When you declare a struct inside a function, it goes into **memory** — a temporary, linear byte array that is wiped after the function ends.

```solidity
function example() public pure returns (uint256) {
    Person memory p = Person(30, address(0), true);
    return p.age;
}
```

> ⚠️ If you do `Person storage p = user;`, you get a **storage pointer** — changes to `p` will modify the blockchain state.

---

## 3. Mappings in Storage

Mappings **only exist in storage** — they cannot be declared in memory or calldata. They do not store data contiguously; instead, each value is stored at a slot computed by a **keccak256 hash**:

```
slot(key) = keccak256(abi.encode(key, mappingSlot))
```

### Example

```solidity
mapping(address => uint256) public balances;
```

This means:
- Mappings have **no length** — you cannot iterate over them natively.
- Keys that were never set return `0` (the default value).
- Nested mappings compound the hash: `keccak256(abi.encode(key2, keccak256(abi.encode(key1, slot))))`.

```solidity
mapping(address => mapping(address => uint256)) public allowances;
```
## 4. Arrays in Storage

### Fixed-Size Arrays

Stored sequentially in storage like struct fields — element `i` goes into slot `N + i`.

```solidity
uint256[3] public arr;
```

### Dynamic Arrays

The **length** is stored at the array's base slot. The **elements** are stored starting at `keccak256(baseSlot)`.

```solidity
uint256[] public data;
```

### Arrays in Memory

Dynamic arrays can be created in memory, but their size must be fixed at creation time:

```solidity
function example(uint256 n) public pure {
    uint256[] memory arr = new uint256[](n);
}
```
## 5. Calldata

`calldata` is a **read-only**, non-persistent area that holds the input data of an external function call. It is the cheapest location to read from. You cannot write to calldata.

```solidity
function process(uint256[] calldata ids) external pure returns (uint256) {
    return ids.length;
}
```

---

## Quick Reference Cheat Sheet

```
STATE VARIABLES
├── Primitives (uint, bool, address)  → storage (packed into slots)
├── Structs                           → storage (sequential slots, packed fields)
├── Mappings                          → storage only (keccak256-derived slots)
├── Fixed Arrays                      → storage (slot N + index)
└── Dynamic Arrays                    → storage (length at slot N, data at keccak256(N))

FUNCTION SCOPE
├── Local primitives                  → stack (up to 16 variables)
├── Local structs / arrays            → memory (temporary, wiped after call)
├── External input parameters         → calldata (read-only, cheapest)
└── Storage pointer (Type storage p)  → points INTO storage (modifies state)
```

---

## Gas Cost Summary

| Action                  | Cost Approx.          |
|-------------------------|-----------------------|
| Write to storage (cold) | ~20,000 gas           |
| Write to storage (warm) | ~2,900 gas            |
| Read from storage       | ~2,100 gas            |
| Read/write memory       | ~3 gas per word       |
| Read calldata           | ~3 gas per byte       |

> 💡 **Rule of thumb:** Minimize storage writes — they are by far the most expensive EVM operation. Use `memory` for intermediate computations and only write the final result to storage.

---

## Putting It All Together — ERC-20 Example

```solidity
// All stored in STORAGE (persistent, on-chain)
string  public name;                                          // Slot 0
string  public symbol;                                        // Slot 1
uint8   public decimals;                                      // Slot 2
uint256 public totalSupply;                                   // Slot 3

mapping(address => uint256)                     private _balances;    // Slot 4
mapping(address => mapping(address => uint256)) private _allowances;  // Slot 5

// Inside a function — stored in MEMORY (temporary)
function getInfo() public view returns (string memory) {
    string memory info = string(abi.encodePacked(name, " (", symbol, ")"));
    return info; // 'info' lives only during this call
}
```