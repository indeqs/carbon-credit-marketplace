const response = await Functions.makeHttpRequest({
    url: "https://api.npoint.io/bc44b7c8ff91cee9ce07"
});

if (response.error) {
    console.error("An error occurred: ", response.error);
    return;
}

// Initialize a variable to hold the sum of carbonGas
let totalCarbonGas = 0;

// Loop through the response data and sum the carbonGas where isFunctional is true and type is CO2
response.data.sensors.forEach(sensor => {
    if (sensor.isFunctional && sensor.type === "CO2") {
        totalCarbonGas += sensor.measurement.carbonGas;
    }
});

return Functions.encodeString(JSON.stringify({ totalCarbonGas }));
