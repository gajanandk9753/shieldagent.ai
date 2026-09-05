const mongoose = require("mongoose");

let isConnected = false;

async function connectDatabase() {
    if (isConnected && mongoose.connection.readyState === 1) {
        return;
    }

    try {
        await mongoose.connect(process.env.MONGO_URI, {
            serverSelectionTimeoutMS: 10000
        });

        isConnected = true;

        console.log("Database connected successfully");
    } catch (error) {
        isConnected = false;
        console.error("Error connecting with MongoDB:", error);
        throw error;
    }
}

module.exports = connectDatabase;