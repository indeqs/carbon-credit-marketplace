// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {FunctionsClient} from "@chainlink/contracts@1.1.0/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts@1.1.0/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.1.0/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

/**
 * @title FunctionsConsumer
 * @dev This contract uses hardcoded values and should not be used in production.
 */
contract FunctionsConsumer is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // State variables to store the last request ID, response and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    uint256 public s_totalCarbonGas;
    bytes public s_lastError;

    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event Response(bytes32 indexed requestId, bytes response, bytes err);

    // Router address - Hardcoded for Ethereum Sepolia
    address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;

    // JavaScript source code
    string source =
        "const response = await Functions.makeHttpRequest({"
        "url: 'https://api.npoint.io/bc44b7c8ff91cee9ce07'"
        "});"
        "if (response.error) {"
        "console.error('An error occurred: ', response.error);"
        "return;"
        "}"
        "let totalCarbonGas = 0;"
        "response.data.sensors.forEach(sensor => {"
        "if (sensor.isFunctional && sensor.type === 'CO2') {"
        "totalCarbonGas += sensor.measurement.carbonGas;"
        "}"
        "});"
        "return Functions.encodeUint256(totalCarbonGas);";

    // Callback gas limit
    uint32 gasLimit = 300_000;

    // donID - Hardcoded for Ethereum Sepolia
    bytes32 donID =
        0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor() FunctionsClient(router) ConfirmedOwner(msg.sender) {}

    /**
     * @notice Sends an HTTP request for character information
     * @param subscriptionId The ID for the Chainlink subscription
     * @param args The arguments to pass to the HTTP request
     * @return requestId The ID of the request
     */
    function sendRequest(
        uint64 subscriptionId,
        string[] calldata args
    ) external onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        return s_lastRequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        s_totalCarbonGas = abi.decode(s_lastResponse, (uint256));
        s_lastError = err;

        // Emit an event to log the response
        emit Response(requestId, s_lastResponse, s_lastError);
    }
}
