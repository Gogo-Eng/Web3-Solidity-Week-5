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
