- The lib folder is the library folder. It contains contracts that can be imported in your main contract. Your smart contract will use some primitives that are common right? So why re-invent the wheel!
- The test folder contains testing scripts written in Solidity. Meant to cement the concept of test-driven development 
- The script folder contains contracts that deploy our main smart contracts of focus(`MarketPlace.sol`) onto the Ethereum blockchain
- The src folder contains your main contracts that you'll be developing. `MarketPlace.sol` is the main contract of focus here

The idea is:-
1. `CarbonCredits.sol` is the backend logic of this project. It is the one dealing with issuance of carbon credits, tracking carbon emission and trading.
1. `FunctionsConsumer.sol` is the contract that stores the API response coming from the IoT sensors. The API response is stored in the state variable `s_lastResponse`, API errors are stored in the state variable `s_lastError`. `s_lastRequestId` represents a unique identifier associated with a request sent from the smart contract `FunctionsConsumer.sol` to the IoT sensors. We utilize Chainlink Functions for this.
- With Chainlink Functions, you just sent computation code as JavaScript to a network of computers, Decentralized Oracle Network(DON), they do the computation and send back to your smart contract the results of the computation and errors if any
- So we send JavaScript code using Chainlink Functions. The JS code reaches the IoT API and retrieves what we want, which is the total carbon gas emitted by a company, adds the sum of carbon gas emitted together if there are multiple sensors in the company and returns the answer.

### NB: How exactly Chainlink Functions work is outside the scope of this file, kindly see [here](https://docs.chain.link/chainlink-functions/resources/architecture) for a detailed explanation

**The addition and retrieval of the API response only works if the sensor is functional and emits CO2!**

### Q: Why do we have to go this wierd Chainlink Functions intermediate. Can't we just send an API request directly from our smart contract?

**A: NO WE CAN'T. SOLIDITY DOES NOT HAVE THE ABILITY TO SEND HTTP REQUESTS NATIVELY IN A SMART CONTRACT! SO WE GO THROUGH CHAINLINK FUNCTIONS**


3. Once we have the response from the IoT API stored in `FunctionsConsumer.sol`, we import `FunctionsConsumer.sol` into `CarbonCredits.sol` so that we can read the API response into `CarbonCredits.sol` then use the response for our logic.

1. `script.js` is the JS code we send to the bunch of computers.
